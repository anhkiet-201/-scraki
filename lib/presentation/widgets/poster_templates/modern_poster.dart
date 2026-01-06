import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'poster_template.dart';

class ModernPoster extends PosterTemplate {
  const ModernPoster({
    super.key,
    required super.data,
    super.width,
    super.height,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Effective dimensions
        final double w = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : width;
        final double h = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : height;

        // Calculate scale factor using the limiting dimension to ensure fit
        // Base reference: 375 x 667
        final double scaleX = w / 375.0;
        final double scaleY = h / 667.0;
        final double scale = (scaleX < scaleY)
            ? scaleX
            : scaleY; // Use min scale

        return Container(
          width: w,
          height: h,
          color: Colors.white,
          child: Stack(
            children: [
              // Background Gradient decoration
              // Height locked to scale to maintain aspect ratio relative to text
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height:
                    200 * scale, // Fixed visual height proportional to scale
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (data.imageUrls.isNotEmpty)
                      Image.network(
                        data.imageUrls.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox(),
                      ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: data.imageUrls.isNotEmpty
                              ? [
                                  Colors.black.withValues(alpha: 0.8),
                                  Colors.black.withValues(alpha: 0.4),
                                  Colors.transparent,
                                ]
                              : [
                                  const Color(0xFF1A2980),
                                  const Color(0xFF26D0CE),
                                ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      20 * scale,
                      30 * scale,
                      20 * scale,
                      10 * scale,
                    ),
                    child: Column(
                      children: [
                        if (data.catchyHeadline != null &&
                            data.catchyHeadline!.isNotEmpty) ...[
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              data.catchyHeadline!,
                              style: GoogleFonts.montserrat(
                                fontSize: 24 * scale,
                                fontWeight: FontWeight.w900,
                                color: Colors.yellowAccent,
                                letterSpacing: 1.5 * scale,
                                shadows: [
                                  Shadow(
                                    blurRadius: 10.0 * scale,
                                    color: Colors.black45,
                                    offset: Offset(2.0 * scale, 2.0 * scale),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(height: 5 * scale),
                        ] else ...[
                          Text(
                            'TUYỂN DỤNG',
                            style: GoogleFonts.montserrat(
                              fontSize: 24 * scale,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 2.0 * scale,
                            ),
                          ),
                          SizedBox(height: 10 * scale),
                        ],
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            data.jobTitle.toUpperCase(),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: GoogleFonts.roboto(
                              fontSize: 32 * scale,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 10 * scale),

                  // Salary Badge
                  Center(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 20 * scale),
                      padding: EdgeInsets.symmetric(
                        horizontal: 30 * scale,
                        vertical: 10 * scale,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent,
                        borderRadius: BorderRadius.circular(30 * scale),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10 * scale,
                            offset: Offset(0, 5 * scale),
                          ),
                        ],
                      ),
                      child: Text(
                        data.salaryRange,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.roboto(
                          fontSize: 20 * scale,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 15 * scale),

                  // Content Body
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 30 * scale),
                      child: LayoutBuilder(
                        builder: (context, innerConstraints) {
                          return SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: innerConstraints.maxHeight,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildSectionHeader(
                                    'ĐỊA ĐIỂM LÀM VIỆC',
                                    scale,
                                  ),
                                  Text(
                                    data.location,
                                    style: GoogleFonts.roboto(
                                      fontSize: 14 * scale,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 5 * scale),

                                  if (data.requirements.isNotEmpty) ...[
                                    _buildSectionHeader('YÊU CẦU', scale),
                                    ...data.requirements
                                        .take(3)
                                        .map(
                                          (req) =>
                                              _buildBulletPoint(req, scale),
                                        ),
                                    SizedBox(height: 5 * scale),
                                  ],

                                  if (data.benefits.isNotEmpty) ...[
                                    _buildSectionHeader('QUYỀN LỢI', scale),
                                    ...data.benefits
                                        .take(3)
                                        .map(
                                          (ben) =>
                                              _buildBulletPoint(ben, scale),
                                        ),
                                  ],

                                  if (data.imageUrls.isNotEmpty) ...[
                                    SizedBox(height: 8 * scale),
                                    _buildSectionHeader('HÌNH ẢNH', scale),
                                    SizedBox(
                                      height: 80 * scale,
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: data.imageUrls
                                            .take(3)
                                            .length,
                                        separatorBuilder: (_, __) =>
                                            SizedBox(width: 8 * scale),
                                        itemBuilder: (context, index) {
                                          return ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8 * scale,
                                            ),
                                            child: Image.network(
                                              data.imageUrls[index],
                                              width: 100 * scale,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  Container(
                                                    width: 100 * scale,
                                                    color: Colors.grey[300],
                                                    child: Icon(
                                                      Icons.broken_image,
                                                      size: 24 * scale,
                                                    ),
                                                  ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Footer
                  Container(
                    color: Colors.grey[100],
                    padding: EdgeInsets.all(20 * scale),
                    child: Row(
                      children: [
                        Icon(
                          Icons.business,
                          color: const Color(0xFF1A2980),
                          size: 24 * scale,
                        ),
                        SizedBox(width: 10 * scale),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data.companyName,
                                style: GoogleFonts.roboto(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14 * scale,
                                ),
                              ),
                              Text(
                                data.contactInfo,
                                style: GoogleFonts.roboto(fontSize: 12 * scale),
                              ),
                            ],
                          ),
                        ),
                        // QR Code Placeholder
                        Container(
                          width: 60 * scale,
                          height: 60 * scale,
                          color: Colors.black12,
                          child: Icon(
                            Icons.qr_code,
                            color: Colors.black54,
                            size: 24 * scale,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, double scale) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8 * scale),
      child: Text(
        title,
        style: GoogleFonts.montserrat(
          fontSize: 14 * scale,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1A2980),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text, double scale) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2 * scale),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              color: Colors.orangeAccent,
              fontWeight: FontWeight.bold,
              fontSize: 14 * scale,
            ),
          ),
          Expanded(
            child: Text(text, style: GoogleFonts.roboto(fontSize: 13 * scale)),
          ),
        ],
      ),
    );
  }
}
