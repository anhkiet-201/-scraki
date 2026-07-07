import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scraki/features/video_poster/domain/entities/batch_video_config.dart';
import 'package:scraki/features/video_poster/presentation/stores/video_poster_store.dart';
import 'playground_constants.dart';

class PlaygroundNavBar extends StatelessWidget {
  final VideoPosterStore store;

  const PlaygroundNavBar({
    super.key,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: PlaygroundConstants.kSidebarWidth,
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        children: [
          const SizedBox(height: 80),
          _buildNavIcon(PlaygroundConstants.kNavMedia, Icons.inventory_2_outlined, 'MEDIA'),
          const SizedBox(height: 4),
          Observer(
            builder: (context) {
              final isAutocut = store.batchOutputOption == BatchVideoOutputOption.tiktokAutocutSet && !store.isImagePosterMode;
              if (isAutocut) return const SizedBox.shrink();
              return Column(
                children: [
                  _buildNavIcon(PlaygroundConstants.kNavText, Icons.text_fields_rounded, 'TEXT'),
                  const SizedBox(height: 4),
                  _buildNavIcon(PlaygroundConstants.kNavImage, Icons.image_outlined, 'IMAGES'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavIcon(int index, IconData icon, String label) {
    return Observer(
      builder: (context) {
        final active = store.activeNavIndex == index;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: InkWell(
            onTap: () => store.setActiveNavIndex(index),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: active ? const Color(0xFF6366F1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: active ? Colors.white : const Color(0xFF94A3B8),
                    size: 22,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: active ? const Color(0xFF6366F1) : const Color(0xFFCBD5E1),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
