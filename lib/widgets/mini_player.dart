import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/player_service.dart';

class MiniPlayer extends StatelessWidget {
  final VoidCallback onTap;
  const MiniPlayer({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();
    final item = player.currentItem;
    if (item == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: const Color(0xFF16161d),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress line
            LinearProgressIndicator(
              value: player.progress.clamp(0.0, 1.0),
              backgroundColor: const Color(0xFF1e1e28),
              color: const Color(0xFF7c5cfc),
              minHeight: 2,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
              child: Row(
                children: [
                  // Art
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFF1e1e28),
                    ),
                    child: item.albumArt != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(item.albumArt!, fit: BoxFit.cover),
                        )
                      : const Icon(Icons.music_note_rounded,
                          color: Color(0xFF7c5cfc), size: 20),
                  ),
                  const SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: Color(0xFFf0eeff))),
                        Text(item.displayArtist,
                          style: const TextStyle(
                            fontSize: 11, color: Color(0xFF9a94b4))),
                      ],
                    ),
                  ),
                  // Controls
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded),
                    color: const Color(0xFFf0eeff),
                    iconSize: 24,
                    onPressed: player.prev,
                  ),
                  IconButton(
                    icon: Icon(player.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded),
                    color: const Color(0xFFf0eeff),
                    iconSize: 28,
                    onPressed: player.togglePlay,
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded),
                    color: const Color(0xFFf0eeff),
                    iconSize: 24,
                    onPressed: player.next,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
