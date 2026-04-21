import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';
import 'package:scraki/features/email/domain/entities/email_account.dart';
import 'package:scraki/features/email/domain/repositories/i_email_repository.dart';

part 'settings_email_store.g.dart';

@injectable
class SettingsEmailStore = _SettingsEmailStore with _$SettingsEmailStore;

abstract class _SettingsEmailStore with Store {
  final IEmailRepository _repository;

  _SettingsEmailStore(this._repository);

  @observable
  bool isLoading = false;

  @observable
  bool isPaginating = false;

  @observable
  String? errorMessage;

  @observable
  ObservableList<EmailAccount> accounts = ObservableList<EmailAccount>();

  @observable
  String searchQuery = '';

  @observable
  bool hasMore = true;

  String? _lastUpdate;
  static const int _pageSize = 50;

  @action
  Future<void> loadInitialAccounts() async {
    isLoading = true;
    errorMessage = null;
    accounts.clear();
    _lastUpdate = null;
    hasMore = true;

    await _fetchPage();

    isLoading = false;
  }

  @action
  Future<void> loadNextPage() async {
    if (isPaginating || !hasMore) return;

    isPaginating = true;
    errorMessage = null;

    await _fetchPage();

    isPaginating = false;
  }

  @action
  Future<void> setSearchQuery(String query) async {
    searchQuery = query;
    await loadInitialAccounts();
  }

  Future<void> _fetchPage() async {
    final result = await _repository.fetchEmailAccountsPaginated(
      limit: _pageSize,
      lastUpdate: _lastUpdate,
      searchQuery: searchQuery,
    );

    result.fold(
      (failure) {
        errorMessage = 'Lỗi tải dữ liệu: ${failure.message}';
        hasMore = false;
      },
      (paginatedResult) {
        if (paginatedResult.accounts.length < _pageSize) {
          hasMore = false;
        }
        accounts.addAll(paginatedResult.accounts);
        _lastUpdate = paginatedResult.lastUpdate;
      },
    );
  }

  @action
  Future<void> addAccount(EmailAccount account) async {
    isLoading = true;
    final result = await _repository.addEmailAccount(account);
    result.fold(
      (lb) => errorMessage = lb.message,
      (_) => loadInitialAccounts(),
    );
    isLoading = false;
  }

  @action
  Future<void> updateAccount(EmailAccount account) async {
    isLoading = true;
    final result = await _repository.updateEmailAccount(account);
    result.fold(
      (lb) => errorMessage = lb.message,
      (_) {
        final index = accounts.indexWhere((a) => a.email == account.email);
        if (index != -1) {
          accounts[index] = account;
        }
      },
    );
    isLoading = false;
  }

  @action
  Future<void> deleteAccount(String email) async {
    isLoading = true;
    final result = await _repository.deleteEmailAccount(email);
    result.fold(
      (lb) => errorMessage = lb.message,
      (_) {
        accounts.removeWhere((a) => a.email == email);
      },
    );
    isLoading = false;
  }

  @action
  Future<void> bulkImport(String rawText) async {
    isLoading = true;
    errorMessage = null;

    // Parse manually
    final accountsToImport = _parseRawCredentials(rawText);
    if (accountsToImport.isEmpty) {
      errorMessage = 'Không có dữ liệu hợp lệ để import.';
      isLoading = false;
      return;
    }

    final result = await _repository.bulkAddEmailAccounts(accountsToImport);
    result.fold(
      (failure) => errorMessage = 'Lỗi bulk import: ${failure.message}',
      (_) => loadInitialAccounts(),
    );

    isLoading = false;
  }

  List<EmailAccount> _parseRawCredentials(String rawText) {
    if (rawText.trim().isEmpty) return [];
    final List<EmailAccount> results = [];
    final lines = rawText.split(RegExp(r'\r?\n'));
    for (var line in lines) {
      final parts = line.trim().split('|');
      if (parts.length >= 5) {
        try {
          if (parts.length == 5) {
             results.add(EmailAccount(
              username: parts[0].trim(),
              password: parts[1].trim(),
              email: parts[2].trim(),
              refreshToken: parts[3].trim(),
              clientId: parts[4].trim(),
            ));
          } else {
             results.add(EmailAccount(
              username: parts[0].trim(),
              password: parts[1].trim(),
              email: parts[2].trim(),
              refreshToken: parts[4].trim(), // recovery skip parts[3]
              clientId: parts[5].trim(),
            ));
          }
        } catch (_) {}
      }
    }
    return results;
  }

  // Legacy support for other parts of app if needed
  @observable
  String rawCredentials = '';
  
  @action
  Future<void> loadCredentials() async => loadInitialAccounts();
  
  @action
  void updateCredentialsLocally(String text) {
    rawCredentials = text;
  }
  
  @action
  Future<void> saveCredentials() async {
    // Legacy: use bulkImport if needed or do nothing
  }
}
