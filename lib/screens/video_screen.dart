import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import '../models/media_item.dart';

class VideoScreen extends StatefulWidget {
  final List<MediaItem> items;
  final int startIndex;
  const VideoScreen({super.key, required this.items, required this.startIndex});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  late VlcPlayerController _ctrl;
  late int _idx;
  bool _showOverlay = true;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    _idx = widget.startIndex;
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    _initPlayer();
  }

  void _initPlayer() {
    final item = widget.items[_idx];
    // VLC reads directly via file:// path — no MediaStore involved
  _ctrl = VlcPlayerController.file(
  File(item.path),
  hwAcc: HwAcc.full,
  autoPlay: true,
  options: VlcPlayerOptions(),
);
    _ctrl.addListener(_onVlcEvent);
    _hideOverlayAfterDelay();
  }

  void _onVlcEvent() {
    if (!mounted) return;
    final ended = _ctrl.value.playingState == PlayingState.ended;
    if (ended) _next();
    if (_ctrl.value.isPlaying != _isPlaying) {
      setState(() => _isPlaying = _ctrl.value.isPlaying);
    }
  }

  void _hideOverlayAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isPlaying) setState(() => _showOverlay = false);
    });
  }

  void _toggleOverlay() {
    setState(() => _showOverlay = !_showOverlay);
    if (_showOverlay) _hideOverlayAfterDelay();
  }

  Future<void> _next() async {
    if (_idx < widget.items.length - 1) {
      await _ctrl.dispose();
      setState(() => _idx++);
      _initPlayer();
    }
  }

  Future<void> _prev() async {
    final pos = await _ctrl.getPosition();
    if (pos.inSeconds > 3) {
      _ctrl.seekTo(Duration.zero);
      return;
    }
    if (_idx > 0) {
      await _ctrl.dispose();
      setState(() => _idx--);
      _initPlayer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.items[_idx];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleOverlay,
        child: Stack(
          children: [
            Center(
              child: VlcPlayer(
                controller: _ctrl,
                aspectRatio: 16 / 9,
                placeholder: const Center(
                  child: CircularProgressIndicator(color: Color(0xFF7c5cfc))),
              ),
            ),
            AnimatedOpacity(
              opacity: _showOverlay ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: _buildOverlay(item),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlay(MediaItem item) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
          stops: const [0, 0.25, 0.75, 1],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Top
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.fullscreen_rounded, color: Colors.white),
                    onPressed: () {
                      final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
                      SystemChrome.setPreferredOrientations(isLandscape
                        ? [DeviceOrientation.portraitUp]
                        : [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
                    },
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Bottom
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  _buildSeek(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 32),
                        onPressed: _prev,
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () {
                          _isPlaying ? _ctrl.pause() : _ctrl.play();
                        },
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.15),
                          ),
                          child: Icon(
                            _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.white, size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 32),
                        onPressed: _next,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeek() {
    return ValueListenableBuilder(
      valueListenable: _ctrl,
      builder: (_, value, __) {
        final pos = value.position.inMilliseconds.toDouble();
        final dur = value.duration.inMilliseconds.toDouble();
        final progress = dur > 0 ? (pos / dur).clamp(0.0, 1.0) : 0.0;
        final posStr = _fmt(value.position);
        final durStr = _fmt(value.duration);

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(posStr, style: const TextStyle(fontSize: 11, color: Colors.white70)),
                Text(durStr, style: const TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ),
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white24,
                thumbColor: Colors.white,
                overlayShape: SliderComponentShape.noOverlay,
              ),
              child: Slider(
                value: progress,
                onChanged: (v) {
                  _ctrl.seekTo(Duration(milliseconds: (v * dur).round()));
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onVlcEvent);
    _ctrl.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }
}
