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
                child: wrapEditable(
                  'companyName',
                  (s) => Text(
                    data.companyName.toUpperCase(),
                    style: GoogleFonts.lato(
                      fontSize: 14 * scale,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: Colors.black54,
                    ),
                    textScaler: TextScaler.linear(s),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 32 * scale),

          // Main Title
          wrapEditable(
            'headline',
            (s) => Text(
              data.catchyHeadline ?? 'TUYỂN DỤNG',
              style: GoogleFonts.playfairDisplay(
                fontSize: 12 * scale,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
              textScaler: TextScaler.linear(s),
            ),
          ),
          SizedBox(height: 8 * scale),
          wrapEditable(
            'jobTitle',
            (s) => Text(
              data.jobTitle,
              style: GoogleFonts.playfairDisplay(
                fontSize: 36 * scale,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                height: 1.0,
              ),
              textScaler: TextScaler.linear(s),
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
                  _buildInfoRow('LƯƠNG', data.salaryRange, scale, id: 'salary'),
                  SizedBox(height: 16 * scale),
                  _buildInfoRow(
                    'ĐỊA CHỈ',
                    data.location,
                    scale,
                    id: 'location',
                  ),
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
                    ...data.requirements.asMap().entries.map(
                      (entry) => Padding(
                        padding: EdgeInsets.only(bottom: 4 * scale),
                        child: wrapEditable(
                          'req_${entry.key}',
                          (s) => Text(
                            '• ${entry.value}',
                            style: GoogleFonts.lato(
                              fontSize: 14 * scale,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textScaler: TextScaler.linear(s),
                          ),
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
                    ...data.benefits.asMap().entries.map(
                      (entry) => Padding(
                        padding: EdgeInsets.only(bottom: 4 * scale),
                        child: wrapEditable(
                          'ben_${entry.key}',
                          (s) => Text(
                            '• ${entry.value}',
                            style: GoogleFonts.lato(
                              fontSize: 14 * scale,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textScaler: TextScaler.linear(s),
                          ),
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
                      wrapEditable(
                        'contactInfo',
                        (s) => Text(
                          data.contactInfo,
                          style: GoogleFonts.lato(
                            fontSize: 14 * scale,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
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
            fontSize: 12 * scale,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: Colors.grey[500],
          ),
        ),
        SizedBox(height: 4 * scale),
        id != null
            ? wrapEditable(
                id,
                (s) => Text(
                  value,
                  style: GoogleFonts.lato(
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textScaler: TextScaler.linear(s),
                ),
              )
            : Text(
                value,
                style: GoogleFonts.lato(
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
      ],
    );
  }
}
