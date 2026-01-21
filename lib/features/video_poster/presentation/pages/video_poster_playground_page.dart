import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:scraki/features/video_poster/presentation/stores/video_poster_store.dart';
import 'package:scraki/features/video_poster/presentation/widgets/form/modern_text_field.dart';
import 'package:scraki/features/video_poster/presentation/widgets/form/modern_slider.dart';
import 'package:scraki/features/video_poster/presentation/widgets/preview/tiktok_safe_zone.dart';
import 'package:scraki/features/video_poster/presentation/widgets/preview/video_overlay_item/video_overlay_item.dart';
import 'package:scraki/features/video_poster/presentation/widgets/controls/floating_glass_controls.dart';
import 'package:scraki/features/video_poster/presentation/widgets/controls/duration_status_overlay.dart';
import 'package:scraki/features/video_poster/presentation/widgets/panels/job_hub_panel.dart';
import 'package:scraki/features/video_poster/presentation/widgets/panels/media_library_panel.dart';
import 'package:scraki/features/video_poster/presentation/widgets/anti_reup_settings_panel.dart';

class VideoPosterPlaygroundPage extends StatefulWidget {
  const VideoPosterPlaygroundPage({super.key});

  @override
  State<VideoPosterPlaygroundPage> createState() =>
      _VideoPosterPlaygroundPageState();
}

class _VideoPosterPlaygroundPageState extends State<VideoPosterPlaygroundPage> {
  late final VideoPosterStore store;

  @override
  void initState() {
    super.initState();
    store = GetIt.I<VideoPosterStore>();
  }

