import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'poster_template.dart';

class BoldPoster extends PosterTemplate {
  const BoldPoster({
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
        // Background Image with heavy overlay
        if (data.imageUrls.isNotEmpty)
          Positioned.fill(
            child: Image.network(data.imageUrls.first, fit: BoxFit.cover),
          ),
        Positioned.fill(
          child: Container(
            color: const Color(
              0xFFE8F0FE,
            ).withValues(alpha: 0.95), // Almost solid background
          ),
        ),

        Padding(
          padding: EdgeInsets.all(20.0 * scale),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Massive Job Title
              Text(
                'TUYỂN\nDỤNG',
                style: GoogleFonts.oswald(
                  fontSize: 60 * scale,
                  fontWeight: FontWeight.w900,
                  height: 0.9,
                  color: Colors.black.withValues(alpha: 0.1),
                ),
              ),
              Transform.translate(
                offset: Offset(0, -20 * scale),
                child: wrapEditable(
                  'jobTitle',
                  (s) => Text(
                    data.jobTitle.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.oswald(
                      fontSize: 48 * scale,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      height: 1.0,
                      letterSpacing: -1,
                    ),
                    textScaler: TextScaler.linear(s),
                  ),
                ),
              ),

              SizedBox(height: 20 * scale),

              // Highlight Box
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 20 * scale,
                  vertical: 15 * scale,
                ),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.zero,
                ),
                child: wrapEditable(
                  'salary',
                  (s) => Text(
                    data.salaryRange,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.roboto(
                      fontSize: 16 * scale,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                    textScaler: TextScaler.linear(s),
                  ),
                ),
              ),

              SizedBox(height: 30 * scale),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBoldSection(
                        'ĐỊA CHỈ',
                        data.location,
                        scale,
                        id: 'location',
                      ),
                      SizedBox(height: 12 * scale),
                      if (data.requirements.isNotEmpty)
                        _buildBoldSection(
                          'Yêu cầu',
                          data.requirements.take(3).join('\n• '),
                          scale,
                          id: 'requirements',
                        ),
                      SizedBox(height: 12 * scale),
                      if (data.benefits.isNotEmpty)
                        _buildBoldSection(
                          'Quyền lợi',
                          data.benefits.take(3).join('\n• '),
                          scale,
                          id: 'benefits',
                        ),
                    ],
                  ),
                ),
              ),

              // Footer with slanted cut design
              Container(
                color: Colors.blueAccent[700],
                padding: EdgeInsets.all(20 * scale),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'ỨNG TUYỂN',
                      style: GoogleFonts.oswald(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 16 * scale,
                      ),
                    ),
                    wrapEditable(
                      'contactInfo',
                      (s) => Text(
                        data.contactInfo,
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 12 * scale,
                          fontWeight: FontWeight.bold,
                        ),
                        textScaler: TextScaler.linear(s),
                      ),
                    ),
                    SizedBox(height: 4 * scale),
                    wrapEditable(
                      'companyName',
                      (s) => Text(
                        data.companyName,
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 12 * scale,
                        ),
                        textScaler: TextScaler.linear(s),
                      ),
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

  Widget _buildBoldSection(
    String title,
    String content,
    double scale, {
    String? id,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.oswald(
            fontSize: 12 * scale,
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent[700],
          ),
        ),
        Container(
          width: 40 * scale,
          height: 1.5 * scale,
          color: Colors.black,
          margin: EdgeInsets.symmetric(vertical: 4 * scale),
        ),
        id != null
            ? wrapEditable(
                id,
                (s) => Text(
                  content,
                  style: GoogleFonts.roboto(
                    fontSize: 14 * scale,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.left,
                  textScaler: TextScaler.linear(s),
                ),
              )
            : Text(
                content,
                style: GoogleFonts.roboto(
                  fontSize: 14 * scale,
                  color: Colors.black87,
                  height: 1.4,
                ),
                textAlign: TextAlign.left,
              ),
      ],
    );
  }
}
