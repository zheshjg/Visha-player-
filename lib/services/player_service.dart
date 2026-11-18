import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/media_item.dart';

enum RepeatMode { off, all, one }
enum PlayerState { idle, playing, paused, loading }

class PlayerService extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<MediaItem> _playlist = [];
  List<MediaItem> _queue = [];
  int _currentIndex = -1;
  bool _shuffle = false;
  RepeatMode _repeat = RepeatMode.off;
  PlayerState _state = PlayerState.idle;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 0.8;

  // Getters
  List<MediaItem> get playlist => _playlist;
  List<MediaItem> get queue => _queue;
  int get currentIndex => _currentIndex;
  MediaItem? get currentItem => _currentIndex >= 0 && _currentIndex < _queue.length ? _queue[_currentIndex] : null;
  bool get shuffle => _shuffle;
  RepeatMode get repeat => _repeat;
  PlayerState get state => _state;
  Duration get position => _position;
  Duration get duration => _duration;
  double get volume => _volume;
  bool get isPlaying => _state == PlayerState.playing;
  double get progress => _duration.inMilliseconds > 0 ? _position.inMilliseconds / _duration.inMilliseconds : 0.0;

  PlayerService() {
    _audioPlayer.playerStateStream.listen((s) {
      if (s.playing) {
        _state = PlayerState.playing;
      } else {
        _state = s.processingState == ProcessingState.loading ? PlayerState.loading : PlayerState.paused;
      }
      notifyListeners();
    });

    _audioPlayer.positionStream.listen((p) {
      _position = p;
      notifyListeners();
    });

    _audioPlayer.durationStream.listen((d) {
      if (d != null) _duration = d;
      notifyListeners();
    });

    _audioPlayer.processingStateStream.listen((s) {
      if (s == ProcessingState.completed) _onTrackEnd();
    });

    _audioPlayer.setVolume(_volume);
  }

  void setPlaylist(List<MediaItem> items) {
    _playlist = items;
    _queue = List.from(items);
    notifyListeners();
  }

  Future<void> playAt(int index) async {
    if (index < 0 || index >= _queue.length) return;
    final item = _queue[index];
    if (item.type == MediaType.video) return; // handled by video player

    _currentIndex = index;
    _state = PlayerState.loading;
    notifyListeners();

    try {
      // Direct file path - no MediaStore, no content URI
      await _audioPlayer.setFilePath(item.path);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Play error: $e');
      _state = PlayerState.idle;
      notifyListeners();
    }
  }

  Future<void> togglePlay() async {
    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  Future<void> seekTo(double progress) async {
    final ms = (_duration.inMilliseconds * progress).round();
    await _audioPlayer.seek(Duration(milliseconds: ms));
  }

  Future<void> next() async {
    if (_repeat == RepeatMode.one) {
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.play();
      return;
    }

    int next;
    if (_shuffle) {
      next = (List.generate(_queue.length, (i) => i)..shuffle()).first;
    } else {
      next = _currentIndex + 1;
      if (next >= _queue.length) {
        if (_repeat == RepeatMode.all) next = 0;
        else { await _audioPlayer.pause(); return; }
      }
    }
    await playAt(next);
  }

  Future<void> prev() async {
    if (_position.inSeconds > 3) {
      await _audioPlayer.seek(Duration.zero);
      return;
    }
    int prev = _currentIndex - 1;
    if (prev < 0) prev = _queue.length - 1;
    await playAt(prev);
  }

  void toggleShuffle() {
    _shuffle = !_shuffle;
    notifyListeners();
  }

  void toggleRepeat() {
    _repeat = RepeatMode.values[(_repeat.index + 1) % RepeatMode.values.length];
    notifyListeners();
  }

  Future<void> setVolume(double vol) async {
    _volume = vol.clamp(0.0, 1.0);
    await _audioPlayer.setVolume(_volume);
    notifyListeners();
  }

  void _onTrackEnd() => next();

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
