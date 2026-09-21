# MOB Driver

Flutter app for delivery drivers, talking to `../mob-delivery-backend` (Django/DRF).
API reference (HTML): open `../mob-delivery-backend/docs/api/index.html` in any browser — one
self-contained file — or run the backend and visit `/api/redoc/` (reading) or `/api/docs/` (try calls).

**Journey:** phone → SMS OTP → *(new drivers: details + Aadhaar / licence photos →
company approval)* → dashboard → *Start duty* (location permission, pick a vehicle) → a
trip is assigned → map with the route polyline → arrive → start → *(items: check each one
off, optional photo)* → *scan-to-pay QR* (COD) → customer's OTP → complete → paid into the
**wallet**. Plus the invoice (download / WhatsApp / share), trip history, earnings, payout
details, vehicle switching, document status and sign-out / delete account.

## Run it

**1. Backend** (from `../mob-delivery-backend`). `.env` points at local Postgres (db
`driver`) and Redis; `seed_drivers` creates KYC-verified drivers `+919000000000`…`09`.

```bash
source .venv/bin/activate
python manage.py migrate
python manage.py seed_drivers --count 10        # skip if already seeded
python manage.py runserver 0.0.0.0:8000         # DRIVER_OTP_DEBUG_RESPONSE=True → the app shows the OTP
docker compose up -d valhalla                   # routing; first start builds Bengaluru tiles (minutes)
```

Without Valhalla, booking a trip fails with `503 ROUTING_UNAVAILABLE`.

**2. App** (from `mob-driver`)

```bash
flutter pub get
open -a Simulator && flutter run               # iOS simulator → http://127.0.0.1:8000
flutter run -d <android-emulator-id>           # Android emulator → http://10.0.2.2:8000
flutter run --dart-define=API_BASE_URL=http://<your-mac-ip>:8000/api/v1/   # real phone (add the IP to ALLOWED_HOSTS)
```

Sign in with `9000000000` — the app shows the OTP ("Test mode … Fill").

**3. Put an order on the driver.** The app can't create orders — the *company* side books
them and the backend assigns the nearest online driver. For testing there's a one-liner:

```bash
# terminal A — routing (draws the route line). Pick one:
python scripts/dev_valhalla_stub.py            # instant stand-in, works anywhere, ignores real roads
docker compose up -d valhalla                  # the real thing; only covers Bengaluru; first start takes minutes

# in the app: tap "Start duty" (allow location, pick a vehicle)   ← the driver must be on duty

# terminal B — book an order next to that driver
python manage.py book_test_trip                            # the FULL flow: COD + 3 items to verify + invoice,
                                                          # pickup at the driver, drop ~4 km away
python manage.py book_test_trip --mode prepaid --distance-km 8
python manage.py book_test_trip --items 0 --no-invoice     # a plain order; also --no-verify-items, --items 5
python manage.py book_test_trip --pickup-lat 12.9716 --pickup-lng 77.5946 \
    --drop-lat 12.9784 --drop-lng 77.6408 --pickup-address "MG Road" --drop-address "Indiranagar"
```

The trip opens on the driver's screen within ~5 s: map with the route line → arrive → start →
payment QR → the customer's OTP (shown in the app in test mode) → complete.

The driver is matched from their phone's GPS: on Chrome that's your real location (allow it in
the browser); on a simulator set a custom location. The command puts the pickup at the driver's
last reported spot, so they're always the nearest driver.

Booking the way a real company system does — `POST /api/v1/trips` with an API-client token
(`python manage.py create_api_client --company-name MOB --name local`) — is documented in the API
reference (*Booking a delivery*); try it from Swagger at `/api/docs/`.

### New drivers, wallet, items and invoice

Anyone can now sign in with a new number — the backend creates them a driver account in the
company set by `DRIVER_SIGNUP_COMPANY_ID` (in `DEBUG`, the only company is used). Try it:

```bash
python manage.py migrate                         # once, after pulling this change
# in the app: sign in with a NEW number (e.g. 9555500001)
#   → "Tell us about yourself" → Aadhaar + licence (camera or gallery) → "Under review"
python manage.py approve_driver --phone +919555500001      # what the company's review does
python manage.py approve_driver --phone +919555500001 --reject aadhar --note "Blurry"   # try "fix and re-upload"
# pull to refresh in the app → the dashboard unlocks; tap Start duty, then:
python manage.py book_test_trip --phone +919555500001      # 3 items, verification on, invoice — all the defaults
```

That order has three items with pictures, asks the driver to verify each at the drop (tick
*Delivered*, or *Problem* with a reason; a photo is optional and taken with the camera), and
carries a real sample invoice PDF with **Download / WhatsApp / Share** buttons. Payment and
completion are blocked until every item has an answer. Completing pays the driver
`DRIVER_EARNING_PERCENT`% (80 by default) of the fare into the **Wallet** tab: balance,
today / week / month / all time, a 7-day chart and the statement. The company records payouts
with `POST /drivers/{id}/wallet/transactions` (see the API reference); Django admin has a read-only
view of the ledger.

The company sends the invoice and items when it books (`invoice_url`, `invoice_number`,
`verify_items`, `items[]` on `POST /trips`) — see the API reference (*Items & invoices*).

### Razorpay locally (the scan-to-pay QR)

For a cash-on-delivery trip the backend asks **Razorpay** for a single-use QR for the exact fare and
learns it was paid from Razorpay's webhook (or when the driver taps *Check payment*). The default
`PAYMENT_PROVIDER=razorpay` therefore needs keys — until they're set the payment screen shows
"Online payments aren't set up on this server yet". Three ways to run it locally:

