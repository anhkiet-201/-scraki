import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scraki/features/video_poster/presentation/stores/video_poster_store.dart';

class BatchVideoPanel extends StatelessWidget {
  final VideoPosterStore store;

  const BatchVideoPanel({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131313),
        border: Border(
          left: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          _buildConfiguration(),
          Expanded(child: _buildLogView()),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: const Text(
        'TẠO VIDEO HÀNG LOẠT',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildConfiguration() {
    return Observer(
      builder: (context) {
        final isCreating = store.isBatchCreating;

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Số lượng video (1-999):',
                style: TextStyle(fontSize: 12, color: Colors.white54),
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: store.batchOutputCount.toString(),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                enabled: !isCreating,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: const TextStyle(fontSize: 14),
                onChanged: (val) {
                  final count = int.tryParse(val);
                  if (count != null) {
                    store.setBatchOutputCount(count);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogView() {
    return Container(
      color: Colors.black,
      child: Observer(
        builder: (context) {
          final logs = store.batchLogs;
          if (logs.isEmpty) {
            return const Center(
              child: Text(
                'Log hệ thống sẽ hiển thị tại đây...',
                style: TextStyle(
                  color: Colors.white24,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            );
          }

          return ListView.builder(
            reverse:
                false, // In practice, auto-scroll is better but reverse breaks top-down logical reading if we just reverse the list.
            // Better approach for auto-scroll is scrolling to bottom, or simply reversing and inserting at index 0. We'll use simple list for now.
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  log,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Colors.greenAccent,
                    height: 1.4,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFooter() {
    return Observer(
      builder: (context) {
        final isCreating = store.isBatchCreating;
        final hasVideos = store.sourceVideoPaths.isNotEmpty;
        final outputDir = store.batchOutputDir;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (outputDir != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thư mục lưu:',
                        style: TextStyle(fontSize: 10, color: Colors.white54),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        outputDir,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              ElevatedButton(
                onPressed: (!hasVideos && !isCreating)
                    ? null
                    : () {
                        if (isCreating) {
                          store.cancelBatchVideos();
                        } else {
                          store.createBatchVideos();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCreating
                      ? Colors.redAccent
                      : const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: Colors.white10,
                ),
                child: isCreating
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'DỪNG XỬ LÝ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        'TẠO VIDEO',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
              ),
              if (!hasVideos)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Vui lòng thêm video nguồn trước',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: Colors.redAccent),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
