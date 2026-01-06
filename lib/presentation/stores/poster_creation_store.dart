import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';

import '../../domain/entities/poster_data.dart';
import '../../domain/usecase/fetch_jobs_usecase.dart';
import '../../domain/usecase/parse_job_text_usecase.dart';
import '../../domain/usecase/fetch_job_detail_usecase.dart';

part 'poster_creation_store.g.dart';

@lazySingleton
class PosterCreationStore = _PosterCreationStore with _$PosterCreationStore;

abstract class _PosterCreationStore with Store {
  final ParseJobTextUseCase _parseJobTextUseCase;
  final FetchJobsUseCase _fetchJobsUseCase;
  final FetchJobDetailUseCase _fetchJobDetailUseCase;

  _PosterCreationStore(
    this._parseJobTextUseCase,
    this._fetchJobsUseCase,
    this._fetchJobDetailUseCase,
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
      PosterData jobToParse = job;

      // 1. Fetch detailed info if slug exists
      if (job.slug != null && job.slug!.isNotEmpty) {
        final detailResult = await _fetchJobDetailUseCase(job.slug!);
        if (detailResult.isRight()) {
          jobToParse = detailResult.getRight().toNullable() ?? job;
        }
      }

      // 2. Parse AI content
      if (jobToParse.rawContent != null && jobToParse.rawContent!.isNotEmpty) {
        final parseResult = await _parseJobTextUseCase(jobToParse.rawContent!);

        parseResult.fold(
          (failure) {
            errorMessage = failure.message;
            currentPosterData = jobToParse; // Fallback to raw detail
          },
          (parsedData) {
            // 3. Merge Images + Slug from Detail into Parsed Data (which only has text fields)
            currentPosterData = parsedData.copyWith(
              slug: jobToParse.slug,
              imageUrls: jobToParse.imageUrls,
            );
          },
        );
      } else {
        currentPosterData = jobToParse;
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
