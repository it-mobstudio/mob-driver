import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:m_o_b_demand_side/core/utils/formatters.dart';
import 'package:m_o_b_demand_side/features/driver/data/media/invoice_actions.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/captured_photo.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/driver_profile.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/driver_stats.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/trip.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/wallet.dart';

import '../../support/fakes.dart';

Map<String, dynamic> kycJson({
  bool aadharSubmitted = true,
  bool dlSubmitted = true,
  bool policeSubmitted = false,
}) =>
    {
      'aadhar': {
        'status': 'pending',
        'submitted': aadharSubmitted,
        'number_last4': aadharSubmitted ? '0123' : null,
        'front_url': aadharSubmitted ? 'https://cdn.example.com/a-front.jpg' : null,
        'back_url': aadharSubmitted ? 'https://cdn.example.com/a-back.jpg' : null,
        'rejection_note': null,
      },
      'dl': {
        'status': 'pending',
        'submitted': dlSubmitted,
        'number': dlSubmitted ? 'KA01 20110012345' : null,
        'expiry_date': '2027-03-01',
        'front_url': dlSubmitted ? 'https://cdn.example.com/dl.jpg' : null,
        'back_url': null,
        'rejection_note': null,
      },
      'police': {
        'status': 'pending',
        'submitted': policeSubmitted,
        'document_url': null,
        'rejection_note': null,
      },
    };

