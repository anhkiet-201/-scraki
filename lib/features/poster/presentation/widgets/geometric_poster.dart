import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'poster_template.dart';

class GeometricPoster extends PosterTemplate {
  const GeometricPoster({
    super.key,
    required super.data,
    super.width,
    super.height,
    super.customizationStore,
  });

  @override
  Widget buildPoster(BuildContext context, double scale, double w, double h) {
    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          // Geometric Shapes
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              width: w * 0.8,
              height: h * 0.4,
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF),
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(100 * scale),
                ),
              ),
            ),
          ),
          Positioned(
            top: h * 0.3,
            right: 0,
            child: Container(
              width: w * 0.4,
              height: w * 0.4,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6584),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(20 * scale), // Reduced padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20 * scale),
                wrapEditable(
                  'headline',
                  (text, s) => Text(
                    text.toUpperCase(),
                    style: GoogleFonts.montserrat(
                      fontSize: 13 * scale,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.8),
                      letterSpacing: 2,
                    ),
                    textScaler: TextScaler.linear(s),
                  ),
                  defaultText: data.catchyHeadline ?? 'ĐANG TUYỂN DỤNG',
                ),
                SizedBox(height: 10 * scale),
                Expanded(
                  flex: 2,
                  child: wrapEditable(
                    'jobTitle',
                    (text, s) => Text(
                      text,
                      style: GoogleFonts.montserrat(
                        fontSize: 28 * scale,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.1,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      textScaler: TextScaler.linear(s),
                    ),
                    defaultText: data.jobTitle,
                  ),
                ),

                SizedBox(height: 8 * scale),

                wrapEditable(
                  'companyName',
                  (text, s) => Text(
                    text,
                    style: GoogleFonts.montserrat(
                      fontSize: 15 * scale,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textScaler: TextScaler.linear(s),
                  ),
                  defaultText: data.companyName,
                ),

                SizedBox(height: 12 * scale),

                // Details Card
                Expanded(
                  flex: 5,
                  child: Container(
                    padding: EdgeInsets.all(16 * scale),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16 * scale),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGeoRow(
                          Icons.monetization_on,
                          data.salaryRange,
                          scale,
                          id: 'salary',
                        ),
                        SizedBox(height: 10 * scale),
                        _buildGeoRow(
                          Icons.location_on,
                          data.location,
                          scale,
                          id: 'location',
                        ),
                        Divider(height: 20 * scale),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'YÊU CẦU',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 10 * scale,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    SizedBox(height: 4 * scale),
                                    if (data.requirements.isNotEmpty)
                                      ...data.requirements
                                          .take(3)
                                          .map(
                                            (req) => _buildGeoItem(req, scale),
                                          ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8 * scale),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'QUYỀN LỢI',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 10 * scale,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    SizedBox(height: 4 * scale),
                                    if (data.benefits.isNotEmpty)
                                      ...data.benefits
                                          .take(3)
                                          .map(
                                            (ben) => _buildGeoItem(ben, scale),
                                          ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 8 * scale),
                        wrapEditable(
                          'contactInfo',
                          (text, s) => Text(
                            text,
                            style: GoogleFonts.montserrat(
                              fontSize: 13 * scale,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF6C63FF),
                            ),
                            textScaler: TextScaler.linear(s),
                          ),
                          defaultText: data.contactInfo,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeoItem(String text, double scale) {
    return Padding(
      padding: EdgeInsets.only(bottom: 3 * scale),
      child: Text(
        text,
        style: GoogleFonts.montserrat(
          fontSize: 10 * scale,
          color: Colors.black87,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildGeoRow(IconData icon, String text, double scale, {String? id}) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[400], size: 14 * scale),
        SizedBox(width: 8 * scale),
        Expanded(
          child: id != null
              ? wrapEditable(
                  id,
                  (t, s) => Text(
                    t,
                    style: GoogleFonts.montserrat(
                      fontSize: 13 * scale,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    textScaler: TextScaler.linear(s),
                  ),
                  defaultText: text,
                )
              : Text(
                  text,
                  style: GoogleFonts.montserrat(
                    fontSize: 13 * scale,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
        ),
      ],
    );
  }

  @override
  String get templateId => 'geometric';
}
