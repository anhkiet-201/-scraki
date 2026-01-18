import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:scraki/features/poster/domain/entities/poster_data.dart';
import 'package:scraki/features/poster/presentation/stores/poster_creation_store.dart';
import 'package:scraki/features/video_poster/presentation/stores/video_poster_store.dart';

import 'dart:async';
import 'dart:ui';

class VideoPosterPlaygroundPage extends StatefulWidget {
  const VideoPosterPlaygroundPage({super.key});

  @override
  State<VideoPosterPlaygroundPage> createState() =>
      _VideoPosterPlaygroundPageState();
}

class _VideoPosterPlaygroundPageState extends State<VideoPosterPlaygroundPage> {
  final _store = GetIt.I<VideoPosterStore>();
  final _creationStore = GetIt.I<PosterCreationStore>();

  // Player State
  late final Player _player;
  late final VideoController _controller;

  // Local Playback State
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<bool>? _playingSub;

  // --- V4 UX State ---
  int _activeNavIndex = 0; // 0: Job Hub, 1: Media Library, 2: Effects/Content
  bool _isFocusMode = false;

  // Form Controllers
  final _titleController = TextEditingController(
    text: "Hiring Flutter Developer",
  );
  final _salaryController = TextEditingController(text: "\$2000 - \$4000");
  final _companyController = TextEditingController(text: "Scraki Inc.");
  final _locationController = TextEditingController(text: "Từ xa");
  final _contactController = TextEditingController(text: "Tuyển dụng");
  final _headlineController = TextEditingController(
    text: "Cơ hội việc làm hấp dẫn!",
  );
  final _captionController = TextEditingController(
    text: "#tuyendung #vieclam #flutter",
  );
  final _requirementsController = TextEditingController(
    text: "Có kinh nghiệm Flutter\nThành thạo Dart\nBiết sử dụng MobX",
  );
  final _benefitsController = TextEditingController(
    text: "Lương thưởng hấp dẫn\nBảo hiểm đầy đủ\nMôi trường chuyên nghiệp",
  );
  final _jobSearchController = TextEditingController();
  ReactionDisposer? _dataSyncDisposer;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(
      _player,
      configuration: const VideoControllerConfiguration(
        enableHardwareAcceleration: true,
      ),
    );

    // Listen to playback state
    _durationSub = _player.stream.duration.listen(
      (d) => setState(() => _duration = d),
    );
    _positionSub = _player.stream.position.listen(
      (p) => setState(() => _position = p),
    );
    _playingSub = _player.stream.playing.listen(
      (p) => setState(() => _isPlaying = p),
    );

    // Initial poster data
    _updatePosterData();

    // Sync playlist when videos are added
    _syncPlaylist();

