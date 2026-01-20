import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scraki/features/poster/presentation/stores/poster_creation_store.dart';

/// Job Hub panel for selecting recruitment jobs
///
/// Features:
/// - Job search functionality
/// - Job list with loading states
/// - Job selection callback
/// - Refresh jobs action
class JobHubPanel extends StatelessWidget {
  final PosterCreationStore store;
  final TextEditingController searchController;
  final VoidCallback onJobSelected;

  const JobHubPanel({
    super.key,
    required this.store,
    required this.searchController,
    required this.onJobSelected,
  });

  @override
  Widget build(BuildContext context) {
    if(store.availableJobs.isEmpty) {
      store.loadAvailableJobs();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "CÔNG VIỆC",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 18),
                onPressed: () => store.loadAvailableJobs(),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          child: TextField(
            controller: searchController,
            onSubmitted: (v) => store.searchJobs(v),
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: "Tìm kiếm công việc...",
              hintStyle: const TextStyle(color: Colors.white24),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 18,
                color: Colors.white24,
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const Divider(height: 1, color: Colors.white10),
        Expanded(
          child: Observer(
            builder: (_) {
              if (store.isLoading && store.availableJobs.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
              return Stack(
                children: [
                  ListView.builder(
                    itemCount: store.availableJobs.length,
                    itemBuilder: (context, index) {
                      final job = store.availableJobs[index];
                      return ListTile(
                        dense: true,
                        title: Text(
                          job.jobTitle,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          "${job.companyName} • ${job.salaryRange}",
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white38,
                          ),
                        ),
                        onTap: () {
                          store.selectJob(job);
                          onJobSelected();
                        },
                      );
                    },
                  ),
                  if (store.isLoading && store.availableJobs.isNotEmpty)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black26,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
