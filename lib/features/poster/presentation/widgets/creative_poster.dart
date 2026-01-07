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
        // Background Gradient
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [const Color(0xFFFF9A9E), const Color(0xFFFECFEF)],
              ),
            ),
          ),
        ),

        // abstract shapes
        Positioned(
          top: -50 * scale,
          right: -50 * scale,
          child: Container(
            width: 200 * scale,
            height: 200 * scale,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
          ),
        ),

        Positioned(
          bottom: 100 * scale,
          left: -30 * scale,
          child: Container(
            width: 150 * scale,
            height: 150 * scale,
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(40 * scale),
            ),
          ),
        ),

        // Main Content
        Padding(
          padding: EdgeInsets.all(24.0 * scale),
          child: Column(
            children: [
              // Image Bubble
              if (data.imageUrls.isNotEmpty)
                Center(
                  child: Container(
                    padding: EdgeInsets.all(6 * scale),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 15 * scale,
                          offset: Offset(0, 10 * scale),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.network(
                        data.imageUrls.first,
                        width: 120 * scale,
                        height: 120 * scale,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              if (data.imageUrls.isNotEmpty) SizedBox(height: 20 * scale),

              wrapEditable(
                'headline',
                (text, s) => Text(
                  text,
                  style: GoogleFonts.poppins(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.0,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  textScaler: TextScaler.linear(s),
                ),
                defaultText: data.catchyHeadline?.toUpperCase() ?? 'ĐANG TUYỂN DỤNG',
              ),

              SizedBox(height: 10 * scale),

              wrapEditable(
                'jobTitle',
                (text, s) => Text(
                  text,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 24 * scale,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D2D2D),
                    height: 1.1,
                  ),
                  textScaler: TextScaler.linear(s),
                ),
                defaultText: data.jobTitle,
              ),

              SizedBox(height: 20 * scale),

              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 24 * scale,
                  vertical: 12 * scale,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(50 * scale),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: wrapEditable(
                  'salary',
                  (text, s) => Text(
                    text,
                    style: GoogleFonts.poppins(
                      fontSize: 18 * scale,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFF6B6B),
                    ),
                    textScaler: TextScaler.linear(s),
                  ),
                  defaultText: data.salaryRange,
                ),
              ),

              SizedBox(height: 30 * scale),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildCreativeRow(
                        Icons.location_on_rounded,
                        data.location,
                        scale,
                        id: 'location',
                      ),
                      SizedBox(height: 12 * scale),

                      if (data.requirements.isNotEmpty) ...[
                        Text(
                          'YÊU CẦU',
                          style: GoogleFonts.poppins(
                            fontSize: 12 * scale,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        SizedBox(height: 4 * scale),
                        ...data.requirements.asMap().entries.map(
                          (entry) => Padding(
                            padding: EdgeInsets.only(bottom: 4 * scale),
                            child: _buildCreativeRow(
                              Icons.star_rounded,
                              entry.value,
                              scale,
                              id: 'req_${entry.key}',
                            ),
                          ),
                        ),
                        SizedBox(height: 12 * scale),
                      ],

                      if (data.benefits.isNotEmpty) ...[
                        Text(
                          'PHÚC LỢI',
                          style: GoogleFonts.poppins(
                            fontSize: 12 * scale,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        SizedBox(height: 4 * scale),
                        ...data.benefits.asMap().entries.map(
                          (entry) => Padding(
                            padding: EdgeInsets.only(bottom: 4 * scale),
                            child: _buildCreativeRow(
                              Icons.favorite_rounded,
                              entry.value,
                              scale,
                              id: 'ben_${entry.key}',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20 * scale),

              // Bottom Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20 * scale),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.circular(24 * scale),
                ),
                child: Column(
                  children: [
                    Text(
                      'ỨNG TUYỂN NGAY',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 12 * scale,
                      ),
                    ),
                    SizedBox(height: 8 * scale),
                    wrapEditable(
                      'contactInfo',
                      (text, s) => Text(
                        text,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16 * scale,
                        ),
                        textScaler: TextScaler.linear(s),
                      ),
                      defaultText: data.contactInfo,
                    ),
                    SizedBox(height: 4 * scale),
                    wrapEditable(
                      'companyName',
                      (text, s) => Text(
                        text,
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 14 * scale,
                        ),
                        textScaler: TextScaler.linear(s),
                      ),
                      defaultText: data.companyName,
                    ),
                  ],
                ),
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
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20 * scale, color: const Color(0xFF2D2D2D)),
        SizedBox(width: 8 * scale),
        Flexible(
          child: id != null
              ? wrapEditable(
                  id,
                  (text, s) => Text(
                    text,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14 * scale,
                      color: const Color(0xFF4A4A4A),
                    ),
                    textScaler: TextScaler.linear(s),
                  ),
                  defaultText: text,
                )
              : Text(
                  text,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14 * scale,
                    color: const Color(0xFF4A4A4A),
                  ),
                ),
        ),
      ],
    );
  }
  
  @override
  String get templateId => 'creative';
}
