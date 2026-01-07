import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';
import 'package:scraki/features/recruitment/domain/usecases/fetch_jobs_usecase.dart';
import 'package:scraki/features/recruitment/domain/usecases/parse_job_text_usecase.dart';
import 'package:scraki/features/poster/domain/entities/poster_data.dart';

part 'poster_creation_store.g.dart';

@lazySingleton
// ignore: library_private_types_in_public_api
class PosterCreationStore = _PosterCreationStore with _$PosterCreationStore;

abstract class _PosterCreationStore with Store {
  final ParseJobTextUseCase _parseJobTextUseCase;
  final FetchJobsUseCase _fetchJobsUseCase;

  _PosterCreationStore(
    this._parseJobTextUseCase,
    this._fetchJobsUseCase,
  );

  /// Current step in the wizard
  // 0: Input/Selection
  // 1: Edit/Preview
  @observable
  int currentStep = 0;

  @observable
  bool isLoading = false;

  @observable
  String? errorMessage;

  /// The data currently being edited or previewed.
  @observable
  PosterData? currentPosterData;

  /// List of jobs fetched from API (for selection).
  @observable
  ObservableList<PosterData> availableJobs = ObservableList<PosterData>();

  @action
  Future<void> loadAvailableJobs() async {
    isLoading = true;
    errorMessage = null;

    final result = await _fetchJobsUseCase();
    result.fold(
      (failure) {
        errorMessage = failure.message;
      },
      (jobs) {
        availableJobs = ObservableList.of(jobs);
      },
    );

    isLoading = false;
  }

  @action
  Future<void> parseJobDescription(String text) async {
    if (text.isEmpty) {
      errorMessage = 'Please enter job description';
      return;
    }

    isLoading = true;
    errorMessage = null;

    final result = await _parseJobTextUseCase(text);
    result.fold(
      (failure) {
        errorMessage = failure.message;
      },
      (data) {
        // If we have an existing slug or images, we might want to preserve them.
        // But parseJobDescription is usually raw entry.
        currentPosterData = data;
        currentStep = 1; // Move to Editor
      },
    );

    isLoading = false;
  }

  @action
  Future<void> selectJob(PosterData job) async {
    isLoading = true;
    errorMessage = null;

    try {
      // 2. Parse AI content
      if (job.rawContent != null && job.rawContent!.isNotEmpty) {
        final parseResult = await _parseJobTextUseCase(job.rawContent!);
        parseResult.fold(
          (failure) {
            errorMessage = failure.message;
            currentPosterData = job; // Fallback to raw detail
          },
          (parsedData) {
            currentPosterData = parsedData.copyWith(
              slug: job.slug,
              imageUrls: job.imageUrls,
              salaryRange: job.salaryRange,
            );
          },
        );
      } else {
        currentPosterData = job;
      }

      currentStep = 1; // Move to Editor
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
    }
  }

  @action
  void updatePosterData(PosterData newData) {
    currentPosterData = newData;
  }

  @action
  void reset() {
    currentStep = 0;
    currentPosterData = null;
    errorMessage = null;
    isLoading = false;
  }
}