  @override
  void dispose() {
    // CRITICAL: Dispose the player to prevent "Callback invoked after it has been deleted"
    // crashes on hot restart or navigation.
    store.disposePlayer();
    super.dispose();
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
          const SingleActivator(LogicalKeyboardKey.space, control: true): () {
            if (store.player.state.position >= store.player.state.duration &&
                store.player.state.duration > Duration.zero) {
              store.player.seek(Duration.zero);
              store.player.play();
            } else {
              store.player.playOrPause();
            }
          },
          const SingleActivator(LogicalKeyboardKey.keyF, control: true): () {
            store.toggleFocusMode();
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
                      Observer(
                        builder: (_) {
                          if (!store.isFocusMode) {
                            return SizedBox(
                              width: 300,
                              child: store.activeNavIndex == 0
                                  ? JobHubPanel(
                                      store: store.creationStore,
                                      searchController:
                                          store.jobSearchController,
                                      onJobSelected:
                                          store.updatePosterDataFromControllers,
                                    )
                                  : MediaLibraryPanel(
                                      store: store,
                                      onVideoTap: store.playVideoAtIndex,
                                      onVideosChanged: store.syncPlaylist,
                                    ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),

                      // 4. MAIN WORKSPACE (AUTO SCALING)
                      Observer(
                        builder: (context) {
                          return Expanded(
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
                                    child: FloatingGlassControls(
                                      isPlaying: store.isPlaying,
                                      // Use total timeline position/duration
                                      position: store.totalPosition,
                                      duration: store.totalDuration,
                                      onPlayPause: () =>
                                          store.player.playOrPause(),
                                      onSeek: (v) => store.seekTimeline(v),
                                    ),
                                  ),
                                ),

                                // STATUS OVERLAY
                                Positioned(
                                  top: 20,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: DurationStatusOverlay(
                                      duration: store.duration,
                                      playbackSpeed: store.playbackSpeed,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      // 5. RIGHT PROPERTIES PANEL (PERMANENT OR FOCUS-HIDDEN)
                      if (!store.isFocusMode) ...[
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
            store.sourceVideoPaths.clear();
            store.player.open(Playlist([]));
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
            store.isFocusMode ? "THOÁT TẬP TRUNG" : "CHẾ ĐỘ TẬP TRUNG",
            store.isFocusMode
                ? Icons.fullscreen_exit_rounded
                : Icons.fullscreen_rounded,
            store.toggleFocusMode,
            isOutline: store.isFocusMode,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkStepper() {
    return Observer(
      builder: (_) {
        int step = 1;
        if (store.sourceVideoPaths.isNotEmpty) step = 2;
        if (store.isProcessing) step = 3;
        if (store.generatedVideoPath != null) step = 4;

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
    return Observer(
      builder: (context) {
        bool active = (store.activeNavIndex == index);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: InkWell(
            onTap: () => store.setActiveNavIndex(index),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFF6366F1)
                        : Colors.transparent,
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
      },
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
        ModernTextField(
          controller: store.titleController,
          label: "Vị trí",
          icon: Icons.work_outline,
          onChanged: store.updatePosterDataFromControllers,
        ),
        const SizedBox(height: 16),
        ModernTextField(
          controller: store.companyController,
          label: "Công ty",
          icon: Icons.business_outlined,
          onChanged: store.updatePosterDataFromControllers,
        ),
        const SizedBox(height: 16),
        ModernTextField(
          controller: store.salaryController,
          label: "Mức lương",
          icon: Icons.payments_outlined,
          onChanged: store.updatePosterDataFromControllers,
        ),
        const SizedBox(height: 16),
        ModernTextField(
          controller: store.locationController,
          label: "Địa điểm",
          icon: Icons.location_on_outlined,
          onChanged: store.updatePosterDataFromControllers,
        ),
        const SizedBox(height: 16),
        ModernTextField(
          controller: store.contactController,
          label: "Liên hệ",
          icon: Icons.contact_mail_outlined,
          onChanged: store.updatePosterDataFromControllers,
        ),
        const SizedBox(height: 16),
        ModernTextField(
          controller: store.headlineController,
          label: "Tiêu đề phụ",
          icon: Icons.campaign_outlined,
          onChanged: store.updatePosterDataFromControllers,
        ),
        const SizedBox(height: 16),
        ModernTextField(
          controller: store.captionController,
          label: "TikTok Caption",
          icon: Icons.closed_caption_outlined,
          onChanged: store.updatePosterDataFromControllers,
        ),
        const SizedBox(height: 16),
        ModernTextField(
          controller: store.requirementsController,
          label: "Yêu cầu công việc (Mỗi dòng một ý)",
          icon: Icons.list_alt_rounded,
          maxLines: null,
          onChanged: store.updatePosterDataFromControllers,
        ),
        const SizedBox(height: 16),
        ModernTextField(
          controller: store.benefitsController,
          label: "Quyền lợi (Mỗi dòng một ý)",
          icon: Icons.card_giftcard_rounded,
          maxLines: null,
          onChanged: store.updatePosterDataFromControllers,
        ),
        const SizedBox(height: 32),
        _buildSectionHeader("CÀI ĐẶT VIDEO"),
        Observer(
          builder: (_) => ModernSlider(
            label: "Tốc độ phát",
            value: store.playbackSpeed,
            min: 0.5,
            max: 2.0,
            onChanged: (v) => store.setPlaybackSpeed(v),
            suffix: "x",
          ),
        ),
        const SizedBox(height: 16),
        Observer(
          builder: (_) => ModernSlider(
            label: "Âm lượng",
            value: store.volume,
            min: 0.0,
            max: 1.0,
            onChanged: (v) {
              store.setVolume(v);
              store.player.setVolume(v * 100);
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
            value: store.applyBlur,
            onChanged: (v) => store.setApplyBlur(v),
            activeThumbColor: const Color(0xFF6366F1),
          ),
        ),
        Observer(
          builder: (_) => ModernSlider(
            label: "Độ mờ",
            value: store.blurIntensity,
            min: 0.0,
            max: 20.0,
            onChanged: (v) => store.setBlurIntensity(v),
            suffix: "px",
            enabled: store.applyBlur,
          ),
        ),
        const SizedBox(height: 32),
        _buildSectionHeader("CHỐNG QUÉT BẢN QUYỀN"),
        AntiReupSettingsPanel(store: store),
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
                  Observer(
                    warnWhenNoObservables: false,
                    builder: (context) {
                      if (store.sourceVideoPaths.isEmpty) {
                        return Container(
                          color: Colors.black,
                          child: const Center(
                            child: Text(
                              "No Video Selected",
                              style: TextStyle(color: Colors.white24),
                            ),
                          ),
                        );
                      }
                      return Video(
                        controller: store.videoController,
                        fit: BoxFit.cover,
                        controls: (state) => const SizedBox.shrink(),
                      );
                    },
                  ),

                  // TikTok Safe Zone Visualization
                  const TikTokSafeZone(),

                  // Virtual Canvas for Overlays
                  Positioned.fill(
                    child: Observer(
                      builder: (context) {
                        if (store.creationStore.currentPosterData == null) {
                          return const SizedBox.shrink();
                        }
                        return FittedBox(
                          fit: BoxFit.contain,
                          child: SizedBox(
                            width: 720,
                            height: 1280,
                            child: RepaintBoundary(
                              key: store.previewKey,
                              child: Observer(
                                builder: (context) {
                                  final posterData = store.selectedPosterData;
                                  if (posterData == null) {
                                    return const SizedBox.shrink();
                                  }
                                  const virtualConstraints = BoxConstraints(
                                    maxWidth: 720,
                                    maxHeight: 1280,
                                  );
                                  return GestureDetector(
                                    onTap: () =>
                                        store.setSelectedOverlayType(null),
                                    behavior: HitTestBehavior.opaque,
                                    child: Stack(
                                      children: [
                                        VideoOverlayItem(
                                          label: posterData.jobTitle,
                                          x: store.titleX,
                                          y: store.titleY,
                                          type: 'title',
                                          isSelected:
                                              store.selectedOverlayType ==
                                              'title',
                                          constraints: virtualConstraints,
                                          color: Colors.white,
                                          fontSize: store.titleFontSize,
                                          onPositionUpdate:
                                              store.updatePosition,
                                          onSelect:
                                              store.setSelectedOverlayType,
                                          onResize: store.updateFontSize,
                                          onTextChange: store.updateTextContent,
                                        ),
                                        VideoOverlayItem(
                                          label: posterData.salaryRange,
                                          x: store.salaryX,
                                          y: store.salaryY,
                                          type: 'salary',
                                          isSelected:
                                              store.selectedOverlayType ==
                                              'salary',
                                          constraints: virtualConstraints,
                                          color: Colors.yellow,
                                          fontSize: store.salaryFontSize,
                                          onPositionUpdate:
                                              store.updatePosition,
                                          onSelect:
                                              store.setSelectedOverlayType,
                                          onResize: store.updateFontSize,
                                          onTextChange: store.updateTextContent,
                                        ),
                                        VideoOverlayItem(
                                          label: "🏢 ${posterData.companyName}",
                                          x: store.companyX,
                                          y: store.companyY,
                                          type: 'company',
                                          isSelected:
                                              store.selectedOverlayType ==
                                              'company',
                                          constraints: virtualConstraints,
                                          color: Colors.white70,
                                          fontSize: store.companyFontSize,
                                          onPositionUpdate:
                                              store.updatePosition,
                                          onSelect:
                                              store.setSelectedOverlayType,
                                          onResize: store.updateFontSize,
                                          onTextChange: store.updateTextContent,
                                        ),
                                        VideoOverlayItem(
                                          label: "📍 ${posterData.location}",
                                          x: store.locationX,
                                          y: store.locationY,
                                          type: 'location',
                                          isSelected:
                                              store.selectedOverlayType ==
                                              'location',
                                          constraints: virtualConstraints,
                                          color: Colors.white54,
                                          fontSize: store.locationFontSize,
                                          onPositionUpdate:
                                              store.updatePosition,
                                          onSelect:
                                              store.setSelectedOverlayType,
                                          onResize: store.updateFontSize,
                                          onTextChange: store.updateTextContent,
                                        ),
                                        VideoOverlayItem(
                                          label:
                                              posterData
                                                      .requirements
                                                      .isNotEmpty ==
                                                  true
                                              ? "📋 YÊU CẦU:\n${posterData.requirements.map((e) => "• $e").join("\n")}"
                                              : "",
                                          x: store.requirementsX,
                                          y: store.requirementsY,
                                          type: 'requirements',
                                          isSelected:
                                              store.selectedOverlayType ==
                                              'requirements',
                                          constraints: virtualConstraints,
                                          color: Colors.white,
                                          fontSize: store.requirementsFontSize,
                                          onPositionUpdate:
                                              store.updatePosition,
                                          onSelect:
                                              store.setSelectedOverlayType,
                                          onResize: store.updateFontSize,
                                          onTextChange: store.updateTextContent,
                                        ),
                                        VideoOverlayItem(
                                          label:
                                              posterData.benefits.isNotEmpty ==
                                                  true
                                              ? "🎁 QUYỀN LỢI:\n${posterData.benefits.map((e) => "• $e").join("\n")}"
                                              : "",
                                          x: store.benefitsX,
                                          y: store.benefitsY,
                                          type: 'benefits',
                                          isSelected:
                                              store.selectedOverlayType ==
                                              'benefits',
                                          constraints: virtualConstraints,
                                          color: Colors.greenAccent,
                                          fontSize: store.benefitsFontSize,
                                          onPositionUpdate:
                                              store.updatePosition,
                                          onSelect:
                                              store.setSelectedOverlayType,
                                          onResize: store.updateFontSize,
                                          onTextChange: store.updateTextContent,
                                        ),
                                        VideoOverlayItem(
                                          label: "📞 ${posterData.contactInfo}",
                                          x: store.contactX,
                                          y: store.contactY,
                                          type: 'contact',
                                          isSelected:
                                              store.selectedOverlayType ==
                                              'contact',
                                          constraints: virtualConstraints,
                                          color: Colors.white,
                                          fontSize: store.contactFontSize,
                                          onPositionUpdate:
                                              store.updatePosition,
                                          onSelect:
                                              store.setSelectedOverlayType,
                                          onResize: store.updateFontSize,
                                          onTextChange: store.updateTextContent,
                                        ),
                                        VideoOverlayItem(
                                          label:
                                              posterData.catchyHeadline ?? "",
                                          x: store.headlineX,
                                          y: store.headlineY,
                                          type: 'headline',
                                          isSelected:
                                              store.selectedOverlayType ==
                                              'headline',
                                          constraints: virtualConstraints,
                                          color: Colors.yellowAccent,
                                          fontSize: store.headlineFontSize,
                                          onPositionUpdate:
                                              store.updatePosition,
                                          onSelect:
                                              store.setSelectedOverlayType,
                                          onResize: store.updateFontSize,
                                          onTextChange: store.updateTextContent,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
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
              onPressed:
                  store.isProcessing ||
                      store.sourceVideoPaths.isEmpty ||
                      store.creationStore.currentPosterData == null
                  ? null
                  : () => store.handleExportVideo(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: store.isProcessing
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
            builder: (_) => store.generatedVideoPath != null
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
