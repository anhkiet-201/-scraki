import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'poster_template.dart';

class MinimalistPoster extends PosterTemplate {
  const MinimalistPoster({
    super.key,
    required super.data,
    super.width,
    super.height,
  });

  @override
  Widget buildPoster(BuildContext context, double scale, double w, double h) {
    return Padding(
      padding: EdgeInsets.all(24.0 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Company Name & Logo/Image
          Row(
            children: [
              if (data.imageUrls.isNotEmpty)
                Container(
                  width: 40 * scale,
                  height: 40 * scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: NetworkImage(data.imageUrls.first),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              if (data.imageUrls.isNotEmpty) SizedBox(width: 12 * scale),
              Expanded(
                child: Text(
                  data.companyName.toUpperCase(),
                  style: GoogleFonts.lato(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 32 * scale),

          // Main Title
          Text(
            data.catchyHeadline ?? 'TUYỂN DỤNG',
            style: GoogleFonts.playfairDisplay(
              fontSize: 12 * scale,
              fontStyle: FontStyle.italic,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8 * scale),
          Text(
            data.jobTitle,
            style: GoogleFonts.playfairDisplay(
              fontSize: 36 * scale,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              height: 1.0,
            ),
          ),

          SizedBox(height: 24 * scale),
          Divider(color: Colors.black, thickness: 1 * scale),
          SizedBox(height: 24 * scale),

          // Details grid
          Expanded(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('LƯƠNG', data.salaryRange, scale),
                  SizedBox(height: 16 * scale),
                  _buildInfoRow('ĐỊA CHỈ', data.location, scale),
                  SizedBox(height: 24 * scale),

                  if (data.requirements.isNotEmpty) ...[
                    Text(
                      'Yêu cầu',
                      style: GoogleFonts.lato(
                        fontSize: 12 * scale,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: Colors.grey[500],
                      ),
                    ),
                    SizedBox(height: 8 * scale),
                    ...data.requirements
                        .take(3)
                        .map(
                          (req) => Padding(
                            padding: EdgeInsets.only(bottom: 4 * scale),
                            child: Text(
                              '• $req',
                              style: GoogleFonts.lato(
                                fontSize: 14 * scale,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    SizedBox(height: 16 * scale),
                  ],

                  if (data.benefits.isNotEmpty) ...[
                    Text(
                      'Quyền lợi',
                      style: GoogleFonts.lato(
                        fontSize: 12 * scale,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: Colors.grey[500],
                      ),
                    ),
                    SizedBox(height: 8 * scale),
                    ...data.benefits
                        .take(3)
                        .map(
                          (ben) => Padding(
                            padding: EdgeInsets.only(bottom: 4 * scale),
                            child: Text(
                              '• $ben',
                              style: GoogleFonts.lato(
                                fontSize: 14 * scale,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                  ],
                ],
              ),
            ),
          ),

          // Footer
          Container(
            padding: EdgeInsets.symmetric(vertical: 16 * scale),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ỨNG TUYỂN',
                        style: GoogleFonts.lato(
                          fontSize: 12 * scale,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        data.contactInfo,
                        style: GoogleFonts.lato(fontSize: 14 * scale),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 12 * scale,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: Colors.grey[500],
          ),
        ),
        SizedBox(height: 4 * scale),
        Text(
          value,
          style: GoogleFonts.lato(
            fontSize: 16 * scale,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
