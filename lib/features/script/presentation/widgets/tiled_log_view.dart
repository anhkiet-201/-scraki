import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/log_entry.dart';
import '../stores/script_store.dart';

class TiledLogView extends StatelessWidget {
  final ScriptStore store;

  const TiledLogView({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final devices = store.selectedSerials.toList();
        if (devices.isEmpty) {
          return const Center(child: Text('Hãy chọn thiết bị để xem log riêng biệt'));
        }

        // Dynamic column count based on device count
        int crossAxisCount = 2;
        if (devices.length >= 7) {
          crossAxisCount = 4;
        } else if (devices.length >= 3) {
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
          itemCount: devices.length,
          itemBuilder: (context, index) {
            final serial = devices[index];
            return Observer(
              builder: (_) {
                final deviceModel = store.devices.firstWhere((d) => d.serial == serial).modelName;
                final logs = store.terminalOutput.where((l) => l.serial == serial).toList();

                return _DeviceLogTile(
                  serial: serial,
                  model: deviceModel,
                  logs: logs,
                  store: store,
                );
              },
            );
          },
        );
      },
    );
  }
}

class _DeviceLogTile extends StatefulWidget {
  final String serial;
  final String model;
  final List<LogEntry> logs;
  final ScriptStore store;

  const _DeviceLogTile({
    required this.serial,
    required this.model,
    required this.logs,
    required this.store,
  });

  @override
  State<_DeviceLogTile> createState() => _DeviceLogTileState();
}

class _DeviceLogTileState extends State<_DeviceLogTile> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    _scrollToBottom();

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
                const Icon(Icons.terminal_rounded, size: 14, color: Color(0xFF64748B)), // Slate 500
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.model.toUpperCase(),
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
                    final isActive = widget.store.hasActiveSubscription(widget.serial);
                    if (!isActive) {
                      return Text(
                        '${widget.logs.length} lines',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 8, 
                          color: const Color(0xFF94A3B8), // Slate 400
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }
                    return Row(
                      children: [
                        SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 2, 
                            color: theme.colorScheme.primary.withValues(alpha: 0.5)
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => widget.store.stopCommand(widget.serial),
                          child: const Icon(Icons.stop_circle_rounded, size: 16, color: Colors.pinkAccent),
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
              child: SelectionArea(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: widget.logs.length,
                  itemBuilder: (context, i) {
                    final log = widget.logs[i];
                    
                    switch (log.type) {
                      case LogType.command:
                        return Padding(
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
                                    color: const Color(0xFF1E293B), // Slate 800
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      case LogType.error:
                        return Padding(
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
                        return Padding(
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
                        return Padding(
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
                  },
                ),
              ),
            ),
          ),
          // Mini Prompt
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))), // Slate 100
              color: Color(0xFFF8FAFC), // Slate 50
            ),
            child: Row(
              children: [
                Text(
                  r'$', 
                  style: GoogleFonts.firaCode(
                    fontSize: 10, 
                    fontWeight: FontWeight.bold, 
                    color: theme.colorScheme.primary
                  )
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
                      hintStyle: GoogleFonts.firaCode(fontSize: 9, color: const Color(0xFF94A3B8)),
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (value) {
                      widget.store.executeCommandOnDevice(widget.serial, value);
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
