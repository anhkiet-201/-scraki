# Kế Hoạch Triển Khai Video Poster & Anti-Reup trên Windows

## 1. Tổng Quan

### Mục Tiêu

Triển khai toàn bộ tính năng Video Poster (bao gồm Anti-Reup) để chạy ổn định trên Windows, đảm bảo tương thích 100% với phiên bản macOS hiện tại.

### Các Tính Năng Cần Hỗ Trợ

- ✅ Video Editing & Overlay
- ✅ Multi-video Concatenation
- ✅ Anti-Reup Processing (Speed, Noise, Color, Duration)
- ✅ Audio Handling (Mixed streams)
- ✅ FFmpeg Integration
- ✅ Preview Player (media_kit)

---

## 2. Phân Tích Dependencies & Platform Differences

### 2.1. Flutter Packages Hiện Tại

| Package            | macOS | Windows | Action Required       |
| ------------------ | ----- | ------- | --------------------- |
| `media_kit`        | ✅    | ✅      | None - Cross-platform |
| `media_kit_video`  | ✅    | ✅      | None - Cross-platform |
| `media_kit_libs_*` | ✅    | ⚠️      | Verify Windows libs   |
| `path_provider`    | ✅    | ✅      | None - Cross-platform |
| `get_it`           | ✅    | ✅      | None - Pure Dart      |
| `injectable`       | ✅    | ✅      | None - Pure Dart      |
| `mobx`             | ✅    | ✅      | None - Pure Dart      |
| `freezed`          | ✅    | ✅      | None - Pure Dart      |

### 2.2. FFmpeg Dependencies

#### macOS (Hiện Tại)

```bash
# Installed via Homebrew
brew install ffmpeg
# Location: /opt/homebrew/bin/ffmpeg
```

#### Windows (Cần Triển Khai)

**Option 1: Static Binary (Recommended)**

