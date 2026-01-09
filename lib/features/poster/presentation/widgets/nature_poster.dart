import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'poster_template.dart';

class NaturePoster extends PosterTemplate {
  const NaturePoster({
    super.key,
    required super.data,
    super.width,
    super.height,
    super.customizationStore,
  });

  @override
  Widget buildPoster(BuildContext context, double scale, double w, double h) {
    // Colors
    final bgColor = const Color(0xFFF3F6E9); // Lightsage
    final darkGreen = const Color(0xFF2E4F2F);

    return Container(
      color: bgColor,
      child: Stack(
        children: [
          // Leaves
          Positioned(
            top: -50 * scale,
            right: -50 * scale,
            child: Container(
              width: 200 * scale,
              height: 200 * scale,
              decoration: BoxDecoration(
                color: const Color(0xFF88B04B).withOpacity(0.2),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(100 * scale),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -30 * scale,
            left: -30 * scale,
            child: Container(
              width: 150 * scale,
              height: 150 * scale,
              decoration: BoxDecoration(
                color: darkGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(20 * scale), // Reduced padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 10 * scale),

                // Company Tag
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14 * scale,
                    vertical: 5 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20 * scale),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: wrapEditable(
                    'companyName',
                    (text, s) => Text(
                      text.toUpperCase(),
                      style: GoogleFonts.sourceSans3(
                        fontSize: 11 * scale, // Reduced
                        fontWeight: FontWeight.bold,
                        color: darkGreen,
                        letterSpacing: 1.0,
                      ),
                      textScaler: TextScaler.linear(s),
                    ),
                    defaultText: data.companyName,
                  ),
                ),

                SizedBox(height: 16 * scale),

                // Job Title
                wrapEditable(
                  'jobTitle',
                  (text, s) => Text(
                    text,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28 * scale, // Reduced from 32
                      fontWeight: FontWeight.w700,
                      color: darkGreen,
                      height: 1.1,
                    ),
                    maxLines: 3,
                    textScaler: TextScaler.linear(s),
                  ),
                  defaultText: data.jobTitle,
                ),

                SizedBox(height: 8 * scale),

                // Greeting
                wrapEditable(
                  'headline',
                  (text, s) => Text(
                    text,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.sourceSans3(
                      fontSize: 13 * scale,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[700],
                    ),
                    textScaler: TextScaler.linear(s),
                  ),
                  defaultText:
                      data.catchyHeadline ?? 'Cùng phát triển vững bền',
                ),

                SizedBox(height: 16 * scale),

                // Info Card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(14 * scale),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20 * scale),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildRowItem(
                        Icons.monetization_on_outlined,
                        data.salaryRange,
                        scale,
                        darkGreen,
                        id: 'salary',
                      ),
                      Divider(height: 12 * scale),
                      _buildRowItem(
                        Icons.location_on_outlined,
                        data.location,
                        scale,
                        darkGreen,
                        id: 'location',
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 12 * scale),

                // List Container
                Expanded(
                  flex: 5,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'YÊU CẦU',
                              style: GoogleFonts.sourceSans3(
                                fontSize: 11 * scale,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF88B04B),
                                letterSpacing: 1.0,
                              ),
                            ),
                            SizedBox(height: 6 * scale),
                            if (data.requirements.isNotEmpty)
                              ...data.requirements.asMap().entries.take(3).map((
                                entry,
                              ) {
                                final index = entry.key;
                                final req = entry.value;
                                return wrapEditable(
                                  'req_$index',
                                  (text, s) => _buildListItem(
                                    text,
                                    scale,
                                    darkGreen,
                                    Icons.eco,
                                  ),
                                  defaultText: req,
                                );
                              }),
                          ],
                        ),
                      ),
                      SizedBox(width: 8 * scale),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'QUYỀN LỢI',
                              style: GoogleFonts.sourceSans3(
                                fontSize: 11 * scale,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF88B04B),
                                letterSpacing: 1.0,
                              ),
                            ),
                            SizedBox(height: 6 * scale),
                            if (data.benefits.isNotEmpty)
                              ...data.benefits.asMap().entries.take(3).map((
                                entry,
                              ) {
                                final index = entry.key;
                                final ben = entry.value;
                                return wrapEditable(
                                  'ben_$index',
                                  (text, s) => _buildListItem(
                                    text,
                                    scale,
                                    darkGreen,
                                    Icons.wb_sunny_outlined,
                                  ),
                                  defaultText: ben,
                                );
                              }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Contact Button
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 10 * scale),
                  decoration: BoxDecoration(
                    color: darkGreen,
                    borderRadius: BorderRadius.circular(25 * scale),
                  ),
                  child: wrapEditable(
                    'contactInfo',
                    (text, s) => Text(
                      'ỨNG TUYỂN: $text',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.sourceSans3(
                        fontSize: 12 * scale,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textScaler: TextScaler.linear(s),
                    ),
                    defaultText: data.contactInfo,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(String text, double scale, Color color, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4 * scale),
      child: Row(
        children: [
          Icon(icon, size: 10 * scale, color: color),
          SizedBox(width: 4 * scale),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.sourceSans3(
                fontSize: 11 * scale,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRowItem(
    IconData icon,
    String text,
    double scale,
    Color color, {
    String? id,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(5 * scale),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 12 * scale, color: color),
        ),
        SizedBox(width: 10 * scale),
        Expanded(
          child: id != null
              ? wrapEditable(
                  id,
                  (t, s) => Text(
                    t,
                    style: GoogleFonts.sourceSans3(
                      fontSize: 13 * scale,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    textScaler: TextScaler.linear(s),
                  ),
                  defaultText: text,
                )
              : Text(
                  text,
                  style: GoogleFonts.sourceSans3(
                    fontSize: 13 * scale,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
        ),
      ],
    );
  }

  @override
  String get templateId => 'nature';
}
