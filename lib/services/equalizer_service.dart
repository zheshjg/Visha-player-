import 'package:flutter/foundation.dart';

class EqPreset {
  final String name;
  final List<double> bands;
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

  bool get enabled => _enabled;
  int get activePreset => _activePreset;
  List<double> get bands => List.unmodifiable(_bands);

  void setBand(int idx, double value) {
    _bands[idx] = value.clamp(-12.0, 12.0);
    _activePreset = -1;
    notifyListeners();
  }

  void applyPreset(int idx) {
    _activePreset = idx;
    _bands = List.from(presets[idx].bands);
    notifyListeners();
  }

  void toggleEnabled() {
    _enabled = !_enabled;
    notifyListeners();
  }
}
