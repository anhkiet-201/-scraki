import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scraki/features/video_poster/domain/entities/image_poster_config.dart';
import 'package:scraki/features/video_poster/presentation/stores/video_poster_store.dart';

class ImagePosterPanel extends StatefulWidget {
  final VideoPosterStore store;

  const ImagePosterPanel({super.key, required this.store});

  @override
  State<ImagePosterPanel> createState() => _ImagePosterPanelState();
}

class _ImagePosterPanelState extends State<ImagePosterPanel> {
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
      child: Text(
        'TẠO ẢNH POSTER HÀNG LOẠT',
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
                'SỐ LƯỢNG BỘ ẢNH (SETS)',
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              const SizedBox(height: 16),
              Text(
                'NỀN TẢNG (PLATFORM SET)',
                style: TextStyle(
                  fontSize: 10, 
                  fontWeight: FontWeight.bold,
                  color: isLight ? const Color(0xFF94A3B8) : Colors.white38,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isLight ? Colors.black.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isLight ? Colors.black.withValues(alpha: 0.05) : Colors.white10,
                    width: 0.5,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<PosterPlatformSet>(
                    value: widget.store.posterPlatformSet,
                    dropdownColor: isLight ? Colors.white : const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    elevation: 8,
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: isLight ? const Color(0xFF64748B) : Colors.white38,
                    ),
                    isExpanded: true,
                    style: TextStyle(
                      color: isLight ? const Color(0xFF0F172A) : Colors.white,
                      fontSize: 13,
                    ),
                    onChanged: isCreating
                        ? null
                        : (PosterPlatformSet? newValue) {
                            if (newValue != null) {
                              widget.store.setPosterPlatformSet(newValue);
                            }
                          },
                    items: PosterPlatformSet.values.map<DropdownMenuItem<PosterPlatformSet>>((PosterPlatformSet value) {
                      return DropdownMenuItem<PosterPlatformSet>(
                        value: value,
                        child: Text(
                          value.label,
                          style: TextStyle(
                            color: isLight ? const Color(0xFF0F172A) : Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (widget.store.posterPlatformSet == PosterPlatformSet.facebook) ...[
                Text(
                  'LOẠI FACEBOOK (FACEBOOK SUBTYPE)',
                  style: TextStyle(
                    fontSize: 10, 
                    fontWeight: FontWeight.bold,
                    color: isLight ? const Color(0xFF94A3B8) : Colors.white38,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isLight ? Colors.black.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isLight ? Colors.black.withValues(alpha: 0.05) : Colors.white10,
                      width: 0.5,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<FacebookSubtype>(
                      value: widget.store.facebookSubtype,
                      dropdownColor: isLight ? Colors.white : const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                      elevation: 8,
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: isLight ? const Color(0xFF64748B) : Colors.white38,
                      ),
                      isExpanded: true,
                      style: TextStyle(
                        color: isLight ? const Color(0xFF0F172A) : Colors.white,
                        fontSize: 13,
                      ),
                      onChanged: isCreating
                          ? null
                          : (FacebookSubtype? newValue) {
                              if (newValue != null) {
                                widget.store.setFacebookSubtype(newValue);
                              }
                            },
                      items: FacebookSubtype.values.map<DropdownMenuItem<FacebookSubtype>>((FacebookSubtype value) {
                        return DropdownMenuItem<FacebookSubtype>(
                          value: value,
                          child: Text(
                            value.label,
                            style: TextStyle(
                              color: isLight ? const Color(0xFF0F172A) : Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
               Text(
                'QUY CÁCH: 1080x1350 (JPEG)',
                style: TextStyle(
                  fontSize: 10, 
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6366F1),
                  letterSpacing: 0.5,
                ),
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
      ),
      child: Observer(
        builder: (context) {
          final logs = widget.store.batchLogs;
          if (logs.isEmpty) {
            return Center(
              child: Text(
                'Log hệ thống sẽ hiển thị tại đây...',
                style: TextStyle(
                  color: isLight ? const Color(0xFFCBD5E1) : Colors.white24,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            );
          }

          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '> $log',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Observer(
      builder: (context) {
        final isCreating = widget.store.isBatchCreating;
        final hasVideos = widget.store.sourceVideoPaths.isNotEmpty;
        final outputDir = widget.store.batchOutputDir;

        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (outputDir != null) ...[
                 Text(
                    'LƯU TẠI: $outputDir',
                    style: TextStyle(fontSize: 10, color: Colors.blueGrey),
                  ),
                const SizedBox(height: 12),
              ],
              ElevatedButton(
                onPressed: (!hasVideos && !isCreating)
                    ? null
                    : () {
                        if (isCreating) {
                          widget.store.cancelBatchVideos();
                        } else {
                          widget.store.exportImagePosters();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCreating ? Colors.redAccent : const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: isCreating
                    ? const Text('DỪNG XỬ LÝ')
                    : const Text('XUẤT BỘ ẢNH'),
              ),
            ],
          ),
        );
      },
    );
  }
}
