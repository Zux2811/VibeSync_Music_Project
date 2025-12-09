# Player Widgets Documentation

## Overview
Các widget con của Music Player, mỗi widget có trách nhiệm riêng biệt.

---

## 1. PlayerControls Widget

### Purpose
Hiển thị các nút điều khiển phát lại (Play/Pause, Next, Previous, Shuffle, Repeat).

### Props
```dart
PlayerControls(
  provider: PlayerProvider,           // State provider
  onPlayPause: VoidCallback,          // Play/Pause callback
  onNext: VoidCallback,               // Next track callback
  onPrevious: VoidCallback,           // Previous track callback
  onShuffle: VoidCallback,            // Shuffle toggle callback
  onRepeat: VoidCallback,             // Repeat mode toggle callback
)
```

### Features
- Shuffle button (top left) - Grey/Cyan
- Repeat button (top right) - Grey/Cyan
- Previous button (bottom left)
- Play/Pause button (center) - Gradient background
- Next button (bottom right)
- Tooltips for each button
- Color feedback based on state

### Example
```dart
PlayerControls(
  provider: provider,
  onPlayPause: () => provider.togglePlayPause(),
  onNext: () => provider.nextTrack(),
  onPrevious: () => provider.previousTrack(),
  onShuffle: () => provider.toggleShuffle(),
  onRepeat: () => provider.toggleRepeatMode(),
)
```

---

## 2. ProgressSlider Widget

### Purpose
Hiển thị thanh tiến trình phát lại với thời gian hiện tại và tổng thời lượng.

### Props
```dart
ProgressSlider(
  currentPosition: Duration,          // Current playback position
  totalDuration: Duration,            // Total song duration
  onChanged: ValueChanged<Duration>,  // Position changed callback
  onChangeStart: VoidCallback?,       // Drag start callback
  onChangeEnd: VoidCallback?,         // Drag end callback
)
```

### Features
- Draggable slider
- Current time display (MM:SS or HH:MM:SS)
- Total duration display
- Smooth animations
- Custom styling (cyan color)
- Thumb with shadow
- Overlay on drag

### Example
```dart
ProgressSlider(
  currentPosition: provider.state.currentPosition,
  totalDuration: provider.currentSong?.duration ?? Duration.zero,
  onChanged: (position) => provider.updatePosition(position),
  onChangeStart: () => print('Drag started'),
  onChangeEnd: () => print('Drag ended'),
)
```

---

## 3. SongInfo Widget

### Purpose
Hiển thị thông tin bài hát (album art, tiêu đề, nghệ sĩ, nút yêu thích).

### Props
```dart
SongInfo(
  song: Song?,                        // Current song
  isFavorite: bool,                   // Is favorite flag
  onFavoritePressed: VoidCallback,    // Favorite button callback
)
```

### Features
- Album art (280x280) with shadow
- Song title (max 2 lines)
- Artist name (max 1 line)
- Album name (if available)
- Favorite button with animation
- Placeholder for missing images
- Network image error handling

### Example
```dart
SongInfo(
  song: provider.currentSong,
  isFavorite: provider.isFavorite,
  onFavoritePressed: () => provider.toggleFavorite(),
)
```

---

## 4. PlayerMenu Widget

### Purpose
Hiển thị menu tùy chọn (3 chấm) với các tùy chọn: Playlist, Artist, Download, Share.

### Props
```dart
PlayerMenu(
  onAddToPlaylist: VoidCallback,      // Add to playlist callback
  onViewArtist: VoidCallback,         // View artist callback
  onDownload: VoidCallback,           // Download callback
  onShare: VoidCallback,              // Share callback
)
```

### Features
- Popup menu button (3 dots icon)
- 4 menu items with icons
- Custom styling (dark background)
- Cyan accent color
- Smooth animations

### Menu Items
1. **Add to Playlist** - Add current song to playlist
2. **View Artist** - Show artist information
3. **Download** - Download song for offline
4. **Share** - Share song with others

### Example
```dart
PlayerMenu(
  onAddToPlaylist: () => showPlaylistSelector(),
  onViewArtist: () => showArtistInfo(),
  onDownload: () => downloadSong(),
  onShare: () => shareSong(),
)
```

---

## 5. PlaylistSelectorBottomSheet Widget

