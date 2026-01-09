import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'poster_template.dart';

class TypographyPoster extends PosterTemplate {
  const TypographyPoster({
    super.key,
    required super.data,
    super.width,
    super.height,
    super.customizationStore,
  });

  @override
  Widget buildPoster(BuildContext context, double scale, double w, double h) {
    return Container(
      color: const Color(0xFFF5F5F0), // Off-white/Cream
      padding: EdgeInsets.symmetric(
        horizontal: 20 * scale, // Reduced padding
        vertical: 24 * scale, // Reduced padding
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Massive Headline
          wrapEditable(
            'jobTitle',
            (text, s) => Text(
              text.toUpperCase(),
              style: GoogleFonts.anton(
                fontSize: 46 * scale, // Reduced from 52
                height: 1.2,
                color: const Color(0xFF1A1A1A),
                letterSpacing: -0.5,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              textScaler: TextScaler.linear(s),
            ),
            defaultText: data.jobTitle,
          ),

          SizedBox(height: 10 * scale),

          // 2. Sub-headline / Company
          Row(
            children: [
              Container(
                width: 32 * scale,
                height: 2 * scale,
                color: Colors.redAccent,
              ),
              SizedBox(width: 8 * scale),
              Expanded(
                child: wrapEditable(
                  'companyName',
                  (text, s) => Text(
                    'TẠI $text'.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 13 * scale, // Reduced font
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: const Color(0xFF1A1A1A),
                    ),
                    textScaler: TextScaler.linear(s),
                  ),
                  defaultText: data.companyName,
                ),
              ),
            ],
          ),

          SizedBox(height: 16 * scale),

          // 3. Grid details
          Row(
            children: [
              _buildTypoStat('LƯƠNG', data.salaryRange, scale, id: 'salary'),
              SizedBox(width: 16 * scale),
              _buildTypoStat('ĐỊA ĐIỂM', data.location, scale, id: 'location'),
            ],
          ),

          SizedBox(height: 16 * scale),

          // 4. Requirements & Benefits Split
          Expanded(
            flex: 4,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildListSection(
                    'YÊU CẦU',
                    data.requirements,
                    scale,
                    'req',
                  ),
                ),
                SizedBox(width: 12 * scale),
                Expanded(
                  child: _buildListSection(
                    'QUYỀN LỢI',
                    data.benefits,
                    scale,
                    'ben',
                  ),
                ),
              ],
            ),
          ),

          // 5. Highlighted Catchphrase
          Container(
            padding: EdgeInsets.all(10 * scale),
            margin: EdgeInsets.symmetric(vertical: 8 * scale),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(0),
            ),
            child: wrapEditable(
              'headline',
              (text, s) => Text(
                text.toUpperCase(),
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 16 * scale,
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
                textScaler: TextScaler.linear(s),
              ),
              defaultText: data.catchyHeadline ?? 'Gia nhập đội ngũ',
            ),
          ),

          // 6. Minimal Contact
          Center(
            child: wrapEditable(
              'contactInfo',
              (text, s) => Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 11 * scale,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
                textScaler: TextScaler.linear(s),
              ),
              defaultText: data.contactInfo,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListSection(
    String title,
    List<String> items,
    double scale,
    String idPrefix,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 9 * scale,
            fontWeight: FontWeight.w900,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 4 * scale),
        if (items.isEmpty)
          Text('-', style: TextStyle(fontSize: 10 * scale))
        else
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: 3 * scale),
              child: wrapEditable(
                '${idPrefix}_$index',
                (text, s) => Text(
                  text,
                  style: GoogleFonts.inter(
                    fontSize: 10 * scale,
                    height: 1.2,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textScaler: TextScaler.linear(s),
                ),
                defaultText: item,
              ),
            );
          }),
      ],
    );
  }

  Widget _buildTypoStat(
    String label,
    String value,
    double scale, {
    String? id,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9 * scale,
              fontWeight: FontWeight.w900,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 2 * scale),
          Container(
            padding: EdgeInsets.only(left: 6 * scale),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: Colors.redAccent, width: 2 * scale),
              ),
            ),
            child: id != null
                ? wrapEditable(
                    id,
                    (t, s) => Text(
                      t,
                      style: GoogleFonts.inter(
                        fontSize: 12 * scale, // Reduced
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textScaler: TextScaler.linear(s),
                    ),
                    defaultText: value,
                  )
                : Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 12 * scale,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  String get templateId => 'typography';
}
