import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scraki/core/stores/session_manager_store.dart';
import '../store/phone_view_store.dart';

class DeviceTaskOverlay extends StatelessWidget {
  final PhoneViewStore store;

  const DeviceTaskOverlay({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Observer(
        builder: (_) {
          final task = store.activeTask;
          if (task == null) return const SizedBox.shrink();

          final color = _getTaskColor(task.type);

          return Center(
            child: Material(
              type: MaterialType.transparency,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    constraints: const BoxConstraints(
                      maxWidth: 320,
                      minWidth: 200,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: color.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildIcon(task.type, color),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                task.status,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 10,
                                ),
                              ),
                              if (task.progress > 0) ...[
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: task.progress,
                                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                                    valueColor: AlwaysStoppedAnimation<Color>(color),
                                    minHeight: 3,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (task.progress > 0) ...[
                          const SizedBox(width: 10),
                          Text(
                            '${(task.progress * 100).toInt()}%',
                            style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getTaskColor(DeviceTaskType type) {
    switch (type) {
      case DeviceTaskType.push:
        return Colors.orangeAccent;
      case DeviceTaskType.install:
        return Colors.blueAccent;
      case DeviceTaskType.videoGen:
        return Colors.purpleAccent;
    }
  }

  Widget _buildIcon(DeviceTaskType type, Color color) {
    IconData iconData;
    switch (type) {
      case DeviceTaskType.push:
        iconData = Icons.upload_file_rounded;
        break;
      case DeviceTaskType.install:
        iconData = Icons.system_update_alt_rounded;
        break;
      case DeviceTaskType.videoGen:
        iconData = Icons.movie_creation_rounded;
        break;
    }
    return Icon(iconData, color: color, size: 24);
  }
}
