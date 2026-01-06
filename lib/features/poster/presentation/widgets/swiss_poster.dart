import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'poster_template.dart';

class SwissPoster extends PosterTemplate {
  const SwissPoster({
    super.key,
    required super.data,
    super.width,
    super.height,
    super.customizationStore,
  });

  @override
  Widget buildPoster(BuildContext context, double scale, double w, double h) {
    // Swiss Palette
    final primaryColor = const Color(0xFFE30613); // Swiss Red
    final secondaryColor = const Color(0xFFFFFFFF); // White
    final textColor = const Color(0xFF000000); // Black

    return Container(
      width: w,
      height: h,
      color: secondaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Bold Header Section (Compact)
          Container(
            color: primaryColor,
            padding: EdgeInsets.symmetric(
              horizontal: 24 * scale,
              vertical: 20 * scale,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                wrapEditable(
                  'headline',
                  (s) => Text(
                    data.catchyHeadline?.toUpperCase() ?? 'TUYỂN DỤNG',
                    style: GoogleFonts.inter(
                      fontSize: 40 * scale,
                      fontWeight: FontWeight.w900,
                      color: secondaryColor,
                      height: 0.9,
                      letterSpacing: -1.0,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textScaler: TextScaler.linear(s),
                  ),
                ),
                SizedBox(height: 8 * scale),
                wrapEditable(
                  'companyName',
                  (s) => Text(
                    data.companyName.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 16 * scale,
                      fontWeight: FontWeight.bold,
                      color: secondaryColor.withValues(alpha: 0.9),
                    ),
                    textScaler: TextScaler.linear(s),
                  ),
                ),
              ],
            ),
          ),

          // 2. Main Body Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(24 * scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Job Title (Dominant)
                  wrapEditable(
                    'jobTitle',
                    (s) => Text(
                      data.jobTitle,
                      style: GoogleFonts.inter(
                        fontSize: 34 * scale,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        height: 1.1,
                        letterSpacing: -1.0,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textScaler: TextScaler.linear(s),
                    ),
                  ),

                  SizedBox(height: 20 * scale),

                  // Divider
                  Container(
                    width: double.infinity,
                    height: 4 * scale,
                    color: primaryColor,
                  ),

                  SizedBox(height: 20 * scale),

                  // 3. Grid Layout (Meta Info Left, Details Right)
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Col 1: Meta Information (1/3 width)
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSwissSection(
                                'MỨC LƯƠNG',
                                scale,
                                primaryColor,
                              ),
                              wrapEditable(
                                'salary',
                                (s) => Text(
                                  data.salaryRange,
                                  style: GoogleFonts.inter(
                                    fontSize: 15 * scale,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                  textScaler: TextScaler.linear(s),
                                ),
                              ),
                              SizedBox(height: 20 * scale),
                              _buildSwissSection(
                                'ĐỊA ĐIỂM',
                                scale,
                                primaryColor,
                              ),
                              wrapEditable(
                                'location',
                                (s) => Text(
                                  data.location,
                                  style: GoogleFonts.inter(
                                    fontSize: 15 * scale,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                  textScaler: TextScaler.linear(s),
                                ),
                              ),
                              SizedBox(height: 20 * scale),
                              _buildSwissSection(
                                'LIÊN HỆ',
                                scale,
                                primaryColor,
                              ),
                              wrapEditable(
                                'contactInfo',
                                (s) => Text(
                                  data.contactInfo,
                                  style: GoogleFonts.inter(
                                    fontSize:
                                        14 *
                                        scale, // Smaller for contact to fit
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                  textScaler: TextScaler.linear(s),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(width: 20 * scale),

                        // Col 2: Detailed Lists (2/3 width)
                        Expanded(
                          flex: 5,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (data.requirements.isNotEmpty) ...[
                                  _buildSwissSection(
                                    'YÊU CẦU',
                                    scale,
                                    primaryColor,
                                  ),
                                  SizedBox(height: 8 * scale),
                                  ...data.requirements.asMap().entries.map(
                                    (entry) => _buildSwissItem(
                                      entry.value,
                                      scale,
                                      textColor,
                                      id: 'req_${entry.key}',
                                    ),
                                  ),
                                  SizedBox(height: 16 * scale),
                                ],
                                if (data.benefits.isNotEmpty) ...[
                                  _buildSwissSection(
                                    'QUYỀN LỢI',
                                    scale,
                                    primaryColor,
                                  ),
                                  SizedBox(height: 8 * scale),
                                  ...data.benefits.asMap().entries.map(
                                    (entry) => _buildSwissItem(
                                      entry.value,
                                      scale,
                                      textColor,
                                      id: 'ben_${entry.key}',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildSwissSection(String text, double scale, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4 * scale),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11 * scale,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSwissItem(
    String text,
    double scale,
    Color color, {
    required String id,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6 * scale),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: 14 * scale,
              color: const Color(0xFFE30613), // Red bullet
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: wrapEditable(
              id,
              (s) => Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 13 * scale,
                  color: color,
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                ),
                textScaler: TextScaler.linear(s),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
