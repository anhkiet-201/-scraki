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

  @action
  void addSourceVideos(List<String> paths) {
    sourceVideoPaths.addAll(paths);
  }

  @action
  void duplicateSourceVideo(String path) {
    sourceVideoPaths.add(path);
  }

  @action
  void removeSourceVideo(int index) {
    if (index >= 0 && index < sourceVideoPaths.length) {
      sourceVideoPaths.removeAt(index);
    }
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

      final composition = VideoComposition(
        id: const Uuid().v4(),
        sourceVideoPaths: sourceVideoPaths.toList(),
        posterData: selectedPosterData!,
        // Default options for now, can be exposed to UI later
      );

      generatedVideoPath = await _repository.generateVideo(composition);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isProcessing = false;
    }
  }
}
