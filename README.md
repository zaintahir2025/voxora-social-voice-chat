# Voxora — Social Voice Chat Platform

> **Talk. Play. Build.** A free, open-source social voice chat platform built with Flutter and powered by Supabase.

[![Deploy to GitHub Pages](https://github.com/zaintahir2025/voxora-social-voice-chat/actions/workflows/pages.yml/badge.svg)](https://github.com/zaintahir2025/voxora-social-voice-chat/actions/workflows/pages.yml)

🌐 **Live Demo:** [https://zaintahir2025.github.io/voxora-social-voice-chat/](https://zaintahir2025.github.io/voxora-social-voice-chat/)

---

## Features

### 🎙️ Live Voice Rooms
- Create and join real-time voice rooms with WebRTC peer-to-peer audio
- Room topics, descriptions, and capacity limits
- Host/listener roles with mute/unmute controls
- Meeting tools with agenda, decisions, and action items
- Invite links with one-click copy

### 💬 Real-time Messaging
- Direct messages between users
- Group chat creation with multi-select
- Real-time message delivery via Supabase
- Message search and conversation management

### 👥 Social Network
- User profiles with avatars, covers, and bios
- Friend request system (send, accept, view pending)
- Interest tags and user discovery
- Search and filter by all/friends/pending

### 🎮 In-App Games
- **Chess** — Full chess engine with move validation
- **Ludo** — Multi-player dice game with color tokens
- **Cards** — Quick-round card game with scoring
- All games sync in real-time across players

### 🛡️ Admin Panel
- User management with block/unblock
- Room moderation (end live rooms)
- User search and stats dashboard

### ✨ Professional UI/UX
- Premium dark theme with glassmorphism
- Responsive design (desktop sidebar + mobile bottom nav)
- Smooth micro-animations and hover effects
- Gradient buttons with press feedback
- Online status indicators
- Cross-platform: Web, Android, iOS, Windows, macOS, Linux

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Frontend** | Flutter (Dart) |
| **Backend** | Supabase (PostgreSQL, Auth, Realtime, Storage) |
| **Voice** | WebRTC via `flutter_webrtc` |
| **Games** | `chess` package for chess engine |
| **Fonts** | Google Fonts (Inter) |
| **CI/CD** | GitHub Actions → GitHub Pages |

---

## Getting Started

### Prerequisites
- Flutter SDK 3.11+
- A Supabase project with the required tables

### Run Locally

```bash
# Clone the repo
git clone https://github.com/zaintahir2025/voxora-social-voice-chat.git
cd voxora-social-voice-chat

# Install dependencies
flutter pub get

# Run with Supabase credentials
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your_anon_key
```

### Build for Web

```bash
flutter build web --release \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your_anon_key \
  --base-href "/voxora-social-voice-chat/"
```

---

## Deployment

The app auto-deploys to GitHub Pages on every push to `main` via the CI workflow at `.github/workflows/pages.yml`.

Set these **repository variables** in GitHub Settings → Secrets and variables → Actions → Variables:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

---

## Project Structure

```
lib/
├── config/
│   ├── constants.dart     # Supabase config & game constants
│   └── theme.dart         # Dark theme, colors, decorations
├── models/
│   └── models.dart        # All data models (Profile, Room, etc.)
├── providers/
│   └── app_provider.dart  # State management & Supabase CRUD
├── screens/
│   ├── auth_screen.dart   # Login/signup with animated UI
│   ├── home_screen.dart   # Main layout with sidebar/bottom nav
│   ├── loading_screen.dart # Animated loading splash
│   └── setup_screen.dart  # Backend config helper
├── services/
│   └── voice_room_service.dart  # WebRTC voice signaling
├── views/
│   ├── admin_view.dart    # Admin user/room management
│   ├── games_view.dart    # Chess, Ludo, Cards
│   ├── messages_view.dart # DMs and group chats
│   ├── people_view.dart   # User discovery & friends
│   ├── profile_view.dart  # Profile editor
│   └── rooms_view.dart    # Voice room interface
└── widgets/
    └── common_widgets.dart # Reusable UI components
```

---

## License

MIT — Free to use, modify, and distribute.
