import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../data/repositories/download_repository.dart';
import '../../../../../data/models/player_state_model.dart';
import '../../../../player/player_provider.dart';

class DownloadedSongsPage extends StatefulWidget {
  const DownloadedSongsPage({super.key});

  @override
  State<DownloadedSongsPage> createState() => _DownloadedSongsPageState();
}

class _DownloadedSongsPageState extends State<DownloadedSongsPage> {
  List<Song> _songs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await DownloadRepository.getDownloadedSongs();
    if (!mounted) return;
    setState(() {
      _songs = items;
      _loading = false;
    });
  }

  Future<void> _remove(int songId) async {
    final ok = await DownloadRepository.removeDownloaded(songId);
    if (!mounted) return;
    if (ok) {
      setState(() {
        _songs.removeWhere((s) => s.id == songId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa khỏi tải xuống')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa thất bại')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nhạc đã tải')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _songs.isEmpty
              ? const Center(child: Text('Chưa có bài hát nào được tải'))
              : ListView.separated(
                  itemCount: _songs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final song = _songs[index];
                    final isFile = song.audioUrl.startsWith('file://');
                    return ListTile(
                      leading: _buildCover(song),
                      title: Text(song.title),
                      subtitle: Text(song.artist),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Xóa',
                        onPressed: () => _remove(song.id),
                      ),
                      onTap: () async {
                        // Phát từ danh sách tải xuống
                        await context.read<PlayerProvider>().setPlaylistAndPlay(
                              _songs,
                              index: index,
                            );
                      },
                    );
                  },
                ),
    );
  }

  Widget _buildCover(Song song) {
    final url = song.imageUrl;
    if (url == null || url.isEmpty) return const Icon(Icons.music_note);
    // Hiển thị ảnh từ local hoặc network
    if (!url.startsWith('http') && !url.startsWith('assets')) {
      final f = File(url);
      return Image.file(
        f,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.music_note),
      );
    }
    if (url.startsWith('http')) {
      return Image.network(
        url,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.music_note),
      );
    }
    return Image.asset(
      url,
      width: 48,
      height: 48,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Icon(Icons.music_note),
    );
  }
}

