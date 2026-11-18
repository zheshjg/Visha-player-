import 'dart:typed_data';

enum MediaType { audio, video }

class MediaItem {
  final String path;
  final String name;
  final String? artist;
  final String? album;
  final Duration? duration;
  final MediaType type;
  final Uint8List? albumArt;
  final int fileSize;

  MediaItem({
    required this.path,
    required this.name,
    this.artist,
    this.album,
    this.duration,
    required this.type,
    this.albumArt,
    this.fileSize = 0,
  });

  String get displayArtist => artist ?? (type == MediaType.audio ? 'Unknown Artist' : 'Video');

  String get formattedDuration {
    if (duration == null) return '--:--';
    final m = duration!.inMinutes;
    final s = duration!.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String get formattedSize {
    if (fileSize > 1048576) return '${(fileSize / 1048576).toStringAsFixed(1)} MB';
    return '${(fileSize / 1024).toStringAsFixed(0)} KB';
  }

  MediaItem copyWith({Duration? duration, Uint8List? albumArt, String? artist, String? album}) {
    return MediaItem(
      path: path,
      name: name,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      type: type,
      albumArt: albumArt ?? this.albumArt,
      fileSize: fileSize,
    );
  }
}
