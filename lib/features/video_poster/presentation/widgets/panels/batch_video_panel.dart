import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'package:scraki/features/video_poster/presentation/stores/video_poster_store.dart';

/// Các định dạng audio được hỗ trợ khi chọn file hoặc drag & drop.
const _kAudioExtensions = [
  'mp3', 'aac', 'wav', 'm4a', 'ogg', 'flac', 'opus', 'wma', 'aiff',
];

class BatchVideoPanel extends StatefulWidget {
  final VideoPosterStore store;

  const BatchVideoPanel({super.key, required this.store});

  @override
  State<BatchVideoPanel> createState() => _BatchVideoPanelState();
}

class _BatchVideoPanelState extends State<BatchVideoPanel> {
  final ScrollController _scrollController = ScrollController();

  // Trạng thái hover cho vùng drag & drop
  bool _isAudioDragOver = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ─── File Picker ──────────────────────────────────────────────────────────

  Future<void> _pickAudioFile() async {
    try {
      const typeGroup = XTypeGroup(
        label: 'Audio files',
        extensions: _kAudioExtensions,
      );
      final file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file != null) {
        widget.store.setCustomAudioPath(file.path);
      }
    } catch (e) {
      debugPrint('[BatchVideoPanel] Failed to pick audio file: $e');
    }
  }

  // ─── Drag & Drop validation ───────────────────────────────────────────────

  bool _isAudioFile(String filename) {
    final ext = p.extension(filename).toLowerCase().replaceFirst('.', '');
    return _kAudioExtensions.contains(ext);
  }

  // ─── Build ────────────────────────────────────────────────────────────────

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
      decoration: const BoxDecoration(border: null),
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
    return Observer(
      builder: (context) {
        final isCreating = widget.store.isBatchCreating;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOutputCountField(context, isCreating),
              const SizedBox(height: 20),
              _buildAudioSection(context, isCreating),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // ─── Số lượng video ───────────────────────────────────────────────────────

  Widget _buildOutputCountField(BuildContext context, bool isCreating) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(context, 'SỐ LƯỢNG VIDEO'),
        const SizedBox(height: 10),
        TextFormField(
          initialValue: widget.store.batchOutputCount.toString(),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          enabled: !isCreating,
          decoration: InputDecoration(
            filled: true,
            fillColor: isLight
                ? Colors.black.withValues(alpha: 0.03)
                : Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isLight
                    ? Colors.black.withValues(alpha: 0.05)
                    : Colors.white10,
                width: 0.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isLight
                    ? Colors.black.withValues(alpha: 0.05)
                    : Colors.white10,
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
    );
  }

  // ─── Section Âm thanh tùy chỉnh ──────────────────────────────────────────

  Widget _buildAudioSection(BuildContext context, bool isCreating) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Observer(
      builder: (context) {
        final audioPath = widget.store.customAudioPath;
        final hasAudio = audioPath != null && audioPath.isNotEmpty;
        final volume = widget.store.customAudioVolume;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel(context, 'ÂM THANH NỀN'),
            const SizedBox(height: 10),

            // ── Drop zone + picker ─────────────────────────────────────────
            DropRegion(
              formats: Formats.standardFormats,
              onDropOver: (event) {
                // chỉ nhận file audio
                final items = event.session.items;
                final couldBeAudio = items.any((item) {
                  return item.canProvide(Formats.fileUri) ||
                      item.canProvide(Formats.plainText);
                });
                if (couldBeAudio && !isCreating) {
                  setState(() => _isAudioDragOver = true);
                }
                return couldBeAudio
                    ? DropOperation.copy
                    : DropOperation.none;
              },
              onDropLeave: (_) {
                setState(() => _isAudioDragOver = false);
              },
              onPerformDrop: (event) async {
                setState(() => _isAudioDragOver = false);
                if (isCreating) return;
                for (final item in event.session.items) {
                  final reader = item.dataReader!;
                  if (reader.canProvide(Formats.fileUri)) {
                    reader.getValue(Formats.fileUri, (uri) {
                      if (uri == null) return;
                      final filePath = uri.toFilePath();
                      if (_isAudioFile(filePath)) {
                        widget.store.setCustomAudioPath(filePath);
                      }
                    });
                    break;
                  }
                }
              },
              child: _buildDropZone(
                context,
                isLight: isLight,
                isCreating: isCreating,
                hasAudio: hasAudio,
                audioPath: audioPath,
              ),
            ),

            // ── Volume slider (chỉ hiện khi đã có audio) ─────────────────
            if (hasAudio) ...[
              const SizedBox(height: 12),
              _buildVolumeSlider(
                context,
                isLight: isLight,
                isCreating: isCreating,
                volume: volume,
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildDropZone(
    BuildContext context, {
    required bool isLight,
    required bool isCreating,
    required bool hasAudio,
    required String? audioPath,
  }) {
    final isDragging = _isAudioDragOver;

    final borderColor = isDragging
        ? const Color(0xFF6366F1)
        : hasAudio
        ? const Color(0xFF10B981).withValues(alpha: 0.7)
        : isLight
        ? Colors.black.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.12);

    final bgColor = isDragging
        ? const Color(0xFF6366F1).withValues(alpha: 0.08)
        : hasAudio
        ? const Color(0xFF10B981).withValues(alpha: 0.06)
        : isLight
        ? Colors.black.withValues(alpha: 0.02)
        : Colors.white.withValues(alpha: 0.03);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: isDragging ? 1.5 : 1.0,
          style: hasAudio ? BorderStyle.solid : BorderStyle.solid,
        ),
      ),
      child: hasAudio
          ? _buildAudioSelectedRow(context, isLight, audioPath!, isCreating)
          : _buildEmptyDropZone(context, isLight, isCreating, isDragging),
    );
  }

  Widget _buildEmptyDropZone(
    BuildContext context,
    bool isLight,
    bool isCreating,
    bool isDragging,
  ) {
    return InkWell(
      onTap: isCreating ? null : _pickAudioFile,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDragging
                    ? const Color(0xFF6366F1).withValues(alpha: 0.15)
                    : isLight
                    ? Colors.black.withValues(alpha: 0.05)
                    : Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isDragging ? Icons.file_download_outlined : Icons.music_note_rounded,
                size: 20,
                color: isDragging
                    ? const Color(0xFF6366F1)
                    : isLight
                    ? const Color(0xFF94A3B8)
                    : Colors.white38,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isDragging ? 'Thả file vào đây' : 'Thêm nhạc nền',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDragging
                          ? const Color(0xFF6366F1)
                          : isLight
                          ? const Color(0xFF334155)
                          : Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'MP3, AAC, WAV, M4A... hoặc kéo thả',
                    style: TextStyle(
                      fontSize: 10,
                      color: isLight
                          ? const Color(0xFFCBD5E1)
                          : Colors.white24,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.add_circle_outline_rounded,
              size: 18,
              color: isLight
                  ? const Color(0xFF94A3B8)
                  : Colors.white24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioSelectedRow(
    BuildContext context,
    bool isLight,
    String audioPath,
    bool isCreating,
  ) {
    final fileName = p.basename(audioPath);
    final ext = p.extension(fileName).toUpperCase().replaceFirst('.', '');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // Icon file type badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  ext.length > 4 ? ext.substring(0, 4) : ext,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF10B981),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isLight ? const Color(0xFF0F172A) : Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Nhạc nền đã chọn · nhấn để thay đổi',
                  style: TextStyle(
                    fontSize: 10,
                    color: isLight
                        ? const Color(0xFF94A3B8)
                        : Colors.white38,
                  ),
                ),
              ],
            ),
          ),
          // Change button
          if (!isCreating) ...[
            InkWell(
              onTap: _pickAudioFile,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.swap_horiz_rounded,
                  size: 18,
                  color: isLight
                      ? const Color(0xFF64748B)
                      : Colors.white54,
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Clear button
            InkWell(
              onTap: () => widget.store.setCustomAudioPath(null),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: Colors.redAccent.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVolumeSlider(
    BuildContext context, {
    required bool isLight,
    required bool isCreating,
    required double volume,
  }) {
    final pct = (volume * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.volume_up_rounded,
                  size: 14,
                  color: isLight
                      ? const Color(0xFF64748B)
                      : Colors.white54,
                ),
                const SizedBox(width: 6),
                Text(
                  'Âm lượng nhạc',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isLight
                        ? const Color(0xFF475569)
                        : Colors.white60,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$pct%',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6366F1),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF6366F1),
            inactiveTrackColor: isLight
                ? Colors.black.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.1),
            thumbColor: const Color(0xFF6366F1),
            overlayColor: const Color(0xFF6366F1).withValues(alpha: 0.12),
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          ),
          child: Slider(
            value: volume,
            min: 0.0,
            max: 1.0,
            onChanged: isCreating
                ? null
                : (val) => widget.store.setCustomAudioVolume(val),
          ),
        ),
        // Volume hint: audio gốc luôn ở 5%
        Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 11,
                color: isLight ? const Color(0xFFCBD5E1) : Colors.white24),
            const SizedBox(width: 4),
            Text(
              'Audio gốc video giữ ở mức 5%',
              style: TextStyle(
                fontSize: 10,
                color: isLight ? const Color(0xFFCBD5E1) : Colors.white24,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Log view ─────────────────────────────────────────────────────────────

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
                  final isError = log.toLowerCase().contains('error') ||
                      log.toLowerCase().contains('failed');
                  final isSuccess = log.toLowerCase().contains('success') ||
                      log.toLowerCase().contains('done');

                  Color logColor =
                      isLight ? const Color(0xFF475569) : Colors.greenAccent;
                  if (isError) logColor = Colors.redAccent;
                  if (isSuccess) {
                    logColor =
                        isLight ? const Color(0xFF10B981) : Colors.greenAccent;
                  }

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
                            color: isLight
                                ? const Color(0xFF94A3B8)
                                : Colors.white24,
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
                              fontWeight: (isError || isSuccess)
                                  ? FontWeight.bold
                                  : FontWeight.normal,
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

  // ─── Footer ───────────────────────────────────────────────────────────────

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
            color: isLight
                ? const Color(0xFFF8FAFC)
                : const Color(0xFF1A1A1A),
            border: null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (outputDir != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isLight
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.05),
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
                          color: isLight
                              ? const Color(0xFF94A3B8)
                              : Colors.white38,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        outputDir,
                        style: TextStyle(
                          fontSize: 10,
                          color: isLight
                              ? const Color(0xFF475569)
                              : Colors.white70,
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
                  backgroundColor:
                      isCreating ? Colors.redAccent : const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  disabledBackgroundColor: isLight
                      ? Colors.black.withValues(alpha: 0.05)
                      : Colors.white10,
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
                          const Text(
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
                    style: const TextStyle(
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

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Widget _sectionLabel(BuildContext context, String text) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: isLight ? const Color(0xFF94A3B8) : Colors.white38,
        letterSpacing: 1,
      ),
    );
  }
}
