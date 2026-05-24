# Voxora

Voxora is a free Supabase-backed social and professional communication platform built with **Flutter** for web, Android, iOS, Windows, macOS, and Linux.

## What Works

- Supabase email/password authentication.
- Automatic profile creation on signup.
- Profile customization with display name, handle, bio, interests, avatar upload, and cover upload.
- Member discovery for making friends and starting conversations.
- Direct conversations, group conversations, and realtime messages stored in Postgres.
- Live rooms for hangouts, study rooms, communities, and professional meetings.
- Meeting controls in each room: agenda, decisions, action items, invite links, participant list, room chat, join/leave, and WebRTC voice.
- Games: Chess, Ludo, and Cards, playable inside rooms.
- Admin moderation tools for user blocking and ending live rooms.
- Responsive UX: desktop sidebar layout, tablet-friendly split panes, and mobile bottom navigation.

## Free Platform

Voxora has no paid tiers, no in-app purchases, and no monetized boosts. Every user gets the same core communication features.

## Security Notes

Do not commit Supabase service-role keys, database passwords, or secrets.

The GitHub Pages build uses only browser-safe public configuration:

```text
SUPABASE_URL
SUPABASE_ANON_KEY
APP_PUBLIC_URL
```

Data protection is enforced by Supabase Row Level Security.

## Local Development

```bash
flutter pub get
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your_publishable_key \
  --dart-define=APP_PUBLIC_URL=http://localhost:5000/
```

For other platforms:

```bash
flutter run -d windows --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
flutter run -d macos --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
flutter run -d linux --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

## Database

Migrations live in `supabase/migrations`.

```bash
supabase link --project-ref <project-ref>
supabase db push --linked
```

The first registered user becomes an admin automatically.

## Build For Web

```bash
flutter build web --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=... \
  --dart-define=APP_PUBLIC_URL=https://your-name.github.io/voxora-social-voice-chat/
```

Output is in `build/web/`.
