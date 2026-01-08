import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'poster_template.dart';

class ElegantPoster extends PosterTemplate {
  const ElegantPoster({
    super.key,
    required super.data,
    super.width,
    super.height,
    super.customizationStore,
  });

  @override
  Widget buildPoster(BuildContext context, double scale, double w, double h) {
    final cardColor = const Color(0xFFFFFFFF); // White Card
    final itemsColor = const Color(0xFF1A1A1A); // Black Text
    final goldColor = const Color(0xFFD4AF37); // Gold Accent

    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(4 * scale),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 16 * scale, // Reduced from 24
        vertical: 12 * scale, // Reduced from 16
      ),
      child: Column(
        children: [
          // Top Ornament
          Icon(
            Icons.stars,
            color: goldColor,
            size: 16 * scale, // Reduced from 20
          ), // Reduced from 24
          SizedBox(height: 16 * scale),

          // Hiring Headline
          wrapEditable(
            'headline',
            (t, s) => Text(
              t,
              style: GoogleFonts.montserrat(
                fontSize: 10 * scale, // Reduced from 12
                letterSpacing: 3.0,
                fontWeight: FontWeight.w600,
                color: itemsColor.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
              textScaler: TextScaler.linear(s),
            ),
            defaultText: data.catchyHeadline?.toUpperCase() ?? 'TUYỂN DỤNG',
          ),

          SizedBox(height: 16 * scale),
          Divider(
            color: goldColor,
            thickness: 1,
            indent: 80 * scale,
            endIndent: 80 * scale,
          ),
          SizedBox(height: 16 * scale),

          // Job Title
          wrapEditable(
            'jobTitle',
            (t, s) => Text(
              t,
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 20 * scale, // Reduced from 24 (and 28, 32 prev)
                fontWeight: FontWeight.w700,
                color: itemsColor,
                height: 1.1,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textScaler: TextScaler.linear(s),
            ),
            defaultText: data.jobTitle,
          ),

          SizedBox(height: 8 * scale),

          // Company Name
          wrapEditable(
            'companyName',
            (t, s) => Text(
              t,
              style: GoogleFonts.montserrat(
                fontSize: 10 * scale, // Reduced from 12
                fontWeight: FontWeight.w500,
                color: itemsColor.withValues(alpha: 0.5),
                letterSpacing: 1.0,
              ),
              textScaler: TextScaler.linear(s),
            ),
            defaultText: data.companyName,
          ),

          SizedBox(height: 20 * scale), // Reduced from 32
          // Info Row (Salary | Location)
          Container(
            padding: EdgeInsets.symmetric(
              vertical: 6 * scale, // Reduced from 8
            ), // Reduced from 12
            decoration: BoxDecoration(
              border: Border.symmetric(
                horizontal: BorderSide(
                  color: itemsColor.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: _buildElegantInfo(
                      data.salaryRange,
                      scale,
                      itemsColor,
                      id: 'salary',
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 20 * scale,
                  color: itemsColor.withValues(alpha: 0.2),
                  margin: EdgeInsets.symmetric(horizontal: 20 * scale),
                ),
                Expanded(
                  child: Center(
                    child: _buildElegantInfo(
                      data.location,
                      scale,
                      itemsColor,
                      id: 'location',
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20 * scale), // Reduced from 32
          // Content Columns
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Requirements
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Yêu Cầu',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16 * scale, // Reduced from 18
                          fontWeight: FontWeight.bold,
                          color: itemsColor,
                        ),
                      ),
                      SizedBox(height: 12 * scale),
                      if (data.requirements.isNotEmpty)
                        ...data.requirements.asMap().entries.map(
                          (entry) => _buildElegantListItem(
                            entry.value,
                            scale,
                            itemsColor,
                            id: 'req_${entry.key}',
                          ),
                        ),
                    ],
                  ),
                ),

                // Benefits
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Quyền Lợi',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16 * scale, // Reduced from 18
                          fontWeight: FontWeight.bold,
                          color: itemsColor,
                        ),
                      ),
                      SizedBox(height: 12 * scale),
                      if (data.benefits.isNotEmpty)
                        ...data.benefits.asMap().entries.map(
                          (entry) => _buildElegantListItem(
                            entry.value,
                            scale,
                            itemsColor,
                            id: 'ben_${entry.key}',
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Footer / Apply
          Container(
            margin: EdgeInsets.only(top: 20 * scale),
            padding: EdgeInsets.symmetric(
              vertical: 8 * scale, // Reduced from 12
              horizontal: 16 * scale, // Reduced from 24
            ),
            decoration: BoxDecoration(border: Border.all(color: goldColor)),
            child: Column(
              children: [
                Text(
                  'ỨNG TUYỂN',
                  style: GoogleFonts.montserrat(
                    fontSize: 10 * scale,
                    color: itemsColor.withValues(alpha: 0.5),
                    letterSpacing: 2.0,
                  ),
                ),
                SizedBox(height: 4 * scale),
                wrapEditable(
                  'contactInfo',
                  (t, s) => Text(
                    t,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 14 * scale, // Reduced from 16
                      fontWeight: FontWeight.bold,
                      color: itemsColor,
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
    );
  }

  Widget _buildElegantInfo(
    String value,
    double scale,
    Color color, {
    required String id,
  }) {
    return wrapEditable(
      id,
      (text, s) => Text(
        text,
        style: GoogleFonts.montserrat(
          fontSize: 10 * scale, // Reduced from 12
          fontWeight: FontWeight.w600,
          color: color,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textScaler: TextScaler.linear(s),
      ),
      defaultText: value,
    );
  }

  Widget _buildElegantListItem(
    String text,
    double scale,
    Color color, {
    required String id,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8 * scale),
      child: wrapEditable(
        id,
        (t, s) => Text(
          t,
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            fontSize: 9 * scale, // Reduced from 11
            color: color.withValues(alpha: 0.8),
            height: 1.5,
          ),
          textScaler: TextScaler.linear(s),
        ),
        defaultText: text,
      ),
    );
  }

  @override
  String get templateId => 'elegant';
}
