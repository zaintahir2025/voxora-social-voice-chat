# 🌊 Voxora: Next-Gen Social Voice & Gaming Platform

**Voxora** is an advanced, cross-platform social networking application built from the ground up using **Flutter** and **Supabase**. It merges the capabilities of modern social feeds, low-latency peer-to-peer WebRTC voice calling, and integrated AI-driven multiplayer games into a single, cohesive, flat-design UI.

This document serves as an exhaustive technical manual detailing the architecture, state management patterns, algorithmic implementations, and UI/UX design philosophies utilized in the Voxora codebase.

---

## 🏗️ 1. Software Architecture & Design Patterns

Voxora strictly adheres to a **Model-View-Controller-Service (MVCS)** architectural pattern, leveraging the `provider` package to inject dependencies and manage reactive state. This ensures total decoupling of business logic from UI rendering.

### Folder Structure Deep-Dive
*   **`lib/models/` (Data Entities)**: Contains immutable, strongly-typed Dart classes (e.g., `User`, `Post`, `Message`, `GameSession`). These classes often contain `fromJson` and `toJson` factory constructors for seamless serialization with the Supabase backend.
*   **`lib/providers/` (Controllers/State)**: The reactive heart of the application. 
    *   `AppProvider`: A global singleton that wraps the `MaterialApp`. It holds the current user session, active theme state, navigation index, and caches feed data. When data mutates, it calls `notifyListeners()` to rebuild only the dependent UI widgets.
    *   `BotGameProvider`: A specialized state manager that handles the complex state machines required for turn-based games (player turns, valid moves, victory/loss states).
*   **`lib/services/` (Business Logic/External APIs)**: Pure Dart classes responsible for side-effects and external communication.
    *   `CallService`: Interfaces directly with the WebRTC API for media streaming.
    *   `BotService`: Contains the raw algorithms (like Minimax) used for the computer AI.
*   **`lib/screens/` & `lib/views/` (Presentation)**:
    *   `screens/`: High-level scaffolds that define the structural layout (`HomeScreen`, `AuthScreen`).
    *   `views/`: Modular, swappable content fragments rendered inside the Home scaffold (e.g., `FeedView`, `MessagesView`).
*   **`lib/widgets/` (Reusable Components)**: Highly customized, decoupled UI components like `AppCard`, `UserAvatar`, and `SectionHeader`.

---

## 🛠️ 2. Comprehensive Tech Stack

| Package / Tool | Purpose & Implementation Details |
| :--- | :--- |
| **`flutter` (Dart)** | The core UI toolkit used to compile the application to Native Web, iOS, Android, macOS, and Windows from a single codebase. |
| **`provider`** | An `InheritedWidget` wrapper used for O(1) dependency injection and reactive UI rebuilding. Selected over Riverpod/Bloc for its simplicity and direct integration with Flutter's build context. |
| **`supabase_flutter`** | The Backend-as-a-Service (BaaS). Used for OAuth/Email authentication, PostgreSQL row-level security (RLS) databases, file storage buckets (for avatars/posts), and WebSocket-based Real-Time event subscriptions. |
| **`flutter_webrtc`** | Provides the WebRTC C++ bindings. Used to access device microphones, establish RTCPeerConnections, and stream low-latency VoIP data directly between users. |
| **`chess`** | A validated, pure-Dart chess logic engine. It handles Forsyth-Edwards Notation (FEN) parsing, legal move generation, checkmate validation, and en passant logic. |
| **`google_fonts`** | Dynamically serves the **Nunito** font family, providing the app with its signature soft, modern, and highly legible typographic hierarchy. |
| **`file_selector`** | Provides cross-platform native file picker dialogs (specifically optimized for Web/Desktop) to allow users to upload images to their feed. |

---

## 📡 3. Real-Time Communication (WebRTC & Signaling)

Voxora implements a decentralized peer-to-peer voice calling system, completely avoiding the latency and cost of routing audio through a centralized media server.

