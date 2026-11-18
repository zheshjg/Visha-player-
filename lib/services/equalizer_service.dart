import 'package:flutter/foundation.dart';
import 'package:flutter_equalizer/flutter_equalizer.dart';

class EqPreset {
  final String name;
  final List<double> bands; // 5 bands dB
  const EqPreset(this.name, this.bands);
}

class EqualizerService extends ChangeNotifier {
  static const presets = [
    EqPreset('Flat',      [0,  0,  0,  0,  0]),
    EqPreset('Bass Boost',[8,  6,  2, -1, -2]),
    EqPreset('Vocal',     [-2, 0,  4,  4,  2]),
    EqPreset('Rock',      [5,  3,  0,  3,  5]),
    EqPreset('Pop',       [-1, 2,  4,  2, -1]),
    EqPreset('Jazz',      [3,  2,  0,  2,  3]),
    EqPreset('Classical', [4,  2,  0,  2,  4]),
    EqPreset('Hip-Hop',   [5,  4,  1,  0, -1]),
  ];

  static const bandLabels = ['60Hz','230Hz','910Hz','3.6kHz','14kHz'];

  bool _enabled = true;
  int _activePreset = 0;
  List<double> _bands = [0, 0, 0, 0, 0];
  int? _sessionId;

  bool get enabled => _enabled;
  int get activePreset => _activePreset;
  List<double> get bands => List.unmodifiable(_bands);

  Future<void> init(int audioSessionId) async {
    _sessionId = audioSessionId;
    try {
      await FlutterEqualizer.init(audioSessionId);
      await FlutterEqualizer.setEnabled(true);
    } catch (e) {
      debugPrint('EQ init error: $e');
    }
  }

  Future<void> setBand(int idx, double value) async {
    _bands[idx] = value.clamp(-12.0, 12.0);
    _activePreset = -1; // custom
    notifyListeners();
    await _applyBands();
  }

  Future<void> applyPreset(int idx) async {
    _activePreset = idx;
    _bands = List.from(presets[idx].bands);
    notifyListeners();
    await _applyBands();
  }

  Future<void> toggleEnabled() async {
    _enabled = !_enabled;
    notifyListeners();
    try {
      await FlutterEqualizer.setEnabled(_enabled);
    } catch (_) {}
  }

  Future<void> _applyBands() async {
    if (_sessionId == null || !_enabled) return;
    try {
      for (int i = 0; i < _bands.length; i++) {
        await FlutterEqualizer.setBandLevel(i, (_bands[i] * 100).round());
      }
    } catch (e) {
      debugPrint('EQ apply error: $e');
    }
  }
}
