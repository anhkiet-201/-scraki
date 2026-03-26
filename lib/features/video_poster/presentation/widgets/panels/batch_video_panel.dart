import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scraki/features/video_poster/presentation/stores/video_poster_store.dart';

class BatchVideoPanel extends StatefulWidget {
  final VideoPosterStore store;

  const BatchVideoPanel({super.key, required this.store});

  @override
  State<BatchVideoPanel> createState() => _BatchVideoPanelState();
}

class _BatchVideoPanelState extends State<BatchVideoPanel> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF131313),
        border: null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          _buildConfiguration(context),
          Expanded(child: _buildLogView(context)),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      decoration: const BoxDecoration(
        border: null,
      ),
      child: Text(
        'TẠO VIDEO HÀNG LOẠT',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          color: isLight ? const Color(0xFF475569) : Colors.white70,
        ),
      ),
    );
  }

  Widget _buildConfiguration(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Observer(
      builder: (context) {
        final isCreating = widget.store.isBatchCreating;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SỐ LƯỢNG VIDEO',
                style: TextStyle(
                  fontSize: 10, 
                  fontWeight: FontWeight.bold,
                  color: isLight ? const Color(0xFF94A3B8) : Colors.white38,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                initialValue: widget.store.batchOutputCount.toString(),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                enabled: !isCreating,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isLight ? Colors.black.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isLight ? Colors.black.withValues(alpha: 0.05) : Colors.white10,
                      width: 0.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isLight ? Colors.black.withValues(alpha: 0.05) : Colors.white10,
                      width: 0.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                style: TextStyle(
                  fontSize: 14, 
                  fontWeight: FontWeight.bold,
                  color: isLight ? const Color(0xFF0F172A) : Colors.white,
                ),
                onChanged: (val) {
                  final count = int.tryParse(val);
                  if (count != null) {
                    widget.store.setBatchOutputCount(count);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogView(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: null,
        boxShadow: [
          if (isLight)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Observer(
        builder: (context) {
          final logs = widget.store.batchLogs;
          if (logs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Log hệ thống sẽ hiển thị tại đây...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isLight ? const Color(0xFFCBD5E1) : Colors.white24,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
              ),
            );
          }

          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  final isError = log.toLowerCase().contains('error') || log.toLowerCase().contains('failed');
                  final isSuccess = log.toLowerCase().contains('success') || log.toLowerCase().contains('done');
                  
                  Color logColor = isLight ? const Color(0xFF475569) : Colors.greenAccent;
                  if (isError) logColor = Colors.redAccent;
                  if (isSuccess) logColor = isLight ? const Color(0xFF10B981) : Colors.greenAccent;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '> ',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: isLight ? const Color(0xFF94A3B8) : Colors.white24,
                          ),
                        ),
                        Expanded(
                          child: SelectableText(
                            log,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: logColor,
                              height: 1.4,
                              fontWeight: (isError || isSuccess) ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Observer(
      builder: (context) {
        final isCreating = widget.store.isBatchCreating;
        final hasVideos = widget.store.sourceVideoPaths.isNotEmpty;
        final outputDir = widget.store.batchOutputDir;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF1A1A1A),
            border: null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (outputDir != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isLight ? Colors.white : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'THƯ MỤC LƯU:',
                        style: TextStyle(
                          fontSize: 9, 
                          fontWeight: FontWeight.w900,
                          color: isLight ? const Color(0xFF94A3B8) : Colors.white38,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        outputDir,
                        style: TextStyle(
                          fontSize: 10,
                          color: isLight ? const Color(0xFF475569) : Colors.white70,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              ElevatedButton(
                onPressed: (!hasVideos && !isCreating)
                    ? null
                    : () {
                        if (isCreating) {
                          widget.store.cancelBatchVideos();
                        } else {
                          widget.store.createBatchVideos();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCreating
                      ? Colors.redAccent
                      : const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  disabledBackgroundColor: isLight ? Colors.black.withValues(alpha: 0.05) : Colors.white10,
                ),
                child: isCreating
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'DỪNG XỬ LÝ',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        'TẠO VIDEO',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          fontSize: 12,
                        ),
                      ),
              ),
              if (!hasVideos)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    'Vui lòng thêm video nguồn trước',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10, 
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