void main() {
  group('DriverProfile: onboarding', () {
    test('a driver who has just signed up has nothing filled in yet', () {
      final p = DriverProfile.fromJson(profileJson(
        eligible: false,
        onboarding: 'profile_incomplete',
        fullName: '',
        profileComplete: false,
      ));

      expect(p.fullName, '');
      expect(p.isProfileComplete, isFalse);
      expect(p.onboardingStatus, OnboardingStatus.profileIncomplete);
      expect(p.onboardingStatus.needsSetup, isTrue);
    });

    test('only the first two statuses force the sign-up flow', () {
      final forced = OnboardingStatus.values.where((s) => s.needsSetup).toList();
      expect(forced, [OnboardingStatus.profileIncomplete, OnboardingStatus.documentsRequired]);
    });

    test('what was submitted comes through, with the Aadhaar masked to its last four', () {
      final p = DriverProfile.fromJson(profileJson(eligible: false, kyc: kycJson()));

      expect(p.aadhar.submitted, isTrue);
      expect(p.aadhar.reference, '•••• 0123');
      expect(p.aadhar.frontUrl, 'https://cdn.example.com/a-front.jpg');
      expect(p.aadhar.backUrl, 'https://cdn.example.com/a-back.jpg');
      expect(p.drivingLicence.reference, 'KA01 20110012345');
      expect(p.drivingLicence.backUrl, isNull);
      expect(p.police.submitted, isFalse);
    });

    test('a document needs an upload until it has been sent — or once it was sent back', () {
      const notSent = KycItem(KycStatus.pending);
      const inReview = KycItem(KycStatus.pending, submitted: true);
      const verified = KycItem(KycStatus.verified);
      const rejected = KycItem(KycStatus.rejected, submitted: true, rejectionNote: 'Blurry');

      expect(notSent.needsUpload, isTrue);
      expect(inReview.needsUpload, isFalse);
      expect(verified.needsUpload, isFalse, reason: 'verified without a scan on file is still verified');
      expect(rejected.needsUpload, isTrue);
    });

    test('a snapshot saved before onboarding existed still parses: eligible means approved', () {
      final old = profileJson(eligible: true)..remove('onboarding_status')..remove('kyc')..remove('payout');
      final p = DriverProfile.fromJson(old);
      expect(p.onboardingStatus, OnboardingStatus.approved);
      expect(p.payout.isSet, isFalse);

      final oldPending = profileJson(eligible: false)..remove('onboarding_status');
      expect(DriverProfile.fromJson(oldPending).onboardingStatus, OnboardingStatus.underReview);
    });

    test('name and date of birth lock once the Aadhaar is verified', () {
      expect(DriverProfile.fromJson(profileJson(eligible: true)).identityLocked, isTrue);
      expect(DriverProfile.fromJson(profileJson(eligible: false)).identityLocked, isFalse);
    });

    test('rejected documents are listed with the company\'s reason', () {
      final p = DriverProfile.fromJson({
        ...profileJson(eligible: false, onboarding: 'action_required'),
        'aadhar_status': 'rejected',
        'aadhar_rejection_note': 'Blurry',
        'police_status': 'rejected',
        'police_rejection_note': 'Not attested',
      });

      expect(p.rejectedDocuments.map((d) => d.$1), ['Aadhaar', 'Police verification']);
      expect(p.rejectedDocuments.map((d) => d.$2.rejectionNote), ['Blurry', 'Not attested']);
    });

    test('the licence expiry warning counts whole days from today', () {
      final soon = DateTime.now().add(const Duration(days: 12));
      final p = DriverProfile.fromJson({
        ...profileJson(),
        'dl_expiry_date': formatIsoDate(soon),
      });
      expect(p.licenceDaysLeft, 12);

      final today = DriverProfile.fromJson({...profileJson(), 'dl_expiry_date': formatIsoDate(DateTime.now())});
      expect(today.licenceDaysLeft, 0);
    });

    test('payout details summarise as a UPI id or a masked account', () {
      final upi = PayoutDetails.fromJson(const {'upi_id': 'ravi@okhdfc', 'is_set': true});
      expect(upi.summary, 'ravi@okhdfc');

      final bank = PayoutDetails.fromJson(const {
        'bank_account_holder': 'Ravi Kumar',
        'bank_account_last4': '9012',
        'bank_ifsc': 'HDFC0001234',
        'is_set': true,
      });
      expect(bank.summary, 'HDFC0001234 · ••••9012');
      expect(const PayoutDetails().summary, isNull);
    });

    test('copyWith keeps everything else, including what was submitted', () {
      final p = DriverProfile.fromJson(profileJson(eligible: false, kyc: kycJson()));
      final online = p.copyWith(isOnline: true);
      expect(online.isOnline, isTrue);
      expect(online.aadhar, p.aadhar);
      expect(online.onboardingStatus, p.onboardingStatus);
      expect(online.dateOfBirth, p.dateOfBirth);
    });
  });

  group('ProfileUpdate', () {
    test('sends only what was set, with dates in the wire format', () {
      final update = ProfileUpdate(
        fullName: 'Ravi Kumar',
        dateOfBirth: DateTime(1994, 3, 2),
        emergencyContactPhone: '+919555500002',
      );
      expect(update.toJson(), {
        'full_name': 'Ravi Kumar',
        'date_of_birth': '1994-03-02',
        'emergency_contact_phone': '+919555500002',
      });
    });

    test('an empty string is sent (it clears the field); null is not', () {
      expect(const ProfileUpdate(email: '', city: null).toJson(), {'email': ''});
    });
  });

  group('Trip: invoice, items and earning', () {
    Trip withItems(List<Map<String, dynamic>> items, {String status = 'in_progress', bool verify = true}) =>
        Trip.fromJson(tripJson(status: status, verifyItems: verify, items: items, paymentMode: 'prepaid', paymentStatus: 'paid'));

    test('an order with no goods information parses as before', () {
      final t = fakeTrip();
      expect(t.items, isEmpty);
      expect(t.hasItems, isFalse);
      expect(t.hasInvoice, isFalse);
      expect(t.verifyItems, isFalse);
      expect(t.driverEarning, isNull);
      expect(t.needsItemVerification, isFalse);
    });

    test('invoice, items and what the trip paid come through', () {
      final t = Trip.fromJson(tripJson(
        status: 'completed',
        invoiceUrl: 'https://files.example.com/INV-1001.pdf',
        invoiceNumber: 'INV-1001',
        driverEarning: '89.30',
        verifyItems: true,
        items: [
          itemJson(id: 'i-1', imageUrl: 'https://img.example.com/c.jpg'),
          itemJson(id: 'i-2', name: 'TMT bar', quantity: 20, unit: '', status: 'delivered', proofImageUrl: 'https://img.example.com/p.jpg'),
        ],
      ));

      expect(t.hasInvoice, isTrue);
      expect(t.invoiceNumber, 'INV-1001');
      expect(t.driverEarning, 89.3);
      expect(t.items, hasLength(2));
      expect(t.items.first.imageUrl, 'https://img.example.com/c.jpg');
      expect(t.items.first.unitPrice, 380.0);
      expect(t.items.last.status, ItemStatus.delivered);
      expect(t.items.last.proofImageUrl, 'https://img.example.com/p.jpg');
      expect(t.items.last.verifiedAt, isNotNull);
    });

    test('quantity reads with its unit when there is one', () {
      expect(TripItem.fromJson(itemJson(quantity: 4, unit: 'bags')).quantityLabel, '4 bags');
      expect(TripItem.fromJson(itemJson(quantity: 4, unit: '')).quantityLabel, '4');
    });

    test('an in-progress order still owed answers needs verification; once answered it does not', () {
      final pending = withItems([itemJson(id: 'a'), itemJson(id: 'b')]);
      expect(pending.needsItemVerification, isTrue);
      expect(pending.pendingItemCount, 2);
      expect(pending.resolvedItemCount, 0);

      final oneLeft = withItems([itemJson(id: 'a', status: 'delivered'), itemJson(id: 'b')]);
      expect(oneLeft.needsItemVerification, isTrue);
      expect(oneLeft.resolvedItemCount, 1);

      // "Not delivered" is an answer too — it's what unblocks the trip.
      final done = withItems([itemJson(id: 'a', status: 'delivered'), itemJson(id: 'b', status: 'not_delivered', note: 'Damaged')]);
      expect(done.needsItemVerification, isFalse);
      expect(done.items.last.driverNote, 'Damaged');
    });

    test('verification is only asked for when the company asked, and only mid-delivery', () {
      expect(withItems([itemJson()], verify: false).needsItemVerification, isFalse);
      expect(withItems([itemJson()], status: 'assigned').needsItemVerification, isFalse);
      expect(withItems([itemJson()], status: 'completed').needsItemVerification, isFalse);
    });

    test('a changed item makes a different trip, so the poller notices it', () {
      final before = withItems([itemJson(id: 'a')]);
      final after = withItems([itemJson(id: 'a', status: 'delivered')]);
      expect(before, isNot(after));
      expect(before, withItems([itemJson(id: 'a')]));
    });
  });

  group('wallet', () {
    test('the summary reads balance, periods, payouts and the seven days', () {
      final s = WalletSummary.fromJson(const {
        'balance': '260.00',
        'currency': 'INR',
        'today': {'earnings': '150.00', 'trips': 1},
        'week': {'earnings': '275.00', 'trips': 4},
        'month': {'earnings': '295.00', 'trips': 5},
        'lifetime': {'earnings': '305.00', 'trips': 6, 'payouts': '40.00'},
        'last_7_days': [
          {'date': '2026-09-22', 'earnings': '95.00', 'trips': 2},
          {'date': '2026-09-23', 'earnings': '150.00', 'trips': 1},
        ],
      });

      expect(s.balance, 260);
      expect(s.today.earnings, 150);
      expect(s.week.trips, 4);
      expect(s.lifetime.earnings, 305);
      expect(s.lifetimePayouts, 40);
      expect(s.last7Days.map((d) => d.date.day), [22, 23]);
      expect(s.last7Days.last.earnings, 150);
    });

    test('an empty answer is zeroes, never nulls', () {
      final s = WalletSummary.fromJson(const {});
      expect([s.balance, s.today.earnings, s.week.trips, s.lifetimePayouts], [0.0, 0.0, 0, 0.0]);
      expect(s.last7Days, isEmpty);
    });

    test('statement rows carry a sign and a kind', () {
      final credit = WalletEntry.fromJson(const {
        'id': 'w1', 'kind': 'trip_earning', 'amount': '68.00', 'balance_after': '68.00',
        'description': 'Delivery to Indiranagar', 'created_at': '2026-09-23T09:00:00Z',
      });
      final payout = WalletEntry.fromJson(const {
        'id': 'w2', 'kind': 'payout', 'amount': '-40.00', 'balance_after': '28.00', 'reference': 'UTR123',
      });

      expect((credit.kind, credit.isCredit, credit.amount), (WalletKind.tripEarning, true, 68.0));
      expect((payout.kind, payout.isCredit, payout.reference), (WalletKind.payout, false, 'UTR123'));
      expect(WalletEntry.fromJson(const {'id': 'x', 'kind': 'something_new'}).kind, WalletKind.unknown);
    });
  });

  group('stats', () {
    test('earnings are read next to the fare total', () {
      final s = PeriodStats.fromJson(const {'total_fare': '185.00', 'earnings': '148.00', 'trips_completed': 2});
      expect((s.totalFare, s.earnings), (185.0, 148.0));
      expect(PeriodStats.fromJson(const {}).earnings, 0);
    });
  });

  group('formatters', () {
    test('compact money labels a chart bar', () {
      expect(formatCompactMoney(0), '₹0');
      expect(formatCompactMoney(850), '₹850');
      expect(formatCompactMoney(1000), '₹1k');
      expect(formatCompactMoney(1234), '₹1.2k');
      expect(formatCompactMoney(12000), '₹12k');
      expect(formatCompactMoney(150000), '₹1.5L');
      expect(formatCompactMoney(-450), '-₹450');
    });

    test('signed money marks direction', () {
      expect(formatSignedMoney(68), '+₹68.00');
      expect(formatSignedMoney(-150), '−₹150.00');
    });

    test('day headings are relative for the last two days', () {
      final now = DateTime(2026, 9, 23, 15);
      expect(formatDayHeading(DateTime(2026, 9, 23, 1), now: now), 'Today');
      expect(formatDayHeading(DateTime(2026, 9, 22, 23), now: now), 'Yesterday');
      expect(formatDayHeading(DateTime(2026, 9, 20), now: now), 'Sun, 20 Sep');
    });

    test('dates for the wire and for people', () {
      expect(formatIsoDate(DateTime(2026, 3, 2)), '2026-03-02');
      expect(formatDate(DateTime(2026, 3, 2)), '2 Mar 2026');
      expect(formatDate(null), '—');
    });
  });

  group('invoice helpers', () {
    test('a WhatsApp link addresses the customer by digits only', () {
      final uri = whatsAppUri(phone: '+91 98888 00002', message: 'Hi Asha, invoice: https://x.com/a b?c=1&d=2');

      expect((uri.scheme, uri.host, uri.path), ('https', 'wa.me', '/919888800002'));
      expect(uri.queryParameters['text'], 'Hi Asha, invoice: https://x.com/a b?c=1&d=2');
    });

    test('without a number it opens WhatsApp\'s own chat picker', () {
      expect(whatsAppUri(message: 'x').path, '/');
      expect(whatsAppUri(phone: '', message: 'x').path, '/');
    });

    test('the shared file keeps the company\'s name for it, or is named after the invoice', () {
      expect(invoiceFileName('https://files.example.com/invoices/INV-1001.pdf'), 'INV-1001.pdf');
      expect(invoiceFileName('https://files.example.com/photo.JPG?x=1'), 'photo.JPG');
      expect(invoiceFileName('https://files.example.com/download?id=5', invoiceNumber: 'INV/1001'), 'Invoice-INV_1001.pdf');
      expect(invoiceFileName('https://files.example.com/download?id=5'), 'Invoice.pdf');
    });

    test('a captured photo\'s type follows its name', () {
      CapturedPhoto photo(String name) => CapturedPhoto(bytes: Uint8List(1), filename: name);
      expect(photo('a.jpg').mimeType, 'image/jpeg');
      expect(photo('A.PNG').mimeType, 'image/png');
      expect(photo('a.webp').mimeType, 'image/webp');
      expect(photo('a').mimeType, 'image/jpeg');
    });
  });
}
