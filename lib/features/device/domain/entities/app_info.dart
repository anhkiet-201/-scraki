/// Entity đại diện cho thông tin một ứng dụng Android đã cài đặt trên thiết bị
class AppInfo {
  /// Package name của app (e.g., com.android.chrome)
  final String packageName;

  /// Tên hiển thị của app (friendly name)
  final String label;

  /// Flag xác định app là system app hay user-installed app
  final bool isSystemApp;

  /// Main activity để launch app (nếu có)
  /// Null nếu không có launch activity hoặc chưa query được
  final String? launchActivity;

  const AppInfo({
    required this.packageName,
    required this.label,
    this.isSystemApp = false,
    this.launchActivity,
  });

  @override
  String toString() {
    return 'AppInfo(packageName: $packageName, label: $label, isSystemApp: $isSystemApp, launchActivity: $launchActivity)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AppInfo &&
        other.packageName == packageName &&
        other.label == label &&
        other.isSystemApp == isSystemApp &&
        other.launchActivity == launchActivity;
  }

  @override
  int get hashCode {
    return packageName.hashCode ^
        label.hashCode ^
        isSystemApp.hashCode ^
        launchActivity.hashCode;
  }
}
