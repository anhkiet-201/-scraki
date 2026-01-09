import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'poster_template.dart';

class CreativePoster extends PosterTemplate {
  const CreativePoster({
    super.key,
    required super.data,
    super.width,
    super.height,
    super.customizationStore,
  });

  @override
  Widget buildPoster(BuildContext context, double scale, double w, double h) {
    return Stack(
      children: [
        // 1. Vibrant Gradient Background
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFF9A9E),
                  Color(0xFFFECFEF),
                  Color(0xFFE0C3FC),
                ],
              ),
            ),
          ),
        ),

        // 2. Abstract Blob Shapes (Background Decor)
        Positioned(
          top: -60 * scale,
          right: -60 * scale,
          child: Container(
            width: 250 * scale,
            height: 250 * scale,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.4),
                  Colors.white.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 150 * scale,
          left: -40 * scale,
          child: Container(
            width: 180 * scale,
            height: 180 * scale,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.purpleAccent.withValues(alpha: 0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // 3. Main Glassmorphism Content
        Padding(
          padding: EdgeInsets.all(16.0 * scale),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Series
              Column(
                children: [
                  // Logo / Image in Glass Bubble
                  if (data.imageUrls.isNotEmpty)
                    Container(
                      width: 80 * scale,
                      height: 80 * scale,
                      margin: EdgeInsets.only(bottom: 12 * scale),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 15,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.network(
                          data.imageUrls.first,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                  // "WE ARE HIRING" Label
                  wrapEditable(
                    'headline',
                    (text, s) => Text(
                      text,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 12 * scale,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 3.0,
                        color: Colors.white,
                      ),
                      textScaler: TextScaler.linear(s),
                    ),
                    defaultText:
                        data.catchyHeadline?.toUpperCase() ?? 'WE ARE HIRING',
                  ),

                  SizedBox(height: 8 * scale),

                  // Job Title
                  wrapEditable(
                    'jobTitle',
                    (text, s) => Text(
                      text,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 24 * scale,
                        fontWeight: FontWeight.w800,
                        color: Colors.white, // White text for cleaner look
                        height: 1.1,
                        shadows: [
                          Shadow(
                            color: Colors.black12,
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      textScaler: TextScaler.linear(s),
                    ),
                    defaultText: data.jobTitle,
                  ),

                  SizedBox(height: 12 * scale),

                  // Salary Pill
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16 * scale,
                      vertical: 6 * scale,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20 * scale),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                    child: wrapEditable(
                      'salary',
                      (text, s) => Text(
                        text,
                        style: GoogleFonts.poppins(
                          fontSize: 14 * scale,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        textScaler: TextScaler.linear(s),
                      ),
                      defaultText: data.salaryRange,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24 * scale),

              // Glass Container for Details
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24 * scale),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: EdgeInsets.all(16 * scale),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(24 * scale),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // Location
                            _buildCreativeRow(
                              Icons.location_on_rounded,
                              data.location,
                              scale,
                              id: 'location',
                              isHeader: true,
                            ),
                            Divider(
                              color: Colors.black12,
                              height: 24 * scale,
                              thickness: 1,
                            ),

                            // Columns: Requirements | Benefits
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // REQUIREMENTS (Left)
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (data.requirements.isNotEmpty) ...[
                                        Text(
                                          'YÊU CẦU',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11 * scale,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF555555),
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                        SizedBox(height: 8 * scale),
                                        ...data.requirements
                                            .asMap()
                                            .entries
                                            .map(
                                              (entry) => Padding(
                                                padding: EdgeInsets.only(
                                                  bottom: 6 * scale,
                                                ),
                                                child: _buildCreativeRow(
                                                  Icons.check_circle_rounded,
                                                  entry.value,
                                                  scale,
                                                  id: 'req_${entry.key}',
                                                  iconColor: Color(0xFFFF6B6B),
                                                ),
                                              ),
                                            ),
                                      ],
                                    ],
                                  ),
                                ),
                                SizedBox(width: 12 * scale),
                                // BENEFITS (Right)
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (data.benefits.isNotEmpty) ...[
                                        Text(
                                          'QUYỀN LỢI',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11 * scale,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF555555),
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                        SizedBox(height: 8 * scale),
                                        ...data.benefits.asMap().entries.map(
                                          (entry) => Padding(
                                            padding: EdgeInsets.only(
                                              bottom: 6 * scale,
                                            ),
                                            child: _buildCreativeRow(
                                              Icons.star_rounded,
                                              entry.value,
                                              scale,
                                              id: 'ben_${entry.key}',
                                              iconColor: Color(0xFF4ECDC4),
                                            ),
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
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 16 * scale),

              // Footer
              Column(
                children: [
                  Text(
                    'ỨNG TUYỂN NGAY',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 10 * scale,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: 4 * scale),
                  wrapEditable(
                    'contactInfo',
                    (text, s) => Text(
                      text,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14 * scale,
                      ),
                      textAlign: TextAlign.center,
                      textScaler: TextScaler.linear(s),
                    ),
                    defaultText: data.contactInfo,
                  ),
                  wrapEditable(
                    'companyName',
                    (text, s) => Text(
                      text,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 12 * scale,
                      ),
                      textAlign: TextAlign.center,
                      textScaler: TextScaler.linear(s),
                    ),
                    defaultText: data.companyName,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreativeRow(
    IconData icon,
    String text,
    double scale, {
    String? id,
    Color? iconColor,
    bool isHeader = false,
  }) {
    return Row(
      crossAxisAlignment: isHeader
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: isHeader ? 16 * scale : 12 * scale,
          color: iconColor ?? const Color(0xFF555555),
        ),
        SizedBox(width: isHeader ? 8 * scale : 6 * scale),
        Expanded(
          child: id != null
              ? wrapEditable(
                  id,
                  (text, s) => Text(
                    text,
                    textAlign: isHeader ? TextAlign.center : TextAlign.left,
                    style: GoogleFonts.poppins(
                      fontSize: isHeader ? 13 * scale : 11 * scale,
                      fontWeight: isHeader ? FontWeight.w600 : FontWeight.w400,
                      color: const Color(0xFF333333),
                      height: 1.3,
                    ),
                    textScaler: TextScaler.linear(s),
                  ),
                  defaultText: text,
                )
              : Text(
                  text,
                  textAlign: isHeader ? TextAlign.center : TextAlign.left,
                  style: GoogleFonts.poppins(
                    fontSize: isHeader ? 13 * scale : 11 * scale,
                    fontWeight: isHeader ? FontWeight.w600 : FontWeight.w400,
                    color: const Color(0xFF333333),
                    height: 1.3,
                  ),
                ),
        ),
      ],
    );
  }

  @override
  String get templateId => 'creative';
}
