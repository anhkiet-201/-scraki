import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'poster_template.dart';

class MinimalistPoster extends PosterTemplate {
  const MinimalistPoster({
    super.key,
    required super.data,
    super.width,
    super.height,
    super.customizationStore,
  });

  @override
  Widget buildPoster(BuildContext context, double scale, double w, double h) {
    return Padding(
      padding: EdgeInsets.all(
        10.0 * scale,
      ), // Reduced from 16 // Reduced from 20 // Reduced from 24
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Company Name & Logo/Image
          Row(
            children: [
              if (data.imageUrls.isNotEmpty)
                Container(
                  width: 28 * scale, // Reduced from 32
                  height: 28 * scale, // Reduced from 32
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: NetworkImage(data.imageUrls.first),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              if (data.imageUrls.isNotEmpty)
                SizedBox(width: 8 * scale), // Reduced from 12
              Expanded(
                child: wrapEditable(
                  'companyName',
                  (t, s) => Text(
                    t,
                    style: GoogleFonts.lato(
                      fontSize: 11 * scale, // Reduced from 12
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: Colors.black54,
                    ),
                    textScaler: TextScaler.linear(s),
                  ),
                  defaultText: data.companyName.toUpperCase(),
                ),
              ),
            ],
          ),

          SizedBox(
            height: 8 * scale,
          ), // Reduced from 16 // Reduced from 20 // Reduced from 32
          // Main Title
          wrapEditable(
            'headline',
            (t, s) => Text(
              t,
              style: GoogleFonts.playfairDisplay(
                fontSize: 8 * scale, // Reduced from 9
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
              textScaler: TextScaler.linear(s),
            ),
            defaultText: data.catchyHeadline ?? 'TUYỂN DỤNG',
          ),
          SizedBox(height: 4 * scale), // Reduced from 8
          wrapEditable(
            'jobTitle',
            (t, s) => Text(
              t,
              style: GoogleFonts.playfairDisplay(
                fontSize: 20 * scale, // Reduced from 22 (and 28, 32, 36 prev)
                fontWeight: FontWeight.bold,
                color: Colors.black,
                height: 1.0,
              ),
              textScaler: TextScaler.linear(s),
            ),
            defaultText: data.jobTitle,
          ),

          SizedBox(height: 6 * scale), // Reduced from 8
          Divider(color: Colors.black, thickness: 1 * scale),
          SizedBox(height: 6 * scale), // Reduced from 8
          // Details grid
          Expanded(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('LƯƠNG', data.salaryRange, scale, id: 'salary'),
                  SizedBox(height: 12 * scale), // Reduced from 16
                  _buildInfoRow(
                    'ĐỊA CHỈ',
                    data.location,
                    scale,
                    id: 'location',
                  ),
                  SizedBox(height: 16 * scale), // Reduced from 24
                  // Side-by-Side
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                              SizedBox(height: 6 * scale),
                              ...data.requirements.asMap().entries.map(
                                (entry) => Padding(
                                  padding: EdgeInsets.only(bottom: 4 * scale),
                                  child: wrapEditable(
                                    'req_${entry.key}',
                                    (t, s) => Text(
                                      t,
                                      style: GoogleFonts.lato(
                                        fontSize: 13 * scale,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textScaler: TextScaler.linear(s),
                                    ),
                                    defaultText: '• ${entry.value}',
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
                                'Quyền lợi',
                                style: GoogleFonts.lato(
                                  fontSize: 12 * scale,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                  color: Colors.grey[500],
                                ),
                              ),
                              SizedBox(height: 6 * scale),
                              ...data.benefits.asMap().entries.map(
                                (entry) => Padding(
                                  padding: EdgeInsets.only(bottom: 4 * scale),
                                  child: wrapEditable(
                                    'ben_${entry.key}',
                                    (t, s) => Text(
                                      t,
                                      style: GoogleFonts.lato(
                                        fontSize: 13 * scale,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textScaler: TextScaler.linear(s),
                                    ),
                                    defaultText: '• ${entry.value}',
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

          // Footer
          Container(
            padding: EdgeInsets.symmetric(
              vertical: 6 * scale,
            ), // Reduced from 12 // Reduced from 16
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
                          fontSize: 10 * scale, // Reduced from 12
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      wrapEditable(
                        'contactInfo',
                        (t, s) => Text(
                          t,
                          style: GoogleFonts.lato(
                            fontSize: 14 * scale,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
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
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, double scale, {String? id}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 8 * scale, // Reduced from 9
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: Colors.grey[500],
          ),
        ),
        SizedBox(height: 2 * scale), // Reduced from 4
        id != null
            ? wrapEditable(
                id,
                (t, s) => Text(
                  t,
                  style: GoogleFonts.lato(
                    fontSize: 13 * scale, // Reduced from 14
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textScaler: TextScaler.linear(s),
                ),
                defaultText: value,
              )
            : Text(
                value,
                style: GoogleFonts.lato(
                  fontSize: 15 * scale, // Reduced from 16
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
      ],
    );
  }

  @override
  String get templateId => 'minimalist';
}
