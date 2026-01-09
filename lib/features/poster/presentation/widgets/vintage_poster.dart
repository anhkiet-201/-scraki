import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'poster_template.dart';

class VintagePoster extends PosterTemplate {
  const VintagePoster({
    super.key,
    required super.data,
    super.width,
    super.height,
    super.customizationStore,
  });

  @override
  Widget buildPoster(BuildContext context, double scale, double w, double h) {
    // Sepia / Vintage Paper Color
    final bgColor = const Color(0xFFF4E4BC);
    final inkColor = const Color(0xFF4B3621);
    final accentRed = const Color(0xFF8B0000);

    return Container(
      color: bgColor,
      child: Container(
        margin: EdgeInsets.all(10 * scale),
        decoration: BoxDecoration(
          border: Border.all(color: inkColor, width: 3 * scale),
        ),
        child: Container(
          margin: EdgeInsets.all(4 * scale),
          decoration: BoxDecoration(
            border: Border.all(color: inkColor, width: 1 * scale),
          ),
          padding: EdgeInsets.all(12 * scale),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // WANTED / HEADER
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 20 * scale,
                  vertical: 6 * scale,
                ),
                decoration: BoxDecoration(
                  color: inkColor,
                  borderRadius: BorderRadius.circular(4 * scale),
                ),
                child: wrapEditable(
                  'headline',
                  (text, s) => Text(
                    text.toUpperCase(),
                    style: GoogleFonts.rye(
                      fontSize: 16 * scale,
                      color: bgColor,
                      letterSpacing: 2.0,
                    ),
                    textScaler: TextScaler.linear(s),
                  ),
                  defaultText: data.catchyHeadline ?? 'TRUY TÌM',
                ),
              ),

              SizedBox(height: 12 * scale),

              // Job Title
              wrapEditable(
                'jobTitle',
                (text, s) => Text(
                  text.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ultra(
                    fontSize: 28 * scale,
                    color: inkColor,
                    height: 1.0,
                  ),
                  maxLines: 4,
                  textScaler: TextScaler.linear(s),
                ),
                defaultText: data.jobTitle,
              ),

              SizedBox(height: 6 * scale),

              Text(
                'TẠI',
                style: GoogleFonts.rye(fontSize: 9 * scale, color: inkColor),
              ),

              SizedBox(height: 4 * scale),

              wrapEditable(
                'companyName',
                (text, s) => Text(
                  text.toUpperCase(),
                  style: GoogleFonts.rye(
                    fontSize: 14 * scale,
                    color: accentRed,
                  ),
                  maxLines: 1,
                  textScaler: TextScaler.linear(s),
                ),
                defaultText: data.companyName,
              ),

              SizedBox(height: 12 * scale),
              Divider(color: inkColor, thickness: 2 * scale),
              SizedBox(height: 12 * scale),

              // REWARD / DETAILS
              Text(
                'ĐÃI NGỘ',
                style: GoogleFonts.rye(fontSize: 12 * scale, color: inkColor),
              ),
              SizedBox(height: 6 * scale),
              wrapEditable(
                'salary',
                (text, s) => Text(
                  text,
                  style: GoogleFonts.ultra(
                    fontSize: 20 * scale,
                    color: inkColor,
                  ),
                  textScaler: TextScaler.linear(s),
                ),
                defaultText: data.salaryRange,
              ),

              SizedBox(height: 12 * scale),

              // Location
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_city, color: inkColor, size: 14 * scale),
                  SizedBox(width: 8 * scale),
                  wrapEditable(
                    'location',
                    (text, s) => Text(
                      text.toUpperCase(),
                      style: GoogleFonts.rye(
                        fontSize: 11 * scale,
                        color: inkColor,
                      ),
                      textScaler: TextScaler.linear(s),
                    ),
                    defaultText: data.location,
                  ),
                ],
              ),

              SizedBox(height: 12 * scale),

              Expanded(
                flex: 4,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'YÊU CẦU',
                            style: GoogleFonts.rye(
                              fontSize: 10 * scale,
                              color: accentRed,
                            ),
                          ),
                          if (data.requirements.isNotEmpty)
                            ...data.requirements.asMap().entries.take(3).map((
                              entry,
                            ) {
                              final index = entry.key;
                              final req = entry.value;
                              return wrapEditable(
                                'req_$index',
                                (text, s) =>
                                    _buildVintageItem(text, scale, inkColor),
                                defaultText: req,
                              );
                            }),
                        ],
                      ),
                    ),
                    SizedBox(width: 8 * scale),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'QUYỀN LỢI',
                            style: GoogleFonts.rye(
                              fontSize: 10 * scale,
                              color: accentRed,
                            ),
                          ),
                          if (data.benefits.isNotEmpty)
                            ...data.benefits.asMap().entries.take(3).map((
                              entry,
                            ) {
                              final index = entry.key;
                              final ben = entry.value;
                              return wrapEditable(
                                'ben_$index',
                                (text, s) =>
                                    _buildVintageItem(text, scale, inkColor),
                                defaultText: ben,
                              );
                            }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Finger pointing icon if possible, else just text
              Text(
                '☟',
                style: TextStyle(fontSize: 20 * scale, color: accentRed),
              ),

              SizedBox(height: 6 * scale),

              wrapEditable(
                'contactInfo',
                (text, s) => Text(
                  'LIÊN HỆ: $text',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.courierPrime(
                    fontSize: 12 * scale,
                    color: inkColor,
                    fontWeight: FontWeight.bold,
                  ),
                  textScaler: TextScaler.linear(s),
                ),
                defaultText: data.contactInfo,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVintageItem(String text, double scale, Color color) {
    return Padding(
      padding: EdgeInsets.only(top: 3 * scale),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.courierPrime(fontSize: 10 * scale, color: color),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  @override
  String get templateId => 'vintage';
}
