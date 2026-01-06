import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';

import '../stores/poster_creation_store.dart';
import '../widgets/poster_templates/modern_poster.dart';

class PosterCreatorScreen extends StatefulWidget {
  const PosterCreatorScreen({super.key});

  @override
  State<PosterCreatorScreen> createState() => _PosterCreatorScreenState();
}

class _PosterCreatorScreenState extends State<PosterCreatorScreen> {
  late final PosterCreationStore _store;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _store = GetIt.I<PosterCreationStore>();
    _store.loadAvailableJobs();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tạo Poster Tuyển Dụng', style: GoogleFonts.roboto()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _store.reset(),
          ),
        ],
      ),
      body: Observer(
        builder: (context) {
          if (_store.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_store.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Lỗi: ${_store.errorMessage}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  ElevatedButton(
                    onPressed: () => _store.reset(),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (_store.currentStep == 0) {
            return _buildInputStep();
          } else {
            return _buildPreviewStep();
          }
        },
      ),
    );
  }

  Widget _buildInputStep() {
    return Row(
      children: [
        // Left: Input Form
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nhập mô tả công việc (JD)',
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Paste nội dung tuyển dụng vào đây...',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _store.parseJobDescription(_textController.text),
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Phân tích bằng AI'),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Right: API List
        Expanded(
          flex: 3,
          child: Container(
            color: Colors.grey[50],
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Hoặc chọn từ VieclamHR',
                    style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Observer(
                    builder: (context) {
                      return ListView.builder(
                        itemCount: _store.availableJobs.length,
                        itemBuilder: (context, index) {
                          final job = _store.availableJobs[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              title: Text(
                                job.jobTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${job.companyName} • ${job.salaryRange}',
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                              ),
                              onTap: () => _store.selectJob(job),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewStep() {
    return Row(
      children: [
        // Left: Editor (Simplified for MVP, just list fields or Json Editor)
        // For now, allow Back to edit
        Expanded(
          flex: 1,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Chỉnh sửa thông tin (Coming Soon)'),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _store.currentStep = 0,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Quay lại'),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement Export logic
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tính năng xuất ảnh đang phát triển'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Xuất ảnh (PNG)'),
                ),
              ],
            ),
          ),
        ),

        // Right: Live Preview
        Expanded(
          flex: 1,
          child: Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.all(40),
            child: Center(
              child: FittedBox(
                child: Material(
                  elevation: 10,
                  shadowColor: Colors.black45,
                  child: ModernPoster(data: _store.currentPosterData!),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
