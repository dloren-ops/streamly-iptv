# Streamly — Lightweight & Fast IPTV Player

A beautiful, lightweight IPTV player built with Flutter. Live TV, Movies and
Series in one app. Works on Android, iOS, Android TV, Web, Windows, Mac, and Linux.

## Features

- **Xtream Codes login** — sign in with server URL + username + password
- **Secure credentials** — stored in the device Keychain/Keystore (not plain text)
- **Live TV** — M3U/M3U8 playlists with search and category filtering
- **EPG (program guide)** — "now / next" with a live progress bar (XMLTV)
- **Movies (VOD)** — poster grid with ratings, full playback with seek
- **Series** — seasons, episodes, and per-episode playback
- **Refresh/update button** — reload channels from the source any time
- **Favorites** — saved across refreshes
- **Auto-login** — instant startup from cache, then background refresh
- Beautiful dark UI, hardware-accelerated video, lightweight footprint

## Architecture (Clean Layers)

```
lib/
├── main.dart                  → Entry point (providers + routing)
├── models/                    → DOMAIN LAYER (data structures)
│   ├── channel.dart           → Live channel
│   ├── category.dart          → Category helper
│   ├── epg_program.dart       → EPG program
│   └── vod_item.dart          → Movie / Series / Episode
├── services/                  → DATA LAYER (external connections)
│   ├── m3u_parser.dart        → Efficient M3U parser
│   ├── playlist_service.dart  → Playlist loading & caching
│   ├── xtream_service.dart    → Xtream auth + URL building
│   ├── epg_service.dart       → Streaming XMLTV parser
│   ├── vod_service.dart       → Movies & series API
│   └── storage_service.dart   → Hive + secure storage
├── providers/                 → LOGIC LAYER (state management)
│   ├── channel_provider.dart  → Live TV + EPG state
│   └── vod_provider.dart      → Movies & series state
├── screens/                   → PRESENTATION LAYER (pages)
│   ├── login_screen.dart      → Xtream login
│   ├── main_navigation.dart   → Bottom tabs
│   ├── home_screen.dart       → Live channel list
│   ├── movies_screen.dart     → Movies grid
│   ├── series_screen.dart     → Series grid
│   ├── series_detail_screen.dart → Seasons & episodes
│   ├── player_screen.dart     → Live player (with EPG)
│   ├── vod_player_screen.dart → VOD player (with seek)
│   ├── favorites_screen.dart  → Favorites
│   ├── add_playlist_screen.dart → Add M3U playlist
│   └── settings_screen.dart   → Account, stats & settings
├── widgets/                   → PRESENTATION LAYER (reusable UI)
│   ├── channel_card.dart      → Channel item (with EPG)
│   ├── vod_card.dart          → Movie/series poster
│   ├── category_chips.dart    → Category filter
│   ├── search_bar_widget.dart → Search input
│   ├── loading_shimmer.dart   → Loading placeholder
│   └── empty_state.dart       → Empty state display
└── theme/
    └── app_theme.dart         → Colors, gradients, typography
```

## Getting Started

### Prerequisites
- Flutter SDK 3.2+
- Android Studio or VS Code with the Flutter extension

### Installation

```bash
# Clone the project
git clone https://github.com/dloren-ops/streamly-iptv.git
cd streamly-iptv

# Generate the platform folders (android/ios/web/...) for this package
flutter create .

# Install dependencies
flutter pub get

# Run on a connected device
flutter run

# Build a release APK
flutter build apk --release
```

> Note: `flutter create .` regenerates the native platform folders (which are
> intentionally not committed). The provided `android/app/src/main/AndroidManifest.xml`
> already enables Internet access, cleartext traffic and Android TV (Leanback).

### Signing in

1. Open the app
2. Enter your **Server URL**, **Username** and **Password** (Xtream Codes)
3. Channels, movies and series load automatically
4. Use the **refresh** button (top-left on Live) to update content anytime

## Performance Optimizations

- **Lazy parsing** — M3U parsed line by line; XMLTV parsed via a streaming
  event parser, keeping only current/upcoming programs
- **Lazy VOD** — movies/series only fetched when their tab is opened
- **Local caching** — Hive for instant startup; favorites preserved on refresh
- **Virtualized lists/grids** — only visible items are built
- **Image caching** — posters and logos cached on disk
- **Hardware decode** — video uses hardware acceleration
- **Trimmed dependencies** — no unused packages

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Framework | Flutter 3.2+ |
| Language | Dart 3.2+ |
| Video | media_kit (libmpv) |
| State | Provider |
| Storage | Hive + flutter_secure_storage |
| Network | Dio |
| EPG | xml (streaming events) |
| Images | cached_network_image |
