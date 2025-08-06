import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class AddressSelectionWidget extends StatelessWidget {
  const AddressSelectionWidget({super.key});

  static String routeName = 'AddressSelection';
  static String routePath = '/address_selection';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Color(0xFF0A243F)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0.0,
        title: Text('Search location',
            style: GoogleFonts.interTight(
                color: Color(0xFF0A243F),
                fontWeight: FontWeight.bold,
                fontSize: 20)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search for area, street name..',
                  prefixIcon: Icon(Icons.search, color: Color(0xFFAFB4C0)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                ),
              ),
              SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.my_location, color: Color(0xFF0360E5)),
                title: Text('Detect my location',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                subtitle: Text('Koramangala, Bengaluru',
                    style: GoogleFonts.inter(color: Color(0xFF6C7C8C))),
                onTap: () {},
              ),
              SizedBox(height: 8),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFFE0E0E0)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add, color: Color(0xFF0360E5)),
                      SizedBox(width: 8),
                      Text('Add new address',
                          style:
                              GoogleFonts.inter(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              Text('Your saved address',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600, fontSize: 16)),
              SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    _addressCard(
                        context,
                        'Corey Howell',
                        '66138 Legros Mission Suite 804 Eden Plain Apt. 613, Behind starbucks Chennai, 600009',
                        'Home',
                        'Project: Hotel California'),
                    _addressCard(
                        context,
                        'Lando Norris',
                        '66138 Legros Mission Suite 804 Eden Plain Apt. 613, Behind starbucks Chennai, 600009',
                        'Home',
                        'Project: Hotel California'),
                    _addressCard(
                        context,
                        'Johnathan Wick',
                        '66138 Legros Mission Suite 804 Eden Plain Apt. 613, Behind starbucks Chennai, 600009',
                        'Home',
                        'Project: Hotel California'),
                    _addressCard(
                        context,
                        'Corey Howell',
                        '66138 Legros Mission Suite 804 Eden Plain Apt. 613, Behind starbucks Chennai, 600009',
                        'Home',
                        'Project: Hotel California'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addressCard(BuildContext context, String name, String address,
      String tag, String project) {
    return GestureDetector(
      onTap: () {
        GoRouter.of(context).go('/homepage');
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFFE0E0E0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(name,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Icon(Icons.more_horiz, color: Color(0xFFAFB4C0)),
              ],
            ),
            SizedBox(height: 4),
            Text(address,
                style:
                    GoogleFonts.inter(color: Color(0xFF6C7C8C), fontSize: 14)),
            SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFFF2F6F9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(tag,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500, fontSize: 12)),
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFE066),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(project,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500, fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