    // Sync AI parsed data to local controllers
    _dataSyncDisposer = reaction((_) => _creationStore.currentPosterData, (
      PosterData? data,
    ) {
      if (data != null) {
        _titleController.text = data.jobTitle;
        _companyController.text = data.companyName;
        _salaryController.text = data.salaryRange;
        _locationController.text = data.location;
        _contactController.text = data.contactInfo;
        _headlineController.text = data.catchyHeadline ?? "";
        _captionController.text = data.tikTokCaption ?? "";
        _requirementsController.text = data.requirements.join('\n');
        _benefitsController.text = data.benefits.join('\n');
        _updatePosterData();
      }
    });
  }

  @override
  void dispose() {
    _durationSub?.cancel();
    _positionSub?.cancel();
    _playingSub?.cancel();
    _player.dispose();
    _titleController.dispose();
    _salaryController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _contactController.dispose();
    _headlineController.dispose();
    _captionController.dispose();
    _requirementsController.dispose();
    _benefitsController.dispose();
    _jobSearchController.dispose();
    _dataSyncDisposer?.call();
    super.dispose();
  }

  void _updatePosterData() {
    _store.selectPosterData(
      PosterData(
        jobTitle: _titleController.text,
        companyName: _companyController.text,
        location: _locationController.text,
        salaryRange: _salaryController.text,
        contactInfo: _contactController.text,
        catchyHeadline: _headlineController.text,
        tikTokCaption: _captionController.text,
        requirements: _requirementsController.text
            .split('\n')
            .where((s) => s.trim().isNotEmpty)
            .toList(),
        benefits: _benefitsController.text
            .split('\n')
            .where((s) => s.trim().isNotEmpty)
            .toList(),
      ),
    );
  }

  void _syncPlaylist() {
    if (_store.sourceVideoPaths.isEmpty) return;
    final medias = _store.sourceVideoPaths.map((p) => Media(p)).toList();
    _player.open(Playlist(medias));
    _player.pause(); // Don't auto-play on sync
  }

  void _playVideo(String path) {
    // If it's already in the playlist, just jump to it
    final index = _store.sourceVideoPaths.indexOf(path);
    if (index != -1) {
      _player.jump(index);
      _player.play();
    } else {
      _player.open(Media(path));
      _player.play();
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        cardColor: const Color(0xFF1A1A1A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          surface: Color(0xFF1A1A1A),
          onSurface: Colors.white,
        ),
      ),
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.space): () {
            if (_player.state.position >= _player.state.duration &&
                _player.state.duration > Duration.zero) {
              _player.seek(Duration.zero);
              _player.play();
            } else {
              _player.playOrPause();
            }
          },
          const SingleActivator(LogicalKeyboardKey.keyF, control: true): () {
            _toggleFocusMode();
          },
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            body: Column(
              children: [
                // 1. TOP TOOLBAR
                _buildModernToolbar(),
                Expanded(
                  child: Row(
                    children: [
                      // 2. LEFT NAV BAR (PERMANENT)
                      _buildUnifiedNavBar(),

                      // 3. LEFT TOOLS PANEL (PERMANENT OR FOCUS-HIDDEN)
                      if (!_isFocusMode) ...[
                        SizedBox(
                          width: 300,
                          child: _activeNavIndex == 0
                              ? _buildJobHubPanel()
                              : _buildMediaLibraryPanel(),
                        ),
                        const VerticalDivider(width: 1, color: Colors.white10),
                      ],

                      // 4. MAIN WORKSPACE (AUTO SCALING)
                      Expanded(
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Container(
                                color: Colors.black,
                                child: Center(
                                  child: _buildInteractivePreview(),
                                ),
                              ),
                            ),

                            // FLOATING PLAYER CONTROLS (OVER VIDEO)
                            Positioned(
                              bottom: 40,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: _buildFloatingGlassControls(),
                              ),
                            ),

                            // STATUS OVERLAY
                            Positioned(
                              top: 20,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: _buildDurationStatusOverlay(),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 5. RIGHT PROPERTIES PANEL (PERMANENT OR FOCUS-HIDDEN)
                      if (!_isFocusMode) ...[
                        const VerticalDivider(width: 1, color: Colors.white10),
                        SizedBox(
                          width: 320,
                          child: _buildRightPropertiesPanel(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernToolbar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F).withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 60), // Space for nav bar
          const Text(
            "SCRAKI",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              color: Color(0xFF6366F1),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            "STUDIO",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w300,
              letterSpacing: 2,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          _buildWorkStepper(),
          const Spacer(),
          _buildActionButton("DỰ ÁN MỚI", Icons.add_rounded, () {
            _store.sourceVideoPaths.clear();
            _player.open(Playlist([]));
          }),
          const SizedBox(width: 12),
          _buildActionButton(
            "CÀI ĐẶT",
            Icons.settings_outlined,
            () {},
            isOutline: true,
          ),
          const SizedBox(width: 12),
          _buildActionButton(
            _isFocusMode ? "THOÁT TẬP TRUNG" : "CHẾ ĐỘ TẬP TRUNG",
            _isFocusMode
                ? Icons.fullscreen_exit_rounded
                : Icons.fullscreen_rounded,
            _toggleFocusMode,
            isOutline: _isFocusMode,
          ),
        ],
      ),
    );
  }

  void _toggleFocusMode() {
    setState(() {
      _isFocusMode = !_isFocusMode;
    });
  }

  Widget _buildWorkStepper() {
    return Observer(
      builder: (_) {
        int step = 1;
        if (_store.sourceVideoPaths.isNotEmpty) step = 2;
        if (_store.isProcessing) step = 3;
        if (_store.generatedVideoPath != null) step = 4;

        return Row(
          children: [
            _buildStepperItem(1, "JOB", step >= 1),
            _buildStepperDivider(step >= 2),
            _buildStepperItem(2, "ASSETS", step >= 2),
            _buildStepperDivider(step >= 3),
            _buildStepperItem(3, "EDIT", step >= 3),
            _buildStepperDivider(step >= 4),
            _buildStepperItem(4, "READY", step >= 4),
          ],
        );
      },
    );
  }

  Widget _buildStepperItem(int num, String label, bool active) {
    final color = active ? const Color(0xFF6366F1) : Colors.white24;
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
            color: active ? color.withValues(alpha: 0.1) : Colors.transparent,
          ),
          child: Center(
            child: Text(
              num.toString(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            color: active ? Colors.white70 : Colors.white24,
          ),
        ),
      ],
    );
  }

  Widget _buildStepperDivider(bool active) {
    return Container(
      width: 24,
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: active
          ? const Color(0xFF6366F1).withValues(alpha: 0.5)
          : Colors.white10,
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    VoidCallback onTap, {
    bool isOutline = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isOutline ? Colors.transparent : Colors.white10,
          border: isOutline ? Border.all(color: Colors.white10) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.white70),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnifiedNavBar() {
    return Container(
      width: 64,
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        border: Border(
          right: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 80),
          _buildNavIcon(0, Icons.hub_outlined, "CÔNG VIỆC"),
          _buildNavIcon(1, Icons.inventory_2_outlined, "HÌNH/VIDEO"),
          const Spacer(),
          _buildNavIcon(2, Icons.tune_rounded, "THUỘC TÍNH"),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildNavIcon(int index, IconData icon, String label) {
    bool active = (_activeNavIndex == index);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            _activeNavIndex = index;
            if (index != 2) {
              _isFocusMode = false;
            }
          });
        },
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: active ? const Color(0xFF6366F1) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: active ? Colors.white : Colors.white38,
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: active ? Colors.white : Colors.white24,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingGlassControls() {
    return Container(
      width: 400,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                  onPressed: () => _player.playOrPause(),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDuration(_position),
                  style: const TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: Colors.white70,
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 4,
                      ),
                      activeTrackColor: const Color(0xFF6366F1),
                      inactiveTrackColor: Colors.white10,
                      thumbColor: Colors.white,
                    ),
                    child: Slider(
                      value: _position.inMilliseconds.toDouble().clamp(
                        0.0,
                        _duration.inMilliseconds.toDouble(),
                      ),
                      max: _duration.inMilliseconds.toDouble(),
                      onChanged: (v) {
                        _player.seek(Duration(milliseconds: v.toInt()));
                      },
                    ),
                  ),
                ),
                Text(
                  _formatDuration(_duration),
                  style: const TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: Colors.white30,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJobHubPanel() {
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
                onPressed: () => _creationStore.loadAvailableJobs(),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          child: TextField(
            controller: _jobSearchController,
            onSubmitted: (v) => _creationStore.searchJobs(v),
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
              if (_creationStore.isLoading &&
                  _creationStore.availableJobs.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
              return Stack(
                children: [
                  ListView.builder(
                    itemCount: _creationStore.availableJobs.length,
                    itemBuilder: (context, index) {
                      final job = _creationStore.availableJobs[index];
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
                          _creationStore.selectJob(job);
                          _updatePosterData();
                        },
                      );
                    },
                  ),
                  if (_creationStore.isLoading &&
                      _creationStore.availableJobs.isNotEmpty)
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

  Widget _buildMediaLibraryPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            "TÀI NGUYÊN",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ),
        const Divider(height: 1, color: Colors.white10),
        Expanded(
          child: DropTarget(
            onDragDone: (details) {
              final paths = details.files.map((e) => e.path).toList();
              _store.addSourceVideos(paths);
              _syncPlaylist();
            },
            child: Observer(
              builder: (_) => ListView.builder(
                itemCount: _store.sourceVideoPaths.length,
                itemBuilder: (context, index) {
                  final path = _store.sourceVideoPaths[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.movie_outlined, size: 16),
                    title: Text(
                      path.split('/').last,
                      style: const TextStyle(fontSize: 11),
                    ),
                    onTap: () => _playVideo(path),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 14),
                      onPressed: () => _store.removeSourceVideo(index),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRightPropertiesPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            "THÀNH PHẦN",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ),
        const Divider(height: 1, color: Colors.white10),
        Expanded(
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: "NỘI DUNG"),
                    Tab(text: "HIỆU ỨNG"),
                  ],
                  indicatorColor: Color(0xFF6366F1),
                  labelStyle: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelColor: Colors.white24,
                ),
                Expanded(
                  child: TabBarView(
                    children: [_buildContentTab(), _buildEffectsTab()],
                  ),
                ),
                _buildExportSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionHeader("CHI TIẾT CÔNG VIỆC"),
        _buildModernTextField(_titleController, "Vị trí", Icons.work_outline),
        const SizedBox(height: 16),
        _buildModernTextField(
          _companyController,
          "Công ty",
          Icons.business_outlined,
        ),
        const SizedBox(height: 16),
        _buildModernTextField(
          _salaryController,
          "Mức lương",
          Icons.payments_outlined,
        ),
        const SizedBox(height: 16),
        _buildModernTextField(
          _locationController,
          "Địa điểm",
          Icons.location_on_outlined,
        ),
        const SizedBox(height: 16),
        _buildModernTextField(
          _contactController,
          "Liên hệ",
          Icons.contact_mail_outlined,
        ),
        const SizedBox(height: 16),
        _buildModernTextField(
          _headlineController,
          "Tiêu đề phụ",
          Icons.campaign_outlined,
        ),
        const SizedBox(height: 16),
        _buildModernTextField(
          _captionController,
          "TikTok Caption",
          Icons.closed_caption_outlined,
        ),
        const SizedBox(height: 16),
        _buildModernTextField(
          _requirementsController,
          "Yêu cầu công việc (Mỗi dòng một ý)",
          Icons.list_alt_rounded,
          maxLines: null,
        ),
        const SizedBox(height: 16),
        _buildModernTextField(
          _benefitsController,
          "Quyền lợi (Mỗi dòng một ý)",
          Icons.card_giftcard_rounded,
          maxLines: null,
        ),
        const SizedBox(height: 32),
        _buildSectionHeader("CÀI ĐẶT VIDEO"),
        Observer(
          builder: (_) => _buildModernSlider(
            "Tốc độ phát",
            _store.playbackSpeed,
            0.5,
            2.0,
            (v) => _store.setPlaybackSpeed(v),
            suffix: "x",
          ),
        ),
        const SizedBox(height: 16),
        Observer(
          builder: (_) => _buildModernSlider(
            "Âm lượng",
            _store.volume,
            0.0,
            1.0,
            (v) {
              _store.setVolume(v);
              _player.setVolume(v * 100);
            },
            suffix: "%",
            multiplier: 100,
          ),
        ),
      ],
    );
  }

  Widget _buildEffectsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionHeader("HÌNH ẢNH"),
        Observer(
          builder: (_) => SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              "Làm mờ nền",
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
            value: _store.applyBlur,
            onChanged: (v) => _store.setApplyBlur(v),
            activeThumbColor: const Color(0xFF6366F1),
          ),
        ),
        Observer(
          builder: (_) => _buildModernSlider(
            "Độ mờ",
            _store.blurIntensity,
            0.0,
            20.0,
            (v) => _store.setBlurIntensity(v),
            suffix: "px",
            enabled: _store.applyBlur,
          ),
        ),
        const SizedBox(height: 32),
        _buildSectionHeader("CHỐNG QUÉT BẢN QUYỀN"),
        Observer(
          builder: (_) => SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              "Dấu ấn AI",
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
            subtitle: const Text(
              "Vượt qua kiểm tra re-up",
              style: TextStyle(fontSize: 10, color: Colors.white24),
            ),
            value: _store.enableAntiReup,
            onChanged: (v) => _store.updateEffect('anti_reup', v ? 1.0 : 0.0),
            activeThumbColor: const Color(0xFF6366F1),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          color: Colors.white24,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildModernTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int? maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white38),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: (_) => _updatePosterData(),
          style: const TextStyle(fontSize: 13),
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 16, color: Colors.white24),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.02),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white10),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF6366F1)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged, {
    String suffix = "",
    double multiplier = 1.0,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: enabled ? Colors.white70 : Colors.white24,
              ),
            ),
            Text(
              "${(value * multiplier).toStringAsFixed(multiplier == 100 ? 0 : 1)}$suffix",
              style: TextStyle(
                fontSize: 11,
                color: enabled ? const Color(0xFF6366F1) : Colors.white24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            activeTrackColor: enabled
                ? const Color(0xFF6366F1)
                : Colors.white10,
            inactiveTrackColor: Colors.white10,
            thumbColor: enabled ? Colors.white : Colors.white12,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: enabled ? onChanged : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDurationStatusOverlay() {
    final effectiveDuration =
        _duration.inSeconds /
        (_store.playbackSpeed > 0 ? _store.playbackSpeed : 1.0);
    String status = "Tối ưu TikTok: Sẵn sàng";
    Color color = Colors.greenAccent;

    if (effectiveDuration < 15) {
      status = "Thời lượng: Ngắn (Tự động lặp)";
      color = Colors.orangeAccent;
    } else if (effectiveDuration > 30) {
      status = "Thời lượng: Dài (Tự động cắt)";
      color = Colors.lightBlueAccent;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.black.withValues(alpha: 0.5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Text(
                status,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInteractivePreview() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(20),
      child: Center(
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  // Video Preview
                  Video(
                    controller: _controller,
                    controls: (state) => const SizedBox.shrink(),
                  ),

                  // TikTok Safe Zone Visualization
                  _buildTikTokSafeZone(),

                  // Interactive Text Overlays
                  Observer(
                    builder: (_) => _buildOverlayItem(
                      label: _store.selectedPosterData?.jobTitle ?? "",
                      x: _store.titleX,
                      y: _store.titleY,
                      type: 'title',
                      constraints: constraints,
                      color: Colors.white,
                      fontSize: 26,
                    ),
                  ),
                  Observer(
                    builder: (_) => _buildOverlayItem(
                      label: _store.selectedPosterData?.salaryRange ?? "",
                      x: _store.salaryX,
                      y: _store.salaryY,
                      type: 'salary',
                      constraints: constraints,
                      color: Colors.yellow,
                      fontSize: 20,
                    ),
                  ),
                  Observer(
                    builder: (_) => _buildOverlayItem(
                      label:
                          "🏢 ${_store.selectedPosterData?.companyName ?? ""}",
                      x: _store.companyX,
                      y: _store.companyY,
                      type: 'company',
                      constraints: constraints,
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  Observer(
                    builder: (_) => _buildOverlayItem(
                      label: "📍 ${_store.selectedPosterData?.location ?? ""}",
                      x: _store.locationX,
                      y: _store.locationY,
                      type: 'location',
                      constraints: constraints,
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                  Observer(
                    builder: (_) => _buildOverlayItem(
                      label:
                          _store.selectedPosterData?.requirements.isNotEmpty ==
                              true
                          ? "📋 YÊU CẦU:\n${_store.selectedPosterData!.requirements.map((e) => "• $e").join("\n")}"
                          : "",
                      x: _store.requirementsX,
                      y: _store.requirementsY,
                      type: 'requirements',
                      constraints: constraints,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  Observer(
                    builder: (_) => _buildOverlayItem(
                      label:
                          _store.selectedPosterData?.benefits.isNotEmpty == true
                          ? "🎁 QUYỀN LỢI:\n${_store.selectedPosterData!.benefits.map((e) => "• $e").join("\n")}"
                          : "",
                      x: _store.benefitsX,
                      y: _store.benefitsY,
                      type: 'benefits',
                      constraints: constraints,
                      color: Colors.greenAccent,
                      fontSize: 14,
                    ),
                  ),
                  Observer(
                    builder: (_) => _buildOverlayItem(
                      label:
                          "📞 ${_store.selectedPosterData?.contactInfo ?? ""}",
                      x: _store.contactX,
                      y: _store.contactY,
                      type: 'contact',
                      constraints: constraints,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  Observer(
                    builder: (_) => _buildOverlayItem(
                      label: _store.selectedPosterData?.catchyHeadline ?? "",
                      x: _store.headlineX,
                      y: _store.headlineY,
                      type: 'headline',
                      constraints: constraints,
                      color: Colors.yellowAccent,
                      fontSize: 18,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOverlayItem({
    required String label,
    required double x,
    required double y,
    required String type,
    required BoxConstraints constraints,
    required Color color,
    required double fontSize,
  }) {
    return Positioned.fill(
      child: Align(
        alignment: Alignment(x * 2 - 1, y * 2 - 1),
        child: GestureDetector(
          onPanUpdate: (details) {
            final newX = (x + details.delta.dx / constraints.maxWidth).clamp(
              0.0,
              1.0,
            );
            final newY = (y + details.delta.dy / constraints.maxHeight).clamp(
              0.0,
              1.0,
            );
            _store.updatePosition(type, newX, newY);
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.move,
            child: Container(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.8),
                  width: 1.5,
                ),
                color: Colors.black45,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    const Shadow(
                      color: Colors.black,
                      blurRadius: 4,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
                softWrap: true,
                textAlign: type == 'requirements' || type == 'benefits'
                    ? TextAlign.left
                    : TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTikTokSafeZone() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            border: Border.symmetric(
              vertical: BorderSide(
                color: Colors.white.withValues(alpha: 0.02),
                width: 20,
              ),
              horizontal: BorderSide(
                color: Colors.white.withValues(alpha: 0.02),
                width: 80,
              ),
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 180,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  alignment: Alignment.bottomCenter,
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    "VÙNG TƯƠNG TÁC TIKTOK",
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.white.withValues(alpha: 0.2),
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 60,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [
                        Colors.black.withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExportSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.black26,
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        children: [
          Observer(
            builder: (_) => ElevatedButton(
              onPressed: _store.isProcessing
                  ? null
                  : () => _store.generateVideo(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _store.isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      "XUẤT VIDEO",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Observer(
            builder: (_) => _store.generatedVideoPath != null
                ? Text(
                    "Xuất video thành công",
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.greenAccent.withValues(alpha: 0.8),
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
