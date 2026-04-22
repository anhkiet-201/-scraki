import 'dart:math';
import 'package:mobx/mobx.dart';
import 'package:injectable/injectable.dart';
import 'package:scraki/core/utils/logger.dart';
import 'package:scraki/features/tiktok_seeding/domain/repositories/i_tiktok_seeding_repository.dart';
import 'package:scraki/features/tiktok_seeding/domain/services/i_tiktok_seeding_service.dart';

part 'tiktok_seeding_store.g.dart';

@lazySingleton
class TikTokSeedingStore = _TikTokSeedingStoreBase with _$TikTokSeedingStore;

abstract class _TikTokSeedingStoreBase with Store {
  final ITikTokSeedingService _seedingService;
  final ITikTokSeedingRepository _repository;

  _TikTokSeedingStoreBase(this._seedingService, this._repository);

  ReactionDisposer? _saveDisposer;

  @action
  Future<void> init() async {
    final result = await _repository.getBulkInput();
    result.fold(
      (failure) => logger.e('[TikTokSeedingStore] Failed to load: ${failure.message}'),
      (input) => bulkInput = input,
    );

    // Auto save khi bulkInput thay đổi
    _saveDisposer = reaction(
      (_) => bulkInput,
      (input) => _repository.saveBulkInput(input),
      delay: 500, // Debounce 500ms
    );
  }

  void dispose() {
    _saveDisposer?.call();
  }

  @observable
  String bulkInput = '';

  @observable
  bool isProcessing = false;

  @observable
  String? errorMessage;

  @computed
  List<String> get keywords {
    if (bulkInput.trim().isEmpty) return [];
    return bulkInput
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  @action
  void setBulkInput(String value) {
    bulkInput = value;
  }

  @action
  Future<void> runBatchSeeding(List<String> deviceSerials) async {
    if (keywords.isEmpty) {
      errorMessage = 'Vui lòng nhập ít nhất một từ khóa hoặc link.';
      return;
    }

    if (deviceSerials.isEmpty) {
      errorMessage = 'Vui lòng chọn ít nhất một thiết bị.';
      return;
    }

    isProcessing = true;
    errorMessage = null;

    try {
      // 1. Chuẩn bị danh sách từ khóa đã trộn (Shuffled)
      final shuffledKeywords = List<String>.from(keywords)..shuffle(Random());
      int keywordIndex = 0;

      for (int i = 0; i < deviceSerials.length; i++) {
        final serial = deviceSerials[i];
        
        // 2. Lấy từ khóa từ danh sách đã trộn (vòng hành nếu hết)
        if (keywordIndex >= shuffledKeywords.length) {
          shuffledKeywords.shuffle(Random());
          keywordIndex = 0;
        }
        final selectedKeyword = shuffledKeywords[keywordIndex++];

        logger.i('[TikTokSeedingStore] Đẩy seeding cho $serial với keyword: $selectedKeyword');
        
        // 3. Thực thi (không await Future.wait để có thể thêm delay giữa các máy)
        await _seedingService.openSearch(serial, selectedKeyword);

        // 4. Thêm độ trễ ngẫu nhiên giữa các máy (trừ máy cuối cùng)
        if (i < deviceSerials.length - 1) {
          final delayMs = 1500 + Random().nextInt(2500); // 1.5s - 4.0s
          logger.d('[TikTokSeedingStore] Delay ${delayMs}ms trước máy tiếp theo...');
          await Future<void>.delayed(Duration(milliseconds: delayMs));
        }
      }

      logger.i('[TikTokSeedingStore] Hoàn thành đẩy batch seeding cho ${deviceSerials.length} máy.');
    } catch (e) {
      logger.e('[TikTokSeedingStore] Lỗi khi chạy batch seeding', error: e);
      errorMessage = e.toString();
    } finally {
      isProcessing = false;
    }
  }

  @action
  Future<void> runSingleSeeding(String serial, String query) async {
    isProcessing = true;
    errorMessage = null;
    try {
      await _seedingService.openSearch(serial, query);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isProcessing = false;
    }
  }

  @action
  Future<void> runRandomSeeding(String serial) async {
    if (keywords.isEmpty) {
      errorMessage = 'Vui lòng nhập danh sách từ khóa trong Batch Seeding trước.';
      return;
    }

    final random = Random.secure();
    final randomKeyword = keywords[random.nextInt(keywords.length)];
    
    await runSingleSeeding(serial, randomKeyword);
  }
}
