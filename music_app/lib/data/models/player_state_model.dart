// lib/data/models/player_state_model.dart

enum RepeatMode {
  noRepeat, // Không lặp lại
  repeatAll, // Lặp lại tất cả
  repeatOne, // Lặp lại một bài
}

enum PlaybackState { playing, paused, stopped, loading }

class Song {
  final int id;
  final String title;
  final String artist;
  final String audioUrl;
  final String? imageUrl;
  final String? album;
  final Duration duration;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.audioUrl,
    this.imageUrl,
    this.album,
    required this.duration,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Unknown',
      artist: json['artist'] ?? 'Unknown Artist',
      audioUrl: json['audioUrl'] ?? '',
      imageUrl: json['imageUrl'],
      album: json['album'],
      duration: Duration(seconds: json['duration'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'audioUrl': audioUrl,
    'imageUrl': imageUrl,
    'album': album,
    'duration': duration.inSeconds,
  };
}

class PlayerState {
  final List<Song> playlist;
  final int currentIndex;
  final PlaybackState playbackState;
  final Duration currentPosition;
  final Duration totalDuration;
  final RepeatMode repeatMode;
  final bool isShuffle;
  final Set<int> favorites;
  final bool isLoading;
  final String? errorMessage;

  PlayerState({
    this.playlist = const [],
    this.currentIndex = 0,
    this.playbackState = PlaybackState.stopped,
    this.currentPosition = Duration.zero,
    this.totalDuration = Duration.zero,
    this.repeatMode = RepeatMode.noRepeat,
    this.isShuffle = false,
    this.favorites = const {},
    this.isLoading = false,
    this.errorMessage,
  });

  Song? get currentSong =>
      currentIndex >= 0 && currentIndex < playlist.length
          ? playlist[currentIndex]
          : null;

  bool get isCurrentSongFavorite =>
      currentSong != null && favorites.contains(currentSong!.id);

  bool get isPlaying => playbackState == PlaybackState.playing;

  PlayerState copyWith({
    List<Song>? playlist,
    int? currentIndex,
    PlaybackState? playbackState,
    Duration? currentPosition,
    Duration? totalDuration,
    RepeatMode? repeatMode,
    bool? isShuffle,
    Set<int>? favorites,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PlayerState(
      playlist: playlist ?? this.playlist,
      currentIndex: currentIndex ?? this.currentIndex,
      playbackState: playbackState ?? this.playbackState,
      currentPosition: currentPosition ?? this.currentPosition,
      totalDuration: totalDuration ?? this.totalDuration,
      repeatMode: repeatMode ?? this.repeatMode,
      isShuffle: isShuffle ?? this.isShuffle,
      favorites: favorites ?? this.favorites,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
