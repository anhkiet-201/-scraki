import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scraki/core/stores/session_manager_store.dart';
import '../store/phone_view_store.dart';

/// Overlay hiển thị tiến trình tác vụ thiết bị
/// Đã được đơn giản hóa: không hiện %, thêm nút Cancel
class DeviceTaskOverlay extends StatelessWidget {
  final PhoneViewStore store;

  const DeviceTaskOverlay({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 12,
      left: 12,
      right: 12,
      child: Observer(
        builder: (_) {
          final task = store.activeTask;
          if (task == null) return const SizedBox.shrink();

          return Align(
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -0.2),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOut,
                    )),
                    child: child,
                  ),
                );
              },
              child: _TaskCard(
                key: ValueKey('${task.type}_${task.phase}'),
                task: task,
                onCancel: () => store.cancelActiveTask(),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final DeviceTaskState task;
  final VoidCallback onCancel;

  const _TaskCard({
    super.key,
    required this.task,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isRunning = task.phase == DeviceTaskPhase.running;

    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderRow(task: task, onCancel: onCancel),
          if (isRunning) ...[
            const SizedBox(height: 10),
            const _ProgressBar(),
          ],
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final DeviceTaskState task;
  final VoidCallback onCancel;

  const _HeaderRow({
    required this.task,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isRunning = task.phase == DeviceTaskPhase.running;

    return Row(
      children: [
        _LeadingIcon(task: task),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                task.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                task.status,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        if (isRunning) ...[
          const SizedBox(width: 4),
          _CancelButton(onPressed: onCancel),
        ],
      ],
    );
  }
}

class _CancelButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _CancelButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(6),
          child: Icon(
            Icons.close_rounded,
            color: Colors.white.withOpacity(0.4),
            size: 16,
          ),
        ),
      ),
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  final DeviceTaskState task;

  const _LeadingIcon({required this.task});

  @override
  Widget build(BuildContext context) {
    if (task.phase == DeviceTaskPhase.success) {
      return const _StatusIcon(
        icon: Icons.check_rounded,
        color: Color(0xFF32D74B),
      );
    }
    if (task.phase == DeviceTaskPhase.failed) {
      return const _StatusIcon(
        icon: Icons.close_rounded,
        color: Color(0xFFFF453A),
      );
    }

    final icon = switch (task.type) {
      DeviceTaskType.push => Icons.upload_rounded,
      DeviceTaskType.install => Icons.install_mobile_rounded,
      DeviceTaskType.videoGen => Icons.ondemand_video_rounded,
    };

    return _StatusIcon(
      icon: icon,
      color: Colors.white.withOpacity(0.8),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        // Luôn là indeterminate (chạy qua lại) theo yêu cầu đơn giản hóa
        value: null,
        backgroundColor: Colors.white.withOpacity(0.08),
        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
        minHeight: 2,
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _StatusIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 16),
    );
  }
}
