import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'poster_template.dart';

class HighContrastPoster extends PosterTemplate {
  const HighContrastPoster({
    super.key,
    required super.data,
    super.width,
    super.height,
    super.customizationStore,
  });

  @override
  Widget buildPoster(BuildContext context, double scale, double w, double h) {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(20 * scale), // Reduced padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Yellow Box)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12 * scale,
                    vertical: 6 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700), // Gold/Yellow
                    borderRadius: BorderRadius.circular(0),
                  ),
                  child: wrapEditable(
                    'headline',
                    (text, s) => Text(
                      text.toUpperCase(),
                      style: GoogleFonts.oswald(
                        fontSize: 12 * scale, // Reduced font
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        letterSpacing: 1.2,
                      ),
                      textScaler: TextScaler.linear(s),
                    ),
                    defaultText: data.catchyHeadline ?? 'TUYỂN DỤNG',
                  ),
                ),
                SizedBox(height: 16 * scale), // Reduced spacing
                // Job Title (Big White)
                wrapEditable(
                  'jobTitle',
                  (text, s) => Text(
                    text.toUpperCase(),
                    style: GoogleFonts.oswald(
                      fontSize: 24 * scale, // Reduced font
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    textScaler: TextScaler.linear(s),
                  ),
                  defaultText: data.jobTitle,
                ),
                SizedBox(height: 8 * scale),

                // Company Name
                wrapEditable(
                  'companyName',
                  (text, s) => Text(
                    text.toUpperCase(),
                    style: GoogleFonts.robotoMono(
                      fontSize: 14 * scale, // Reduced font
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFFD700),
                    ),
                    textScaler: TextScaler.linear(s),
                  ),
                  defaultText: data.companyName,
                ),

                SizedBox(height: 10 * scale),
                Divider(color: Colors.white24, thickness: 2 * scale),
                SizedBox(height: 10 * scale),

                // Info Grid
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildSection(
                        'LƯƠNG',
                        data.salaryRange,
                        scale,
                        id: 'salary',
                      ),
                    ),
                    SizedBox(width: 12 * scale),
                    Expanded(
                      child: _buildSection(
                        'ĐỊA ĐIỂM',
                        data.location,
                        scale,
                        id: 'location',
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20 * scale),

                // Content Area (Requirements & Benefits)
                Expanded(
                  flex: 6,
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
                                fontSize: 13 * scale,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFFFD700),
                              ),
                            ),
                            SizedBox(height: 6 * scale),
                            Expanded(
                              child: SingleChildScrollView(
                                physics: const NeverScrollableScrollPhysics(),
                                child: Column(
                                  children: [
                                    if (data.requirements.isNotEmpty)
                                      ...data.requirements.asMap().entries.map((
                                        entry,
                                      ) {
                                        final index = entry.key;
                                        final req = entry.value;
                                        return wrapEditable(
                                          'req_$index',
                                          (text, s) =>
                                              _buildListItem(text, scale),
                                          defaultText: req,
                                        );
                                      }),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 10 * scale),
                      // Benefits
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'QUYỀN LỢI',
                              style: GoogleFonts.oswald(
                                fontSize: 13 * scale,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFFFD700),
                              ),
                            ),
                            SizedBox(height: 6 * scale),
                            Expanded(
                              child: SingleChildScrollView(
                                physics: const NeverScrollableScrollPhysics(),
                                child: Column(
                                  children: [
                                    if (data.benefits.isNotEmpty)
                                      ...data.benefits
                                          .asMap()
                                          .entries
                                          .take(5)
                                          .map((entry) {
                                            final index = entry.key;
                                            final ben = entry.value;
                                            return wrapEditable(
                                              'ben_$index',
                                              (text, s) =>
                                                  _buildListItem(text, scale),
                                              defaultText: ben,
                                            );
                                          }),
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

                SizedBox(height: 12 * scale),

                // Footer CTA
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(10 * scale),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2 * scale),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'ỨNG TUYỂN NGAY',
                        style: GoogleFonts.oswald(
                          fontSize: 13 * scale,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4 * scale),
                      wrapEditable(
                        'contactInfo',
                        (text, s) => Text(
                          text,
                          style: GoogleFonts.robotoMono(
                            fontSize: 12 * scale,
                            color: const Color(0xFFFFD700),
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
          ),
          Positioned(
            top: -50 * scale,
            right: -50 * scale,
            child: Transform.rotate(
              angle: 0.785,
              child: Container(
                width: 100 * scale,
                height: 200 * scale,
                color: const Color(0xFFFFD700).withOpacity(0.1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String value, double scale, {String? id}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.oswald(
            fontSize: 9 * scale,
            fontWeight: FontWeight.bold,
            color: Colors.grey[400],
          ),
        ),
        SizedBox(height: 2 * scale),
        id != null
            ? wrapEditable(
                id,
                (t, s) => Text(
                  t,
                  style: GoogleFonts.robotoMono(
                    fontSize: 12 * scale,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textScaler: TextScaler.linear(s),
                ),
                defaultText: value,
              )
            : Text(
                value,
                style: GoogleFonts.robotoMono(
                  fontSize: 12 * scale,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ],
    );
  }

  Widget _buildListItem(String text, double scale) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4 * scale),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(color: Colors.white, fontSize: 10 * scale),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.robotoMono(
                fontSize: 10 * scale,
                color: Colors.white,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  String get templateId => 'high_contrast';
}
