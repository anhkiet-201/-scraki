import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:scraki/features/poster/domain/entities/poster_data.dart';
import 'package:scraki/features/video_poster/presentation/stores/video_poster_store.dart';

class VideoPosterPlaygroundPage extends StatefulWidget {
  const VideoPosterPlaygroundPage({super.key});

  @override
  State<VideoPosterPlaygroundPage> createState() =>
      _VideoPosterPlaygroundPageState();
}

class _VideoPosterPlaygroundPageState extends State<VideoPosterPlaygroundPage> {
  final _store = GetIt.I<VideoPosterStore>();

  // Temporary controller for quick data entry
  final _titleController = TextEditingController(
    text: "Hiring Flutter Developer",
  );
  final _salaryController = TextEditingController(text: "\$2000 - \$4000");

  @override
  void initState() {
    super.initState();
    // Initialize with default data
    _updatePosterData();
  }

  void _updatePosterData() {
    _store.selectPosterData(
      PosterData(
        jobTitle: _titleController.text,
        companyName: "Scraki Inc.",
        location: "Remote",
        salaryRange: _salaryController.text,
        contactInfo: "contact@scraki.com",
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Poster Playground')),
      body: Row(
        children: [
          // Left Panel: Source Videos
          Expanded(flex: 1, child: _buildDropZone()),
          const VerticalDivider(width: 1),
          // Right Panel: Controls & Preview
          Expanded(flex: 1, child: _buildControlPanel()),
        ],
      ),
    );
  }

  Widget _buildDropZone() {
    return DropTarget(
      onDragDone: (details) {
        final paths = details.files.map((e) => e.path).toList();
        _store.addSourceVideos(paths);
      },
      child: Container(
        color: Colors.grey.shade100,
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.cloud_upload, size: 48, color: Colors.grey),
            const Text("Drag & Drop Videos Here"),
            const SizedBox(height: 20),
            Expanded(
              child: Observer(
                builder: (_) {
                  if (_store.sourceVideoPaths.isEmpty) {
                    return const Center(child: Text("No videos added"));
                  }
                  return ListView.builder(
                    itemCount: _store.sourceVideoPaths.length,
                    itemBuilder: (context, index) {
                      final path = _store.sourceVideoPaths[index];
                      return ListTile(
                        leading: const Icon(Icons.video_file),
                        title: Text(path.split('/').last),
                        subtitle: Text(path),
                        trailing: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => _store.removeSourceVideo(index),
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
    );
  }

  Widget _buildControlPanel() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Recruitment Info",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: "Job Title"),
            onChanged: (_) => _updatePosterData(),
          ),
          TextField(
            controller: _salaryController,
            decoration: const InputDecoration(labelText: "Salary Range"),
            onChanged: (_) => _updatePosterData(),
          ),
          const SizedBox(height: 20),
          const Spacer(),
          Observer(
            builder: (_) {
              if (_store.isProcessing) {
                return const Center(child: CircularProgressIndicator());
              }

              if (_store.errorMessage != null) {
                return Text(
                  _store.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                );
              }

              if (_store.generatedVideoPath != null) {
                return Column(
                  children: [
                    const Text(
                      "Video Generated Successfully!",
                      style: TextStyle(color: Colors.green),
                    ),
                    SelectableText(_store.generatedVideoPath!),
                    // TODO: Add Open/Play button
                  ],
                );
              }

              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _store.generateVideo(),
              icon: const Icon(Icons.movie_creation),
              label: const Text("GENERATE VIDEO POSTER (20-30s)"),
            ),
          ),
        ],
      ),
    );
  }
}
