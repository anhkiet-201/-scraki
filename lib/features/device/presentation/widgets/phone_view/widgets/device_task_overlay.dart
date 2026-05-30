import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';
import 'package:scraki/core/stores/session_manager_store.dart';
import '../store/phone_view_store.dart';

/// Overlay hiển thị tiến trình tác vụ thiết bị
class DeviceTaskOverlay extends StatefulWidget {
  final PhoneViewStore store;

  const DeviceTaskOverlay({super.key, required this.store});

  @override
  State<DeviceTaskOverlay> createState() => _DeviceTaskOverlayState();
}

class _DeviceTaskOverlayState extends State<DeviceTaskOverlay> {
  bool _isMinimized = true; // Mặc định hình tròn khi xuất hiện
  bool _isExiting = false;
  DeviceTaskState? _displayTask;
  Timer? _timer;
  ReactionDisposer? _reactionDisposer;

  @override
  void initState() {
    super.initState();
    _displayTask = widget.store.activeTask;
    if (_displayTask == null) {
      _isMinimized = true;
    }

    _reactionDisposer = reaction(
      (_) => widget.store.activeTask,
      (task) {
        if (task == null) {
          _cancelTimer();
          if (_displayTask != null && !_isExiting) {
             _handleExit();
          }
        } else {
          bool isNewTask = _displayTask == null || _displayTask!.type != task.type || _isExiting;
          
          _isExiting = false;
          setState(() {
             _displayTask = task;
             if (isNewTask) {
                // Task mới xuất hiện -> Bắt đầu ở dạng thu nhỏ để tạo hiệu ứng Scale Up 44x44
                _isMinimized = true;
             }
          });
          
          if (isNewTask) {
             // Chờ 250ms (thời gian Scale/Fade In) + 250ms đứng đợi ở dạng Icon = 500ms
             Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted && widget.store.activeTask != null) {
                   setState(() => _isMinimized = false);
                   _checkAutoMinimize(widget.store.activeTask!);
                }
             });
          } else {
             // Task đang chạy có update
             if (task.phase == DeviceTaskPhase.success || task.phase == DeviceTaskPhase.failed) {
               _cancelTimer();
               if (_isMinimized) setState(() => _isMinimized = false);
             } else if (task.phase == DeviceTaskPhase.running) {
               // Không can thiệp, Timer sẽ tự động lo việc auto-minimize
             }
          }
        }
      },
      fireImmediately: true,
    );
  }

  void _checkAutoMinimize(DeviceTaskState task) {
     if (task.phase == DeviceTaskPhase.running && task.autoMinimize) {
        _startTimer();
     }
  }

  void _handleExit() {
     _cancelTimer();
     if (!_isMinimized) {
        // Đang là card lớn -> Thu nhỏ lại thành hình tròn trước
        setState(() {
           _isMinimized = true;
        });
        // Chờ 350ms (thời gian AnimatedSize thu nhỏ) + 250ms đứng đợi = 600ms
        Future.delayed(const Duration(milliseconds: 600), () {
           if (mounted && widget.store.activeTask == null) {
              setState(() {
                 _isExiting = true;
              });
              // Xóa displayTask sau khi Fade/Scale Down hoàn tất (250ms)
              Future.delayed(const Duration(milliseconds: 250), () {
                 if (mounted && _isExiting) {
                    setState(() => _displayTask = null);
                 }
              });
           }
        });
     } else {
        // Đã là hình tròn -> Đứng đợi 250ms rồi Fade/Scale Down biến mất
        Future.delayed(const Duration(milliseconds: 250), () {
           if (mounted && widget.store.activeTask == null) {
              setState(() {
                 _isExiting = true;
              });
              Future.delayed(const Duration(milliseconds: 250), () {
                 if (mounted && _isExiting) {
                    setState(() => _displayTask = null);
                 }
              });
           }
        });
     }
  }

  @override
  void dispose() {
    _cancelTimer();
    _reactionDisposer?.call();
    super.dispose();
  }

  void _startTimer() {
    _cancelTimer();
    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        final task = widget.store.activeTask;
        if (task != null && task.phase == DeviceTaskPhase.running && task.autoMinimize) {
          setState(() {
            _isMinimized = true;
          });
        }
      }
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _expandAndRestartTimer() {
    setState(() {
      _isMinimized = false;
    });
    final task = widget.store.activeTask;
    if (task != null && task.phase == DeviceTaskPhase.running && task.autoMinimize) {
      _startTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 12,
      left: 12,
      right: 12,
      child: Align(
        alignment: Alignment.topCenter,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: animation,
                child: child,
              ),
            );
          },
          child: (_displayTask == null || _isExiting)
              ? const SizedBox.shrink(key: ValueKey('empty'))
              : _buildMorphingContainer(_displayTask!),
        ),
      ),
    );
  }

  Widget _buildMorphingContainer(DeviceTaskState task) {
    return AnimatedContainer(
      key: const ValueKey('content'),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(_isMinimized ? 22 : 16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: _isMinimized ? 10 : 20,
            offset: Offset(0, _isMinimized ? 4 : 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_isMinimized ? 22 : 16),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
              return Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  ...previousChildren.map((child) => Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        child: child,
                      )),
                  if (currentChild != null) currentChild,
                ],
              );
            },
            child: _isMinimized
                ? _MinimizedTaskIcon(
                    key: const ValueKey('minimized'),
                    task: task,
                    onTap: _expandAndRestartTimer,
                  )
                : _TaskCard(
                    key: ValueKey('${task.type}_${task.phase}'),
                    task: task,
                    onCancel: () => widget.store.cancelActiveTask(),
                  ),
          ),
        ),
      ),
    );
  }
}

class _MinimizedTaskIcon extends StatelessWidget {
  final DeviceTaskState task;
  final VoidCallback onTap;

  const _MinimizedTaskIcon({super.key, required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        color: Colors.transparent, // To catch taps
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (task.phase == DeviceTaskPhase.running)
              SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withValues(alpha: 0.3)),
                ),
              ),
            _LeadingIcon(task: task),
          ],
        ),
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
      width: 320,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  color: Colors.white.withValues(alpha: 0.5),
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
            color: Colors.white.withValues(alpha: 0.4),
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
      DeviceTaskType.imagePost => Icons.photo_library_rounded,
      DeviceTaskType.script => Icons.terminal_rounded,
      DeviceTaskType.command => Icons.code_rounded,
    };

    return _StatusIcon(
      icon: icon,
      color: Colors.white.withValues(alpha: 0.8),
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
        backgroundColor: Colors.white.withValues(alpha: 0.08),
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
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 16),
    );
  }
}
