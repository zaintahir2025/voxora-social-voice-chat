# Voxora

Voxora is a Flutter and Supabase social app for real accounts, friends, picture posts, chat, audio/video calls, and games.

## Features

- Sign up and log in with Supabase Auth.
- Add, accept, and remove friends.
- Chat one-to-one or create group chats with friends.
- Start audio or video calls from a conversation.
- Add picture posts with captions.
- Like, share, comment on posts, edit your own posts, delete your own posts, and delete comments you own or comments on your posts.
- View and customize user profiles with avatar, cover, bio, and interests.
- Switch between light and dark themes with sun/moon controls.
- Play Chess, Ludo, and Cards with friends by invite code or with local computer bots.
- Read rules and tutorials inside each game, with chess and Ludo move guides.

## Local Run

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

Apply the Supabase migrations before using a fresh backend. The final migration resets old app data and recreates the clean social/games schema.
