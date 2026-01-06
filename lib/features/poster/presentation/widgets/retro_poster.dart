import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'poster_template.dart';

class RetroPoster extends PosterTemplate {
  const RetroPoster({
    super.key,
    required super.data,
    super.width,
    super.height,
    super.customizationStore,
  });

  @override
  Widget buildPoster(BuildContext context, double scale, double w, double h) {
    // Retro Palette
    final bgColor = const Color(0xFFF4E4BC); // Cream/Yellowed Paper
    final inkColor = const Color(0xFF2D2926); // Off-Black Ink
    final accentColor = const Color(0xFFC74B38); // Faded Red

    return Container(
      width: w,
      height: h,
      color: bgColor,
      padding: EdgeInsets.all(16 * scale),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: inkColor, width: 3 * scale),
        ),
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 20 * scale),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: inkColor, width: 2 * scale),
                ),
              ),
              child: Column(
                children: [
                  wrapEditable(
                    'companyName',
                    (s) => Text(
                      data.companyName.toUpperCase(),
                      style: GoogleFonts.roboto(
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.bold,
                        color: inkColor,
                        letterSpacing: 2.0,
                      ),
                      textScaler: TextScaler.linear(s),
                    ),
                  ),
                  SizedBox(height: 8 * scale),
                  wrapEditable(
                    'headline',
                    (s) => Text(
                      data.catchyHeadline?.toUpperCase() ?? 'TUYỂN DỤNG',
                      style: GoogleFonts.rye(
                        fontSize: 42 * scale,
                        fontWeight: FontWeight.normal,
                        color: accentColor,
                      ),
                      textScaler: TextScaler.linear(s),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

            // Job Title Box
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24 * scale),
              decoration: BoxDecoration(
                color: inkColor.withValues(alpha: 0.05),
                border: Border(
                  bottom: BorderSide(color: inkColor, width: 1 * scale),
                ),
              ),
              child: wrapEditable(
                'jobTitle',
                (s) => Text(
                  data.jobTitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.abrilFatface(
                    fontSize: 32 * scale,
                    color: inkColor,
                    height: 1.0,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textScaler: TextScaler.linear(s),
                ),
              ),
            ),

            // Info Row with vertical dividers
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _buildRetroInfo(
                      'THÙ LAO',
                      data.salaryRange,
                      scale,
                      inkColor,
                      id: 'salary',
                    ),
                  ),
                  VerticalDivider(color: inkColor, width: 1),
                  Expanded(
                    child: _buildRetroInfo(
                      'NƠI LÀM VIỆC',
                      data.location,
                      scale,
                      inkColor,
                      id: 'location',
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: inkColor, height: 1),

            // Body Content (Two Columns like newspaper)
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(16 * scale),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Requirements
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'YÊU CẦU',
                            style: GoogleFonts.oswald(
                              fontSize: 14 * scale,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              color: inkColor,
                            ),
                          ),
                          SizedBox(height: 8 * scale),
                          if (data.requirements.isNotEmpty)
                            ...data.requirements.asMap().entries.map(
                              (entry) => _buildRetroListItem(
                                entry.value,
                                scale,
                                inkColor,
                                id: 'req_${entry.key}',
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16 * scale),
                    // Benefits
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ĐÃI NGỘ',
                            style: GoogleFonts.oswald(
                              fontSize: 14 * scale,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              color: inkColor,
                            ),
                          ),
                          SizedBox(height: 8 * scale),
                          if (data.benefits.isNotEmpty)
                            ...data.benefits.asMap().entries.map(
                              (entry) => _buildRetroListItem(
                                entry.value,
                                scale,
                                inkColor,
                                id: 'ben_${entry.key}',
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer / Apply Box
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16 * scale),
              color: inkColor,
              child: Column(
                children: [
                  Text(
                    'LIÊN HỆ TRỰC TIẾP HOẶC QUA',
                    style: GoogleFonts.roboto(
                      fontSize: 10 * scale,
                      color: bgColor,
                      letterSpacing: 1.0,
                    ),
                  ),
                  SizedBox(height: 4 * scale),
                  wrapEditable(
                    'contactInfo',
                    (s) => Text(
                      data.contactInfo.toUpperCase(),
                      style: GoogleFonts.oswald(
                        fontSize: 18 * scale,
                        fontWeight: FontWeight.bold,
                        color: bgColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textScaler: TextScaler.linear(s),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRetroInfo(
    String label,
    String value,
    double scale,
    Color color, {
    required String id,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 12 * scale,
        horizontal: 8 * scale,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.oswald(
              fontSize: 10 * scale,
              color: color.withValues(alpha: 0.6),
            ),
          ),
          SizedBox(height: 4 * scale),
          wrapEditable(
            id,
            (s) => Text(
              value,
              textAlign: TextAlign.center,
              style: GoogleFonts.robotoSlab(
                fontSize: 12 * scale,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textScaler: TextScaler.linear(s),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetroListItem(
    String text,
    double scale,
    Color color, {
    required String id,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6 * scale),
      child: wrapEditable(
        id,
        (s) => Text(
          '- $text',
          style: GoogleFonts.robotoSlab(fontSize: 10 * scale, color: color),
          textScaler: TextScaler.linear(s),
        ),
      ),
    );
  }
}
