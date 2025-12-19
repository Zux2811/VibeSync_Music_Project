// lib/presentation/player/player_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart' as ja;
import '../../data/models/player_state_model.dart';
import '../../data/repositories/player_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class PlayerProvider extends ChangeNotifier {
  final PlayerRepository _repository = PlayerRepository();

  // Primary audio engine
  final ja.AudioPlayer _player = ja.AudioPlayer();

  // Secondary audio player for AutoMix crossfade
  ja.AudioPlayer? _nextPlayer;

  // AutoMix crossfade state
  Timer? _crossfadeTimer;
  bool _isCrossfading = false;
  static const String _autoMixKey = 'auto_mix_enabled';
  static const String _crossfadeDurationKey = 'crossfade_duration';

  PlayerState _state = PlayerState();

  PlayerState get state => _state;
  Song? get currentSong => _state.currentSong;
  bool get isPlaying => _state.isPlaying;
  bool get isFavorite => _state.isCurrentSongFavorite;
  RepeatMode get repeatMode => _state.repeatMode;
  bool get isShuffle => _state.isShuffle;
  bool get isAutoMixEnabled => _state.isAutoMixEnabled;
  int get crossfadeDuration => _state.crossfadeDurationSeconds;

  PlayerProvider() {
    _attachPlayerListeners();
    _loadAutoMixSettings();
  }

  /// Load AutoMix settings from SharedPreferences
  Future<void> _loadAutoMixSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_autoMixKey) ?? false;
    final duration = prefs.getInt(_crossfadeDurationKey) ?? 8;
    _updateState(
      _state.copyWith(
        isAutoMixEnabled: enabled,
        crossfadeDurationSeconds: duration,
      ),
    );
  }

  /// Save AutoMix settings to SharedPreferences
  Future<void> _saveAutoMixSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoMixKey, _state.isAutoMixEnabled);
    await prefs.setInt(_crossfadeDurationKey, _state.crossfadeDurationSeconds);
  }

  /// Toggle AutoMix on/off
  Future<void> toggleAutoMix() async {
    final newValue = !_state.isAutoMixEnabled;
    _updateState(_state.copyWith(isAutoMixEnabled: newValue));
    await _saveAutoMixSettings();

    if (!newValue) {
      // Cancel any ongoing crossfade when disabling
      _cancelCrossfade();
    }
  }

  /// Set crossfade duration (in seconds, 3-15 range recommended)
  Future<void> setCrossfadeDuration(int seconds) async {
    final clamped = seconds.clamp(3, 15);
    _updateState(_state.copyWith(crossfadeDurationSeconds: clamped));
    await _saveAutoMixSettings();
  }

  /// Cancel ongoing crossfade
  void _cancelCrossfade() {
    _crossfadeTimer?.cancel();
    _crossfadeTimer = null;
    _isCrossfading = false;
    _nextPlayer?.dispose();
    _nextPlayer = null;
    _player.setVolume(1.0);
    _updateState(_state.copyWith(isCrossfading: false));
  }

  /// Check if we should start crossfade based on current position
  void _checkAutoMixTrigger(Duration position) {
    if (!_state.isAutoMixEnabled || _isCrossfading) return;
    if (_state.totalDuration == Duration.zero) return;
    if (_state.playlist.length <= 1) return;
    if (!_state.isPlaying) return;

    // Calculate remaining time
    final remaining = _state.totalDuration - position;
    final crossfadeDur = Duration(seconds: _state.crossfadeDurationSeconds);

    // Buffer to prevent triggering too early or too late
    const minRemaining = Duration(milliseconds: 500);

    // Start crossfade when remaining time is within crossfade duration window
    if (remaining <= crossfadeDur && remaining > minRemaining) {
      debugPrint('AutoMix: Triggering crossfade. Remaining: $remaining');
      _startCrossfade();
    }
  }

  /// Get the next track index based on current mode
  int _getNextIndex() {
    if (_state.playlist.isEmpty) return 0;

    if (_state.isShuffle) {
      final r = Random();
      int nextIdx;
      do {
        nextIdx = r.nextInt(_state.playlist.length);
      } while (nextIdx == _state.currentIndex && _state.playlist.length > 1);
      return nextIdx;
    }

    int nextIndex = _state.currentIndex + 1;
    if (nextIndex >= _state.playlist.length) {
      if (_state.repeatMode == RepeatMode.repeatAll) {
        nextIndex = 0;
      } else {
        return -1; // No next track
      }
    }
    return nextIndex;
  }

  /// Start the crossfade transition
  Future<void> _startCrossfade() async {
    if (_isCrossfading) return;
    if (!_state.isPlaying) return;

    final nextIndex = _getNextIndex();
    if (nextIndex < 0) {
      debugPrint('AutoMix: No next track available');
      return;
    }

    _isCrossfading = true;
    _updateState(_state.copyWith(isCrossfading: true));

    // Get next song
    final nextSong = _state.playlist[nextIndex];
    debugPrint('AutoMix: Starting crossfade to "${nextSong.title}"');

    // Create and prepare next player
    _nextPlayer?.dispose();
    _nextPlayer = ja.AudioPlayer();

    try {
      await _nextPlayer!.setUrl(nextSong.audioUrl);
      await _nextPlayer!.setVolume(0.0);
      await _nextPlayer!.play();
    } catch (e) {
      debugPrint('AutoMix: Failed to prepare next track: $e');
      _cancelCrossfade();
      return;
    }

    // Calculate crossfade parameters
    final crossfadeMs = _state.crossfadeDurationSeconds * 1000;
    const tickMs = 100; // Update every 100ms for smooth transition
    final totalTicks = crossfadeMs ~/ tickMs;
    int currentTick = 0;

    // Store start position of next player for syncing later
    Duration nextPlayerStartPosition = Duration.zero;

    // Start crossfade timer
    _crossfadeTimer?.cancel();
    _crossfadeTimer = Timer.periodic(const Duration(milliseconds: tickMs), (
      timer,
    ) async {
      if (!_isCrossfading) {
        timer.cancel();
        return;
      }

      currentTick++;

      // Calculate volumes using ease curve
      final progress = (currentTick / totalTicks).clamp(0.0, 1.0);
      final easeProgress = _easeInOutCubic(progress);

      final currentVolume = (1.0 - easeProgress).clamp(0.0, 1.0);
      final nextVolume = easeProgress.clamp(0.0, 1.0);

      try {
        await _player.setVolume(currentVolume);
        await _nextPlayer?.setVolume(nextVolume);
      } catch (e) {
        debugPrint('AutoMix: Volume adjustment error: $e');
      }

      // Crossfade complete
      if (currentTick >= totalTicks) {
        timer.cancel();
        nextPlayerStartPosition = _nextPlayer?.position ?? Duration.zero;
        await _completeCrossfade(nextIndex, nextPlayerStartPosition);
      }
    });
  }

  /// Easing function for smooth volume transitions
  double _easeInOutCubic(double t) {
    return t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2;
  }

  /// Complete the crossfade and swap players
  Future<void> _completeCrossfade(int nextIndex, Duration syncPosition) async {
    try {
      // Stop the current track on main player
      await _player.pause();

      // Reset main player volume
      await _player.setVolume(1.0);

      // Seek main player to the next track
      await _player.seek(syncPosition, index: nextIndex);

      // Start playing from synced position
      await _player.play();

      // Update state to the new track
      _updateState(
        _state.copyWith(
          currentIndex: nextIndex,
          currentPosition: syncPosition,
          isCrossfading: false,
          playbackState: PlaybackState.playing,
        ),
      );
    } catch (e) {
      debugPrint('AutoMix: Complete crossfade error: $e');
    } finally {
      // Clean up next player
      try {
        await _nextPlayer?.stop();
        await _nextPlayer?.dispose();
      } catch (e) {
        debugPrint('AutoMix: Cleanup error: $e');
      }
      _nextPlayer = null;
      _isCrossfading = false;
      _crossfadeTimer = null;
    }
  }

  void _attachPlayerListeners() {
    // Position updates - also check for AutoMix trigger
    _player.positionStream.listen((pos) {
      _updateState(_state.copyWith(currentPosition: pos));
      _checkAutoMixTrigger(pos);
    });

    // Duration updates
    _player.durationStream.listen((dur) {
      if (dur != null) {
        _updateState(_state.copyWith(totalDuration: dur));
      }
    });

    // Play/pause state
    _player.playerStateStream.listen((st) {
      final playing = st.playing;
      _updateState(
        _state.copyWith(
          playbackState: playing ? PlaybackState.playing : PlaybackState.paused,
        ),
      );
    });

    // Index changes (when skipping)
    _player.currentIndexStream.listen((idx) {
      if (idx != null && idx >= 0 && idx < _state.playlist.length) {
        _updateState(
          _state.copyWith(currentIndex: idx, currentPosition: Duration.zero),
        );
      }
    });
  }

  // Khởi tạo, nạp danh sách bài hát và set vào audio engine (không tự động phát)
  Future<void> initializePlaylist() async {
    _updateState(_state.copyWith(isLoading: true));
    try {
      final songs = await _repository.getSongs();
      final favorites = await _repository.getFavorites();

      _updateState(
        _state.copyWith(
          playlist: songs,
          favorites: Set<int>.from(favorites),
          isLoading: false,
        ),
      );

      if (songs.isNotEmpty) {
        final sources =
            songs
                .map((s) => ja.AudioSource.uri(Uri.parse(s.audioUrl)))
                .toList();
        await _player.setAudioSource(
          ja.ConcatenatingAudioSource(children: sources),
          initialIndex: 0,
          initialPosition: Duration.zero,
        );
        _updateState(_state.copyWith(currentIndex: 0));
      }
    } catch (e) {
      _updateState(
        _state.copyWith(isLoading: false, errorMessage: e.toString()),
      );
    }
  }

  // Phát/Tạm dừng
  void togglePlayPause() {
    if (_player.playing) {
      _player.pause();
      _updateState(_state.copyWith(playbackState: PlaybackState.paused));
    } else {
      _player.play();
      _updateState(_state.copyWith(playbackState: PlaybackState.playing));
    }
  }

  // Giới hạn chuyển bài cho tier Free: tối đa 6 lần/12 giờ
  static const int _skipWindowMillis = 12 * 60 * 60 * 1000; // 12h
  static const String _skipCountKey = 'skip_count_12h';
  static const String _skipWindowStartKey = 'skip_window_start_ms';

  Future<bool> tryNextTrack({required bool isPro}) async {
    if (isPro) {
      await _player.seekToNext();
      return true;
    }
    final ok = await _consumeSkipToken();
    if (!ok) return false;

    if (_state.isShuffle && _state.playlist.isNotEmpty) {
      // Free tier: random jump (can cause duplicates)
      final r = Random();
      final idx = r.nextInt(_state.playlist.length);
      await _player.seek(Duration.zero, index: idx);
      await _player.play();
    } else {
      await _player.seekToNext();
    }
    return true;
  }

  Future<bool> tryPreviousTrack({required bool isPro}) async {
    if (isPro) {
      await _player.seekToPrevious();
      return true;
    }
    final ok = await _consumeSkipToken();
    if (!ok) return false;

    if (_state.isShuffle && _state.playlist.isNotEmpty) {
      final r = Random();
      final idx = r.nextInt(_state.playlist.length);
      await _player.seek(Duration.zero, index: idx);
      await _player.play();
    } else {
      await _player.seekToPrevious();
    }
    return true;
  }

  Future<bool> _consumeSkipToken() async {
    final sp = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    int start = sp.getInt(_skipWindowStartKey) ?? 0;
    int count = sp.getInt(_skipCountKey) ?? 0;

    if (start == 0 || now - start > _skipWindowMillis) {
      // Reset window
      start = now;
      count = 0;
    }

    if (count >= 6) {
      // out of tokens in window
      await sp.setInt(_skipWindowStartKey, start);
      await sp.setInt(_skipCountKey, count);
      return false;
    }

    count += 1;
    await sp.setInt(_skipWindowStartKey, start);
    await sp.setInt(_skipCountKey, count);
    return true;
  }

  // Chuyển đổi chế độ Shuffle
  Future<void> toggleShuffle() async {
    final enabled = !_state.isShuffle;
    await _player.setShuffleModeEnabled(enabled);
    _updateState(_state.copyWith(isShuffle: enabled));
  }

  // Chuyển đổi chế độ Repeat (map sang LoopMode của just_audio)
  Future<void> toggleRepeatMode() async {
    final nextMode =
        _state.repeatMode == RepeatMode.noRepeat
            ? RepeatMode.repeatAll
            : _state.repeatMode == RepeatMode.repeatAll
            ? RepeatMode.repeatOne
            : RepeatMode.noRepeat;

    final loop =
        nextMode == RepeatMode.noRepeat
            ? ja.LoopMode.off
            : nextMode == RepeatMode.repeatAll
            ? ja.LoopMode.all
            : ja.LoopMode.one;
    await _player.setLoopMode(loop);

    _updateState(_state.copyWith(repeatMode: nextMode));
  }

  /// Cycle through play modes: Normal -> Shuffle -> RepeatOne -> RepeatAll -> Normal
  Future<void> cyclePlayMode() async {
    final currentMode = _state.playMode;

    switch (currentMode) {
      case PlayMode.normal:
        // Switch to shuffle
        await _player.setShuffleModeEnabled(true);
        await _player.setLoopMode(ja.LoopMode.off);
        _updateState(
          _state.copyWith(isShuffle: true, repeatMode: RepeatMode.noRepeat),
        );
        break;

      case PlayMode.shuffle:
        // Switch to repeat one
        await _player.setShuffleModeEnabled(false);
        await _player.setLoopMode(ja.LoopMode.one);
        _updateState(
          _state.copyWith(isShuffle: false, repeatMode: RepeatMode.repeatOne),
        );
        break;

      case PlayMode.repeatOne:
        // Switch to repeat all
        await _player.setLoopMode(ja.LoopMode.all);
        _updateState(_state.copyWith(repeatMode: RepeatMode.repeatAll));
        break;

      case PlayMode.repeatAll:
        // Switch back to normal
        await _player.setLoopMode(ja.LoopMode.off);
        _updateState(_state.copyWith(repeatMode: RepeatMode.noRepeat));
        break;
    }
  }

  /// Get current play mode
  PlayMode get playMode => _state.playMode;

  /// Set player volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    final clampedVolume = volume.clamp(0.0, 1.0);
    await _player.setVolume(clampedVolume);
  }

  /// Get current volume
  double get volume => _player.volume;

  // Cập nhật vị trí phát
  void updatePosition(Duration position) {
    _player.seek(position);
    _updateState(_state.copyWith(currentPosition: position));
  }

  // Chuyển đến bài hát cụ thể
  Future<void> playTrackAtIndex(int index) async {
    if (index >= 0 && index < _state.playlist.length) {
      await _player.seek(Duration.zero, index: index);
      await _player.play();
      _updateState(
        _state.copyWith(
          currentIndex: index,
          currentPosition: Duration.zero,
          playbackState: PlaybackState.playing,
        ),
      );
    }
  }

  // Thêm/Xóa yêu thích
  Future<void> toggleFavorite() async {
    if (_state.currentSong == null) return;

    try {
      final songId = _state.currentSong!.id;
      final isFavorite = _state.isCurrentSongFavorite;

      if (isFavorite) {
        await _repository.removeFromFavorites(songId);
      } else {
        await _repository.addToFavorites(songId);
      }

      final newFavorites = Set<int>.from(_state.favorites);
      if (isFavorite) {
        newFavorites.remove(songId);
      } else {
        newFavorites.add(songId);
      }

      _updateState(_state.copyWith(favorites: newFavorites));
    } catch (e) {
      _updateState(_state.copyWith(errorMessage: e.toString()));
    }
  }

  // Thêm vào playlist
  Future<bool> addToPlaylist(int playlistId) async {
    if (_state.currentSong == null) return false;

    try {
      await _repository.addToPlaylist(playlistId, _state.currentSong!.id);
      return true;
    } catch (e) {
      _updateState(_state.copyWith(errorMessage: e.toString()));
      return false;
    }
  }

  // Tải xuống bài hát. Trả về true nếu thành công.
  Future<bool> downloadCurrentSong() async {
    if (_state.currentSong == null) return false;

    try {
      final ok = await _repository.downloadSong(_state.currentSong!);
      return ok;
    } catch (e) {
      _updateState(_state.copyWith(errorMessage: e.toString()));
      return false;
    }
  }

  // Lấy thông tin nghệ sĩ
  Future<Map<String, dynamic>> getArtistInfo() async {
    if (_state.currentSong == null) {
      return {};
    }

    try {
      return await _repository.getArtistInfo(_state.currentSong!.artist);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Thiết lập playlist và phát bài hát chỉ định
  Future<void> setPlaylistAndPlay(
    List<Song> playlist, {
    Song? currentSong,
    int? index,
  }) async {
    // 1. Xác định index chính xác
    int playIndex = index ?? 0;
    if (currentSong != null) {
      final idx = playlist.indexWhere((s) => s.id == currentSong.id);
      if (idx != -1) {
        playIndex = idx;
      }
    }

    // 2. Cập nhật state một lần duy nhất để tránh race condition
    _updateState(
      _state.copyWith(
        playlist: playlist,
        currentIndex: playIndex,
        currentPosition: Duration.zero,
        playbackState: PlaybackState.playing,
      ),
    );

    // 3. Thiết lập AudioSource MỚI cho trình phát
    // Luôn set lại source để đảm bảo trình phát và state luôn đồng bộ
    final sources =
        playlist.map((s) => ja.AudioSource.uri(Uri.parse(s.audioUrl))).toList();

    await _player.setAudioSource(
      ja.ConcatenatingAudioSource(children: sources),
      initialIndex: playIndex,
      initialPosition: Duration.zero,
    );

    // 4. Bắt đầu phát
    await _player.play();
  }

  // Phát 1 bài cụ thể (giữ nguyên playlist hiện tại, nếu không tồn tại thì thêm vào cuối)
  Future<void> playSong(Song song) async {
    final list = List<Song>.from(_state.playlist);
    int idx = list.indexWhere((s) => s.id == song.id);
    if (idx == -1) {
      list.add(song);
      idx = list.length - 1;
    }
    await setPlaylistAndPlay(list, index: idx);
  }

  @override
  void dispose() {
    _cancelCrossfade();
    _player.dispose();
    super.dispose();
  }

  void _updateState(PlayerState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Clears the current error message from the player state.
  ///
  /// The `errorMessage` field is intended to be consumed once and then cleared.
  /// UI widgets that display errors should:
  /// 1. Subscribe to this provider
  /// 2. Check if `state.errorMessage` is not null
  /// 3. Display the error to the user (e.g., in a SnackBar)
  /// 4. Call `clearError()` immediately after displaying
  ///
  /// This ensures each error is shown exactly once and prevents stale error
  /// messages from persisting across multiple rebuilds.
  void clearError() {
    _updateState(_state.copyWith(errorMessage: null));
  }
}
