import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'poster_template.dart';

class LuxuryPoster extends PosterTemplate {
  const LuxuryPoster({
    super.key,
    required super.data,
    super.width,
    super.height,
    super.customizationStore,
  });

  @override
  Widget buildPoster(BuildContext context, double scale, double w, double h) {
    final gold = const Color(0xFFC5A059);
    final darkBg = const Color(0xFF0F141A);

    return Container(
      color: darkBg,
      child: Container(
        margin: EdgeInsets.all(10 * scale),
        decoration: BoxDecoration(
          border: Border.all(color: gold, width: 1 * scale),
        ),
        child: Padding(
          padding: EdgeInsets.all(20 * scale), // Reduced padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.diamond_outlined, color: gold, size: 20 * scale),
              SizedBox(height: 12 * scale),

              wrapEditable(
                'companyName',
                (text, s) => Text(
                  text.toUpperCase(),
                  style: GoogleFonts.cinzel(
                    fontSize: 12 * scale, // Reduced
                    color: Colors.white70,
                    letterSpacing: 2.0,
                  ),
                  textScaler: TextScaler.linear(s),
                ),
                defaultText: data.companyName,
              ),

              SizedBox(height: 20 * scale),

              Divider(
                color: gold.withOpacity(0.3),
                indent: 35 * scale,
                endIndent: 35 * scale,
              ),
              SizedBox(height: 20 * scale),

              wrapEditable(
                'jobTitle',
                (text, s) => Text(
                  text,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28 * scale, // Reduced from 32
                    fontStyle: FontStyle.italic,
                    color: gold,
                    height: 1.1,
                  ),
                  maxLines: 2,
                  textScaler: TextScaler.linear(s),
                ),
                defaultText: data.jobTitle,
              ),

              SizedBox(height: 12 * scale),

              wrapEditable(
                'headline',
                (text, s) => Text(
                  text.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    fontSize: 9 * scale, // Reduced
                    color: Colors.white54,
                    letterSpacing: 1.5,
                  ),
                  textScaler: TextScaler.linear(s),
                ),
                defaultText: data.catchyHeadline ?? 'CƠ HỘI ĐỘC QUYỀN',
              ),

              SizedBox(height: 20 * scale),

              // Details
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'MỨC LƯƠNG',
                          style: GoogleFonts.lato(
                            fontSize: 8 * scale,
                            color: gold,
                          ),
                        ),
                        SizedBox(height: 4 * scale),
                        wrapEditable(
                          'salary',
                          (text, s) => Text(
                            text,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.lato(
                              fontSize: 11 * scale,
                              color: Colors.white,
                            ),
                            textScaler: TextScaler.linear(s),
                          ),
                          defaultText: data.salaryRange,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 25 * scale,
                    width: 1,
                    color: gold.withOpacity(0.3),
                    margin: EdgeInsets.symmetric(horizontal: 10 * scale),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'ĐỊA ĐIỂM',
                          style: GoogleFonts.lato(
                            fontSize: 8 * scale,
                            color: gold,
                          ),
                        ),
                        SizedBox(height: 4 * scale),
                        wrapEditable(
                          'location',
                          (text, s) => Text(
                            text,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.lato(
                              fontSize: 11 * scale,
                              color: Colors.white,
                            ),
                            textScaler: TextScaler.linear(s),
                          ),
                          defaultText: data.location,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16 * scale),

              // Requirements & Benefits
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'YÊU CẦU',
                            style: GoogleFonts.cinzel(
                              fontSize: 9 * scale,
                              color: gold,
                            ),
                          ),
                          SizedBox(height: 6 * scale),
                          if (data.requirements.isNotEmpty)
                            ...data.requirements.asMap().entries.take(3).map((
                              entry,
                            ) {
                              final index = entry.key;
                              final req = entry.value;
                              return wrapEditable(
                                'req_$index',
                                (text, s) => _buildLuxuryItem(text, scale),
                                defaultText: req,
                              );
                            }),
                        ],
                      ),
                    ),
                    SizedBox(width: 8 * scale),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'ĐẶC QUYỀN',
                            style: GoogleFonts.cinzel(
                              fontSize: 9 * scale,
                              color: gold,
                            ),
                          ),
                          SizedBox(height: 6 * scale),
                          if (data.benefits.isNotEmpty)
                            ...data.benefits.asMap().entries.take(3).map((
                              entry,
                            ) {
                              final index = entry.key;
                              final ben = entry.value;
                              return wrapEditable(
                                'ben_$index',
                                (text, s) => _buildLuxuryItem(text, scale),
                                defaultText: ben,
                              );
                            }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                width: double.infinity,
                padding: EdgeInsets.all(10 * scale),
                decoration: BoxDecoration(
                  color: gold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4 * scale),
                ),
                child: wrapEditable(
                  'contactInfo',
                  (text, s) => Text(
                    'LIÊN HỆ: $text',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cinzel(
                      fontSize: 11 * scale,
                      color: gold,
                      fontWeight: FontWeight.bold,
                    ),
                    textScaler: TextScaler.linear(s),
                  ),
                  defaultText: data.contactInfo,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLuxuryItem(String text, double scale) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6 * scale),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.lato(fontSize: 10 * scale, color: Colors.white70),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  @override
  String get templateId => 'luxury';
}