### The Signaling Flow (`CallService`)
Before two users can send audio, they must discover each other. Voxora uses **Supabase Realtime Channels** as a signaling server to exchange connection data:
1.  **Offer Creation**: Caller creates an SDP (Session Description Protocol) "Offer" detailing their device's media codecs and local IP candidates.
2.  **Transmission**: The Offer is broadcasted via a Supabase WebSocket channel to the target user's UUID.
3.  **Answer & ICE Candidates**: The receiver intercepts the payload, generates an SDP "Answer", and begins exchanging ICE (Interactive Connectivity Establishment) candidates to punch through NATs/Firewalls.
4.  **Peer Connection**: Once the ICE negotiation completes, a direct `RTCPeerConnection` is established via `flutter_webrtc`, and raw audio tracks are streamed bidirectionally.

---

## 🤖 4. Game Engine & AI Algorithms

Voxora includes an interactive `GamesView` featuring robust, mathematically-driven AI opponents.

### Chess AI implementation (`bot_service.dart`)
The computer opponent does not play randomly; it utilizes the **Minimax Algorithm** enhanced with **Alpha-Beta Pruning**.
*   **Heuristic Evaluation**: The algorithm assigns a numerical value to the board state (e.g., Queen = 900, Rook = 500, Pawn = 100).
*   **Game Tree Search**: The AI simulates all possible legal moves up to a certain depth (e.g., 3 or 4 moves ahead). It assumes the human player will always make the optimal counter-move.
*   **Alpha-Beta Pruning**: As the algorithm searches the tree, it abandons ("prunes") branches that are mathematically proven to be worse than a previously evaluated branch, drastically reducing computation time and memory overhead.

---

## 🎨 5. Gen-Z Minimalist UI/UX Design System

The application's visual identity (`lib/config/theme.dart`) was strictly engineered to emulate the ultra-clean, flat aesthetics of modern applications like Instagram and Threads.

### Color Theory & Theming
*   **Material 3 Dynamic Schemes**: Colors are generated using `ColorScheme.fromSeed(seedColor: VoxoraColors.primaryPop)`.
*   **Dark Mode (Sleek Navy)**: Unlike generic apps that use pure black, Voxora uses an elegant deep navy (`#0B192C`) background with subtle, slightly lighter cards (`#14223A`).
*   **Light Mode (Pure Minimal)**: Utilizes a pure white background (`#FFFFFF`) with ultra-thin, 1px grey borders (`#DBDBDB`) to define hierarchy without visual clutter.

### Component Design Philosophy
*   **Zero Shadows**: Drop-shadows have been entirely eradicated from the UI (`AppCard`) in favor of flat 1px borders, creating a modern, frictionless feel.
*   **Responsive Scaling**: The `HomeScreen` utilizes an `isWide = MediaQuery.of(context).size.width >= 980` breakpoint. 
    *   On Desktop, the `_Sidebar` is permanently affixed to the left, and the main view utilizes a `SingleChildScrollView` allowing the Topbar to scroll naturally.
    *   On Mobile, the sidebar degrades into a compact `BottomNavigationBar`.
*   **Dynamic Avatar Fallbacks**: If `UserAvatar` encounters a null URL or a network error, it does not throw an exception. It gracefully degrades into a highly polished, perfectly scaled grey silhouette (`Icon(Icons.person)` on a white background) matching standard industry placeholders.

---

## 🚀 6. CI/CD DevOps Pipeline

Voxora utilizes **GitHub Actions** (`.github/workflows/pages.yml`) for robust Continuous Integration and Continuous Deployment.

1.  **Trigger**: Every push to the `main` branch triggers the workflow.
2.  **Environment Setup**: Provisions an Ubuntu runner and installs the specified Flutter SDK.
3.  **Dependency Resolution**: Executes `flutter pub get`.
4.  **Strict Code Quality Gate**: Runs `flutter analyze`. **This is a critical step.** If any unused variables, missing imports, or dead code exist, the build *fails immediately*. This ensures pristine codebase health.
5.  **Compilation**: Executes `flutter build web --release --base-href=/voxora-social-voice-chat/`, compiling the Dart code into a highly optimized WASM (WebAssembly) and JavaScript bundle.
6.  **Deployment**: Uploads the compiled artifacts and publishes them directly to **GitHub Pages**.

---

## 💻 7. Local Development & Installation

To run this project locally on your machine:

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/zaintahir2025/voxora-social-voice-chat.git
    ```
2.  **Navigate to the directory**:
    ```bash
    cd voxora-social-voice-chat
    ```
3.  **Install dependencies**:
    ```bash
    flutter pub get
    ```
4.  **Run the application (Web)**:
    ```bash
    flutter run -d chrome
    ```
