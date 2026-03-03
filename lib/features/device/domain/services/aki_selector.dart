/// Hệ thống Selector type-safe cho `aki_remote` CLI.
///
/// Thay vì truyền raw string dễ sai format, dùng các class này để
/// tạo selector đúng cú pháp theo tài liệu AkiRemote.
///
/// **Ví dụ:**
/// ```dart
/// // Thay vì viết: 'text:Kết nối'
/// AkiSelector.text('Kết nối')
///
/// // Thay vì viết: 'id-contains:username && text:admin'
/// AkiSelector.idContains('username') & AkiSelector.text('admin')
/// ```
abstract class AkiSelector {
  const AkiSelector();

  /// Chuyển selector thành chuỗi đúng format của aki_remote CLI.
  String toSelectorString();

  // ---------------------------------------------------------------------------
  // Factory constructors (API fluent)
  // ---------------------------------------------------------------------------

  /// Khớp chính xác theo `resource-id`.
  ///
  /// Ví dụ: `AkiSelector.id('com.android.settings:id/title')`
  /// → `id:com.android.settings:id/title`
  static AkiSelector id(String value) => _ExactSelector('id', value);

  /// Khớp chuỗi con theo `resource-id`.
  ///
  /// Ví dụ: `AkiSelector.idContains('username')`
  /// → `id-contains:username`
  static AkiSelector idContains(String value) => _ContainsSelector('id', value);

  /// Khớp chính xác theo `text`.
  ///
  /// Ví dụ: `AkiSelector.text('Samsung account')`
  /// → `text:Samsung account`
  static AkiSelector text(String value) => _ExactSelector('text', value);

  /// Khớp chuỗi con theo `text`.
  ///
  /// Ví dụ: `AkiSelector.textContains('Hẹn')`
  /// → `text-contains:Hẹn`
  static AkiSelector textContains(String value) =>
      _ContainsSelector('text', value);

  /// Khớp chính xác theo `content-desc`.
  ///
  /// Ví dụ: `AkiSelector.desc('Search')`
  /// → `desc:Search`
  static AkiSelector desc(String value) => _ExactSelector('desc', value);

  /// Khớp chuỗi con theo `content-desc`.
  ///
  /// Ví dụ: `AkiSelector.descContains('Cài đặt')`
  /// → `desc-contains:Cài đặt`
  static AkiSelector descContains(String value) =>
      _ContainsSelector('desc', value);

  /// Khớp chính xác theo `class`.
  ///
  /// Ví dụ: `AkiSelector.className('android.widget.Button')`
  /// → `class:android.widget.Button`
  static AkiSelector className(String value) => _ExactSelector('class', value);

  /// Khớp chuỗi con theo `text` hoặc `desc` (không cần prefix).
  ///
  /// Ví dụ: `AkiSelector.contains('Nguyễn')`
  /// → `Nguyễn`
  static AkiSelector contains(String value) => _RawContainsSelector(value);

  // ---------------------------------------------------------------------------
  // Combination operator
  // ---------------------------------------------------------------------------

  /// Kết hợp hai selector bằng toán tử `&&`.
  ///
  /// ```dart
  /// AkiSelector.text('Samsung account') & AkiSelector.className('android.widget.TextView')
  /// // → "text:Samsung account && class:android.widget.TextView"
  /// ```
  AkiSelector operator &(AkiSelector other) => _AndSelector(this, other);

  @override
  String toString() => toSelectorString();
}

// ---------------------------------------------------------------------------
// Private implementations
// ---------------------------------------------------------------------------

/// Selector khớp chính xác: `<type>:<value>`.
class _ExactSelector extends AkiSelector {
  final String _type;
  final String _value;

  const _ExactSelector(this._type, this._value);

  @override
  String toSelectorString() => '$_type:$_value';
}

/// Selector khớp chuỗi con: `<type>-contains:<value>`.
class _ContainsSelector extends AkiSelector {
  final String _type;
  final String _value;

  const _ContainsSelector(this._type, this._value);

  @override
  String toSelectorString() => '$_type-contains:$_value';
}

/// Selector contains thuần (không prefix) — khớp text hoặc desc.
class _RawContainsSelector extends AkiSelector {
  final String _value;

  const _RawContainsSelector(this._value);

  @override
  String toSelectorString() => _value;
}

/// Kết hợp hai selector bằng `&&`.
class _AndSelector extends AkiSelector {
  final AkiSelector _left;
  final AkiSelector _right;

  const _AndSelector(this._left, this._right);

  @override
  String toSelectorString() =>
      '${_left.toSelectorString()} && ${_right.toSelectorString()}';
}
