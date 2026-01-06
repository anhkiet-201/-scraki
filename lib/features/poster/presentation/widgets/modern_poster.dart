import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'poster_template.dart';

class ModernPoster extends PosterTemplate {
  const ModernPoster({
    super.key,
    required super.data,
    super.width,
    super.height,
    super.customizationStore,
  });

  @override
  Widget buildPoster(BuildContext context, double scale, double w, double h) {
    return Column(
      children: [
        // TOP SECTION: Header & Image (35% Height)
        SizedBox(
          height: h * 0.25,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              if (data.imageUrls.isNotEmpty)
                Image.network(
                  data.imageUrls.first,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(color: const Color(0xFF2C3E50)),
                )
              else
                Container(
                  color: const Color(0xFF2C3E50),
                  child: Center(
                    child: Icon(
                      Icons.business_center,
                      size: 25 * scale,
                      color: Colors.white24,
                    ),
                  ),
                ),

              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.2),
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),

              // Company Info & Job Title Overlay
              Padding(
                padding: EdgeInsets.all(20 * scale),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10 * scale,
                        vertical: 4 * scale,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent,
                        borderRadius: BorderRadius.circular(4 * scale),
                      ),
                      child: wrapEditable(
                        'headline',
                        (s) => Text(
                          data.catchyHeadline?.toUpperCase() ?? 'HIRING',
                          style: GoogleFonts.roboto(
                            fontSize: 10 * scale,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          textScaler: TextScaler.linear(s),
                        ),
                      ),
                    ),
                    SizedBox(height: 8 * scale),
                    wrapEditable(
                      'jobTitle',
                      (s) => Text(
                        data.jobTitle,
                        style: GoogleFonts.robotoCondensed(
                          fontSize: 32 * scale,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textScaler: TextScaler.linear(s),
                      ),
                    ),
                    SizedBox(height: 4 * scale),
                    wrapEditable(
                      'companyName',
                      (s) => Text(
                        data.companyName.toUpperCase(),
                        style: GoogleFonts.roboto(
                          fontSize: 14 * scale,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
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

        // BOTTOM SECTION: Details (65% Height)
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(color: Colors.white),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16 * scale,
                16 * scale,
                16 * scale,
                0,
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Salary & Location Grid
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildModernInfoBox(
                              'LƯƠNG',
                              data.salaryRange,
                              Icons.monetization_on_outlined,
                              Colors.green[700]!,
                              scale,
                              id: 'salary',
                            ),
                          ),
                          SizedBox(width: 16 * scale),
                          Expanded(
                            child: _buildModernInfoBox(
                              'ĐỊA ĐIỂM',
                              data.location,
                              Icons.location_on_outlined,
                              Colors.blue[700]!,
                              scale,
                              id: 'location',
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16 * scale),
                      Divider(color: Colors.grey[200]),
                      SizedBox(height: 16 * scale),

                      // Requirements
                      if (data.requirements.isNotEmpty) ...[
                        _buildSectionTitle('YÊU CẦU', scale),
                        SizedBox(height: 12 * scale),
                        ...data.requirements.asMap().entries.map(
                          (entry) => _buildListItem(
                            entry.value,
                            scale,
                            id: 'req_${entry.key}',
                          ),
                        ),
                        SizedBox(height: 16 * scale),
                      ],

                      // Benefits
                      if (data.benefits.isNotEmpty) ...[
                        _buildSectionTitle('QUYỀN LỢI', scale),
                        SizedBox(height: 12 * scale),
                        ...data.benefits.asMap().entries.map(
                          (entry) => _buildListItem(
                            entry.value,
                            scale,
                            icon: Icons.star_border_rounded,
                            color: Colors.orange,
                            id: 'ben_${entry.key}',
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Floating Footer/Contact
                  Positioned(
                    bottom: 16 * scale,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20 * scale,
                        vertical: 16 * scale,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E272E),
                        borderRadius: BorderRadius.circular(16 * scale),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 15,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8 * scale),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.phone_in_talk_rounded,
                              color: Colors.white,
                              size: 20 * scale,
                            ),
                          ),
                          SizedBox(width: 12 * scale),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ỨNG TUYỂN NGAY',
                                  style: GoogleFonts.roboto(
                                    fontSize: 10 * scale,
                                    color: Colors.white54,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                wrapEditable(
                                  'contactInfo',
                                  (s) => Text(
                                    data.contactInfo,
                                    style: GoogleFonts.roboto(
                                      fontSize: 14 * scale,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textScaler: TextScaler.linear(s),
                                  ),
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
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, double scale) {
    return Text(
      title,
      style: GoogleFonts.roboto(
        fontSize: 14 * scale,
        fontWeight: FontWeight.w900,
        color: const Color(0xFF1E272E),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildListItem(
    String text,
    double scale, {
    IconData icon = Icons.check_circle_outline_rounded,
    Color color = const Color(0xFF1E272E),
    String? id,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8 * scale),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2 * scale, right: 10 * scale),
            child: Icon(icon, size: 16 * scale, color: color),
          ),
          Expanded(
            child: id != null
                ? wrapEditable(
                    id,
                    (s) => Text(
                      text,
                      style: GoogleFonts.roboto(
                        fontSize: 14 * scale,
                        color: const Color(0xFF485460),
                        height: 1.4,
                      ),
                      textScaler: TextScaler.linear(s),
                    ),
                  )
                : Text(
                    text,
                    style: GoogleFonts.roboto(
                      fontSize: 14 * scale,
                      color: const Color(0xFF485460),
                      height: 1.4,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernInfoBox(
    String title,
    String value,
    IconData icon,
    Color accent,
    double scale, {
    String? id,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14 * scale, color: Colors.grey[500]),
            SizedBox(width: 6 * scale),
            Text(
              title,
              style: GoogleFonts.roboto(
                fontSize: 11 * scale,
                fontWeight: FontWeight.bold,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        SizedBox(height: 6 * scale),
        id != null
            ? wrapEditable(
                id,
                (s) => Text(
                  value,
                  style: GoogleFonts.roboto(
                    fontSize:
                        14 * scale, // Slightly smaller to prevent overflow
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E272E),
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textScaler: TextScaler.linear(s),
                ),
              )
            : Text(
                value,
                style: GoogleFonts.roboto(
                  fontSize: 14 * scale, // Slightly smaller to prevent overflow
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E272E),
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
      ],
    );
  }
}
