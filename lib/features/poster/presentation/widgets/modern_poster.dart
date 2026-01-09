import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'poster_template.dart';

class ModernPoster extends PosterTemplate {
  const ModernPoster({
    super.key,
    required super.data,
    super.width,
    super.height,
    super.customizationStore,
  });

  @override
  Widget buildPoster(BuildContext context, double scale, double w, double h) {
    return Column(
      children: [
        // TOP SECTION: Header & Image (30% Height - Reduced from 35% for 0.7 aspect ratio)
        SizedBox(
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              // Background Image
              if (data.imageUrls.isNotEmpty)
                Positioned.fill(
                  child: Image.network(
                    data.imageUrls.first,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(color: const Color(0xFF2C3E50)),
                  ),
                )
              else
                Positioned.fill(
                  child: Container(
                    color: const Color(0xFF2C3E50),
                    child: Center(
                      child: Icon(
                        Icons.business_center,
                        size: 16 * scale, // Reduced from 20 (and 25 prev)
                        color: Colors.white24,
                      ),
                    ),
                  ),
                ),

              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.2),
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
              ),

              // Company Info & Job Title Overlay
              Padding(
                padding: EdgeInsets.all(10 * scale), // Reduced from 12
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8 * scale, // Reduced from 10
                        vertical: 2 * scale, // Reduced from 4
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent,
                        borderRadius: BorderRadius.circular(4 * scale),
                      ),
                      child: wrapEditable(
                        'headline',
                        (text, s) => Text(
                          text,
                          style: GoogleFonts.roboto(
                            fontSize: 9 * scale, // Reduced from 10
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          textScaler: TextScaler.linear(s),
                        ),
                        defaultText:
                            data.catchyHeadline?.toUpperCase() ?? 'HIRING',
                      ),
                    ),
                    SizedBox(height: 8 * scale, width: double.infinity),
                    wrapEditable(
                      'jobTitle',
                      (text, s) => Text(
                        text,
                        style: GoogleFonts.robotoCondensed(
                          fontSize:
                              20 * scale, // Reduced from 22 (and 26, 30 prev)
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textScaler: TextScaler.linear(s),
                      ),
                      defaultText: data.jobTitle,
                    ),
                    SizedBox(height: 4 * scale),
                    wrapEditable(
                      'companyName',
                      (text, s) => Text(
                        text,
                        style: GoogleFonts.roboto(
                          fontSize: 10 * scale, // Reduced from 11
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
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
        ),

        // BOTTOM SECTION: Details (65% Height)
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(color: Colors.white),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                6 * scale, // Reduced from 8
                6 * scale, // Reduced from 8
                6 * scale, // Reduced from 8
                0,
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Salary & Location Grid
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildModernInfoBox(
                              'LƯƠNG',
                              data.salaryRange,
                              Icons.monetization_on_outlined,
                              Colors.green[700]!,
                              scale,
                              id: 'salary',
                            ),
                          ),
                          SizedBox(
                            width: 4 * scale, // Reduced spacing from 6
                          ), // Reduced spacing from 16
                          Expanded(
                            child: _buildModernInfoBox(
                              'ĐỊA ĐIỂM',
                              data.location,
                              Icons.location_on_outlined,
                              Colors.blue[700]!,
                              scale,
                              id: 'location',
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 8 * scale), // Reduced from 10
                      Divider(color: Colors.grey[200]),
                      SizedBox(height: 8 * scale), // Reduced from 10
                      // Side-by-Side Requirements & Benefits
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (data.requirements.isNotEmpty) ...[
                                  _buildSectionTitle('YÊU CẦU', scale),
                                  SizedBox(height: 8 * scale),
                                  ...data.requirements.asMap().entries.map(
                                    (entry) => _buildListItem(
                                      entry.value,
                                      scale,
                                      id: 'req_${entry.key}',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(width: 12 * scale),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (data.benefits.isNotEmpty) ...[
                                  _buildSectionTitle('QUYỀN LỢI', scale),
                                  SizedBox(height: 8 * scale),
                                  ...data.benefits.asMap().entries.map(
                                    (entry) => _buildListItem(
                                      entry.value,
                                      scale,
                                      icon: Icons.star_border_rounded,
                                      color: Colors.orange,
                                      id: 'ben_${entry.key}',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Floating Footer/Contact
                  Positioned(
                    bottom: 16 * scale,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10 * scale, // Reduced from 12
                        vertical: 6 * scale, // Reduced from 8
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E272E),
                        borderRadius: BorderRadius.circular(16 * scale),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 15,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8 * scale),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.phone_in_talk_rounded,
                              color: Colors.white,
                              size: 14 * scale, // Reduced from 18
                            ),
                          ),
                          SizedBox(width: 12 * scale),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ỨNG TUYỂN NGAY',
                                  style: GoogleFonts.roboto(
                                    fontSize: 10 * scale,
                                    color: Colors.white54,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                wrapEditable(
                                  'contactInfo',
                                  (text, s) => Text(
                                    text,
                                    style: GoogleFonts.roboto(
                                      fontSize: 12 * scale, // Reduced from 14
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, double scale) {
    return Text(
      title,
      style: GoogleFonts.roboto(
        fontSize: 10 * scale,
        fontWeight: FontWeight.w900,
        color: const Color(0xFF1E272E),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildListItem(
    String text,
    double scale, {
    IconData icon = Icons.check_circle_outline_rounded,
    Color color = const Color(0xFF1E272E),
    String? id,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8 * scale),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: 2 * scale,
              right: 6 * scale,
            ), // Reduced right from 10
            child: Icon(
              icon,
              size: 10 * scale, // Reduced size from 12
              color: color,
            ), // Reduced size from 16
          ),
          Expanded(
            child: id != null
                ? wrapEditable(
                    id,
                    (t, s) => Text(
                      t,
                      style: GoogleFonts.roboto(
                        fontSize: 13 * scale, // Reduced from 14
                        color: const Color(0xFF485460),
                        height: 1.4,
                      ),
                      textScaler: TextScaler.linear(s),
                    ),
                    defaultText: text,
                  )
                : Text(
                    text,
                    style: GoogleFonts.roboto(
                      fontSize: 13 * scale, // Reduced from 14
                      color: const Color(0xFF485460),
                      height: 1.4,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernInfoBox(
    String title,
    String value,
    IconData icon,
    Color accent,
    double scale, {
    String? id,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 10 * scale, color: Colors.grey[500]),
            SizedBox(width: 2 * scale),
            Text(
              title,
              style: GoogleFonts.roboto(
                fontSize: 10 * scale,
                fontWeight: FontWeight.bold,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        SizedBox(height: 6 * scale),
        id != null
            ? wrapEditable(
                id,
                (t, s) => Text(
                  t,
                  style: GoogleFonts.roboto(
                    fontSize:
                        14 * scale, // Slightly smaller to prevent overflow
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E272E),
                    height: 1.1, // Reduced line height from 1.2
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textScaler: TextScaler.linear(s),
                ),
                defaultText: value,
              )
            : Text(
                value,
                style: GoogleFonts.roboto(
                  fontSize: 12 * scale, // Reduced from 14
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E272E),
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
      ],
    );
  }

  @override
  String get templateId => "modern";
}
