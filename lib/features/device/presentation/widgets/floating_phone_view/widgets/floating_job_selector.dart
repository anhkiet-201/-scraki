import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scraki/core/mixins/di_mixin.dart';
import 'package:scraki/features/poster/domain/entities/poster_data.dart';
import 'package:scraki/features/poster/presentation/stores/poster_creation_store.dart';

import 'dart:async';

class FloatingJobSelector extends StatefulWidget {
  final void Function(PosterData) onJobSelected;
  final VoidCallback onCancel;

  const FloatingJobSelector({
    super.key,
    required this.onJobSelected,
    required this.onCancel,
  });

  @override
  State<FloatingJobSelector> createState() => _FloatingJobSelectorState();
}

class _FloatingJobSelectorState extends State<FloatingJobSelector> {
  late final PosterCreationStore _store;

  @override
  void initState() {
    super.initState();
    _store = inject<PosterCreationStore>();
    _store.loadAvailableJobs();
  }

  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _store.searchJobs(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;

    return Column(
      mainAxisSize: MainAxisSize.min, // Shrink to fit
      children: [
        // Modern Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: onSurface.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.work_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chọn việc làm',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tạo poster từ tin tuyển dụng',
                      style: TextStyle(
                        fontSize: 13,
                        color: onSurface.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: widget.onCancel,
                color: onSurface.withValues(alpha: 0.8),
                iconSize: 22,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),

        // SearchBar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SizedBox(
            height: 40,
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm công việc...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: onSurface.withValues(alpha: 0.5),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: onSurface.withValues(alpha: 0.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
                filled: true,
                fillColor: onSurface.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: colorScheme.primary.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
              ),
              style: TextStyle(fontSize: 14, color: onSurface),
            ),
          ),
        ),

        // List
        Expanded(
          child: Observer(
            builder: (_) {
              if (_store.isLoading) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(strokeWidth: 2),
                      SizedBox(height: 16),
                      Text(
                        'Đang tải...',
                        style: TextStyle(
                          color: onSurface.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (_store.availableJobs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 48,
                        color: onSurface.withValues(alpha: 0.5),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Không việc làm',
                        style: TextStyle(
                          color: onSurface.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  if (scrollInfo.metrics.pixels >=
                          scrollInfo.metrics.maxScrollExtent - 200 &&
                      !_store.isLoading &&
                      !_store.isLoadMore &&
                      _store.hasMore) {
                    _store.loadAvailableJobs(loadMore: true);
                  }
                  return false;
                },
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount:
                      _store.availableJobs.length + (_store.hasMore ? 1 : 0),
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    indent: 64,
                    endIndent: 16,
                    color: onSurface.withValues(alpha: 0.1),
                  ),
                  itemBuilder: (context, index) {
                    if (index == _store.availableJobs.length) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 8, bottom: 8),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }
                    final job = _store.availableJobs[index];
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => widget.onJobSelected(job),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: colorScheme.tertiary
                                    .withValues(alpha: 0.1),
                                child: Text(
                                  job.jobTitle.isNotEmpty
                                      ? job.jobTitle[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: colorScheme.tertiary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      job.jobTitle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            job.location,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: onSurface.withValues(
                                                alpha: 0.9,
                                              ),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (job.salaryRange.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.green.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    job.salaryRange,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
