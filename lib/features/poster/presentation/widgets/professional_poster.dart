import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'poster_template.dart';

class ProfessionalPoster extends PosterTemplate {
  const ProfessionalPoster({
    super.key,
    required super.data,
    super.width,
    super.height,
    super.customizationStore,
  });

  @override
  Widget buildPoster(BuildContext context, double scale, double w, double h) {
    return Container(
      color: const Color(0xFFF8F9FA), // Off White
      child: Column(
        children: [
          // Header
          Container(
            height: h * 0.13, // Reduced
            width: double.infinity,
            color: const Color(0xFF0056B3), // Corporate Blue
            padding: EdgeInsets.all(16 * scale), // Reduced
            child: Center(
              child: wrapEditable(
                'companyName',
                (text, s) => Text(
                  text.toUpperCase(),
                  style: GoogleFonts.roboto(
                    fontSize: 18 * scale, // Reduced
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                  textScaler: TextScaler.linear(s),
                ),
                defaultText: data.companyName,
              ),
            ),
          ),

          Expanded(
            child: Padding(
              padding: EdgeInsets.all(24 * scale), // Reduced from 32
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TUYỂN DỤNG',
                    style: GoogleFonts.roboto(
                      fontSize: 12 * scale,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                      letterSpacing: 1.0,
                    ),
                  ),
                  SizedBox(height: 10 * scale),
                  wrapEditable(
                    'jobTitle',
                    (text, s) => Text(
                      text,
                      style: GoogleFonts.roboto(
                        fontSize: 28 * scale, // Reduced from 32
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF333333),
                        height: 1.1,
                      ),
                      maxLines: 3,
                      textScaler: TextScaler.linear(s),
                    ),
                    defaultText: data.jobTitle,
                  ),

                  SizedBox(height: 20 * scale),

                  // Grid
                  Container(
                    padding: EdgeInsets.all(12 * scale),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8 * scale),
                    ),
                    child: Column(
                      children: [
                        _buildProRow(
                          'Mức lương',
                          data.salaryRange,
                          scale,
                          id: 'salary',
                        ),
                        Divider(height: 20 * scale),
                        _buildProRow(
                          'Địa điểm',
                          data.location,
                          scale,
                          id: 'location',
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20 * scale),

                  Expanded(
                    flex: 4,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Yêu cầu:',
                                style: GoogleFonts.roboto(
                                  fontSize: 12 * scale,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 6 * scale),
                              if (data.requirements.isNotEmpty)
                                ...data.requirements.asMap().entries.map((
                                  entry,
                                ) {
                                  final index = entry.key;
                                  final req = entry.value;
                                  return wrapEditable(
                                    'req_$index',
                                    (text, s) => _buildProItem(text, scale),
                                    defaultText: req,
                                  );
                                }),
                            ],
                          ),
                        ),
                        SizedBox(width: 8 * scale),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quyền lợi:',
                                style: GoogleFonts.roboto(
                                  fontSize: 12 * scale,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 6 * scale),
                              ...data.benefits.asMap().entries.map((entry) {
                                final index = entry.key;
                                final ben = entry.value;
                                return wrapEditable(
                                  'ben_$index',
                                  (text, s) => _buildProItem(text, scale),
                                  defaultText: ben,
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Footer
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12 * scale),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0056B3).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8 * scale),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Gửi CV về:',
                          style: GoogleFonts.roboto(
                            fontSize: 10 * scale,
                            color: const Color(0xFF0056B3),
                          ),
                        ),
                        SizedBox(height: 4 * scale),
                        wrapEditable(
                          'contactInfo',
                          (text, s) => Text(
                            text,
                            style: GoogleFonts.roboto(
                              fontSize: 13 * scale,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0056B3),
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
          ),
        ],
      ),
    );
  }

  Widget _buildProItem(String text, double scale) {
    return Padding(
      padding: EdgeInsets.only(bottom: 3 * scale),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontSize: 12 * scale)),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.roboto(
                fontSize: 11 * scale,
                color: Colors.grey[800],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProRow(String label, String value, double scale, {String? id}) {
    return Row(
      children: [
        SizedBox(
          width: 70 * scale,
          child: Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 12 * scale,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: id != null
              ? wrapEditable(
                  id,
                  (t, s) => Text(
                    t,
                    style: GoogleFonts.roboto(
                      fontSize: 12 * scale,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                    textScaler: TextScaler.linear(s),
                  ),
                  defaultText: value,
                )
              : Text(
                  value,
                  style: GoogleFonts.roboto(
                    fontSize: 12 * scale,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
        ),
      ],
    );
  }

  @override
  String get templateId => 'professional';
}
