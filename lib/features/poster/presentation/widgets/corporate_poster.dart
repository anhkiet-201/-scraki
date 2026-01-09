import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'poster_template.dart';

class CorporatePoster extends PosterTemplate {
  const CorporatePoster({
    super.key,
    required super.data,
    super.width,
    super.height,
    super.customizationStore,
  });

  @override
  Widget buildPoster(BuildContext context, double scale, double w, double h) {
    final primaryColor = const Color(0xFF003366); // Dark Navy Blue
    final accentColor = const Color(0xFF007BFF); // Corporate Blue

    return Column(
      children: [
        // Header Stripes
        Row(
          children: [
            Expanded(
              child: Container(
                height: 6 * scale,
                color: primaryColor,
              ), // Reduced from 8
            ),
            Expanded(
              child: Container(
                height: 6 * scale,
                color: accentColor,
              ), // Reduced from 8
            ),
            Expanded(
              child: Container(
                height: 6 * scale,
                color: Colors.grey[300],
              ), // Reduced from 8
            ),
          ],
        ),

        Expanded(
          child: Padding(
            padding: EdgeInsets.all(12.0 * scale), // Reduced from 16
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Nav-like structure
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6 * scale, // Reduced from 8
                          vertical: 3 * scale, // Reduced from 4
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(4 * scale),
                        ),
                        child: Text(
                          'TUYỂN DỤNG',
                          style: GoogleFonts.roboto(
                            color: Colors.white,
                            fontSize: 9 * scale, // Reduced from 10
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      Spacer(),
                      wrapEditable(
                        'locationShort',
                        (text, s) => Text(
                          text,
                          style: GoogleFonts.roboto(
                            fontSize: 10 * scale, // Reduced from 12
                            color: Colors.grey[600],
                          ),
                          textScaler: TextScaler.linear(s),
                        ),
                        defaultText: data.location.split(',').first,
                      ),
                    ],
                  ),

                  SizedBox(height: 20 * scale),

                  // Job Title
                  // Job Title
                  wrapEditable(
                    'jobTitle',
                    (text, s) => Text(
                      text,
                      style: GoogleFonts.robotoSlab(
                        fontSize:
                            20 * scale, // Reduced from 24 (and 28, 32 prev)
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        height: 1.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textScaler: TextScaler.linear(s),
                    ),
                    defaultText: data.jobTitle,
                  ),

                  // Image Banner
                  if (data.imageUrls.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8 * scale),
                      child: SizedBox(
                        height:
                            90 * scale, // Reduced from 100 (and 120, 150 prev)
                        width: double.infinity,
                        child: Image.network(
                          data.imageUrls.first,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                  SizedBox(height: 12 * scale), // Reduced from 16
                  // Info Grid
                  Column(
                    children: [
                      _buildCorporateBox(
                        'LƯƠNG',
                        data.salaryRange,
                        Colors.blue[50]!,
                        primaryColor,
                        scale,
                        id: 'salary',
                      ),
                      SizedBox(height: 8 * scale), // Reduced from 12
                      _buildCorporateBox(
                        'ĐỊA CHỈ',
                        data.location
                            .split(',')
                            .last
                            .trim(), // City only usually
                        Colors.grey[100]!,
                        Colors.black87,
                        scale,
                        id: 'location',
                      ),
                    ],
                  ),

                  SizedBox(
                    height: 10 * scale,
                  ), // Reduced from 12 // Reduced from 16
                  // Requirements List
                  // Side-by-Side Requirements & Benefits
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (data.requirements.isNotEmpty) ...[
                              Text(
                                'YÊU CẦU',
                                style: GoogleFonts.roboto(
                                  fontSize: 10 * scale,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[500],
                                ),
                              ),
                              Divider(),
                              ...data.requirements.asMap().entries.map(
                                (entry) => Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 2 * scale,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        size: 16 * scale,
                                        color: accentColor,
                                      ),
                                      SizedBox(width: 8 * scale),
                                      Expanded(
                                        child: wrapEditable(
                                          'req_${entry.key}',
                                          (text, s) => Text(
                                            text,
                                            style: GoogleFonts.roboto(
                                              fontSize: 12 * scale,
                                              color: Colors.black87,
                                            ),
                                            textScaler: TextScaler.linear(s),
                                          ),
                                          defaultText: entry.value,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(width: 8 * scale),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (data.benefits.isNotEmpty) ...[
                              Text(
                                'QUYỀN LỢI',
                                style: GoogleFonts.roboto(
                                  fontSize: 10 * scale,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[500],
                                ),
                              ),
                              Divider(),
                              ...data.benefits.asMap().entries.map(
                                (entry) => Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 2 * scale,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.star,
                                        size: 16 * scale,
                                        color: Colors.orange,
                                      ),
                                      SizedBox(width: 8 * scale),
                                      Expanded(
                                        child: wrapEditable(
                                          'ben_${entry.key}',
                                          (text, s) => Text(
                                            text,
                                            style: GoogleFonts.roboto(
                                              fontSize: 12 * scale,
                                              color: Colors.black87,
                                            ),
                                            textScaler: TextScaler.linear(s),
                                          ),
                                          defaultText: entry.value,
                                        ),
                                      ),
                                    ],
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

        // Footer
        Container(
          color: primaryColor,
          padding: EdgeInsets.all(12 * scale), // Reduced from 16
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    wrapEditable(
                      'companyName',
                      (text, s) => Text(
                        text,
                        style: GoogleFonts.roboto(
                          fontSize: 14 * scale,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textScaler: TextScaler.linear(s),
                      ),
                      defaultText: data.companyName,
                    ),
                    SizedBox(height: 4 * scale),
                    wrapEditable(
                      'contactInfo',
                      (text, s) => Text(
                        data.contactInfo,
                        style: GoogleFonts.roboto(
                          fontSize: 10 * scale, // Reduced from 12
                          color: Colors.white70,
                        ),
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
      ],
    );
  }

  Widget _buildCorporateBox(
    String title,
    String value,
    Color bg,
    Color textColor,
    double scale, {
    String? id,
  }) {
    return Container(
      padding: EdgeInsets.all(6 * scale), // Reduced from 8
      width: double.infinity,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8 * scale),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: 9 * scale, // Reduced from 10
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4 * scale),
          id != null
              ? wrapEditable(
                  id,
                  (text, s) => Text(
                    text,
                    style: GoogleFonts.roboto(
                      fontSize: 12 * scale, // Reduced from 14
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textScaler: TextScaler.linear(s),
                  ),
                  defaultText: value,
                )
              : Text(
                  value,
                  style: GoogleFonts.roboto(
                    fontSize: 12 * scale, // Reduced from 14
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
        ],
      ),
    );
  }

  @override
  String get templateId => 'corporate';
}
