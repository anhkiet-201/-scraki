import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scraki/features/video_poster/presentation/stores/video_poster_store.dart';

class PlaygroundToolbar extends StatelessWidget {
  final VideoPosterStore store;

  const PlaygroundToolbar({
    super.key,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        border: null,
      ),
      child: Row(
        children: [
          const SizedBox(width: 60),
          const Text(
            'SCRAKI',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              color: Color(0xFF6366F1),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'STUDIO',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w300,
              letterSpacing: 2,
              color: Color(0xFF475569),
            ),
          ),
          const Spacer(),
          Observer(
            builder: (_) {
              return Row(
                children: [
                  _buildOutputToggle(),
                  const SizedBox(width: 12),
                  if (!store.isImagePosterMode) ...[
                    const SizedBox(width: 12),
                    _buildModeToggle(),
                  ],
                  const SizedBox(width: 12),
                  _buildActionButton('DỰ ÁN MỚI', Icons.add_rounded, () {
                    store.resetProject();
                  }),
                ],
              );
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildOutputToggle() {
    return Observer(
      builder: (_) {
        final isImageMode = store.isImagePosterMode;
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildModeOption(
                label: 'VIDEO',
                icon: Icons.movie_outlined,
                isActive: !isImageMode,
                onTap: () {
                  if (isImageMode) store.toggleImagePosterMode();
                },
              ),
              _buildModeOption(
                label: 'POSTER',
                icon: Icons.image_outlined,
                isActive: isImageMode,
                onTap: () {
                  if (!isImageMode) store.toggleImagePosterMode();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeToggle() {
    return Observer(
      builder: (_) {
        final isPreview = store.isPreviewMode;
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildModeOption(
                label: 'CHỈNH SỬA',
                icon: Icons.edit_note_rounded,
                isActive: !isPreview,
                onTap: () {
                  if (isPreview) store.togglePreviewMode();
                },
              ),
              _buildModeOption(
                label: 'XEM TRƯỚC',
                icon: Icons.play_circle_outline_rounded,
                isActive: isPreview,
                onTap: () {
                  if (!isPreview) store.togglePreviewMode();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeOption({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF6366F1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    VoidCallback onTap, {
    bool isOutline = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isOutline ? Colors.transparent : Colors.black.withValues(alpha: 0.05),
          border: isOutline ? Border.all(color: Colors.black.withValues(alpha: 0.1)) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF475569)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
