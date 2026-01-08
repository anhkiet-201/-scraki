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
      padding: EdgeInsets.all(12 * scale), // Reduced from 16
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: inkColor,
            width: 2 * scale,
          ), // Reduced from 3
        ),
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: 10 * scale, // Reduced from 16
              ), // Reduced from 20
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: inkColor, width: 2 * scale),
                ),
              ),
              child: Column(
                children: [
                  wrapEditable(
                    'companyName',
                    (t, s) => Text(
                      t,
                      style: GoogleFonts.roboto(
                        fontSize: 12 * scale, // Reduced from 14
                        fontWeight: FontWeight.bold,
                        color: inkColor,
                        letterSpacing: 2.0,
                      ),
                      textScaler: TextScaler.linear(s),
                    ),
                    defaultText: data.companyName.toUpperCase(),
                  ),
                  SizedBox(height: 8 * scale),
                  wrapEditable(
                    'headline',
                    (t, s) => Text(
                      t,
                      style: GoogleFonts.rye(
                        fontSize: 24 * scale, // Reduced from 32 (and 36 prev)
                        fontWeight: FontWeight.normal,
                        color: accentColor,
                      ),
                      textScaler: TextScaler.linear(s),
                      textAlign: TextAlign.center,
                    ),
                    defaultText:
                        data.catchyHeadline?.toUpperCase() ?? 'TUYỂN DỤNG',
                  ),
                ],
              ),
            ),

            // Job Title Box
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(8 * scale), // Reduced from 12
              decoration: BoxDecoration(
                color: inkColor.withValues(alpha: 0.05),
                border: Border(
                  bottom: BorderSide(color: inkColor, width: 1 * scale),
                ),
              ),
              child: wrapEditable(
                'jobTitle',
                (t, s) => Text(
                  t,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.abrilFatface(
                    fontSize: 20 * scale, // Reduced from 24 (and 28, 32 prev)
                    color: inkColor,
                    height: 1.0,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textScaler: TextScaler.linear(s),
                ),
                defaultText: data.jobTitle,
              ),
            ),

            // Info Row with vertical dividers
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _buildRetroInfo(
                      'LƯƠNG',
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
                padding: EdgeInsets.all(12 * scale), // Reduced from 16
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
                              fontSize: 12 * scale, // Reduced from 14
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
                              fontSize: 12 * scale, // Reduced from 14
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
              padding: EdgeInsets.all(8 * scale), // Reduced from 12
              color: inkColor,
              child: Column(
                children: [
                  Text(
                    'ỨNG TUYỂN',
                    style: GoogleFonts.roboto(
                      fontSize: 10 * scale,
                      color: bgColor,
                      letterSpacing: 1.0,
                    ),
                  ),
                  SizedBox(height: 4 * scale),
                  wrapEditable(
                    'contactInfo',
                    (t, s) => Text(
                      t,
                      style: GoogleFonts.oswald(
                        fontSize: 14 * scale, // Reduced from 18
                        fontWeight: FontWeight.bold,
                        color: bgColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textScaler: TextScaler.linear(s),
                    ),
                    defaultText: data.contactInfo.toUpperCase(),
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
        vertical: 6 * scale, // Reduced from 8
        horizontal: 4 * scale, // Reduced from 6
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.oswald(
              fontSize: 9 * scale, // Reduced from 10
              color: color.withValues(alpha: 0.6),
            ),
          ),
          SizedBox(height: 4 * scale),
          wrapEditable(
            id,
            (t, s) => Text(
              t,
              textAlign: TextAlign.center,
              style: GoogleFonts.robotoSlab(
                fontSize: 10 * scale, // Reduced from 12
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textScaler: TextScaler.linear(s),
            ),
            defaultText: value,
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
        (t, s) => Text(
          t,
          style: GoogleFonts.robotoSlab(
            fontSize: 10 * scale,
            color: color,
          ), // Reduced from 10
          textScaler: TextScaler.linear(s),
        ),
        defaultText: '- $text',
      ),
    );
  }

  @override
  String get templateId => 'retro';
}
