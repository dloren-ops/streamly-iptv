# IPTV Player - Lightweight & Fast

A beautiful, lightweight IPTV player built with Flutter. Works on Android, iOS, Android TV, Web, Windows, Mac, and Linux.

## Architecture (Clean Layers)

```
lib/
├── main.dart              → Entry point
├── models/                → DOMAIN LAYER (Data structures)
│   ├── channel.dart       → Channel model
│   └── category.dart      → Category model
├── services/              → DATA LAYER (External connections)
│   ├── m3u_parser.dart    → Efficient M3U file parser
│   ├── playlist_service.dart → Playlist loading & caching
│   └── storage_service.dart  → Local persistence (Hive)
├── providers/             → LOGIC LAYER (State management)
│   └── channel_provider.dart → App state & business logic
├── screens/               → PRESENTATION LAYER (Pages)
│   ├── main_navigation.dart  → Tab navigation
│   ├── home_screen.dart      → Channel list
│   ├── player_screen.dart    → Video player
│   ├── favorites_screen.dart → Favorites
│   ├── add_playlist_screen.dart → Add M3U playlist
│   └── settings_screen.dart  → App settings
├── widgets/               → PRESENTATION LAYER (Reusable UI)
│   ├── channel_card.dart     → Channel list item
│   ├── category_chips.dart   → Category filter
│   ├── search_bar_widget.dart → Search input
│   ├── loading_shimmer.dart  → Loading placeholder
│   └── empty_state.dart      → Empty state display
└── theme/                 → PRESENTATION LAYER (Design)
    └── app_theme.dart        → Colors, gradients, typography
```

## Features

- M3U/M3U8 playlist support (URL or local file)
- Fast channel search & category filtering
- Favorites system
- Beautiful dark UI with smooth animations
- Lightweight (~12MB APK)
- Hardware-accelerated video playback
- Android TV support

## Getting Started

### Prerequisites
- Flutter SDK 3.2+
- Android Studio or VS Code with Flutter extension

### Installation

```bash
# Clone the project
git clone <repo-url>
cd iptv_app

# Install dependencies
flutter pub get

# Run on connected device
flutter run

# Build APK
flutter build apk --release
```

### Adding Your M3U Playlist

1. Open the app
2. Tap the (+) button on the top right
3. Paste your M3U URL or select a local .m3u file
4. Channels will load automatically

## Performance Optimizations

- **Lazy parsing** - M3U files parsed line by line (no full memory load)
- **Local caching** - Hive DB for instant startup
- **Virtual list** - Only visible channels are rendered
- **Image caching** - Logos cached on disk
- **Hardware decode** - Video uses hardware acceleration
- **Minimal buffer** - Fast channel switching (2-3s buffer)

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Framework | Flutter 3.2+ |
| Language | Dart 3.2+ |
| Video | media_kit (libmpv) |
| State | Provider |
| Storage | Hive |
| Network | Dio |
| Images | cached_network_image |
