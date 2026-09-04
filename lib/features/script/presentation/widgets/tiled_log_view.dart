import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scraki/core/mixins/di_mixin.dart';
import 'package:scraki/features/device/domain/entities/device_entity.dart';
import '../../domain/entities/log_entry.dart';
import '../stores/terminal_store.dart';


class TiledLogView extends StatelessWidget {
  final TerminalStore store = inject<TerminalStore>();

  TiledLogView({super.key});

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final targetSerials = <String>{
          ...store.selectedSerials,
          ...store.deviceLogs.keys.where((s) => s != 'system'),
        }.toList();

        if (targetSerials.isEmpty) {
          return const Center(
            child: Text('Hãy chọn hoặc chạy kịch bản trên thiết bị để xem log riêng biệt'),
          );
        }

        // Dynamic column count based on device count
        int crossAxisCount = 2;
        if (targetSerials.length >= 7) {
          crossAxisCount = 4;
        } else if (targetSerials.length >= 3) {
          crossAxisCount = 3;
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.4, // Slightly taller to account for input
          ),
          itemCount: targetSerials.length,
          itemBuilder: (context, index) {
            final serial = targetSerials[index];
            final device = store.getDeviceBySerial(serial) ??
                DeviceEntity(
                  id: serial,
                  serial: serial,
                  modelName: serial,
                  status: DeviceStatus.connected,
                  connectionType: ConnectionType.usb,
                );
            return _DeviceLogTile(device: device);
          },
        );
      },
    );
  }
}

class _DeviceLogTile extends StatefulWidget {
  final DeviceEntity device;

  const _DeviceLogTile({required this.device});

  @override
  State<_DeviceLogTile> createState() => _DeviceLogTileState();
}

class _DeviceLogTileState extends State<_DeviceLogTile> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final TerminalStore _store = inject<TerminalStore>();

  @override
  void dispose() {
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)), // Slate 200
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Sub-header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC), // Slate 50
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.terminal_rounded,
                  size: 14,
                  color: Color(0xFF64748B),
                ), // Slate 500
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '[${widget.device.serial.split(':').first}] ${widget.device.modelName}'
                        .toUpperCase(),
                    style: GoogleFonts.firaCode(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      color: const Color(0xFF1E293B), // Slate 800
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Observer(
                  builder: (_) {
                    final isActive =
                        _store.shellStates[widget.device.serial] ?? false;
                    if (!isActive) {
                      final hasLastExec =
                          _store.lastExecutions.containsKey(widget.device.serial);
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hasLastExec) ...[
                            IconButton(
                              icon: const Icon(
                                Icons.replay_rounded,
                                size: 14,
                                color: Color(0xFF64748B), // Slate 500
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Chạy lại lệnh/script gần nhất',
                              onPressed: () => _store.rerunLastExecution(widget.device.serial),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            '${_store.deviceLogs[widget.device.serial]?.length ?? 0} lines',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 8,
                              color: const Color(0xFF94A3B8), // Slate 400
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Tooltip(
                          message: 'Dừng kịch bản trên thiết bị này',
                          child: GestureDetector(
                            onTap: () => _store.stopCommand(widget.device.serial),
                            child: const Icon(
                              Icons.stop_circle_rounded,
                              size: 18,
                              color: Colors.pinkAccent,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          // Mini Terminal
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              color: Colors.white,
              child: Observer(
                builder: (context) {
                  final itemCount =
                      _store.deviceLogs[widget.device.serial]?.length ?? 0;
                  return ListView.builder(
                    itemCount: itemCount,
                    reverse: true,
                    itemBuilder: (context, i) {
                      final log = _store
                          .deviceLogs[widget.device.serial]!
                          .reversed
                          .toList()[i];
                      final Widget logItem;
                      switch (log.type) {
                        case LogType.command:
                          logItem = Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r'$ ',
                                  style: GoogleFonts.firaCode(
                                    fontSize: 9,
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    log.message,
                                    style: GoogleFonts.firaCode(
                                      fontSize: 9,
                                      color: const Color(
                                        0xFF1E293B,
                                      ), // Slate 800
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        case LogType.error:
                          logItem = Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              log.message,
                              style: GoogleFonts.firaCode(
                                fontSize: 9,
                                color: Colors.red.shade700,
                                height: 1.4,
                              ),
                            ),
                          );
                        case LogType.info:
                          logItem = Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              '// ${log.message}',
                              style: GoogleFonts.firaCode(
                                fontSize: 9,
                                color: const Color(0xFF94A3B8), // Slate 400
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          );
                        default:
                          logItem = Padding(
                            padding: const EdgeInsets.symmetric(vertical: 1),
                            child: Text(
                              log.message,
                              style: GoogleFonts.firaCode(
                                fontSize: 9,
                                color: const Color(0xFF334155), // Slate 700
                                height: 1.5,
                              ),
                            ),
                          );
                      }
                      return SelectionArea(child: logItem);
                    },
                  );
                },
              ),
            ),
          ),
          // Mini Prompt
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFF1F5F9)),
              ), // Slate 100
              color: Color(0xFFF8FAFC), // Slate 50
            ),
            child: Row(
              children: [
                Text(
                  r'$',
                  style: GoogleFonts.firaCode(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    focusNode: _focusNode,
                    style: GoogleFonts.firaCode(
                      fontSize: 9,
                      color: const Color(0xFF1E293B), // Slate 800
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Nhập lệnh...',
                      hintStyle: GoogleFonts.firaCode(
                        fontSize: 9,
                        color: const Color(0xFF94A3B8),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (value) {
                      _store.executeCommandOnDevice(
                        widget.device.serial,
                        value,
                      );
                      _inputController.clear();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_focusNode.canRequestFocus) {
                          _focusNode.requestFocus();
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
