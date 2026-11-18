import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import '../models/media_item.dart';

class FileScanner {
  static const _audioExts = {
    'mp3','flac','aac','ogg','m4a','wav','wma','opus','ape','alac','aiff'
  };
  static const _videoExts = {
    'mp4','mkv','avi','mov','webm','flv','ts','m4v','3gp','wmv','rmvb'
  };

  static const _scanRoots = [
    '/storage/emulated/0',
    '/storage/emulated/0/Music',
    '/storage/emulated/0/Download',
    '/storage/emulated/0/Movies',
    '/storage/emulated/0/DCIM',
    '/storage/emulated/0/Videos',
    '/storage/emulated/0/WhatsApp/Media',
    '/storage/emulated/0/Telegram',
  ];

  static const _skipDirs = {
    'Android','data','obb','.thumbnails','.trash',
    '.nomedia','lost+found','proc','sys'
  };

  /// Scans filesystem directly using File API — no MediaStore, no ContentResolver
  static Future<List<MediaItem>> scanAll({
    void Function(int found)? onProgress,
  }) async {
    final results = <MediaItem>[];
    final seen = <String>{};

    for (final root in _scanRoots) {
      final dir = Directory(root);
      if (!await dir.exists()) continue;
      await _scanDir(dir, results, seen, onProgress, depth: 0);
    }

    // Sort: audio first, then by name
    results.sort((a, b) {
      if (a.type != b.type) return a.type == MediaType.audio ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return results;
  }

  static Future<void> _scanDir(
    Directory dir,
    List<MediaItem> results,
    Set<String> seen,
    void Function(int)? onProgress, {
    required int depth,
  }) async {
    if (depth > 6) return;

    try {
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is Directory) {
          final name = entity.path.split('/').last;
          if (_skipDirs.contains(name) || name.startsWith('.')) continue;
          await _scanDir(entity, results, seen, onProgress, depth: depth + 1);
        } else if (entity is File) {
          final path = entity.path;
          if (seen.contains(path)) continue;
          final ext = path.split('.').last.toLowerCase();

          MediaType? type;
          if (_audioExts.contains(ext)) type = MediaType.audio;
          else if (_videoExts.contains(ext)) type = MediaType.video;
          else continue;

          seen.add(path);
          final item = await _buildItem(entity, type);
          if (item != null) {
            results.add(item);
            onProgress?.call(results.length);
          }
        }
      }
    } catch (_) {
      // Permission denied on some dirs — skip silently
    }
  }

  static Future<MediaItem?> _buildItem(File file, MediaType type) async {
    try {
      final stat = await file.stat();
      final rawName = file.path.split('/').last.replaceAll(RegExp(r'\.[^.]+$'), '');

      String name = rawName;
      String? artist;
      String? album;
      Uint8List? art;
      Duration? duration;

      if (type == MediaType.audio) {
        try {
          final meta = await readMetadata(file, getImage: true);
          if (meta.title != null && meta.title!.isNotEmpty) name = meta.title!;
          artist = meta.artist;
          album = meta.album;
          if (meta.duration != null) duration = meta.duration;
          if (meta.pictures.isNotEmpty) {
            art = Uint8List.fromList(meta.pictures.first.bytes);
          }
        } catch (_) {
          // No metadata — use filename
        }
      }

      return MediaItem(
        path: file.path,
        name: name,
        artist: artist,
        album: album,
        duration: duration,
        type: type,
        albumArt: art,
        fileSize: stat.size,
      );
    } catch (_) {
      return null;
    }
  }
}
