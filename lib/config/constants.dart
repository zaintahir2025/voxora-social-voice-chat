const supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://xssffpytngvjdjfspqac.supabase.co',
);
const supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhzc2ZmcHl0bmd2amRqZnNwcWFjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk2MTA3NjAsImV4cCI6MjA5NTE4Njc2MH0.-vQyJN4aD-lPYmVMuLZfBEuYw29Z3yOS1CJkXEnsbws',
);
const appPublicUrl = String.fromEnvironment(
  'APP_PUBLIC_URL',
  defaultValue: 'https://zaintahir2025.github.io/voxora-social-voice-chat/',
);
bool get isSupabaseConfigured =>
    supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

const ludoColorNames = ['red', 'blue', 'yellow', 'green'];
const ludoBoardColors = {
  'red': 0xFFE53935,
  'blue': 0xFF1E88E5,
  'green': 0xFF43A047,
  'yellow': 0xFFFDD835,
};
const ludoTrackLength = 52;
const ludoStartOffsets = {'red': 0, 'blue': 13, 'yellow': 26, 'green': 39};
const ludoSafeTrackIndices = {0, 8, 13, 21, 26, 34, 39, 47};

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

const gameTitles = {'chess': 'Chess', 'ludo': 'Ludo', 'cards': 'Cards'};
