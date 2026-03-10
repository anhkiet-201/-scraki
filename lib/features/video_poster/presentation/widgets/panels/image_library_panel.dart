import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:scraki/features/video_poster/presentation/stores/video_poster_store.dart';
import 'dart:io';

/// Image Library panel — drag-and-drop Image items to the video canvas
class ImageLibraryPanel extends StatelessWidget {
  final VideoPosterStore store;

  const ImageLibraryPanel({super.key, required this.store});

  /// Mở hộp thoại chọn ảnh hỗ trợ format PNG, JPG, GIF
  Future<void> _pickImage(BuildContext context) async {
    const XTypeGroup typeGroup = XTypeGroup(
      label: 'images',
      extensions: <String>['jpg', 'png', 'gif', 'jpeg'],
    );
    final XFile? file = await openFile(
      acceptedTypeGroups: <XTypeGroup>[typeGroup],
    );

    if (file != null) {
      if (!context.mounted) return;
      final isGif = file.name.toLowerCase().endsWith('.gif');
      // Tự động add vào giữa màn hình khi chọn từ máy
      store.addCustomImage(file.path, 0.5, 0.5, isGif: isGif);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Demo sources: a few default assets or web URLs
    final List<Map<String, dynamic>> demoImages = [
      {
        'url': 'https://dummyimage.com/400x400/e63946/ffffff.png&text=SALE',
        'isGif': false,
        'label': 'Giảm Giá',
      },
      {
        'url':
            'https://github.githubassets.com/images/spinners/octocat-spinner-128.gif',
        'isGif': true,
        'label': 'Octocat (GIF)',
      },
      {
        'url': 'https://dummyimage.com/400x400/2a9d8f/ffffff.png&text=WhatsApp',
        'isGif': false,
        'label': 'WhatsApp',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            "HÌNH ẢNH (BETA)",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ),
        const Divider(height: 1, color: Colors.white10),

        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () => _pickImage(context),
            icon: const Icon(Icons.upload_file),
            label: const Text('Tải ảnh lên'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(40),
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
          ),
        ),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            "Kéo thả vào Video:",
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: demoImages.length,
            itemBuilder: (context, index) {
              final item = demoImages[index];
              final url = item['url'] as String;
              final isGif = item['isGif'] as bool;

              final imageData = {'url': url, 'isGif': isGif};

              return Draggable<Map<String, dynamic>>(
                data: imageData,
                feedback: Material(
                  color: Colors.transparent,
                  child: Opacity(
                    opacity: 0.7,
                    child: SizedBox(
                      width: 100,
                      height: 100,
                      child: Image.network(url, fit: BoxFit.contain),
                    ),
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.3,
                  child: _ImageCard(
                    url: url,
                    label: item['label'] as String,
                    isGif: isGif,
                  ),
                ),
                child: _ImageCard(
                  url: url,
                  label: item['label'] as String,
                  isGif: isGif,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ImageCard extends StatelessWidget {
  final String url;
  final String label;
  final bool isGif;

  const _ImageCard({
    required this.url,
    required this.label,
    required this.isGif,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Center(
              child: url.startsWith('http')
                  ? Image.network(url, fit: BoxFit.contain)
                  : Image.file(File(url), fit: BoxFit.contain),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(11),
                ),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
          ),
          if (isGif)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'GIF',
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
