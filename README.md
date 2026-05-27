# Voxora: Social Voice Chat Platform

Voxora is a modern, cross-platform social application built entirely in Flutter. Designed to emulate the ultra-clean, minimal aesthetic of platforms like Instagram and Threads, Voxora allows users to interact via real-time text chats, voice calls, dynamic social feeds, and integrated multiplayer games.

This document provides a comprehensive overview of the technical concepts, architecture, and implementation details of the Voxora platform.

---

## 🛠️ Technology Stack

Voxora utilizes a robust suite of modern tools and packages:

*   **Frontend Framework**: [Flutter](https://flutter.dev/) (Dart)
*   **State Management**: `provider` (App-wide reactive state synchronization)
*   **Backend as a Service (BaaS)**: `supabase_flutter` (Authentication, Database, Real-time Events, Storage)
*   **Real-Time Media**: `flutter_webrtc` (Peer-to-Peer Voice Calling)
*   **Game Engines**: `chess` (Dart chess engine) and custom heuristics for Ludo.
*   **Typography & Styling**: `google_fonts` (Nunito)
*   **CI/CD Pipeline**: GitHub Actions for automated Web deployment

---

## 🏛️ Application Architecture

The application strictly adheres to a clean, modular architecture, separating the UI layer from business logic and data services.

### 1. Folder Structure
*   `lib/config/`: App-wide configurations like colors, fonts, and the dynamic `ThemeData` engine.
*   `lib/models/`: Strongly typed Dart data models (e.g., `User`, `Post`, `Message`, `GameSession`).
*   `lib/providers/`: The reactive business logic layer.
    *   `app_provider.dart`: Global state manager handling auth, navigation, unread counts, and mock backend integration for the feed/chats.
    *   `bot_game_provider.dart`: State manager specifically isolating the complex logic of turn-based AI gaming.
*   `lib/services/`: Pure Dart classes handling external API interactions and logic.
    *   `call_service.dart`: WebRTC signaling and peer connection management.
    *   `bot_service.dart`: AI heuristics (Minimax/Alpha-Beta) for game opponent calculations.
*   `lib/screens/`: Top-level navigational containers (`HomeScreen`, `AuthScreen`, `LoadingScreen`).
*   `lib/views/`: Reusable, swappable screen fragments used inside the `HomeScreen` (e.g., `FeedView`, `MessagesView`).
*   `lib/widgets/`: Highly reusable UI components (`AppCard`, `UserAvatar`, `SectionHeader`).

### 2. State Management (Provider)
Voxora avoids passing state down deeply nested widget trees by utilizing the `Provider` pattern.
The `AppProvider` sits at the root of the app, wrapping the `MaterialApp`. When users interact with the app (e.g., liking a post, sending a message), they call methods on the `AppProvider`. The provider updates its internal data structures and calls `notifyListeners()`, which automatically triggers targeted widget rebuilds across the app.

---

## 🎨 UI/UX & Design System

The application features a deeply customized, Gen-Z tailored aesthetic focusing on high contrast, minimalism, and fluidity.

*   **Responsive Layouts**: 
    *   **Desktop (`isWide >= 980px`)**: Displays a fixed left-hand Sidebar and a dynamically scrolling main content area.
    *   **Mobile**: Hides the Sidebar in favor of a sleek `BottomNavigationBar`.
*   **Theme Engine**: Built around `ColorScheme.fromSeed` and pure contrast principles.
    *   **Dark Mode**: Employs a pure black (`#000000`) background with extremely subtle deep grey (`#14223A`) cards to maximize content visibility and reduce eye strain.
    *   **Light Mode**: Uses pure white with ultra-thin 1px grey borders (`#DBDBDB`) mimicking high-end social platforms.
*   **Flat UI Components**: Custom widgets like `AppCard` purposefully avoid heavy drop-shadows and boxy backgrounds, opting instead for a flush, seamless, and flat visual hierarchy.

---

## 🚀 Core Features & Concepts

### 1. Social Feed & Interaction (`feed_view.dart`)
The home feed allows users to view, like, and interact with posts.
*   **Lazy Rendering**: Utilizes `ListView.builder` inside a customized scroll view to ensure that posts are only rendered when they enter the viewport, saving memory.
*   **Stateful Interactivity**: Liking a post instantly reflects in the UI through localized state, while asynchronously updating the backend.

### 2. Real-Time Chat & Voice (`messages_view.dart` & `call_service.dart`)
*   **Signaling**: Uses Supabase real-time channels to transmit SDP (Session Description Protocol) offers, answers, and ICE candidates between clients.
*   **WebRTC**: Once a connection is established via the `flutter_webrtc` package, audio tracks are streamed directly peer-to-peer, bypassing the server to achieve ultra-low latency voice chat.

### 3. Integrated Bot Gaming (`bot_game_provider.dart`)
Voxora features an interactive "Play" section allowing users to play against a built-in AI.
*   **Chess Engine**: Integrates a validated Dart chess engine to manage board state, legal moves, and FEN (Forsyth-Edwards Notation) parsing.
*   **Minimax Algorithm**: The AI opponent evaluates the best possible move by simulating future board states and minimizing the player's maximum payoff (Alpha-Beta pruning optimization).

### 4. Dynamic Identity Fallbacks (`UserAvatar`)
When a user has not uploaded a profile picture, Voxora gracefully handles the UI by defaulting to a standard, minimal grey silhouette `Icon(Icons.person)` dynamically sized to fit perfectly within the avatar constraints, ensuring the UI never breaks on an `Image.network` failure.

---

## 🔄 CI/CD Pipeline & Deployment

Voxora is configured for automated, continuous deployment using **GitHub Actions**.

*   **Pipeline Definition**: Defined in `.github/workflows/pages.yml`.
*   **Code Quality**: The pipeline strictly enforces `flutter analyze` to ensure zero dead code, unused imports, or linting warnings exist in the repository before allowing a build.
*   **Compilation**: Upon pushing to the `main` branch, the Action automatically compiles the application into highly optimized HTML/JS/WASM using `flutter build web --release`.
*   **Hosting**: The resulting build artifacts are automatically deployed to **GitHub Pages**, providing instant, live updates to the production web app.