```bash
# 1. Real Razorpay, Test mode — the only way to prove the real service accepts our requests
#    .env: PAYMENT_PROVIDER=razorpay  RAZORPAY_KEY_ID=rzp_test_…  RAZORPAY_KEY_SECRET=…  RAZORPAY_WEBHOOK_SECRET=…
#    Razorpay Dashboard → Webhooks → https://<public tunnel>/api/v1/webhooks/razorpay, event qr_code.credited

# 2. The local stand-in for Razorpay (no account; built from Razorpay's public docs, so it proves
#    OUR plumbing, not that the real service agrees)
python scripts/dev_razorpay_stub.py                    # :8003 — lists the codes it has issued
#    .env: PAYMENT_PROVIDER=razorpay RAZORPAY_KEY_ID=rzp_test_stub RAZORPAY_KEY_SECRET=stub_secret
#          RAZORPAY_WEBHOOK_SECRET=stub_webhook_secret RAZORPAY_API_BASE=http://127.0.0.1:8003/v1
curl -X POST http://127.0.0.1:8003/simulate/<qr id>                # "the customer pays" + webhook
curl -X POST "http://127.0.0.1:8003/simulate/<qr id>?webhook=0"    # pays, but no webhook (Check payment finds it)

# 3. Plain UPI link, nothing verified — the driver's "Payment received" tap is trusted. Never for real money.
#    .env: PAYMENT_PROVIDER=upi_static
```

With Razorpay the payment screen shows Razorpay's QR image, a countdown, "Waiting for the
customer's payment", and moves on to the OTP by itself when the trip turns paid; an expired code
offers "Get a new code". Full flow, webhook setup and edge cases: *Payments (Razorpay)* in the API reference.

### The API documentation

Everything about the API — every endpoint with required/optional fields, examples and errors,
plus guides — is HTML:

| Where | What |
|---|---|
| `mob-delivery-backend/docs/api/index.html` | **One self-contained file.** Open it, e-mail it, or host it on any static host (S3, GitHub Pages, Netlify). No server needed. |
| `/api/redoc/` on the running backend | The same reference with the menu / sub-menu. |
| `/api/docs/` | Swagger UI — *Authorize* with a token and *Try it out*. |
| `/api/schema/` and `docs/api/openapi.yaml` | The OpenAPI file, for Postman or client generators. |

After changing an endpoint, serializer, guide or error code run
`python manage.py build_api_docs` in the backend (`--server-url https://api.example.com/api/v1`
to aim the samples at production); `python manage.py test core.test_openapi` fails while the
committed files are stale, an endpoint is undocumented, or an example no longer matches the API.

`--dart-define` options: `API_BASE_URL`, `GOOGLE_MAPS_API_KEY`, `APP_UPDATE_CHECK=true`
(only if the backend serves `utility/app-version/`).

## Layout

```
lib/features/driver/
  domain/        entities (Trip, DriverProfile, …) + repository interface
  data/          datasource (HTTP), repository, GPS service, on-device snapshot cache
  presentation/
    bloc/        DriverSessionCubit — duty, GPS pings, new-trip polling, trip actions
    pages/       dashboard, trip (map + polyline), item checklist, payment QR, delivery OTP,
                 history, wallet, vehicle, profile, onboarding, documents, edit details, payout details
    widgets/     forms, document sheets + photo tiles, invoice card, shared UI
  data/media/    camera (PhotoCapture) and invoice download / WhatsApp / share (InvoiceActions),
                 both behind interfaces so screens are tested without a phone
lib/features/auth/   phone + OTP login (refresh/logout in core/auth/auth_session.dart)
```

Onboarding is a full-screen layer inside the bottom-nav shell (`ScaffoldWithNavBar`), shown
exactly while the backend's `onboarding_status` says it's the driver's turn — not a route, so
the session that loads the profile keeps running underneath.

`DriverSessionCubit` is an app-wide singleton: it keeps pinging location and polling for
trips whatever screen is showing. Trips reach the app by polling because the backend has
no push channel yet.

## Tests

```bash
flutter test                                    # 300+ unit/widget tests, no server needed
LIVE_API=http://127.0.0.1:8000/api/v1/ LIVE_PHONE=+919000000001 \
  LIVE_CLIENT_ID=… LIVE_CLIENT_SECRET=… flutter test test/live   # real client code vs a real backend
```

`test/live/live_onboarding_test.dart` walks the whole new-driver journey (sign-up, photo
uploads, review, an order with items and invoice, wallet, payout, deleting the account) and
needs a backend on a **throwaway database** plus an admin login — its header has the recipe.

Widget tests load the real Inter font (`test/support/fonts.dart`); without it Flutter's
Ahem test font makes text ~2× wider and reports overflows that don't exist on a device.

## Leftovers

* Never run on a device or simulator (none installed here). Verified: unit/widget tests, the
  real data layer against a real backend, and a web build. Unverified until you run it: the
  camera and photo permission prompts, the share sheet / WhatsApp hand-off, and how the new
  screens look and animate on hardware.
* Documents are photographed (camera or gallery); PDFs can't be picked in the app yet.
* KYC scans are stored in the public media location under unguessable names — use a private
  Azure container with expiring links before real documents go through it.
* Payouts are recorded by the company; the driver can't request a withdrawal yet.

`lib/features/{cart,checkout,credit,home,magic_quote,orders,product,profile,rfq,address}`
are the old customer app. Nothing routes to them; they can be deleted.
