import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/player_service.dart';
import '../services/equalizer_service.dart';
import '../models/media_item.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  bool _showEQ = false;
  bool _showQueue = false;

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();
    final item = player.currentItem;

    return Scaffold(
      backgroundColor: const Color(0xFF0e0e12),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            if (!_showEQ && !_showQueue) ...[
              _buildArt(item),
              _buildMeta(item),
              _buildSeek(player),
              _buildControls(player),
              _buildVolume(player),
              const SizedBox(height: 8),
              _buildBottomBtns(),
            ],
            if (_showEQ) Expanded(child: _buildEQ()),
            if (_showQueue) Expanded(child: _buildQueue(player)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
            color: const Color(0xFF9a94b4),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          const Text('Now Playing',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
              color: Color(0xFF9a94b4))),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.queue_music_rounded),
            color: const Color(0xFF9a94b4),
            onPressed: () => setState(() { _showQueue = !_showQueue; _showEQ = false; }),
          ),
        ],
      ),
    );
  }

  Widget _buildArt(MediaItem? item) {
    return Container(
      width: 220,
      height: 220,
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF1e1e28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7c5cfc).withOpacity(0.25),
            blurRadius: 40,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: item?.albumArt != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.memory(item!.albumArt!, fit: BoxFit.cover),
          )
        : const Icon(Icons.music_note_rounded, size: 80,
            color: Color(0xFF7c5cfc)),
    );
  }

  Widget _buildMeta(MediaItem? item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Text(item?.name ?? 'Select a track',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
              color: Color(0xFFf0eeff))),
          const SizedBox(height: 4),
          Text(item?.displayArtist ?? '—',
            style: const TextStyle(fontSize: 14, color: Color(0xFF9a94b4))),
        ],
      ),
    );
  }

  Widget _buildSeek(PlayerService player) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
      child: Column(
        children: [
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: const Color(0xFF7c5cfc),
              inactiveTrackColor: const Color(0xFF1e1e28),
              thumbColor: const Color(0xFFa78bfa),
              overlayColor: const Color(0xFF7c5cfc).withOpacity(0.2),
            ),
            child: Slider(
              value: player.progress.clamp(0.0, 1.0),
              onChanged: (v) => player.seekTo(v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_fmt(player.position),
                  style: const TextStyle(fontSize: 11, color: Color(0xFF5a5470))),
                Text(_fmt(player.duration),
                  style: const TextStyle(fontSize: 11, color: Color(0xFF5a5470))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(PlayerService player) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Shuffle
          IconButton(
            icon: Icon(Icons.shuffle_rounded,
              color: player.shuffle
                ? const Color(0xFFa78bfa)
                : const Color(0xFF5a5470)),
            onPressed: player.toggleShuffle,
          ),
          // Prev
          IconButton(
            icon: const Icon(Icons.skip_previous_rounded, size: 36),
            color: const Color(0xFFf0eeff),
            onPressed: player.prev,
          ),
          // Play/Pause
          GestureDetector(
            onTap: player.togglePlay,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7c5cfc),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7c5cfc).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                player.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
          ),
          // Next
          IconButton(
            icon: const Icon(Icons.skip_next_rounded, size: 36),
            color: const Color(0xFFf0eeff),
            onPressed: player.next,
          ),
          // Repeat
          IconButton(
            icon: Icon(
              player.repeat == RepeatMode.one
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded,
              color: player.repeat != RepeatMode.off
                ? const Color(0xFFa78bfa)
                : const Color(0xFF5a5470),
            ),
            onPressed: player.toggleRepeat,
          ),
        ],
      ),
    );
  }

  Widget _buildVolume(PlayerService player) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        children: [
          const Icon(Icons.volume_down_rounded, color: Color(0xFF5a5470), size: 20),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                activeTrackColor: const Color(0xFF5a5470),
                inactiveTrackColor: const Color(0xFF1e1e28),
                thumbColor: const Color(0xFF9a94b4),
                overlayShape: SliderComponentShape.noOverlay,
              ),
              child: Slider(
                value: player.volume,
                onChanged: (v) => player.setVolume(v),
              ),
            ),
          ),
          const Icon(Icons.volume_up_rounded, color: Color(0xFF5a5470), size: 20),
        ],
      ),
    );
  }

  Widget _buildBottomBtns() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton.icon(
          onPressed: () => setState(() { _showEQ = true; _showQueue = false; }),
          icon: const Icon(Icons.equalizer_rounded, size: 18),
          label: const Text('Equalizer'),
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF9a94b4)),
        ),
      ],
    );
  }

  // ── Equalizer Panel ──────────────────────────────────────
  Widget _buildEQ() {
    final eq = context.watch<EqualizerService>();
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                color: const Color(0xFF9a94b4),
                onPressed: () => setState(() => _showEQ = false),
              ),
              const Text('Equalizer',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const Spacer(),
              GestureDetector(
                onTap: eq.toggleEnabled,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: eq.enabled
                      ? const Color(0xFF7c5cfc).withOpacity(0.15)
                      : const Color(0xFF1e1e28),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: eq.enabled
                        ? const Color(0xFF7c5cfc).withOpacity(0.4)
                        : const Color(0xFF5a5470).withOpacity(0.3),
                    ),
                  ),
                  child: Text(eq.enabled ? 'ON' : 'OFF',
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: eq.enabled ? const Color(0xFFa78bfa) : const Color(0xFF5a5470),
                    )),
                ),
              ),
            ],
          ),
        ),

        // Presets
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: EqualizerService.presets.length,
            itemBuilder: (_, i) {
              final active = eq.activePreset == i;
              return GestureDetector(
                onTap: () => eq.applyPreset(i),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: active ? const Color(0xFF7c5cfc) : const Color(0xFF1e1e28),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: active
                        ? const Color(0xFF7c5cfc)
                        : const Color(0xFF7c5cfc).withOpacity(0.15),
                    ),
                  ),
                  child: Text(EqualizerService.presets[i].name,
                    style: TextStyle(
                      fontSize: 12,
                      color: active ? Colors.white : const Color(0xFF9a94b4),
                      fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                    )),
                ),
              );
            },
          ),
        ),

        // Bands
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(5, (i) {
                return Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${eq.bands[i] > 0 ? '+' : ''}${eq.bands[i].toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFFa78bfa)),
                      ),
                      Expanded(
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                              activeTrackColor: const Color(0xFF7c5cfc),
                              inactiveTrackColor: const Color(0xFF1e1e28),
                              thumbColor: const Color(0xFFa78bfa),
                              overlayShape: SliderComponentShape.noOverlay,
                            ),
                            child: Slider(
                              min: -12,
                              max: 12,
                              value: eq.bands[i],
                              onChanged: (v) => eq.setBand(i, v),
                            ),
                          ),
                        ),
                      ),
                      Text(EqualizerService.bandLabels[i],
                        style: const TextStyle(fontSize: 10, color: Color(0xFF5a5470))),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  // ── Queue Panel ──────────────────────────────────────────
  Widget _buildQueue(PlayerService player) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                color: const Color(0xFF9a94b4),
                onPressed: () => setState(() => _showQueue = false),
              ),
              Text('Queue (${player.queue.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: player.queue.length,
            itemBuilder: (_, i) {
              final item = player.queue[i];
              final active = i == player.currentIndex;
              return ListTile(
                onTap: () { player.playAt(i); setState(() => _showQueue = false); },
                leading: Text(
                  active ? '▶' : '${i + 1}',
                  style: TextStyle(
                    fontSize: 13,
                    color: active ? const Color(0xFF7c5cfc) : const Color(0xFF5a5470),
                  ),
                ),
                title: Text(item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                    color: active ? const Color(0xFFa78bfa) : const Color(0xFFf0eeff),
                  )),
                subtitle: Text(item.displayArtist,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF9a94b4))),
                trailing: Text(item.formattedDuration,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF5a5470))),
              );
            },
          ),
        ),
      ],
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
