# Voxora - Social Voice Chat Application

Voxora is a polished, free-to-run social voice chat app prototype built from the provided documentation. It is a static React app designed for GitHub Pages, with local persistence and no required API keys.

## Covered Modules

- Splash screen, login, registration, editable user profiles, followers, following, badges, VIP tiers, and levels.
- Home dashboard with live rooms, leaderboards, suggested follows, notifications, and user stats.
- Voice rooms with room creation, joining, participant seats, mic permission/audio meter, hand raise, room chat, gifts, coins, and host rewards.
- Private messaging with persistent direct message threads.
- Wallet with coin packages, JazzCash/EasyPaisa-ready transaction simulation, gift catalog, transaction history, and host earnings.
- VIP membership plans with benefits, badge activation, priority visibility logic, and wallet transactions.
- Push-notification style notification center and admin announcements.
- Leaderboards based on earnings, popularity, and activity.
- Mini games with Beat Tap, Lucky Spin, coin rewards, streaks, and best score tracking.
- Admin panel with user management, room locking/ending, gift creation, transaction monitoring, analytics, notification sending, VIP plan oversight, and leaderboard visibility.

## Free Architecture

This version intentionally needs no paid APIs and no API keys:

- Hosting: GitHub Pages.
- State: browser localStorage.
- Mic preview: browser MediaDevices API.
- Build: Vite, React, TypeScript, and local static assets.

Real multi-user voice needs a signaling/realtime backend. Good free-first options to add later:

- GitHub Pages for the static frontend: https://docs.github.com/pages
- PeerJS Cloud signaling for WebRTC prototypes, or self-host PeerServer: https://peerjs.com/
- Supabase Auth, Postgres, Storage, and Realtime free plan: https://supabase.com/pricing
- Cloudflare Workers free plan for a signaling/API layer: https://developers.cloudflare.com/workers/platform/limits/
- Firebase Spark plan for Auth, Firestore, and FCM prototypes: https://firebase.google.com/docs/projects/billing/firebase-pricing-plans
- LiveKit open-source media server for production-grade rooms when you can self-host: https://docs.livekit.io/
- LiveKit Cloud Build plan for limited no-card testing: https://livekit.io/pricing

For payments, JazzCash and EasyPaisa require merchant onboarding/API credentials. The app includes the wallet and transaction workflow without charging users.

## Local Development

```bash
npm install
npm run dev
```

## Quality Checks

```bash
npm run lint
npm run build
```

## Deployment

The repository includes `.github/workflows/pages.yml`. Push to `main` or `master`, enable GitHub Pages with GitHub Actions as the source, and the workflow deploys `dist`.
