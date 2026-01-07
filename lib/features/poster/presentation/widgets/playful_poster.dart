import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'poster_template.dart';

class PlayfulPoster extends PosterTemplate {
  const PlayfulPoster({
    super.key,
    required super.data,
    super.width,
    super.height,
    super.customizationStore,
  });

  @override
  String get templateId => 'playful';

  @override
  Widget buildPoster(BuildContext context, double scale, double w, double h) {
    // Neo-Brutalism / Pop Palette
    final bgColor = const Color(0xFFFEF9E7); // Cream
    final primaryColor = const Color(0xFFFF6B6B); // Red/Pink
    final secondaryColor = const Color(0xFF4ECDC4); // Teal
    final yellowColor = const Color(0xFFFFD93D); // Yellow
    final purpleColor = const Color(0xFF6C5CE7); // Purple
    final textColor = const Color(0xFF2D3436);

    return Container(
      width: w,
      height: h,
      color: bgColor,
      child: Stack(
        children: [
          // Background Shapes (Abstract)
          Positioned(
            top: -50 * scale,
            right: -50 * scale,
            child: _buildBlob(200 * scale, yellowColor.withValues(alpha: 0.3)),
          ),
          Positioned(
            bottom: 100 * scale,
            left: -30 * scale,
            child: _buildBlob(
              150 * scale,
              secondaryColor.withValues(alpha: 0.3),
            ),
          ),
          Positioned(
            top: 200 * scale,
            left: -40 * scale,
            child: Transform.rotate(
              angle: -0.2, // Radians
              child: Container(
                width: 100 * scale,
                height: 100 * scale,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20 * scale),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(24.0 * scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Header: Company Name Pill
                  Center(
                    child: _buildNeoCard(
                      color: Colors.white,
                      scale: scale,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.0 * scale,
                          vertical: 8.0 * scale,
                        ),
                        child: wrapEditable(
                          'companyName',
                          (t, s) => Text(
                            t.toUpperCase(),
                            style: GoogleFonts.fredoka(
                              fontSize: 14 * scale,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              letterSpacing: 1.0,
                            ),
                            textScaler: TextScaler.linear(s),
                          ),
                          defaultText: data.companyName,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 20 * scale),

                  // Job Title "Sticker"
                  Transform.rotate(
                    angle: -0.05,
                    child: _buildNeoCard(
                      color: yellowColor,
                      scale: scale,
                      offset: Offset(4 * scale, 4 * scale),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 20 * scale,
                          vertical: 24 * scale,
                        ),
                        child: Column(
                          children: [
                            wrapEditable(
                              'headline',
                              (t, s) => Text(
                                t,
                                style: GoogleFonts.permanentMarker(
                                  fontSize: 16 * scale,
                                  color: Colors.black54,
                                ),
                                textScaler: TextScaler.linear(s),
                              ),
                              defaultText:
                                  data.catchyHeadline ?? 'TUYỂN DỤNG',
                            ),
                            SizedBox(height: 8 * scale),
                            wrapEditable(
                              'jobTitle',
                              (t, s) => Text(
                                t.toUpperCase(),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.fredoka(
                                  fontSize: 40 * scale, // Massive font
                                  fontWeight: FontWeight.w900,
                                  color: textColor,
                                  height: 1.0,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.visible,
                                textScaler: TextScaler.linear(s),
                              ),
                              defaultText: data.jobTitle,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 24 * scale),

                  // Salary & Location Chips
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoTag(
                          icon: Icons.monetization_on_outlined,
                          text: data.salaryRange,
                          color: secondaryColor,
                          scale: scale,
                          id: 'salary',
                        ),
                      ),
                      SizedBox(width: 12 * scale),
                      Expanded(
                        child: _buildInfoTag(
                          icon: Icons.location_on_outlined,
                          text: data.location.split(',').last.trim(),
                          color: primaryColor,
                          scale: scale,
                          id: 'location',
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24 * scale),

                  // Main Content: Requirements & Benefits
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Col 1: Requirements
                        Expanded(
                          child: _buildListCard(
                            title: 'YÊU CẦU',
                            items: data.requirements,
                            color: Colors.white,
                            accentColor: purpleColor,
                            scale: scale,
                            prefix: 'req',
                            rotation: 0.02,
                          ),
                        ),
                        SizedBox(width: 12 * scale),
                        // Col 2: Benefits
                        Expanded(
                          child: _buildListCard(
                            title: 'QUYỀN LỢI',
                            items: data.benefits,
                            color: Colors.white,
                            accentColor: secondaryColor,
                            scale: scale,
                            prefix: 'ben',
                            rotation: -0.01,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20 * scale),

                  // Footer: Apply Now
                  _buildNeoCard(
                    color: Colors.black,
                    scale: scale,
                    offset: Offset(4 * scale, 4 * scale),
                    child: Padding(
                      padding: EdgeInsets.all(16 * scale),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.send_rounded,
                            color: yellowColor,
                            size: 24 * scale,
                          ),
                          SizedBox(width: 12 * scale),
                          Expanded(
                            child: wrapEditable(
                              'contactInfo',
                              (t, s) => Text(
                                t,
                                style: GoogleFonts.fredoka(
                                  fontSize: 14 * scale,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textScaler: TextScaler.linear(s),
                              ),
                              defaultText: 'ỨNG TUYỂN: ${data.contactInfo}',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildBlob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildNeoCard({
    required Widget child,
    required Color color,
    required double scale,
    Offset? offset,
  }) {
    final shadowOffset = offset ?? Offset(3 * scale, 3 * scale);
    return Container(
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.black, width: 2.0 * scale),
        borderRadius: BorderRadius.circular(12 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            offset: shadowOffset,
            blurRadius: 0, // Solid shadow
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInfoTag({
    required IconData icon,
    required String text,
    required Color color,
    required double scale,
    required String id,
  }) {
    return _buildNeoCard(
      color: Colors.white,
      scale: scale,
      offset: Offset(2 * scale, 2 * scale),
      child: Padding(
        padding: EdgeInsets.all(12 * scale),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(8 * scale),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24 * scale),
            ),
            SizedBox(height: 8 * scale),
            wrapEditable(
              id,
              (t, s) => Text(
                t,
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textScaler: TextScaler.linear(s),
              ),
              defaultText: text,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListCard({
    required String title,
    required List<String> items,
    required Color color,
    required Color accentColor,
    required double scale,
    required String prefix,
    required double rotation,
  }) {
    return Transform.rotate(
      angle: rotation,
      child: _buildNeoCard(
        color: color,
        scale: scale,
        child: Padding(
          padding: EdgeInsets.all(16 * scale),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12 * scale,
                  vertical: 4 * scale,
                ),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(20 * scale),
                  border: Border.all(color: Colors.black, width: 1.5 * scale),
                ),
                child: Text(
                  title,
                  style: GoogleFonts.fredoka(
                    fontSize: 12 * scale,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 12 * scale),
              Expanded(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    children: items.asMap().entries.map((entry) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 8 * scale),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '• ',
                              style: TextStyle(
                                fontSize: 14 * scale,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Expanded(
                              child: wrapEditable(
                                '${prefix}_${entry.key}',
                                (t, s) => Text(
                                  t,
                                  style: GoogleFonts.quicksand(
                                    fontSize: 12 * scale,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                    height: 1.2,
                                  ),
                                  textScaler: TextScaler.linear(s),
                                ),
                                defaultText: entry.value,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
