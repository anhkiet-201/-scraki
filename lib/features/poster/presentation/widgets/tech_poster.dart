import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'poster_template.dart';

class TechPoster extends PosterTemplate {
  const TechPoster({
    super.key,
    required super.data,
    super.width,
    super.height,
    super.customizationStore,
  });

  @override
  Widget buildPoster(BuildContext context, double scale, double w, double h) {
    final bgColor = const Color(0xFF0A0F1C);
    final accentColor1 = const Color(0xFF00F0FF); // Cyan
    final accentColor2 = const Color(0xFFFF003C); // Magenta
    final textColor = const Color(0xFFE0E0E0);

    return Container(
      width: w,
      height: h,
      color: bgColor,
      child: Stack(
        children: [
          // Background Grid Effect
          Positioned.fill(
            child: CustomPaint(
              painter: GridPainter(color: accentColor1.withValues(alpha: 0.05)),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(12 * scale), // Reduced from 16
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Headline & Company
                Row(
                  children: [
                    Container(
                      width: 4 * scale,
                      height: 26 * scale, // Reduced from 32 (and 40 prev)
                      color: accentColor2,
                    ),
                    SizedBox(width: 12 * scale),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          wrapEditable(
                            'headline',
                            (t, s) => Text(
                              t,
                              style: GoogleFonts.orbitron(
                                fontSize: 10 * scale, // Reduced from 12
                                fontWeight: FontWeight.bold,
                                color: accentColor1,
                                letterSpacing: 1.5,
                              ),
                              textScaler: TextScaler.linear(s),
                            ),
                            defaultText:
                                data.catchyHeadline?.toUpperCase() ??
                                'ĐANG TUYỂN DỤNG',
                          ),
                          SizedBox(height: 4 * scale),
                          wrapEditable(
                            'companyName',
                            (t, s) => Text(
                              t,
                              style: GoogleFonts.robotoMono(
                                fontSize: 14 * scale, // Reduced from 16
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textScaler: TextScaler.linear(s),
                            ),
                            defaultText: data.companyName.toUpperCase(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12 * scale), // Reduced from 16
                // Job Title
                wrapEditable(
                  'jobTitle',
                  (t, s) => Text(
                    t,
                    style: GoogleFonts.orbitron(
                      fontSize: 20 * scale, // Reduced from 24 (and 28, 32 prev)
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textScaler: TextScaler.linear(s),
                  ),
                  defaultText: data.jobTitle.toUpperCase(),
                ),

                SizedBox(height: 16 * scale), // Reduced from 24
                // Info Grid (Salary & Location)
                Container(
                  padding: EdgeInsets.all(8 * scale), // Reduced from 12
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: accentColor1.withValues(alpha: 0.3),
                    ),
                    color: accentColor1.withValues(alpha: 0.05),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTechInfo(
                          'MỨC LƯƠNG',
                          data.salaryRange,
                          accentColor1,
                          scale,
                          id: 'salary',
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40 * scale,
                        color: accentColor1.withValues(alpha: 0.3),
                      ),
                      SizedBox(width: 12 * scale), // Reduced from 16
                      Expanded(
                        child: _buildTechInfo(
                          'ĐỊA ĐIỂM',
                          data.location,
                          accentColor1,
                          scale,
                          id: 'location',
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 12 * scale), // Reduced from 16
                // Details Sections
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Requirements Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '// YÊU CẦU',
                              style: GoogleFonts.robotoMono(
                                fontSize: 10 * scale, // Reduced from 12
                                color: accentColor2,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 12 * scale),
                            if (data.requirements.isNotEmpty)
                              ...data.requirements.asMap().entries.map(
                                (entry) => _buildTechListItem(
                                  entry.value,
                                  accentColor1,
                                  scale,
                                  textColor,
                                  id: 'req_${entry.key}',
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(width: 24 * scale),
                      // Benefits Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '// QUYỀN LỢI',
                              style: GoogleFonts.robotoMono(
                                fontSize: 10 * scale, // Reduced from 12
                                color: accentColor2,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 12 * scale),
                            if (data.benefits.isNotEmpty)
                              ...data.benefits.asMap().entries.map(
                                (entry) => _buildTechListItem(
                                  entry.value,
                                  accentColor1,
                                  scale,
                                  textColor,
                                  id: 'ben_${entry.key}',
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Footer / Contact
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: 8 * scale, // Reduced from 12
                    horizontal: 12 * scale, // Reduced from 16
                  ),
                  decoration: BoxDecoration(
                    color: accentColor2,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor2.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'ỨNG TUYỂN NGAY >>',
                        style: GoogleFonts.robotoMono(
                          fontSize: 10 * scale,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(height: 4 * scale),
                      wrapEditable(
                        'contactInfo',
                        (t, s) => Text(
                          t,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.robotoMono(
                            fontSize: 14 * scale, // Reduced from 16
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textScaler: TextScaler.linear(s),
                        ),
                        defaultText: data.contactInfo,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechInfo(
    String label,
    String value,
    Color accent,
    double scale, {
    required String id,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.robotoMono(
            fontSize: 10 * scale,
            color: accent.withValues(alpha: 0.7),
          ),
        ),
        SizedBox(height: 4 * scale),
        wrapEditable(
          id,
          (t, s) => Text(
            t,
            style: GoogleFonts.robotoMono(
              fontSize: 12 * scale, // Reduced from 14
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textScaler: TextScaler.linear(s),
          ),
          defaultText: value,
        ),
      ],
    );
  }

  Widget _buildTechListItem(
    String text,
    Color accent,
    double scale,
    Color textColor, {
    required String id,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6 * scale), // Reduced from 8
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '>',
            style: GoogleFonts.robotoMono(
              fontSize: 12 * scale, // Reduced from 14
              color: accent,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 8 * scale),
          Expanded(
            child: wrapEditable(
              id,
              (t, s) => Text(
                t,
                style: GoogleFonts.robotoMono(
                  fontSize: 10 * scale, // Reduced from 12
                  color: textColor,
                  height: 1.4,
                ),
                textScaler: TextScaler.linear(s),
              ),
              defaultText: text,
            ),
          ),
        ],
      ),
    );
  }

  @override
  String get templateId => 'tech';
}

class GridPainter extends CustomPainter {
  final Color color;

  GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const gridSize = 30.0;

    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
