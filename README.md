# Voxora

Voxora is a real Supabase-backed social voice chat application deployed from a static Vite/React frontend to GitHub Pages.

## What Works

- Supabase email/password authentication.
- Automatic profile creation on signup.
- Profile customization with display name, handle, bio, interests, avatar upload, and cover upload.
- Member discovery and direct conversations.
- Realtime direct messages stored in Postgres.
- Live room creation, joining, participant tracking, room chat, and gift sending.
- Browser WebRTC voice connections with Supabase Realtime broadcast signaling.
- Coin wallet, coin packages, purchase requests, purchase history, and admin completion that credits coins.
- Admin tools for purchase approval, user blocking, and ending live rooms.
- Row Level Security on all public tables and storage policies for user media.

## Security Notes

Do not commit Supabase service-role keys, database passwords, payment provider secrets, or `.env.local`.

The GitHub Pages build uses only:

```bash
VITE_SUPABASE_URL
VITE_SUPABASE_PUBLISHABLE_KEY
```

These values are browser-safe public configuration. Data protection is enforced by Supabase Row Level Security.

## Local Development

```bash
npm install
cp .env.example .env.local
npm run dev
```

Fill `.env.local` with your Supabase project URL and publishable key.

## Database

Migrations live in `supabase/migrations`.

```bash
supabase link --project-ref <project-ref>
supabase db push --linked
supabase config push --project-ref <project-ref>
```

The first registered user becomes an admin automatically.

## Payments

Coin purchase records are real database records, and admin completion credits coins atomically. JazzCash/EasyPaisa automatic verification requires merchant credentials and a server-side webhook/Edge Function; those secrets must never be placed in the GitHub Pages frontend.

## Checks

```bash
npm run lint
npm run build
```
