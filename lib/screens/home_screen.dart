import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/player_service.dart';
import '../services/file_scanner.dart';
import '../models/media_item.dart';
import '../widgets/mini_player.dart';
import 'player_screen.dart';
import 'video_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<MediaItem> _all = [];
  List<MediaItem> _filtered = [];
  bool _scanning = false;
  int _scanCount = 0;
  String _search = '';
  int _tab = 0; // 0=all 1=music 2=video

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() { _tab = _tabController.index; });
      _applyFilter();
    });
    _startScan();
  }

  Future<void> _startScan() async {
    setState(() { _scanning = true; _scanCount = 0; });
    final items = await FileScanner.scanAll(onProgress: (n) {
      setState(() => _scanCount = n);
    });
    setState(() {
      _all = items;
      _scanning = false;
      _applyFilter();
    });
    context.read<PlayerService>().setPlaylist(items);
  }

  void _applyFilter() {
    List<MediaItem> base;
    if (_tab == 1) base = _all.where((f) => f.type == MediaType.audio).toList();
    else if (_tab == 2) base = _all.where((f) => f.type == MediaType.video).toList();
    else base = _all;

    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      base = base.where((f) =>
        f.name.toLowerCase().contains(q) ||
        (f.artist?.toLowerCase().contains(q) ?? false)
      ).toList();
    }
    setState(() => _filtered = base);
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();

    return Scaffold(
      backgroundColor: const Color(0xFF0e0e12),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildTabs(),
            _buildSearch(),
            Expanded(
              child: _scanning && _all.isEmpty
                ? _buildScanning()
                : _filtered.isEmpty
                  ? _buildEmpty()
                  : _buildList(player),
            ),
            if (player.currentItem != null && player.currentItem!.type == MediaType.audio)
              MiniPlayer(
                onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PlayerScreen())),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [Color(0xFFf0eeff), Color(0xFFa78bfa)],
            ).createShader(b),
            child: const Text('Visha Player',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700,
                color: Colors.white, letterSpacing: -0.5)),
          ),
          const Spacer(),
          if (_scanning)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text('$_scanCount found',
                style: const TextStyle(fontSize: 12, color: Color(0xFF9a94b4))),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF9a94b4)),
            onPressed: _startScan,
            tooltip: 'Rescan',
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF16161d),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF7c5cfc).withOpacity(0.15)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF1e1e28),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF7c5cfc).withOpacity(0.3)),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(3),
        labelColor: const Color(0xFFa78bfa),
        unselectedLabelColor: const Color(0xFF5a5470),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Music'),
          Tab(text: 'Video'),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1e1e28),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF7c5cfc).withOpacity(0.15)),
        ),
        child: TextField(
          onChanged: (v) { _search = v; _applyFilter(); },
          style: const TextStyle(fontSize: 14, color: Color(0xFFf0eeff)),
          decoration: const InputDecoration(
            hintText: 'Search files…',
            hintStyle: TextStyle(color: Color(0xFF5a5470), fontSize: 14),
            prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF5a5470), size: 20),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildScanning() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF7c5cfc)),
          const SizedBox(height: 20),
          Text('Scanning… $_scanCount files found',
            style: const TextStyle(color: Color(0xFF9a94b4), fontSize: 14)),
          const SizedBox(height: 8),
          const Text('Reading directly from storage',
            style: TextStyle(color: Color(0xFF5a5470), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_off_rounded, size: 64,
            color: const Color(0xFF5a5470).withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('No files found',
            style: TextStyle(color: Color(0xFF9a94b4), fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Pull down to rescan',
            style: TextStyle(color: Color(0xFF5a5470), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildList(PlayerService player) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: _filtered.length,
      itemBuilder: (ctx, i) {
        final item = _filtered[i];
        final isPlaying = player.currentItem?.path == item.path;
        return _MediaTile(
          item: item,
          isPlaying: isPlaying,
          isAudioPlaying: isPlaying && player.isPlaying,
          onTap: () {
            final idx = _all.indexOf(item);
            if (item.type == MediaType.video) {
              Navigator.push(ctx, MaterialPageRoute(
                builder: (_) => VideoScreen(items: _filtered
                  .where((f) => f.type == MediaType.video).toList(),
                  startIndex: _filtered
                    .where((f) => f.type == MediaType.video)
                    .toList().indexOf(item)),
              ));
            } else {
              player.setPlaylist(_all);
              player.playAt(idx);
              Navigator.push(ctx, MaterialPageRoute(
                builder: (_) => const PlayerScreen()));
            }
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class _MediaTile extends StatelessWidget {
  final MediaItem item;
  final bool isPlaying;
  final bool isAudioPlaying;
  final VoidCallback onTap;

  const _MediaTile({
    required this.item,
    required this.isPlaying,
    required this.isAudioPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isPlaying ? const Color(0xFF1e1e28) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isPlaying
          ? Border.all(color: const Color(0xFF7c5cfc).withOpacity(0.3))
          : null,
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFF1e1e28),
            borderRadius: BorderRadius.circular(10),
          ),
          child: item.albumArt != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(item.albumArt!, fit: BoxFit.cover),
              )
            : Icon(
                item.type == MediaType.video
                  ? Icons.movie_rounded
                  : Icons.music_note_rounded,
                color: const Color(0xFF7c5cfc).withOpacity(0.5),
                size: 22,
              ),
        ),
        title: Text(item.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isPlaying ? const Color(0xFFa78bfa) : const Color(0xFFf0eeff),
          ),
        ),
        subtitle: Text(
          '${item.displayArtist} · ${item.formattedSize}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: Color(0xFF9a94b4)),
        ),
        trailing: isAudioPlaying
          ? const _PlayingBars()
          : Text(item.formattedDuration,
              style: const TextStyle(fontSize: 11, color: Color(0xFF5a5470))),
      ),
    );
  }
}

class _PlayingBars extends StatefulWidget {
  const _PlayingBars();
  @override
  State<_PlayingBars> createState() => _PlayingBarsState();
}

class _PlayingBarsState extends State<_PlayingBars> with TickerProviderStateMixin {
  late List<AnimationController> _ctrls;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(3, (i) {
      final c = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 400 + i * 150),
      )..repeat(reverse: true);
      return c;
    });
  }

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(3, (i) => AnimatedBuilder(
          animation: _ctrls[i],
          builder: (_, __) => Container(
            width: 4,
            height: 4 + _ctrls[i].value * 12,
            decoration: BoxDecoration(
              color: const Color(0xFF7c5cfc),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        )),
      ),
    );
  }
}
