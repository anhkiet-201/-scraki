import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';
import 'package:scraki/features/poster/domain/entities/poster_data.dart';
import 'package:scraki/features/video_poster/domain/entities/video_composition.dart';
import 'package:scraki/features/video_poster/domain/repositories/video_processing_repository.dart';
import 'package:uuid/uuid.dart';

part 'video_poster_store.g.dart';

@injectable
class VideoPosterStore = _VideoPosterStore with _$VideoPosterStore;

abstract class _VideoPosterStore with Store {
  final VideoProcessingRepository _repository;

  _VideoPosterStore(this._repository);

  @observable
  ObservableList<String> sourceVideoPaths = ObservableList<String>();

  @observable
  PosterData? selectedPosterData;

  @observable
  bool isProcessing = false;

  @observable
  String? generatedVideoPath;

  @observable
  String? errorMessage;

  // --- Pro Editor State ---

  @observable
  double titleX = 0.5;
  @observable
  double titleY = 0.15;

  @observable
  double salaryX = 0.5;
  @observable
  double salaryY = 0.25;

  @observable
  double companyX = 0.5;
  @observable
  double companyY = 0.85;

  @observable
  double requirementsX = 0.1;
  @observable
  double requirementsY = 0.4;

  @observable
  double benefitsX = 0.1;
  @observable
  double benefitsY = 0.6;

  @observable
  double contactX = 0.5;
  @observable
  double contactY = 0.92;

  @observable
  double headlineX = 0.5;
  @observable
  double headlineY = 0.08;

  @observable
  double saturation = 1.2;
  @observable
  double contrast = 1.0;
  @observable
  double playbackSpeed = 1.0;
  @observable
  double zoomIntensity = 0.0;

  @observable
  bool enableAntiReup = true;

  // --- V4 UX State ---
  @observable
  double volume = 1.0;
  @observable
  bool applyBlur = false;
  @observable
  double blurIntensity = 5.0;

  @observable
  double locationX = 0.5;
  @observable
  double locationY = 0.3;

  @observable
  ObservableMap<String, String> thumbnails = ObservableMap<String, String>();

  // --- Actions ---

  @action
  void addSourceVideos(List<String> paths) {
    sourceVideoPaths.addAll(paths);
    _generateThumbnails(paths);
  }

  @action
  void removeSourceVideo(int index) {
    if (index >= 0 && index < sourceVideoPaths.length) {
      sourceVideoPaths.removeAt(index);
    }
  }

  @action
  void updatePosition(String type, double x, double y) {
    switch (type) {
      case 'title':
        titleX = x;
        titleY = y;
        break;
      case 'salary':
        salaryX = x;
        salaryY = y;
        break;
      case 'company':
        companyX = x;
        companyY = y;
        break;
      case 'requirements':
        requirementsX = x;
        requirementsY = y;
        break;
      case 'benefits':
        benefitsX = x;
        benefitsY = y;
        break;
      case 'contact':
        contactX = x;
        contactY = y;
        break;
      case 'headline':
        headlineX = x;
        headlineY = y;
        break;
      case 'location':
        locationX = x;
        locationY = y;
        break;
    }
  }

  @action
  void updateEffect(String type, double value) {
    switch (type) {
      case 'saturation':
        saturation = value;
        break;
      case 'contrast':
        contrast = value;
        break;
      case 'speed':
        playbackSpeed = value;
        break;
      case 'zoom':
        zoomIntensity = value;
        break;
      case 'anti_reup':
        enableAntiReup = value > 0.5;
        break;
      case 'volume':
        volume = value;
        break;
      case 'blur_intensity':
        blurIntensity = value;
        break;
    }
  }

  @action
  void toggleBlur(bool value) {
    applyBlur = value;
  }

  @action
  void setPlaybackSpeed(double value) {
    playbackSpeed = value;
  }

  @action
  void setVolume(double value) {
    volume = value;
  }

  @action
  void setApplyBlur(bool value) {
    applyBlur = value;
  }

  @action
  void setBlurIntensity(double value) {
    blurIntensity = value;
  }

  @action
  void selectPosterData(PosterData data) {
    selectedPosterData = data;
  }

  @action
  Future<void> generateVideo() async {
    if (sourceVideoPaths.isEmpty || selectedPosterData == null) {
      errorMessage = "Please add videos and select recruitment info.";
      return;
    }

    try {
      isProcessing = true;
      errorMessage = null;

      final random = DateTime.now().millisecondsSinceEpoch;
      final composition = VideoComposition(
        id: const Uuid().v4(),
        sourceVideoPaths: sourceVideoPaths.toList(),
        posterData: selectedPosterData!,
        titleX: titleX,
        titleY: titleY,
        salaryX: salaryX,
        salaryY: salaryY,
        companyX: companyX,
        companyY: companyY,
        requirementsX: requirementsX,
        requirementsY: requirementsY,
        benefitsX: benefitsX,
        benefitsY: benefitsY,
        contactX: contactX,
        contactY: contactY,
        headlineX: headlineX,
        headlineY: headlineY,
        locationX: locationX,
        locationY: locationY,
        saturation: saturation,
        contrast: contrast,
        playbackSpeed: playbackSpeed,
        zoomIntensity: zoomIntensity,
        noiseLevel: enableAntiReup ? 0.05 : 0.0,
        hueShift: enableAntiReup ? (random % 10 - 5) / 100.0 : 0.0, // +/- 0.05
        brightnessDelta: enableAntiReup
            ? (random % 10 - 5) / 200.0
            : 0.0, // +/- 0.025
        randomSeed: random,
      );

      generatedVideoPath = await _repository.generateVideo(composition);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isProcessing = false;
    }
  }

  Future<void> _generateThumbnails(List<String> paths) async {
    for (final path in paths) {
      if (!thumbnails.containsKey(path)) {
        try {
          final thumb = await _repository.extractThumbnail(path);
          thumbnails[path] = thumb;
        } catch (e) {
          print('Failed to extract thumbnail: $e');
        }
      }
    }
  }
}