### Purpose
Hiển thị danh sách playlist để chọn, hoặc tạo playlist mới.

### Props
```dart
PlaylistSelectorBottomSheet(
  onPlaylistSelected: Function(int),  // Playlist ID callback
)
```

### Features
- List of existing playlists
- Song count for each playlist
- "Create New Playlist" button
- Create playlist dialog
- Success snackbar notification
- Smooth bottom sheet animation

### Playlists (Mock Data)
```dart
[
  {'id': 1, 'name': 'My Favorites', 'songCount': 25},
  {'id': 2, 'name': 'Workout Mix', 'songCount': 18},
  {'id': 3, 'name': 'Chill Vibes', 'songCount': 42},
  {'id': 4, 'name': 'Party Hits', 'songCount': 35},
]
```

### Example
```dart
showModalBottomSheet(
  context: context,
  backgroundColor: Colors.transparent,
  builder: (context) => PlaylistSelectorBottomSheet(
    onPlaylistSelected: (playlistId) {
      provider.addToPlaylist(playlistId);
    },
  ),
)
```

---

## 6. ArtistInfoBottomSheet Widget

### Purpose
Hiển thị thông tin chi tiết về nghệ sĩ (avatar, bio, stats, actions).

### Props
```dart
ArtistInfoBottomSheet(
  artistName: String,                 // Artist name
  onClose: VoidCallback,              // Close callback
)
```

### Features
- Artist avatar (circular with border)
- Artist name
- Bio/description
- Statistics (Followers, Songs, Albums)
- "Play All Songs" button
- "Follow Artist" button
- Smooth bottom sheet animation

### Stats Display
```dart
1.2M Followers
45 Songs
8 Albums
```

### Example
```dart
showModalBottomSheet(
  context: context,
  backgroundColor: Colors.transparent,
  builder: (context) => ArtistInfoBottomSheet(
    artistName: provider.currentSong!.artist,
    onClose: () => Navigator.pop(context),
  ),
)
```

---

## Widget Composition

```
PlayerPage
├── AppBar
│   └── PlayerMenu
├── SongInfo
│   └── Album Art (Rotating)
├── ProgressSlider
├── PlayerControls
│   ├── Shuffle Button
│   ├── Repeat Button
│   ├── Previous Button
│   ├── Play/Pause Button (Gradient)
│   └── Next Button
└── Queue Info
```

---

## Styling Guide

### Colors
- **Primary**: `Colors.cyan` (#00BCD4)
- **Background**: `Colors.grey[900]` (#121212)
- **Text**: `Colors.white` (#FFFFFF)
- **Secondary Text**: `Colors.grey[400]` (#BDBDBD)
- **Disabled**: `Colors.grey[600]` (#424242)

### Spacing
- **Large**: 32px
- **Medium**: 16px
- **Small**: 8px
- **Tiny**: 4px

### Border Radius
- **Large**: 16px
- **Medium**: 12px
- **Small**: 8px
- **Tiny**: 4px

### Shadows
- **Album Art**: `BoxShadow(color: black.withOpacity(0.3), blur: 20)`
- **Buttons**: Subtle shadows on hover

---

## Animation Durations

- **Album Rotation**: 20 seconds (full rotation)
- **Favorite Scale**: 300ms
- **Slider Drag**: Smooth (no fixed duration)
- **Bottom Sheet**: Default Flutter animation

---

## Error Handling

Each widget handles:
- Null values gracefully
- Network image errors
- Missing data with placeholders
- User interactions with feedback

---

## Accessibility

- All buttons have tooltips
- High contrast colors
- Semantic labels
- Keyboard navigation support

---

## Performance Tips

1. Use `Consumer` for selective rebuilds
2. Memoize callbacks with `useCallback` equivalent
3. Lazy load images
4. Dispose animations properly
5. Use `const` constructors where possible

---

## Testing

Each widget can be tested independently:

```dart
testWidgets('PlayerControls renders correctly', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PlayerControls(
          provider: mockProvider,
          onPlayPause: () {},
          onNext: () {},
          onPrevious: () {},
          onShuffle: () {},
          onRepeat: () {},
        ),
      ),
    ),
  );

  expect(find.byIcon(Icons.play_arrow), findsOneWidget);
});
```

