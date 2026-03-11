import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:scraki/features/video_poster/presentation/stores/video_poster_store.dart';
import 'package:scraki/features/video_poster/data/services/giphy_service.dart';

/// Image Library panel — drag-and-drop Image items to the video canvas
class ImageLibraryPanel extends StatefulWidget {
  final VideoPosterStore store;

  const ImageLibraryPanel({super.key, required this.store});

  @override
  State<ImageLibraryPanel> createState() => _ImageLibraryPanelState();
}

class _ImageLibraryPanelState extends State<ImageLibraryPanel> {
  final GiphyService _giphyService = GiphyService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _gifs = [];
  bool _isLoading = false;
  Timer? _debounce;

  final ScrollController _scrollController = ScrollController();
  int _offset = 0;
  final int _limit = 20;
  bool _isFetchingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchTrending();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && !_isFetchingMore) {
        _loadMoreGifs();
      }
    }
  }

  Future<void> _loadMoreGifs() async {
    setState(() => _isFetchingMore = true);
    _offset += _limit;

    final query = _searchController.text;
    List<Map<String, dynamic>> moreGifs = [];

    if (query.isEmpty) {
      moreGifs = await _giphyService.getTrendingGifs(
        limit: _limit,
        offset: _offset,
      );
    } else {
      moreGifs = await _giphyService.searchGifs(
        query,
        limit: _limit,
        offset: _offset,
      );
    }

    if (mounted) {
      setState(() {
        _gifs.addAll(moreGifs);
        _isFetchingMore = false;
      });
    }
  }

  Future<void> _fetchTrending() async {
    setState(() {
      _isLoading = true;
      _offset = 0;
    });
    final results = await _giphyService.getTrendingGifs(
      limit: _limit,
      offset: _offset,
    );
    if (mounted) {
      setState(() {
        _gifs = results;
        _isLoading = false;
      });
    }
  }

  Future<void> _onSearchChanged(String query) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        _fetchTrending();
        return;
      }

      setState(() {
        _isLoading = true;
        _offset = 0;
      });
      final results = await _giphyService.searchGifs(
        query,
        limit: _limit,
        offset: _offset,
      );
      if (mounted) {
        setState(() {
          _gifs = results;
          _isLoading = false;
        });
      }
    });
  }

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
      widget.store.addCustomImage(file.path, 0.5, 0.5, isGif: isGif);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            children: [
              ElevatedButton.icon(
                onPressed: () => _pickImage(context),
                icon: const Icon(Icons.upload_file),
                label: const Text('Tải ảnh lên'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm GIF trên Giphy...',
                  hintStyle: const TextStyle(color: Colors.white30),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.white30,
                    size: 18,
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _gifs.isEmpty
              ? Center(
                  child: Text(
                    _searchController.text.isEmpty
                        ? "Không có GIF thịnh hành"
                        : "Không tìm thấy kết cục",
                    style: const TextStyle(color: Colors.white30),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: GridView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 1,
                            ),
                        itemCount: _gifs.length,
                        itemBuilder: (context, index) {
                          final gif = _gifs[index];
                          final url = gif['url'] as String;

                          return InkWell(
                            onTap: () {
                              widget.store.addCustomImage(
                                url,
                                0.5,
                                0.5,
                                isGif: true,
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Image.network(
                                url,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                      Icons.broken_image,
                                      color: Colors.white10,
                                    ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (_isFetchingMore)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
