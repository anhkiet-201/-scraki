import 'package:flutter/material.dart';
import '../../../../features/poster/domain/entities/poster_data.dart';

abstract class PosterTemplate extends StatelessWidget {
  final PosterData data;
  final double width;
  final double height;

  const PosterTemplate({
    super.key,
    required this.data,
    this.width = 400, // Default width for mobile preview? Or huge for export?
    this.height = 600,
  });

  @override
  Widget build(BuildContext context);
}
