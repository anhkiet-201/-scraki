import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:scraki/core/stores/session_manager_store.dart';

class FileUploadTaskClassifier {
  final List<String> paths;

  FileUploadTaskClassifier(this.paths);

  bool get isEmpty => paths.isEmpty;

  String get fileName => paths.isNotEmpty ? p.basename(paths.first) : '';

  bool get isSetDir {
    if (paths.length != 1) return false;
    final path = paths.first;
    if (!Directory(path).existsSync()) return false;

    final nameLower = p.basename(path).toLowerCase();
    return nameLower.startsWith('set_') ||
        nameLower.startsWith('fb_set_') ||
        nameLower.startsWith('tik_set_');
  }

  bool get isVideo {
    if (isSetDir) return false;
    return paths.every((path) {
      final ext = path.toLowerCase().split('.').last;
      return const {
        'mp4',
        'mov',
        'avi',
        'mkv',
        'webm',
        '3gp',
        'ts',
        'm4v',
        'flv',
        'wmv',
      }.contains(ext);
    });
  }

  bool get isImage {
    if (isSetDir || isVideo) return false;
    return paths.every((path) {
      final ext = path.toLowerCase().split('.').last;
      return const {
        'png',
        'jpg',
        'jpeg',
        'webp',
        'gif',
        'bmp',
      }.contains(ext);
    });
  }

  bool get isApk {
    if (isSetDir || isVideo || isImage) return false;
    return paths.every((path) => path.toLowerCase().endsWith('.apk'));
  }

  bool get isXapk {
    if (isSetDir || isVideo || isImage) return false;
    return paths.every((path) => path.toLowerCase().endsWith('.xapk'));
  }

  bool get isFbPrefix {
    final name = fileName.toLowerCase();
    return name.startsWith('fb_feeds_') ||
        name.startsWith('fb_groups_') ||
        name.startsWith('fb_reels_');
  }

  DeviceTaskType determineTaskType() {
    if (isSetDir) {
      final nameLower = fileName.toLowerCase();
      return nameLower.startsWith('fb_set_')
          ? DeviceTaskType.facebookImage
          : DeviceTaskType.imagePost;
    }

    if (isVideo) {
      if (fileName.toLowerCase().startsWith('tik_final_')) {
        return DeviceTaskType.videoGen;
      }
      return isFbPrefix ? DeviceTaskType.facebookVideo : DeviceTaskType.push;
    }

    if (isImage) {
      return isFbPrefix ? DeviceTaskType.facebookImage : DeviceTaskType.push;
    }

    if (isApk || isXapk) {
      return DeviceTaskType.install;
    }

    return DeviceTaskType.push;
  }
}
