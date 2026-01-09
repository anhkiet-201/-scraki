import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'poster_template.dart';

class UrbanPoster extends PosterTemplate {
  const UrbanPoster({
    super.key,
    required super.data,
    super.width,
    super.height,
    super.customizationStore,
  });

  @override
  Widget buildPoster(BuildContext context, double scale, double w, double h) {
    return Container(
      color: const Color(0xFF212121), // Dark Grey
      child: Stack(
        children: [
          // Background Texture/Elements
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: h * 0.4,
            child: Container(
              color: const Color(0xFF333333),
              child: CustomPaint(painter: _SprayPaintPainter()),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(16 * scale), // Reduced padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stencil Headline
                Container(
                  color: Colors.yellowAccent,
                  padding: EdgeInsets.symmetric(
                    horizontal: 6 * scale,
                    vertical: 3 * scale,
                  ),
                  child: wrapEditable(
                    'headline',
                    (text, s) => Text(
                      text.toUpperCase(),
                      style: GoogleFonts.blackOpsOne(
                        fontSize: 16 * scale, // Reduced
                        color: Colors.black,
                        letterSpacing: 1.5,
                      ),
                      textScaler: TextScaler.linear(s),
                    ),
                    defaultText: data.catchyHeadline ?? 'TUYỂN DỤNG',
                  ),
                ),

                SizedBox(height: 12 * scale),

                // Job Title
                wrapEditable(
                  'jobTitle',
                  (text, s) => Text(
                    text.toUpperCase(),
                    style: GoogleFonts.rubikMonoOne(
                      fontSize: 28 * scale, // Reduced from 32
                      color: Colors.white,
                      height: 1.0,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    textScaler: TextScaler.linear(s),
                  ),
                  defaultText: data.jobTitle,
                ),

                SizedBox(height: 8 * scale),

                // Company Tag - Graffiti style
                wrapEditable(
                  'companyName',
                  (text, s) => Text(
                    '@$text'.toLowerCase(),
                    style: GoogleFonts.permanentMarker(
                      fontSize: 18 * scale, // Reduced
                      color: Colors.cyanAccent,
                    ),
                    textScaler: TextScaler.linear(s),
                  ),
                  defaultText: data.companyName,
                ),

                SizedBox(height: 20 * scale),

                // Details Box
                Container(
                  padding: EdgeInsets.all(12 * scale),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2 * scale),
                    color: Colors.transparent,
                  ),
                  child: Column(
                    children: [
                      _buildUrbanRow(
                        'LƯƠNG',
                        data.salaryRange,
                        scale,
                        id: 'salary',
                      ),
                      Divider(
                        color: Colors.white,
                        thickness: 1 * scale,
                        height: 16 * scale,
                      ),
                      _buildUrbanRow(
                        'ĐỊA ĐIỂM',
                        data.location,
                        scale,
                        id: 'location',
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20 * scale),

                // Requirements & Benefits - Tape style
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'YÊU CẦU',
                                style: GoogleFonts.teko(
                                  color: Colors.white,
                                  fontSize: 14 * scale,
                                ),
                              ),
                              SizedBox(height: 4 * scale),
                              if (data.requirements.isNotEmpty)
                                ...data.requirements
                                    .take(5)
                                    .map((req) => _buildTapeItem(req, scale)),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 8 * scale),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'QUYỀN LỢI',
                                style: GoogleFonts.teko(
                                  color: Colors.white,
                                  fontSize: 14 * scale,
                                ),
                              ),
                              SizedBox(height: 4 * scale),
                              if (data.benefits.isNotEmpty)
                                ...data.benefits
                                    .take(5)
                                    .map((ben) => _buildTapeItem(ben, scale)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 12 * scale),

                // Contact
                wrapEditable(
                  'contactInfo',
                  (text, s) => Text(
                    text,
                    style: GoogleFonts.vt323(
                      fontSize: 20 * scale, // Reduced
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
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

  Widget _buildTapeItem(String text, double scale) {
    return Container(
      margin: EdgeInsets.only(bottom: 4 * scale),
      padding: EdgeInsets.symmetric(horizontal: 6 * scale, vertical: 2 * scale),
      color: Colors.white,
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.teko(
          fontSize: 12 * scale,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildUrbanRow(
    String label,
    String value,
    double scale, {
    String? id,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.teko(
            fontSize: 14 * scale, // Reduced
            color: Colors.grey[400],
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: id != null
              ? wrapEditable(
                  id,
                  (t, s) => Text(
                    t,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.teko(
                      fontSize: 16 * scale, // Reduced
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textScaler: TextScaler.linear(s),
                  ),
                  defaultText: value,
                )
              : Text(
                  value,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.teko(
                    fontSize: 16 * scale,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ],
    );
  }

  @override
  String get templateId => 'urban';
}

class _SprayPaintPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Ideally this would draw some random spray dots or lines
    // For now simple placeholders
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
