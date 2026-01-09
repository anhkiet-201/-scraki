import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'poster_template.dart';

class AbstractPoster extends PosterTemplate {
  const AbstractPoster({
    super.key,
    required super.data,
    super.width,
    super.height,
    super.customizationStore,
  });

  @override
  Widget buildPoster(BuildContext context, double scale, double w, double h) {
    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          // Blobs
          Positioned(
            top: -40 * scale,
            left: -40 * scale,
            child: Container(
              width: 250 * scale,
              height: 250 * scale,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD1DC), // Pastel Pink
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: h * 0.2,
            right: -80 * scale,
            child: Container(
              width: 260 * scale,
              height: 260 * scale,
              decoration: BoxDecoration(
                color: const Color(0xFFB0E0E6), // Powder Blue
                shape: BoxShape.circle,
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(20 * scale), // Reduced padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 25 * scale),

                wrapEditable(
                  'jobTitle',
                  (text, s) => Text(
                    text,
                    style: GoogleFonts.abrilFatface(
                      fontSize: 32 * scale, // Reduced from 38
                      color: Colors.black87,
                      height: 1.0,
                    ),
                    maxLines: 3,
                    textScaler: TextScaler.linear(s),
                  ),
                  defaultText: data.jobTitle,
                ),

                SizedBox(height: 8 * scale),

                wrapEditable(
                  'companyName',
                  (text, s) => Text(
                    'tại $text',
                    style: GoogleFonts.poppins(
                      fontSize: 14 * scale, // Reduced
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                    textScaler: TextScaler.linear(s),
                  ),
                  defaultText: data.companyName,
                ),

                SizedBox(height: 20 * scale),

                // Info floating in space
                _buildFloatingCard(
                  data.salaryRange,
                  scale,
                  const Color(0xFFFFFACD), // Lemon Chiffon
                  id: 'salary',
                ),
                SizedBox(height: 6 * scale),
                _buildFloatingCard(
                  data.location,
                  scale,
                  const Color(0xFFE0FFFF), // Light Cyan
                  id: 'location',
                ),

                SizedBox(height: 16 * scale),

                Expanded(
                  flex: 3,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'YÊU CẦU',
                              style: GoogleFonts.poppins(
                                fontSize: 11 * scale,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (data.requirements.isNotEmpty)
                              ...data.requirements.asMap().entries.map((entry) {
                                final index = entry.key;
                                final req = entry.value;
                                return wrapEditable(
                                  'req_$index',
                                  (text, s) => _buildAbstractItem(text, scale),
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
                              style: GoogleFonts.poppins(
                                fontSize: 11 * scale,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (data.benefits.isNotEmpty)
                              ...data.benefits.asMap().entries.map((
                                entry,
                              ) {
                                final index = entry.key;
                                final ben = entry.value;
                                return wrapEditable(
                                  'ben_$index',
                                  (text, s) => _buildAbstractItem(text, scale),
                                  defaultText: ben,
                                );
                              }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: wrapEditable(
                    'contactInfo',
                    (text, s) => Text(
                      text,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.poppins(
                        fontSize: 13 * scale,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
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

  Widget _buildAbstractItem(String text, double scale) {
    return Padding(
      padding: EdgeInsets.only(top: 2 * scale),
      child: Text(
        '- $text',
        style: GoogleFonts.poppins(fontSize: 10 * scale, color: Colors.black87),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildFloatingCard(
    String text,
    double scale,
    Color color, {
    String? id,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16 * scale,
        vertical: 6 * scale,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16 * scale),
          bottomRight: Radius.circular(16 * scale),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: Offset(4, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: id != null
          ? wrapEditable(
              id,
              (t, s) => Text(
                t,
                style: GoogleFonts.poppins(
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
              style: GoogleFonts.poppins(
                fontSize: 13 * scale,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
    );
  }

  @override
  String get templateId => 'abstract';
}
