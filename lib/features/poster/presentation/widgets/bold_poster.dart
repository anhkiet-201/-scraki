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
          padding: EdgeInsets.all(10.0 * scale), // Reduced from 12
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Massive Job Title
              Text(
                'TUYỂN\nDỤNG',
                style: GoogleFonts.oswald(
                  fontSize: 32 * scale, // Reduced from 36 (and 48, 54, 60 prev)
                  fontWeight: FontWeight.w900,
                  height: 0.9,
                  color: Colors.black.withValues(alpha: 0.1),
                ),
              ),
              Transform.translate(
                offset: Offset(0, -20 * scale),
                child: wrapEditable(
                  'jobTitle',
                  (text, s) => Text(
                    text,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.oswald(
                      fontSize:
                          24 * scale, // Reduced from 26 (and 36, 42, 48 prev)
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      height: 1.0,
                      letterSpacing: -1,
                    ),
                    textScaler: TextScaler.linear(s),
                  ),
                  defaultText: data.jobTitle.toUpperCase(),
                ),
              ),

              SizedBox(height: 6 * scale), // Reduced from 8
              // Highlight Box
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12 * scale, // Reduced from 16
                  vertical: 6 * scale, // Reduced from 8
                ),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.zero,
                ),
                child: wrapEditable(
                  'salary',
                  (text, s) => Text(
                    text,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.roboto(
                      fontSize: 15 * scale, // Reduced from 16
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                    textScaler: TextScaler.linear(s),
                  ),
                  defaultText: data.salaryRange,
                ),
              ),

              SizedBox(height: 12 * scale), // Reduced from 16
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
                      SizedBox(height: 10 * scale), // Reduced from 12
                      if (data.requirements.isNotEmpty)
                        _buildBoldSection(
                          'Yêu cầu',
                          data.requirements.join('\n• '),
                          scale,
                          id: 'requirements',
                        ),
                      SizedBox(height: 10 * scale), // Reduced from 12
                      if (data.benefits.isNotEmpty)
                        _buildBoldSection(
                          'Quyền lợi',
                          data.benefits.join('\n• '),
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
                padding: EdgeInsets.all(10 * scale), // Reduced from 12
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'ỨNG TUYỂN',
                      style: GoogleFonts.oswald(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14 * scale, // Reduced from 16
                      ),
                    ),
                    wrapEditable(
                      'contactInfo',
                      (text, s) => Text(
                        text,
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 12 * scale,
                          fontWeight: FontWeight.bold,
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
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 12 * scale,
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
                (text, s) => Text(
                  text,
                  style: GoogleFonts.roboto(
                    fontSize: 12 * scale, // Reduced from 14
                    color: Colors.black87,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.left,
                  textScaler: TextScaler.linear(s),
                ),
                defaultText: content,
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

  @override
  String get templateId => "bold";
}
