import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'poster_template.dart';

class CorporatePoster extends PosterTemplate {
  const CorporatePoster({
    super.key,
    required super.data,
    super.width,
    super.height,
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
              child: Container(height: 8 * scale, color: primaryColor),
            ),
            Expanded(
              child: Container(height: 8 * scale, color: accentColor),
            ),
            Expanded(
              child: Container(height: 8 * scale, color: Colors.grey[300]),
            ),
          ],
        ),

        Expanded(
          child: Padding(
            padding: EdgeInsets.all(24.0 * scale),
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
                          horizontal: 12 * scale,
                          vertical: 6 * scale,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(4 * scale),
                        ),
                        child: Text(
                          'TUYỂN DỤNG',
                          style: GoogleFonts.roboto(
                            color: Colors.white,
                            fontSize: 10 * scale,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      Spacer(),
                      Text(
                        data.location.split(',').first, // Short location
                        style: GoogleFonts.roboto(
                          fontSize: 12 * scale,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20 * scale),

                  // Job Title
                  Text(
                    data.jobTitle,
                    style: GoogleFonts.robotoCondensed(
                      fontSize: 36 * scale,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                      height: 1.1,
                    ),
                  ),

                  // Image Banner
                  if (data.imageUrls.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8 * scale),
                      child: SizedBox(
                        height: 150 * scale,
                        width: double.infinity,
                        child: Image.network(
                          data.imageUrls.first,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                  SizedBox(height: 24 * scale),

                  // Info Grid
                  Column(
                    children: [
                      _buildCorporateBox(
                        'LƯƠNG',
                        data.salaryRange,
                        Colors.blue[50]!,
                        primaryColor,
                        scale,
                      ),
                      SizedBox(height: 12 * scale),
                      _buildCorporateBox(
                        'ĐỊA CHỈ',
                        data.location
                            .split(',')
                            .last
                            .trim(), // City only usually
                        Colors.grey[100]!,
                        Colors.black87,
                        scale,
                      ),
                    ],
                  ),

                  SizedBox(height: 24 * scale),

                  // Requirements List
                  if (data.requirements.isNotEmpty) ...[
                    Text(
                      'YÊU CẦU',
                      style: GoogleFonts.roboto(
                        fontSize: 12 * scale,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[500],
                      ),
                    ),
                    Divider(),
                    ...data.requirements
                        .take(3)
                        .map(
                          (req) => Padding(
                            padding: EdgeInsets.symmetric(vertical: 4 * scale),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 16 * scale,
                                  color: accentColor,
                                ),
                                SizedBox(width: 8 * scale),
                                Expanded(
                                  child: Text(
                                    req,
                                    style: GoogleFonts.roboto(
                                      fontSize: 14 * scale,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    SizedBox(height: 16 * scale),
                  ],

                  // Benefits List
                  if (data.benefits.isNotEmpty) ...[
                    Text(
                      'QUYỀN LỢI',
                      style: GoogleFonts.roboto(
                        fontSize: 12 * scale,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[500],
                      ),
                    ),
                    Divider(),
                    ...data.benefits
                        .take(3)
                        .map(
                          (ben) => Padding(
                            padding: EdgeInsets.symmetric(vertical: 4 * scale),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 16 * scale,
                                  color: Colors.orange,
                                ),
                                SizedBox(width: 8 * scale),
                                Expanded(
                                  child: Text(
                                    ben,
                                    style: GoogleFonts.roboto(
                                      fontSize: 14 * scale,
                                      color: Colors.black87,
                                    ),
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
          ),
        ),

        // Footer
        Container(
          color: primaryColor,
          padding: EdgeInsets.all(24 * scale),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.companyName.toUpperCase(),
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16 * scale,
                      ),
                    ),
                    Text(
                      data.contactInfo,
                      style: GoogleFonts.roboto(
                        color: Colors.white70,
                        fontSize: 12 * scale,
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

  Widget _buildCorporateBox(
    String title,
    String value,
    Color bg,
    Color textColor,
    double scale,
  ) {
    return Container(
      padding: EdgeInsets.all(12 * scale),
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
              fontSize: 10 * scale,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4 * scale),
          Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: 14 * scale,
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
}
