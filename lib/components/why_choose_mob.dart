import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Use this inside your page/widget

/// Opens the promise popup

/// The popup content
class PromiseSheet extends StatelessWidget {
  const PromiseSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin:
            const EdgeInsets.only(top: 48), // leave a bit of backdrop at top
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Hero / Header
            _Header(),
            // Body list (scrollable)
            Flexible(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: const [
                  _PromiseBullet(
                    icon: Icons.local_shipping_outlined,
                    title: 'Same day delivery',
                    desc:
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Maecenas eget felis sit amet.',
                  ),
                  _PromiseBullet(
                    icon: Icons.verified_user_outlined,
                    title: 'Assured quality',
                    desc:
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Maecenas eget felis sit amet.',
                  ),
                  _PromiseBullet(
                    icon: Icons.savings_outlined,
                    title: 'Save money',
                    desc:
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Maecenas eget felis sit amet.',
                  ),
                  _PromiseBullet(
                    icon: Icons.receipt_long_outlined,
                    title: 'One point billing',
                    desc:
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Maecenas eget felis sit amet.',
                  ),
                  _PromiseBullet(
                    icon: Icons.assignment_turned_in_outlined,
                    title: 'Warranty claims',
                    desc:
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Maecenas eget felis sit amet.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Header with gradient, logo text, person image and close button
class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF274D7B), Color(0xFF3D6EA1)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Stack(
        children: [
          // Right side model image (replace with your asset)
          Positioned(
            right: 12,
            bottom: 0,
            child: Image.asset(
              'assets/images/mob_person.png', // TODO: add your asset
              height: 160,
              fit: BoxFit.contain,
            ),
          ),
          // Branding text
          Positioned.fill(
            left: 16,
            right: 140,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Replace with your logo if you have an SVG/PNG
                  Text('mad over\nbuildings',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      )),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('promise',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          )),
                      const SizedBox(width: 6),
                      const Icon(Icons.verified, color: Colors.white, size: 20),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Close button
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// Single bullet row
class _PromiseBullet extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;

  const _PromiseBullet({
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFF2F6F9),
            child: Icon(icon, color: const Color(0xFF0A243F)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0A243F),
                    )),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF6C7C8C),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
