import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'poster_template.dart';

class NeonPoster extends PosterTemplate {
  const NeonPoster({
    super.key,
    required super.data,
    super.width,
    super.height,
    super.customizationStore,
  });

  @override
  Widget buildPoster(BuildContext context, double scale, double w, double h) {
    return Container(
      color: const Color(0xFF050510), // Almost Black
      child: Stack(
        children: [
          // Background Glows
          Positioned(
            top: h * 0.2,
            left: w * 0.1,
            child: Container(
              width: w * 0.8,
              height: w * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.purpleAccent.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(20 * scale), // Reduced padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14 * scale,
                    vertical: 6 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(
                      color: Colors.cyanAccent,
                      width: 2 * scale,
                    ),
                    borderRadius: BorderRadius.circular(8 * scale),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.5),
                        blurRadius: 10 * scale,
                      ),
                    ],
                  ),
                  child: wrapEditable(
                    'companyName',
                    (text, s) => Text(
                      text.toUpperCase(),
                      style: GoogleFonts.orbitron(
                        fontSize: 11 * scale, // Reduced
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                      textScaler: TextScaler.linear(s),
                    ),
                    defaultText: data.companyName,
                  ),
                ),

                SizedBox(height: 20 * scale),

                // Neon Text
                Expanded(
                  flex: 3,
                  child: Center(
                    child: wrapEditable(
                      'jobTitle',
                      (text, s) => Text(
                        text.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.monoton(
                          fontSize: 28 * scale, // Reduced
                          color: Colors.pinkAccent,
                          shadows: [
                            BoxShadow(
                              color: Colors.pink,
                              blurRadius: 20 * scale,
                            ),
                            BoxShadow(
                              color: Colors.white,
                              blurRadius: 2 * scale,
                            ),
                          ],
                        ),
                        maxLines: 3,
                        textScaler: TextScaler.linear(s),
                      ),
                      defaultText: data.jobTitle,
                    ),
                  ),
                ),

                SizedBox(height: 10 * scale),

                wrapEditable(
                  'headline',
                  (text, s) => Text(
                    text.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.orbitron(
                      fontSize: 13 * scale,
                      color: Colors.cyanAccent,
                      letterSpacing: 1.5,
                    ),
                    textScaler: TextScaler.linear(s),
                  ),
                  defaultText:
                      data.catchyHeadline ?? 'TƯƠNG LAI LÀ NGAY LÚC NÀY',
                ),

                SizedBox(height: 20 * scale),

                // Grid details
                Container(
                  padding: EdgeInsets.all(14 * scale),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16 * scale),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    children: [
                      _buildNeonRow(
                        Icons.attach_money,
                        data.salaryRange,
                        scale,
                        Colors.greenAccent,
                        id: 'salary',
                      ),
                      SizedBox(height: 10 * scale),
                      _buildNeonRow(
                        Icons.location_on,
                        data.location,
                        scale,
                        Colors.purpleAccent,
                        id: 'location',
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20 * scale),

                // Requirements & Benefits
                Expanded(
                  flex: 4,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'YÊU CẦU',
                              style: GoogleFonts.orbitron(
                                color: Colors.cyanAccent,
                                fontSize: 11 * scale,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (data.requirements.isNotEmpty)
                              ...data.requirements
                                  .take(3)
                                  .map((req) => _buildNeonItem(req, scale)),
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
                              style: GoogleFonts.orbitron(
                                color: Colors.pinkAccent,
                                fontSize: 11 * scale,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (data.benefits.isNotEmpty)
                              ...data.benefits
                                  .take(3)
                                  .map((ben) => _buildNeonItem(ben, scale)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                wrapEditable(
                  'contactInfo',
                  (text, s) => Text(
                    text,
                    style: GoogleFonts.orbitron(
                      fontSize: 14 * scale, // Reduced
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textScaler: TextScaler.linear(s),
                  ),
                  defaultText: data.contactInfo,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeonItem(String text, double scale) {
    return Padding(
      padding: EdgeInsets.only(top: 3 * scale),
      child: Text(
        '> $text',
        style: GoogleFonts.orbitron(
          fontSize: 10 * scale,
          color: Colors.white70,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildNeonRow(
    IconData icon,
    String text,
    double scale,
    Color color, {
    String? id,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 16 * scale),
        SizedBox(width: 8 * scale),
        id != null
            ? wrapEditable(
                id,
                (t, s) => Text(
                  t,
                  style: GoogleFonts.orbitron(
                    fontSize: 13 * scale,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                  textScaler: TextScaler.linear(s),
                ),
                defaultText: text,
              )
            : Text(
                text,
                style: GoogleFonts.orbitron(
                  fontSize: 13 * scale,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
      ],
    );
  }

  @override
  String get templateId => 'neon';
}
