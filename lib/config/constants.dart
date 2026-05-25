// Supabase credentials are injected at build time via --dart-define.
// For local dev, pass them on the command line:
//   flutter run --dart-define=SUPABASE_URL=https://xyz.supabase.co --dart-define=SUPABASE_ANON_KEY=...
//
// For GitHub Pages CI, see .github/workflows/pages.yml

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
const appPublicUrl = String.fromEnvironment(
  'APP_PUBLIC_URL',
  defaultValue: 'https://zaintahir2025.github.io/voxora-social-voice-chat/',
);
bool get isSupabaseConfigured =>
    supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

const fallbackAvatarAsset = 'assets/avatar-zain.png';
const fallbackCoverAsset = 'assets/room-aurora.png';

const ludoColorNames = ['red', 'blue', 'green', 'yellow'];
const cardRanks = [
  '2',
  '3',
  '4',
  '5',
  '6',
  '7',
  '8',
  '9',
  '10',
  'J',
  'Q',
  'K',
  'A',
];
const cardSuits = ['S', 'H', 'D', 'C'];
