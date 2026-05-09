# Flicko Demo

A TikTok-style short video feed + LiveKit real-time live streaming demo built with Flutter.

---

## Table of Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Secrets Configuration](#secrets-configuration)
- [Running the App](#running-the-app)
- [Testing Live Streaming](#testing-live-streaming)
- [Replacing LiveKit Credentials](#replacing-livekit-credentials)
- [Project Structure](#project-structure)
- [Video Preloading Strategy](#video-preloading-strategy)
- [LiveKit Integration](#livekit-integration)
- [Known Limitations](#known-limitations)

---

## Requirements

| Tool | Version |
|------|---------|
| Flutter | ≥ 3.22.0 |
| Dart | ≥ 3.4.0 |
| Xcode | ≥ 15 (iOS) |
| Android Studio | ≥ Hedgehog (Android) |
| A real device | Required for live streaming (camera/mic) |

---

## Installation

**1. Clone the repository**

```bash
git clone https://github.com/<your-username>/flicko_demo.git
cd flicko_demo
```

**2. Install Flutter dependencies**

```bash
flutter pub get
```

**3. Set up your `.env` file** *(see [Secrets Configuration](#secrets-configuration) below)*

**4. Verify the setup**

```bash
flutter analyze   # should print: No issues found
```

---

## Secrets Configuration

API keys are **never hardcoded**. They are loaded at runtime from a `.env` file that is gitignored.

**Step 1** — Copy the template:

```bash
cp .env.example .env
```

**Step 2** — Fill in your LiveKit credentials in `.env`:

```
LIVEKIT_URL=wss://your-project.livekit.cloud
LIVEKIT_API_KEY=your_api_key_here
LIVEKIT_API_SECRET=your_api_secret_here
```

> The `.env` file is listed in `.gitignore` and will **never** be committed.  
> The `.env.example` file (with empty values) is committed as a template for reviewers.

**How it works internally:**

```
.env  →  flutter_dotenv  →  lib/config/env.dart (Env.livekitUrl, etc.)
                         →  lib/features/live/services/token_service.dart
```

---

## Running the App

**iOS**

```bash
flutter run -d <ios-device-id>
```

**Android**

```bash
flutter run -d <android-device-id>
```

To list connected devices:

```bash
flutter devices
```

> ⚠️ A **real physical device** is strongly recommended for live streaming.  
> The iOS Simulator does not support camera/microphone hardware.  
> The Android Emulator supports the viewer role but not the host role.

---

## Testing Live Streaming

You need **two devices** (or one device + one simulator for viewer-only testing).

### Step 1 — Host (Phone A)

1. Open the app → tap **Featured** tab
2. Tap the red **Go Live** button (bottom-right corner)
3. In the bottom sheet, tap **Go Live**
4. Enter a room name (e.g. `test-room`) and your name (e.g. `host-alice`)
5. Tap **Start Streaming** — the app requests camera & mic permissions
6. You are now live ✅

### Step 2 — Viewer (Phone B or Simulator)

1. Open the app → tap **Featured** tab
2. Tap the red **Go Live** button
3. In the bottom sheet, tap **Join as Viewer**
4. Enter the **exact same room name** as the host (e.g. `test-room`) and your name (e.g. `viewer-bob`)
5. Tap **Join Stream**
6. You should see the host's video and hear their audio ✅

### Leaving

- **Host** → tap **End Live** or the ✕ button — camera, mic, Room, and Tracks are all released
- **Viewer** → tap **Leave Stream** or the ✕ button

---

## Replacing LiveKit Credentials

To use your own LiveKit account:

1. Sign up for a free account at [livekit.io](https://livekit.io)
2. Create a new project in the LiveKit Cloud dashboard
3. Copy your **WebSocket URL**, **API Key**, and **API Secret**
4. Update your `.env` file:

```
LIVEKIT_URL=wss://<your-project>.livekit.cloud
LIVEKIT_API_KEY=<your-api-key>
LIVEKIT_API_SECRET=<your-api-secret>
```

No code changes are needed — the app reads these values at startup via `flutter_dotenv`.

---

## Project Structure

```
lib/
├── main.dart                        # Entry point: loads .env → ProviderScope → app
├── config/
│   └── env.dart                     # Typed access to .env values (Env.livekitUrl, etc.)
│
├── features/
│   ├── home/                        # Short video feed module
│   │   ├── models/
│   │   │   └── video_item.dart      # Video data model + CDN URL list
│   │   ├── providers/
│   │   │   ├── feed_provider.dart   # feedProvider (list) + currentPageIndexProvider
│   │   │   └── video_player_provider.dart  # .autoDispose.family — one controller/index
│   │   └── views/
│   │       ├── home_page.dart       # PageView.builder, vertical scroll, preload logic
│   │       └── video_card.dart      # Full-screen card: video + all overlays
│   │
│   └── live/                        # LiveKit live streaming module
│       ├── models/
│       │   ├── live_stream.dart     # Featured stream data model (mock)
│       │   └── room_config.dart     # RoomConfig + RoomRole enum (host/viewer)
│       ├── providers/
│       │   ├── featured_provider.dart  # Mock featured stream list
│       │   └── room_provider.dart      # LiveKit room lifecycle (connect/publish/dispose)
│       ├── services/
│       │   └── token_service.dart   # JWT token generator (demo-only, uses .env keys)
│       └── views/
│           ├── featured_page.dart   # Grid + FAB + bottom sheet
│           ├── live_page.dart       # Room name + identity form
│           ├── host_view.dart       # Local camera preview + mic toggle + end live
│           └── viewer_view.dart     # Remote VideoTrackRenderer + leave
│
└── shared/
    ├── widgets/
    │   └── bottom_nav.dart          # 5-tab nav bar (Home, Featured, +, Messages, Me)
    └── theme/
        └── app_theme.dart           # AppColors + AppTheme (dark, #FE2C55 accent)
```

---

## Video Preloading Strategy

The home feed uses a `PageView.builder` with vertical scroll. Controllers are managed via Riverpod's `autoDispose.family` provider:

```
┌─────────────┐
│  Page N-1   │  ← controller kept alive (preloaded, paused)
├─────────────┤
│  Page N     │  ← controller playing
├─────────────┤
│  Page N+1   │  ← controller kept alive (preloaded, paused)
└─────────────┘
     ... all others: autoDispose releases them
```

**On every page change:**
1. `currentPageIndexProvider` is updated
2. `_preload(index)` eagerly reads `videoPlayerProvider(i-1)`, `(i)`, `(i+1)` — this keeps those providers alive
3. `VideoCard` receives `isActive` — it calls `controller.play()` when active, `controller.pause()` when not
4. Providers outside the `[N-1, N+1]` window are garbage-collected by Riverpod's `autoDispose`

This means at most 3 `VideoPlayerController` instances exist at any time — no memory leaks, no manual dispose map.

---

## LiveKit Integration

### Architecture

```
live_page.dart
    ↓  RoomConfig(roomName, role, identity)
room_provider.dart  (StateNotifierProvider<RoomNotifier, RoomState>)
    ↓  TokenService.generate(config)  →  JWT signed with LIVEKIT_API_KEY + SECRET
    ↓  Room.connect(LIVEKIT_URL, token)
    ↓  Host: setCameraEnabled(true) + setMicrophoneEnabled(true)
    ↓  Viewer: room.addListener → scan remoteParticipants for VideoTrack
    ↓
host_view.dart  /  viewer_view.dart
    ↓  VideoTrackRenderer(track)  — real-time WebRTC video
```

### Token Generation

Tokens are generated on-device using `dart_jsonwebtoken` with the API key and secret from `.env`.

> ⚠️ **Security note:** On-device token generation is acceptable for a demo, but **must not be used in production**. In production, tokens should be issued by a backend server so the API secret is never exposed on the client.

### Resource Cleanup

When the user leaves a room, the following are released in order:

```dart
room.removeListener(...)       // stop watching for track changes
room.localParticipant?.setCameraEnabled(false)   // implicit on disconnect
room.localParticipant?.setMicrophoneEnabled(false)
await room.disconnect()        // graceful WebRTC disconnect
room.dispose()                 // releases all Tracks and internal state
```

This is handled inside `RoomNotifier.disconnect()` and `RoomNotifier.dispose()`.

---

## Known Limitations

| Area | Limitation |
|------|-----------|
| Token generation | On-device only — must be moved server-side for production |
| Featured grid | Mock data — not fetched from a real API |
| Video feed | Fixed list of 9 CDN videos — no pagination or API feed |
| iOS Simulator | Camera/mic not available — host role requires a real device |
| Permissions | Runtime permission prompts not handled with a custom rationale dialog |
| Landscape | Portrait-only — landscape orientation is locked |
| Out of scope | Gifts, danmaku, beauty filters, recording, CDN, auth, payments |
