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
  Widget buildPoster(BuildContext context, double scale, double w, double h) {
    // Vibrant colors
    final bgColors = [
      const Color(0xFFFFDE59), // Yellow
      const Color(0xFFFF914D), // Orange
    ];
    final cardColor = Colors.white;
    final textColor = const Color(0xFF333333);
    final accentColor1 = const Color(0xFF7ED957); // Green info
    final accentColor2 = const Color(0xFF5CE1E6); // Blue info

    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: bgColors,
        ),
      ),
      child: Stack(
        children: [
          // Decorative Circles
          Positioned(
            top: -50 * scale,
            right: -50 * scale,
            child: CircleAvatar(
              radius: 80 * scale,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          Positioned(
            bottom: -50 * scale,
            left: -50 * scale,
            child: CircleAvatar(
              radius: 100 * scale,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(24 * scale),
            child: Column(
              children: [
                // Header Card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20 * scale),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(24 * scale),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      wrapEditable(
                        'headline',
                        (s) => Text(
                          data.catchyHeadline?.toUpperCase() ??
                              'GIA NHẬP TEAM!',
                          style: GoogleFonts.fredoka(
                            fontSize: 16 * scale,
                            fontWeight: FontWeight.w600,
                            color: textColor.withValues(alpha: 0.6),
                          ),
                          textAlign: TextAlign.center,
                          textScaler: TextScaler.linear(s),
                        ),
                      ),
                      SizedBox(height: 8 * scale),
                      wrapEditable(
                        'jobTitle',
                        (s) => Text(
                          data.jobTitle,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 30 * scale,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                            height: 1.1,
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
                          '@ ${data.companyName}',
                          style: GoogleFonts.poppins(
                            fontSize: 14 * scale,
                            fontWeight: FontWeight.w600,
                            color: textColor.withValues(alpha: 0.7),
                          ),
                          textScaler: TextScaler.linear(s),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16 * scale),

                // Info Chips
                Row(
                  children: [
                    Expanded(
                      child: _buildPlayfulChip(
                        data.salaryRange,
                        accentColor1,
                        scale,
                        id: 'salary',
                      ),
                    ),
                    SizedBox(width: 12 * scale),
                    Expanded(
                      child: _buildPlayfulChip(
                        data.location,
                        accentColor2,
                        scale,
                        id: 'location',
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16 * scale),

                // Main Content Card
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20 * scale),
                    decoration: BoxDecoration(
                      color: cardColor.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(24 * scale),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Requirements
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bạn Cần:',
                                style: GoogleFonts.fredoka(
                                  fontSize: 16 * scale,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              SizedBox(height: 8 * scale),
                              if (data.requirements.isNotEmpty)
                                ...data.requirements.asMap().entries.map(
                                  (entry) => _buildPlayfulItem(
                                    entry.value,
                                    scale,
                                    textColor,
                                    id: 'req_${entry.key}',
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12 * scale),
                        // Benefits
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bạn Được:',
                                style: GoogleFonts.fredoka(
                                  fontSize: 16 * scale,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              SizedBox(height: 8 * scale),
                              if (data.benefits.isNotEmpty)
                                ...data.benefits.asMap().entries.map(
                                  (entry) => _buildPlayfulItem(
                                    entry.value,
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
                ),

                SizedBox(height: 16 * scale),

                // Footer Bubble
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24 * scale,
                    vertical: 16 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(50 * scale),
                  ),
                  child: wrapEditable(
                    'contactInfo',
                    (s) => Text(
                      'ỨNG TUYỂN: ${data.contactInfo}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textScaler: TextScaler.linear(s),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayfulChip(
    String text,
    Color color,
    double scale, {
    required String id,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 12 * scale,
        horizontal: 8 * scale,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16 * scale),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.1),
          width: 2,
        ),
      ),
      child: wrapEditable(
        id,
        (s) => Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 12 * scale,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textScaler: TextScaler.linear(s),
        ),
      ),
    );
  }

  Widget _buildPlayfulItem(
    String text,
    double scale,
    Color textColor, {
    required String id,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6 * scale),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14 * scale),
          ),
          Expanded(
            child: wrapEditable(
              id,
              (s) => Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 11 * scale,
                  color: textColor.withValues(alpha: 0.8),
                  height: 1.3,
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
