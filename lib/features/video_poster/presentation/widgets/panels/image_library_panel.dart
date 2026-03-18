import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:scraki/features/video_poster/presentation/stores/video_poster_store.dart';
import 'package:scraki/features/video_poster/data/services/giphy_service.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scraki/features/video_poster/presentation/widgets/panels/common/panel_components.dart';

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
  final ScrollController _horizontalScrollController = ScrollController();
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
    _horizontalScrollController.dispose();
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

        // Phần hiển thị Ảnh/GIF đã thêm vào video
        Observer(
          builder: (_) {
            final images = widget.store.customImages;
            final selectedId = widget.store.selectedCustomImageId;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (images.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      "Ảnh/GIF Đang Dùng:",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                  SizedBox(
                    height: 90,
                    child: Listener(
                      onPointerSignal: (pointerSignal) {
                        if (pointerSignal is PointerScrollEvent) {
                          final offset = pointerSignal.scrollDelta.dy;
                          if (offset != 0 &&
                              _horizontalScrollController.hasClients) {
                            _horizontalScrollController.jumpTo(
                              (_horizontalScrollController.offset + offset).clamp(
                                0.0,
                                _horizontalScrollController
                                    .position
                                    .maxScrollExtent,
                              ),
                            );
                          }
                        }
                      },
                      child: ReorderableListView.builder(
                        scrollController: _horizontalScrollController,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        buildDefaultDragHandles: false,
                        itemCount: images.length,
                        onReorder: (oldIndex, newIndex) {
                          widget.store.reorderCustomImage(oldIndex, newIndex);
                        },
                        itemBuilder: (context, index) {
                          final item = images[index];
                          final isSelected = selectedId == item.id;

                          return ReorderableDragStartListener(
                            key: ValueKey(item.id),
                            index: index,
                            child: GestureDetector(
                              onTap: () {
                                widget.store.selectCustomImage(item.id);
                              },
                              child: Container(
                                width: 80,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A2A2A),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? PanelComponents.kPanelAccentColor
                                        : Colors.white10,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: item.imageUrl.startsWith('http')
                                            ? Image.network(
                                                item.imageUrl,
                                                fit: BoxFit.contain,
                                              )
                                            : Image.file(
                                                File(item.imageUrl),
                                                fit: BoxFit.contain,
                                                errorBuilder: (ctx, err, stack) =>
                                                    const Icon(
                                                      Icons.image,
                                                      color: Colors.white30,
                                                    ),
                                              ),
                                      ),
                                    ),
                                    if (item.isGif)
                                      Positioned(
                                        top: 4,
                                        left: 4,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: PanelComponents.kPanelAccentColor,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: const Text(
                                            'GIF',
                                            style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: () {
                                          widget.store.removeCustomImage(item.id);
                                        },
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.redAccent,
                                            borderRadius: BorderRadius.only(
                                              bottomLeft: Radius.circular(8),
                                              topRight: Radius.circular(8),
                                            ),
                                          ),
                                          padding: const EdgeInsets.all(4),
                                          child: const Icon(
                                            Icons.close,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Observer(
                                        builder: (_) {
                                          if (!item.imageUrl.startsWith('http')) {
                                            return const SizedBox.shrink();
                                          }

                                          final isFavorite = widget
                                              .store
                                              .favoriteImages
                                              .any((f) => f.url == item.imageUrl);
                                          return GestureDetector(
                                            onTap: () {
                                              widget.store.toggleFavorite(
                                                item.imageUrl,
                                                isGif: item.isGif,
                                              );
                                            },
                                            child: Container(
                                              decoration: const BoxDecoration(
                                                color: Colors.black45,
                                                borderRadius: BorderRadius.only(
                                                  topLeft: Radius.circular(8),
                                                  bottomRight: Radius.circular(8),
                                                ),
                                              ),
                                              padding: const EdgeInsets.all(4),
                                              child: Icon(
                                                isFavorite
                                                    ? Icons.favorite
                                                    : Icons.favorite_border,
                                                size: 14,
                                                color: isFavorite
                                                    ? Colors.redAccent
                                                    : Colors.white,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],

                if (selectedId != null) ...[
                  const SizedBox(height: 12),
                  _buildImageProperties(selectedId),
                ],

                if (images.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 12.0),
                    child: Divider(height: 1, color: Colors.white10),
                  ),
              ],
            );
          },
        ),

        Expanded(
          child: DefaultTabController(
            length: 2,
            initialIndex: 1,
            child: Column(
              children: [
                const TabBar(
                  indicatorColor: Color(0xFF6366F1),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white30,
                  tabs: [
                    Tab(text: 'Khám Phá'),
                    Tab(text: 'Yêu Thích'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [_buildDiscoverTab(), _buildFavoritesTab()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageProperties(String selectedId) {
    final image = widget.store.customImages.firstWhere((i) => i.id == selectedId);

    return Column(
      children: [
        // ── Section: APPEARANCE (MÀU SẮC & BO GÓC) ──
        PanelComponents.buildPanelSection(
          title: 'MÀU SẮC & BO GÓC',
          icon: Icons.auto_awesome_rounded,
          initiallyExpanded: true,
          children: [
            PanelComponents.buildPanelRow(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PanelComponents.buildSectionLabel(
                      'BO GÓC: ${image.borderRadius.toInt()}px',
                    ),
                    PanelComponents.buildSlider(
                      context: context,
                      value: image.borderRadius,
                      min: 0,
                      max: 100,
                      onChanged: (v) => widget.store
                          .updateCustomImageBorder(selectedId,
                              borderRadius: v),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PanelComponents.buildSectionLabel('XOAY: ${image.rotation.toInt()}°'),
                    PanelComponents.buildSlider(
                      context: context,
                      value: image.rotation,
                      min: -180,
                      max: 180,
                      divisions: 360,
                      onChanged: (v) => widget.store.updateCustomImageRotation(selectedId, v),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),

        // ── Section: BORDER (VIỀN ẢNH) ──
        PanelComponents.buildPanelSection(
          title: 'VIỀN ẢNH',
          icon: Icons.border_outer_rounded,
          children: [
            PanelComponents.buildSectionLabel('MÀU VIỀN'),
            const SizedBox(height: 8),
            if (widget.store.recentBorderColors.isNotEmpty) ...[
              PanelComponents.buildRecentColors(
                colors: widget.store.recentBorderColors.toList(),
                selectedColor: image.borderColor,
                onSelect: (c) =>
                    widget.store.updateCustomImageBorder(selectedId, color: c),
              ),
              const SizedBox(height: 8),
              PanelComponents.buildPaletteDivider(),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                GestureDetector(
                  onTap: () => widget.store.updateCustomImageBorder(
                    selectedId,
                    width: 0,
                    clearBorderColor: true,
                  ),
                  child: Container(
                    width: 28, height: 28,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: image.borderWidth == 0 ? PanelComponents.kPanelAccentColor : Colors.white10,
                        width: image.borderWidth == 0 ? 2 : 1,
                      ),
                    ),
                    child: const Icon(Icons.block_rounded, size: 14, color: Colors.white38),
                  ),
                ),
                Expanded(
                  child: PanelComponents.buildColorPalette(
                    context: context,
                    colors: PanelComponents.colorPalette,
                    selectedColor: image.borderColor,
                    onSelect: (c) {
                      widget.store.updateCustomImageBorder(selectedId, color: c);
                      if (image.borderWidth == 0) widget.store.updateCustomImageBorder(selectedId, width: 2.0);
                    },
                    onPickCustom: () => PanelComponents.showColorPicker(
                      context: context,
                      initialColor: image.borderColor ?? Colors.white,
                      onColorSelected: (c) {
                        widget.store.updateCustomImageBorder(selectedId, color: c);
                        if (image.borderWidth == 0) widget.store.updateCustomImageBorder(selectedId, width: 2.0);
                      },
                    ),
                  ),
                ),
              ],
            ),
            if (image.borderColor != null && image.borderWidth > 0) ...[
              const SizedBox(height: 16),
              PanelComponents.buildSectionLabel('ĐỘ DÀY VIỀN: ${image.borderWidth.toInt()}px'),
              PanelComponents.buildSlider(
                context: context,
                value: image.borderWidth,
                min: 0, max: 20,
                onChanged: (v) => widget.store.updateCustomImageBorder(selectedId, width: v),
              ),
            ],
          ],
        ),

        // ── Section: TIMELINE ──
        PanelComponents.buildPanelSection(
          title: 'THỜI GIAN HIỂN THỊ',
          icon: Icons.timer_rounded,
          children: [
            PanelComponents.buildTimeInput(
              label: 'BẮT ĐẦU (s)',
              value: image.startTime,
              onChanged: (v) => widget.store.updateCustomImageTiming(selectedId, startTime: v),
            ),
            const SizedBox(height: 12),
            PanelComponents.buildTimeInput(
              label: 'KẾT THÚC (s)',
              value: image.endTime,
              hint: 'Xuyên suốt',
              onChanged: (v) => v == null 
                  ? widget.store.updateCustomImageTiming(selectedId, clearEndTime: true)
                  : widget.store.updateCustomImageTiming(selectedId, endTime: v),
            ),
          ],
        ),

        const SizedBox(height: 16),
        
        // ── Delete Button ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => widget.store.removeCustomImage(selectedId),
              style: TextButton.styleFrom(
                foregroundColor: Colors.redAccent.withOpacity(0.8),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.redAccent.withOpacity(0.2)),
                ),
              ),
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('XÓA ẢNH/GIF NÀY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDiscoverTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
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
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _gifs.isEmpty
              ? Center(
                  child: Text(
                    _searchController.text.isEmpty
                        ? "Không có GIF thịnh hành"
                        : "Không tìm thấy kết quả",
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
                          return _buildGifItem(url, true);
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

  Widget _buildFavoritesTab() {
    return Observer(
      builder: (_) {
        final favorites = widget.store.favoriteImages;

        if (widget.store.isLoadingFavorites && favorites.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (favorites.isEmpty) {
          return const Center(
            child: Text(
              "Chưa có ảnh/GIF yêu thích nào",
              style: TextStyle(color: Colors.white30),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: favorites.length,
          itemBuilder: (context, index) {
            final fav = favorites[index];
            return _buildGifItem(fav.url, fav.isGif);
          },
        );
      },
    );
  }

  Widget _buildGifItem(String url, bool isGif) {
    return Observer(
      builder: (_) {
        final isFavorite = widget.store.favoriteImages.any((f) => f.url == url);

        return Stack(
          children: [
            InkWell(
              onTap: () {
                widget.store.addCustomImage(url, 0.5, 0.5, isGif: isGif);
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
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image, color: Colors.white10),
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => widget.store.toggleFavorite(url, isGif: isGif),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.redAccent : Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

}