- Download FFmpeg Windows Static Build từ [ffmpeg.org](https://ffmpeg.org/download.html#build-windows)
- Bundle vào `windows/` directory của Flutter app
- Path: `windows/ffmpeg/bin/ffmpeg.exe`

**Option 2: System Install**

- Require user install FFmpeg via Chocolatey/Scoop
- Not recommended - phụ thuộc user setup

**Option 3: Package Manager**

- Use `ffmpeg_kit_flutter` package (có Windows support)
- Trade-off: Larger app size, but fully managed

> **Quyết định:** Sử dụng **Option 1 (Static Binary)** để đảm bảo app self-contained.

---

## 3. Code Changes Required

### 3.1. FFmpeg Path Detection

**File:** `lib/features/video_poster/data/repositories/ffmpeg_video_processing_repository_impl.dart`

**Current Implementation (macOS):**

```dart
Future<String?> _findFfmpeg() async {
  try {
    final result = await Process.run('which', ['ffmpeg']);
    if (result.exitCode == 0) {
      return result.stdout.toString().trim();
    }
  } catch (_) {}
  return null;
}
```

**New Implementation (Cross-Platform):**

```dart
import 'dart:io' show Platform;

Future<String?> _findFfmpeg() async {
  // 1. Try bundled FFmpeg first (Windows/macOS/Linux)
  final bundledPath = await _getBundledFfmpegPath();
  if (bundledPath != null && await File(bundledPath).exists()) {
    return bundledPath;
  }

  // 2. Try system PATH (Unix-like)
  if (Platform.isMacOS || Platform.isLinux) {
    try {
      final result = await Process.run('which', ['ffmpeg']);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      }
    } catch (_) {}
  }

  // 3. Try Windows common locations
  if (Platform.isWindows) {
    final commonPaths = [
      r'C:\ffmpeg\bin\ffmpeg.exe',
      r'C:\Program Files\ffmpeg\bin\ffmpeg.exe',
      Platform.environment['PATH']?.split(';').map((p) => '$p\\ffmpeg.exe').toList() ?? [],
    ].expand((e) => e is List ? e : [e]);

    for (final path in commonPaths) {
      if (await File(path).exists()) {
        return path;
      }
    }
  }

  return null;
}

Future<String?> _getBundledFfmpegPath() async {
  if (Platform.isWindows) {
    // Windows: Bundle in windows/ffmpeg/bin/
    final exePath = Platform.resolvedExecutable; // .../scraki.exe
    final exeDir = File(exePath).parent.path;
    return '$exeDir\\ffmpeg\\bin\\ffmpeg.exe';
  } else if (Platform.isMacOS) {
    // macOS: Bundle in Resources/
    final exePath = Platform.resolvedExecutable;
    final resourcesDir = File(exePath).parent.parent.path; // .../Contents
    return '$resourcesDir/Resources/ffmpeg';
  }
  return null;
}
```

### 3.2. Path Handling

**Windows Path Issues:**

- Backslashes (`\`) vs Forward slashes (`/`)
- Drive letters (`C:\`)
- Spaces in paths require quotes

**Solution:**

```dart
import 'package:path/path.dart' as p;

// Use path package for cross-platform path joining
final outputPath = p.join(outputDir.path, 'output_${composition.id}.mp4');

// Normalize paths for FFmpeg (use forward slashes everywhere)
String _normalizePath(String path) {
  return path.replaceAll('\\', '/');
}
```

### 3.3. Temporary Directory

**Current:**

```dart
final tempDir = await getTemporaryDirectory();
final overlayFile = File('${tempDir.path}/overlay_${composition.id}.png');
```

**Enhanced (Cross-Platform Safe):**

```dart
import 'package:path/path.dart' as p;

final tempDir = await getTemporaryDirectory();
final overlayFile = File(
  p.join(tempDir.path, 'overlay_${composition.id}.png')
);
```

### 3.4. Process Execution

**FFmpeg Command Escaping (Windows):**

```dart
// On Windows, paths with spaces must be quoted
List<String> _escapeArgs(List<String> args) {
  if (!Platform.isWindows) return args;

  return args.map((arg) {
    if (arg.contains(' ') && !arg.startsWith('"')) {
      return '"$arg"';
    }
    return arg;
  }).toList();
}

// Usage
final result = await Process.run(
  ffmpegPath,
  _escapeArgs(args),
);
```

---

## 4. FFmpeg Bundling Strategy

### 4.1. Download FFmpeg Windows Build

```bash
# 1. Download latest static build
https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip

# 2. Extract and copy to project
# Create: scraki/windows/ffmpeg/
# Copy: bin/ffmpeg.exe, bin/ffprobe.exe

# 3. Update .gitignore (optional, or commit binaries)
windows/ffmpeg/bin/*.exe
```

### 4.2. Flutter Build Configuration

**File:** `windows/CMakeLists.txt`

```cmake
# Add FFmpeg binaries to output
install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/ffmpeg/bin/ffmpeg.exe"
        DESTINATION "${INSTALL_BUNDLE_LIB_DIR}")
install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/ffmpeg/bin/ffprobe.exe"
        DESTINATION "${INSTALL_BUNDLE_LIB_DIR}")
```

**Alternative: Copy via Dart script**

Create `tool/bundle_ffmpeg.dart`:

```dart
import 'dart:io';
import 'package:path/path.dart' as p;

void main() async {
  if (!Platform.isWindows) return;

  final buildDir = 'build/windows/x64/runner/Release';
  final ffmpegSrc = 'windows/ffmpeg/bin/ffmpeg.exe';
  final ffprobeSrc = 'windows/ffmpeg/bin/ffprobe.exe';

  await File(ffmpegSrc).copy(p.join(buildDir, 'ffmpeg.exe'));
  await File(ffprobeSrc).copy(p.join(buildDir, 'ffprobe.exe'));
  print('✅ FFmpeg bundled successfully');
}
```

Run post-build:

```yaml
# pubspec.yaml
environment:
  sdk: ">=3.0.0 <4.0.0"

# Add to build script or run manually
# dart run tool/bundle_ffmpeg.dart
```

---

## 5. Testing Plan

### 5.1. Unit Tests

- [ ] Test FFmpeg path detection on Windows
- [ ] Test path normalization (backslash → forward slash)
- [ ] Test temp directory creation
- [ ] Test bundled binary execution

### 5.2. Integration Tests

- [ ] Single video export
- [ ] Multi-video concatenation
- [ ] Mixed audio handling (video with/without audio)
- [ ] Anti-Reup randomization (unique hashes)
- [ ] Duration enforcement (15-25s)
- [ ] Preview player accuracy

### 5.3. Platform-Specific Tests

**Windows-Specific:**

- [ ] Paths with spaces (`C:\Program Files\...`)
- [ ] Drive letters (C:, D:)
- [ ] Unicode filenames (Tiếng Việt có dấu)
- [ ] Long path support (>260 chars)
- [ ] Permission issues (write to Documents)

---

## 6. UI/UX Considerations

### 6.1. File Picker

**Current (macOS):**

- Uses native macOS file picker via `file_picker` package

**Windows:**

- Same package works cross-platform
- Verify file type filters (`.mov`, `.mp4`, `.avi`)

### 6.2. Media Player (`media_kit`)

**Verification:**

- Test `media_kit_video` on Windows (should work out-of-box)
- Verify `media_kit_libs_windows_video` is in `pubspec.yaml`

```yaml
dependencies:
  media_kit: ^1.1.10
  media_kit_video: ^1.2.4
  media_kit_libs_windows_video: ^1.0.9 # Windows libs
```

### 6.3. Permissions

**Windows Defender:**

- FFmpeg might trigger antivirus (signing recommended)
- Test with Windows Defender enabled

---

## 7. Deployment Checklist

### 7.1. Pre-Build

- [ ] Download FFmpeg Windows build (static, ~100MB)
- [ ] Place in `windows/ffmpeg/bin/`
- [ ] Update `CMakeLists.txt` or create bundle script
- [ ] Test locally: `flutter run -d windows`

### 7.2. Build

```bash
# Clean build
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# Build Windows release
flutter build windows --release

# Verify FFmpeg is bundled
ls build/windows/x64/runner/Release/ffmpeg.exe
```

### 7.3. Testing

- [ ] Test on clean Windows 10 VM (no dev tools)
- [ ] Test on Windows 11
- [ ] Test with different video formats
- [ ] Test with long file paths
- [ ] Test with Unicode filenames

### 7.4. Packaging

**Option 1: Zip Archive**

```bash
cd build/windows/x64/runner/Release
zip -r scraki-windows-v1.0.0.zip *
```

**Option 2: Installer (NSIS/Inno Setup)**

- Create installer that bundles FFmpeg
- Set up file associations (.mp4 → Scraki)

---

## 8. Known Issues & Mitigation

### Issue 1: FFmpeg Binary Size (~60MB)

**Impact:** Large app size  
**Mitigation:** Use static build (essentials only, ~30MB)

### Issue 2: Antivirus False Positives

**Impact:** Windows Defender might block FFmpeg  
**Mitigation:**

- Code sign the app
- Submit FFmpeg binary to Microsoft for whitelisting
- Document workaround for users

### Issue 3: Long Path Support

**Impact:** Windows MAX_PATH = 260 chars  
**Mitigation:**

- Use short temp paths
- Enable long path support in manifest:

```xml
<!-- windows/runner/Runner.exe.manifest -->
<application>
  <windowsSettings>
    <longPathAware>true</longPathAware>
  </windowsSettings>
</application>
```

### Issue 4: Unicode Paths

**Impact:** FFmpeg might not handle Vietnamese filenames  
**Mitigation:**

- Test thoroughly
- Normalize to ASCII if needed (fallback)

---

## 9. Roadmap

### Phase 1: Core Functionality (1 Week)

- [ ] Update FFmpeg path detection
- [ ] Bundle FFmpeg binary
- [ ] Fix path handling (backslash → forward slash)
- [ ] Test basic video export

### Phase 2: Anti-Reup Features (3 Days)

- [ ] Test randomization on Windows
- [ ] Verify FFmpeg filter chains work
- [ ] Test mixed audio handling
- [ ] Verify duration enforcement

### Phase 3: Testing & Polish (1 Week)

- [ ] Comprehensive testing on Windows 10/11
- [ ] Fix edge cases (long paths, Unicode)
- [ ] Performance optimization
- [ ] Memory leak checks

### Phase 4: Deployment (2 Days)

- [ ] Create installer
- [ ] Code signing
- [ ] Documentation (README for Windows users)
- [ ] Release build

---

## 10. Dependencies to Add

```yaml
# pubspec.yaml - Add Windows-specific deps
dependencies:
  # Existing...

  # Windows Media Playback
  media_kit_libs_windows_video: ^1.0.9

  # Path handling (already have, but verify)
  path: ^1.8.3

dev_dependencies:
  # Existing...
```

---

## 11. Resources

### FFmpeg

- **Windows Builds:** https://www.gyan.dev/ffmpeg/builds/
- **Static Builds:** https://github.com/BtbN/FFmpeg-Builds/releases

### Flutter Windows

- **Platform Channel:** https://docs.flutter.dev/platform-integration/platform-channels
- **Windows Plugin:** https://docs.flutter.dev/desktop#windows

### Media Kit

- **Windows Setup:** https://pub.dev/packages/media_kit_libs_windows_video

---

## 12. Success Criteria

✅ **Functional:**

- Video export works on Windows
- Anti-Reup produces unique hashes
- Preview matches output
- No crashes or memory leaks

✅ **Performance:**

- Export time ≤ macOS (same hardware)
- Memory usage < 2GB for 1080p video

✅ **UX:**

- No extra setup required (bundled FFmpeg)
- Clear error messages if FFmpeg fails
- File picker respects Windows conventions

✅ **Compatibility:**

- Windows 10 (1809+)
- Windows 11
- Both x64 and ARM64 (future)

---

## Tổng Kết

Việc port feature sang Windows là **khả thi** vì:

1. Flutter hỗ trợ Windows tốt
2. FFmpeg cross-platform
3. Tất cả packages đều hỗ trợ Windows

**Công việc chính:**

- Bundle FFmpeg binary (~30MB)
- Fix path handling (backslash)
- Test kỹ trên Windows

**Thời gian ước tính:** 2-3 tuần (bao gồm testing)
