export type ViewId =
  | 'home'
  | 'rooms'
  | 'messages'
  | 'profile'
  | 'wallet'
  | 'vip'
  | 'games'
  | 'admin';

export type VipTier = 'Free' | 'Glow' | 'Prime' | 'Legend';

export type RoomRole = 'host' | 'moderator' | 'speaker' | 'listener';

export type PaymentMethod = 'JazzCash' | 'EasyPaisa' | 'Demo Coins';

export interface User {
  id: string;
  name: string;
  handle: string;
  avatar: string;
  cover: string;
  bio: string;
  followers: string[];
  following: string[];
  level: number;
  vipTier: VipTier;
  coins: number;
  earnings: number;
  popularity: number;
  activity: number;
  blocked: boolean;
  badges: string[];
  interests: string[];
  joinedAt: string;
}

export interface RoomParticipant {
  userId: string;
  name: string;
  avatar: string;
  role: RoomRole;
  muted: boolean;
  speaking: boolean;
  vipTier: VipTier;
}

export interface RoomMessage {
  id: string;
  userId: string;
  name: string;
  body: string;
  time: string;
  kind: 'chat' | 'gift' | 'system';
}

export interface Room {
  id: string;
  title: string;
  topic: string;
  language: string;
  hostId: string;
  hostName: string;
  cover: string;
  mood: string;
  description: string;
  tags: string[];
  participants: RoomParticipant[];
  capacity: number;
  live: boolean;
  locked: boolean;
  giftsReceived: number;
  raisedHands: string[];
  messages: RoomMessage[];
  startedAt: string;
}

export interface DirectMessage {
  id: string;
  from: string;
  body: string;
  time: string;
}

export interface MessageThread {
  id: string;
  userId: string;
  userName: string;
  avatar: string;
  lastMessage: string;
  unread: number;
  messages: DirectMessage[];
}

export interface Gift {
  id: string;
  name: string;
  label: string;
  price: number;
  accent: string;
  rewardPoints: number;
}

export interface Transaction {
  id: string;
  type: 'purchase' | 'gift' | 'earning' | 'withdrawal' | 'vip' | 'bonus';
  amount: number;
  method: PaymentMethod | 'Room Gift' | 'Host Reward' | 'VIP Upgrade' | 'Admin';
  status: 'completed' | 'pending' | 'flagged';
  detail: string;
  time: string;
}

export interface NotificationItem {
  id: string;
  type: 'message' | 'follower' | 'invite' | 'system' | 'wallet' | 'gift';
  title: string;
  body: string;
  time: string;
  read: boolean;
}

export interface VipPlan {
  id: VipTier;
  price: number;
  spotlight: string;
  accent: string;
  benefits: string[];
}

export interface GameStats {
  beatTapBest: number;
  spinWins: number;
  dailyStreak: number;
}

export interface AppState {
  sessionUserId: string | null;
  users: User[];
  rooms: Room[];
  threads: MessageThread[];
  gifts: Gift[];
  transactions: Transaction[];
  notifications: NotificationItem[];
  vipPlans: VipPlan[];
  announcements: NotificationItem[];
  gameStats: GameStats;
}
