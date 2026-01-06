import 'package:flutter/material.dart';
import 'package:scraki/features/device/presentation/widgets/floating_phone_view/widgets/floating_job_selector.dart';
import 'package:scraki/features/device/presentation/widgets/floating_phone_view/widgets/floating_tool_box/widgets/floating_tool_box_card.dart';
import 'package:scraki/features/poster/domain/entities/poster_data.dart';

class JobSelectorPanel extends StatelessWidget {
  final double height;
  final void Function(PosterData) onJobSelected;
  final VoidCallback onCancel;

  const JobSelectorPanel({
    super.key,
    required this.height,
    required this.onJobSelected,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingToolBoxCard(
      width: 300,
      height: height,
      child: FloatingJobSelector(
        onJobSelected: onJobSelected,
        onCancel: onCancel,
      ),
    );
  }
}
