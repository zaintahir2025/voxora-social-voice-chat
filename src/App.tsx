import { FormEvent, ReactNode, useEffect, useMemo, useState } from 'react';
import {
  Activity,
  BadgeCheck,
  Ban,
  BarChart3,
  Bell,
  Check,
  Coins,
  Crown,
  Flame,
  Gamepad2,
  Gift,
  Hand,
  Home,
  Lock,
  LogOut,
  Megaphone,
  MessageCircle,
  Mic,
  MicOff,
  PhoneOff,
  Plus,
  Radio,
  RefreshCw,
  Search,
  Send,
  ShieldCheck,
  Sparkles,
  Star,
  Trophy,
  Unlock,
  UserPlus,
  UserRound,
  Users,
  WalletCards,
  X,
  Zap,
} from 'lucide-react';
import { usePersistentState } from './hooks/usePersistentState';
import { useVoiceMeter } from './hooks/useVoiceMeter';
import { createInitialState } from './lib/seed';
import { cx, formatDate, formatNumber, formatTime, resetAppState, uid } from './lib/storage';
import type {
  AppState,
  Gift as GiftType,
  MessageThread,
  NotificationItem,
  PaymentMethod,
  Room,
  Transaction,
  User,
  ViewId,
  VipPlan,
} from './types/app';

type NavItem = {
  id: ViewId;
  label: string;
  icon: typeof Home;
};

const navItems: NavItem[] = [
  { id: 'home', label: 'Home', icon: Home },
  { id: 'rooms', label: 'Rooms', icon: Radio },
  { id: 'messages', label: 'Messages', icon: MessageCircle },
  { id: 'profile', label: 'Profile', icon: UserRound },
  { id: 'wallet', label: 'Wallet', icon: WalletCards },
  { id: 'vip', label: 'VIP', icon: Crown },
  { id: 'games', label: 'Games', icon: Gamepad2 },
  { id: 'admin', label: 'Admin', icon: ShieldCheck },
];

const coinPackages = [
  { label: 'Starter', coins: 500, price: 'Demo Rs 0', method: 'Demo Coins' as PaymentMethod },
  { label: 'Social', coins: 1500, price: 'JazzCash-ready', method: 'JazzCash' as PaymentMethod },
  { label: 'Host Pack', coins: 4000, price: 'EasyPaisa-ready', method: 'EasyPaisa' as PaymentMethod },
];

const topics = ['All', 'Music', 'Mini Games', 'Study', 'Stories', 'Wellness'];

function App() {
  const [state, setState] = usePersistentState();
  const [view, setView] = useState<ViewId>('home');
  const [showSplash, setShowSplash] = useState(true);
  const [showSimulationNotice, setShowSimulationNotice] = useState(
    () => localStorage.getItem('voxora-simulation-notice-v1') !== 'seen',
  );
  const [activeRoomId, setActiveRoomId] = useState<string | null>(state.rooms[0]?.id ?? null);
  const [notificationsOpen, setNotificationsOpen] = useState(false);

  const currentUser = useMemo(
    () => state.users.find((user) => user.id === state.sessionUserId) ?? null,
    [state.sessionUserId, state.users],
  );

  useEffect(() => {
    const timeout = window.setTimeout(() => setShowSplash(false), 900);
    return () => window.clearTimeout(timeout);
  }, []);

  const unreadCount = state.notifications.filter((notification) => !notification.read).length;
  const activeRoom = state.rooms.find((room) => room.id === activeRoomId) ?? state.rooms[0] ?? null;

  const pushNotification = (notification: Omit<NotificationItem, 'id' | 'time' | 'read'>) => {
    setState((previous) => ({
      ...previous,
      notifications: [
        {
          id: uid('nt'),
          time: new Date().toISOString(),
          read: false,
          ...notification,
        },
        ...previous.notifications,
      ],
    }));
  };

  const handleAuth = (mode: 'login' | 'register', form: FormData) => {
    const name = String(form.get('name') ?? '').trim() || 'Voxora Guest';
    const handle = String(form.get('handle') ?? '').trim().toLowerCase().replace(/[^a-z0-9._]/g, '') || 'guest';
    const bio = String(form.get('bio') ?? '').trim() || 'New to Voxora and ready to join the room.';

    setState((previous) => {
      const existing = previous.users.find((user) => user.handle.toLowerCase() === handle);
      if (mode === 'login' && existing) {
        return { ...previous, sessionUserId: existing.id };
      }

      const id = uid('user');
      const newUser: User = {
        id,
        name,
        handle,
        avatar: 'assets/avatar-zain.png',
        cover: 'assets/room-aurora.png',
        bio,
        followers: [],
        following: ['user-sana'],
        level: 1,
        vipTier: 'Free',
        coins: 1000,
        earnings: 0,
        popularity: 10,
        activity: 12,
        blocked: false,
        badges: ['New Voice'],
        interests: ['Friends', 'Music'],
        joinedAt: new Date().toISOString(),
      };

      return {
        ...previous,
        sessionUserId: id,
        users: [newUser, ...previous.users],
        notifications: [
          {
            id: uid('nt'),
            type: 'system',
            title: 'Profile ready',
            body: 'Your Voxora profile and starter wallet are active.',
            time: new Date().toISOString(),
            read: false,
          },
          ...previous.notifications,
        ],
      };
    });
  };

  const signOut = () => {
    setState((previous) => ({ ...previous, sessionUserId: null }));
    setView('home');
  };

  const resetDemo = () => {
    setState(resetAppState());
    setActiveRoomId(createInitialState().rooms[0].id);
    setView('home');
  };

  const closeSimulationNotice = () => {
    localStorage.setItem('voxora-simulation-notice-v1', 'seen');
    setShowSimulationNotice(false);
  };

  const markNotificationsRead = () => {
    setState((previous) => ({
      ...previous,
      notifications: previous.notifications.map((notification) => ({ ...notification, read: true })),
    }));
  };

  const updateCurrentUser = (patch: Partial<User>) => {
    if (!currentUser) {
      return;
    }

    setState((previous) => ({
      ...previous,
      users: previous.users.map((user) => (user.id === currentUser.id ? { ...user, ...patch } : user)),
    }));
  };

  const toggleFollow = (targetId: string) => {
    if (!currentUser || targetId === currentUser.id) {
      return;
    }

    setState((previous) => {
      const viewer = previous.users.find((user) => user.id === currentUser.id);
      const target = previous.users.find((user) => user.id === targetId);
      if (!viewer || !target) {
        return previous;
      }

      const following = viewer.following.includes(targetId);
      const notifications = following
        ? previous.notifications
        : [
            {
              id: uid('nt'),
              type: 'follower' as const,
              title: 'Followed creator',
              body: `You are now following ${target.name}.`,
              time: new Date().toISOString(),
              read: false,
            },
            ...previous.notifications,
          ];

      return {
        ...previous,
        users: previous.users.map((user) => {
          if (user.id === viewer.id) {
            return {
              ...user,
              following: following
                ? user.following.filter((id) => id !== targetId)
                : [...user.following, targetId],
              activity: Math.min(100, user.activity + (following ? -1 : 2)),
            };
          }

          if (user.id === targetId) {
            return {
              ...user,
              followers: following
                ? user.followers.filter((id) => id !== viewer.id)
                : [...user.followers, viewer.id],
              popularity: Math.max(0, Math.min(100, user.popularity + (following ? -2 : 3))),
            };
          }

          return user;
        }),
        notifications,
      };
    });
  };

  const createRoom = (form: FormData) => {
    if (!currentUser) {
      return;
    }

    const room: Room = {
      id: uid('room'),
      title: String(form.get('title') ?? '').trim() || `${currentUser.name}'s Room`,
      topic: String(form.get('topic') ?? 'Music'),
      language: String(form.get('language') ?? 'Urdu / English'),
      hostId: currentUser.id,
      hostName: currentUser.name,
      cover: 'assets/room-aurora.png',
      mood: String(form.get('mood') ?? 'Live'),
      description: String(form.get('description') ?? '').trim() || 'A fresh Voxora room is live.',
      tags: String(form.get('tags') ?? 'Voice, Friends')
        .split(',')
        .map((tag) => tag.trim())
        .filter(Boolean)
        .slice(0, 4),
      participants: [
        {
          userId: currentUser.id,
          name: currentUser.name,
          avatar: currentUser.avatar,
          role: 'host',
          muted: false,
          speaking: true,
          vipTier: currentUser.vipTier,
        },
      ],
      capacity: Number(form.get('capacity') ?? 18),
      live: true,
      locked: false,
      giftsReceived: 0,
      raisedHands: [],
      messages: [
        {
          id: uid('rm'),
          userId: currentUser.id,
          name: currentUser.name,
          body: 'Room is live.',
          time: new Date().toISOString(),
          kind: 'system',
        },
      ],
      startedAt: new Date().toISOString(),
    };

    setState((previous) => ({
      ...previous,
      rooms: [room, ...previous.rooms],
      users: previous.users.map((user) =>
        user.id === currentUser.id ? { ...user, activity: Math.min(100, user.activity + 5) } : user,
      ),
    }));
    setActiveRoomId(room.id);
    setView('rooms');
  };

  const joinRoom = (roomId: string) => {
    if (!currentUser) {
      return;
    }

    setState((previous) => ({
      ...previous,
      rooms: previous.rooms.map((room) => {
        if (room.id !== roomId) {
          return room;
        }

        const alreadyInside = room.participants.some((participant) => participant.userId === currentUser.id);
        if (alreadyInside || room.participants.length >= room.capacity || room.locked || !room.live) {
          return room;
        }

        return {
          ...room,
          participants: [
            ...room.participants,
            {
              userId: currentUser.id,
              name: currentUser.name,
              avatar: currentUser.avatar,
              role: 'listener',
              muted: true,
              speaking: false,
              vipTier: currentUser.vipTier,
            },
          ],
          messages: [
            ...room.messages,
            {
              id: uid('rm'),
              userId: currentUser.id,
              name: currentUser.name,
              body: `${currentUser.name} joined the room.`,
              time: new Date().toISOString(),
              kind: 'system',
            },
          ],
        };
      }),
      users: previous.users.map((user) =>
        user.id === currentUser.id ? { ...user, activity: Math.min(100, user.activity + 2) } : user,
      ),
    }));
    setActiveRoomId(roomId);
    setView('rooms');
  };

  const leaveRoom = (roomId: string) => {
    if (!currentUser) {
      return;
    }

    setState((previous) => ({
      ...previous,
      rooms: previous.rooms.map((room) => {
        if (room.id !== roomId) {
          return room;
        }

        if (room.hostId === currentUser.id) {
          return { ...room, live: false, participants: room.participants.filter((p) => p.userId !== currentUser.id) };
        }

        return {
          ...room,
          participants: room.participants.filter((participant) => participant.userId !== currentUser.id),
        };
      }),
    }));
    setActiveRoomId(null);
  };

  const sendRoomMessage = (roomId: string, body: string) => {
    if (!currentUser || !body.trim()) {
      return;
    }

    setState((previous) => ({
      ...previous,
      rooms: previous.rooms.map((room) =>
        room.id === roomId
          ? {
              ...room,
              messages: [
                ...room.messages,
                {
                  id: uid('rm'),
                  userId: currentUser.id,
                  name: currentUser.name,
                  body: body.trim(),
                  time: new Date().toISOString(),
                  kind: 'chat',
                },
              ],
            }
          : room,
      ),
    }));
  };

  const toggleHand = (roomId: string) => {
    if (!currentUser) {
      return;
    }

    setState((previous) => ({
      ...previous,
      rooms: previous.rooms.map((room) => {
        if (room.id !== roomId) {
          return room;
        }

        const raised = room.raisedHands.includes(currentUser.id);
        return {
          ...room,
          raisedHands: raised
            ? room.raisedHands.filter((userId) => userId !== currentUser.id)
            : [...room.raisedHands, currentUser.id],
        };
      }),
    }));
  };

  const sendGift = (roomId: string, giftId: string) => {
    if (!currentUser) {
      return;
    }

    const gift = state.gifts.find((item) => item.id === giftId);
    const room = state.rooms.find((item) => item.id === roomId);
    if (!gift || !room) {
      return;
    }

    if (currentUser.coins < gift.price) {
      pushNotification({
        type: 'wallet',
        title: 'More coins needed',
        body: `${gift.name} costs ${gift.price} coins.`,
      });
      setView('wallet');
      return;
    }

    const transaction: Transaction = {
      id: uid('tx'),
      type: 'gift',
      amount: -gift.price,
      method: 'Room Gift',
      status: 'completed',
      detail: `${gift.name} sent in ${room.title}`,
      time: new Date().toISOString(),
    };

    setState((previous) => ({
      ...previous,
      users: previous.users.map((user) => {
        if (user.id === currentUser.id) {
          return { ...user, coins: user.coins - gift.price, activity: Math.min(100, user.activity + 3) };
        }

        if (user.id === room.hostId) {
          return {
            ...user,
            earnings: user.earnings + gift.rewardPoints,
            popularity: Math.min(100, user.popularity + 2),
          };
        }

        return user;
      }),
      rooms: previous.rooms.map((item) =>
        item.id === roomId
          ? {
              ...item,
              giftsReceived: item.giftsReceived + gift.price,
              messages: [
                ...item.messages,
                {
                  id: uid('rm'),
                  userId: currentUser.id,
                  name: currentUser.name,
                  body: `${currentUser.name} sent ${gift.name}.`,
                  time: new Date().toISOString(),
                  kind: 'gift',
                },
              ],
            }
          : item,
      ),
      transactions: [transaction, ...previous.transactions],
      notifications: [
        {
          id: uid('nt'),
          type: 'gift',
          title: 'Gift sent',
          body: `${gift.name} boosted ${room.hostName}'s room.`,
          time: new Date().toISOString(),
          read: false,
        },
        ...previous.notifications,
      ],
    }));
  };

  const buyCoins = (pack: (typeof coinPackages)[number]) => {
    if (!currentUser) {
      return;
    }

    setState((previous) => ({
      ...previous,
      users: previous.users.map((user) =>
        user.id === currentUser.id ? { ...user, coins: user.coins + pack.coins } : user,
      ),
      transactions: [
        {
          id: uid('tx'),
          type: 'purchase',
          amount: pack.coins,
          method: pack.method,
          status: 'completed',
          detail: `${pack.label} top-up`,
          time: new Date().toISOString(),
        },
        ...previous.transactions,
      ],
      notifications: [
        {
          id: uid('nt'),
          type: 'wallet',
          title: 'Coins added',
          body: `${formatNumber(pack.coins)} coins were added through ${pack.method}.`,
          time: new Date().toISOString(),
          read: false,
        },
        ...previous.notifications,
      ],
    }));
  };

  const activateVip = (plan: VipPlan) => {
    if (!currentUser) {
      return;
    }

    if (currentUser.coins < plan.price) {
      pushNotification({
        type: 'wallet',
        title: 'VIP upgrade paused',
        body: `${plan.id} needs ${formatNumber(plan.price)} coins.`,
      });
      setView('wallet');
      return;
    }

    setState((previous) => ({
      ...previous,
      users: previous.users.map((user) =>
        user.id === currentUser.id
          ? {
              ...user,
              vipTier: plan.id,
              coins: user.coins - plan.price,
              badges: Array.from(new Set([...user.badges, `${plan.id} VIP`])),
              popularity: Math.min(100, user.popularity + 5),
            }
          : user,
      ),
      transactions: [
        {
          id: uid('tx'),
          type: 'vip',
          amount: -plan.price,
          method: 'VIP Upgrade',
          status: 'completed',
          detail: `${plan.id} membership activated`,
          time: new Date().toISOString(),
        },
        ...previous.transactions,
      ],
      notifications: [
        {
          id: uid('nt'),
          type: 'system',
          title: 'VIP active',
          body: `${plan.id} benefits are now attached to your profile.`,
          time: new Date().toISOString(),
          read: false,
        },
        ...previous.notifications,
      ],
    }));
  };

  const sendDirectMessage = (threadId: string, body: string) => {
    if (!currentUser || !body.trim()) {
      return;
    }

    setState((previous) => ({
      ...previous,
      threads: previous.threads.map((thread) =>
        thread.id === threadId
          ? {
              ...thread,
              unread: 0,
              lastMessage: body.trim(),
              messages: [
                ...thread.messages,
                { id: uid('dm'), from: currentUser.id, body: body.trim(), time: new Date().toISOString() },
              ],
            }
          : thread,
      ),
    }));
  };

  const messageUser = (user: User) => {
    if (!currentUser || user.id === currentUser.id) {
      return;
    }

    setState((previous) => {
      const existingThread = previous.threads.find((thread) => thread.userId === user.id);
      if (existingThread) {
        return previous;
      }

      return {
        ...previous,
        threads: [
          {
            id: uid('thread'),
            userId: user.id,
            userName: user.name,
            avatar: user.avatar,
            lastMessage: 'Conversation started.',
            unread: 0,
            messages: [
              {
                id: uid('dm'),
                from: currentUser.id,
                body: 'Conversation started.',
                time: new Date().toISOString(),
              },
            ],
          },
          ...previous.threads,
        ],
      };
    });
    setView('messages');
  };

  const adminToggleUserBlock = (userId: string) => {
    setState((previous) => ({
      ...previous,
      users: previous.users.map((user) => (user.id === userId ? { ...user, blocked: !user.blocked } : user)),
    }));
  };

  const adminToggleRoomLock = (roomId: string) => {
    setState((previous) => ({
      ...previous,
      rooms: previous.rooms.map((room) => (room.id === roomId ? { ...room, locked: !room.locked } : room)),
    }));
  };

  const adminEndRoom = (roomId: string) => {
    setState((previous) => ({
      ...previous,
      rooms: previous.rooms.map((room) => (room.id === roomId ? { ...room, live: false, locked: true } : room)),
    }));
  };

  const adminSaveGift = (form: FormData) => {
    const name = String(form.get('giftName') ?? '').trim();
    const price = Number(form.get('giftPrice') ?? 0);
    if (!name || price < 1) {
      return;
    }

    setState((previous) => ({
      ...previous,
      gifts: [
        {
          id: uid('gift'),
          name,
          label: name
            .split(' ')
            .map((part) => part[0])
            .join('')
            .slice(0, 2)
            .toUpperCase(),
          price,
          rewardPoints: Math.max(1, Math.round(price / 4)),
          accent: '#3bebc2',
        },
        ...previous.gifts,
      ],
    }));
  };

  const adminSendAnnouncement = (form: FormData) => {
    const title = String(form.get('title') ?? '').trim();
    const body = String(form.get('body') ?? '').trim();
    if (!title || !body) {
      return;
    }

    const announcement: NotificationItem = {
      id: uid('an'),
      type: 'system',
      title,
      body,
      time: new Date().toISOString(),
      read: false,
    };

    setState((previous) => ({
      ...previous,
      announcements: [announcement, ...previous.announcements],
      notifications: [announcement, ...previous.notifications],
    }));
  };

  const updateGameStats = (patch: Partial<AppState['gameStats']>, coinBonus = 0) => {
    if (!currentUser) {
      return;
    }

    setState((previous) => ({
      ...previous,
      gameStats: { ...previous.gameStats, ...patch },
      users: previous.users.map((user) =>
        user.id === currentUser.id
          ? {
              ...user,
              coins: user.coins + coinBonus,
              activity: Math.min(100, user.activity + 1),
            }
          : user,
      ),
      transactions:
        coinBonus > 0
          ? [
              {
                id: uid('tx'),
                type: 'bonus',
                amount: coinBonus,
                method: 'Admin',
                status: 'completed',
                detail: 'Mini game reward',
                time: new Date().toISOString(),
              },
              ...previous.transactions,
            ]
          : previous.transactions,
    }));
  };

  if (showSplash) {
    return <SplashScreen />;
  }

  if (!currentUser) {
    return (
      <>
        <AuthScreen onAuth={handleAuth} />
        {showSimulationNotice && <SimulationNotice onClose={closeSimulationNotice} />}
      </>
    );
  }

  return (
    <div className="app-shell">
      <Sidebar active={view} onNavigate={setView} />
      <main className="main-surface">
        <Topbar
          currentUser={currentUser}
          unreadCount={unreadCount}
          notificationsOpen={notificationsOpen}
          notifications={state.notifications}
          onToggleNotifications={() => setNotificationsOpen((open) => !open)}
          onReadAll={markNotificationsRead}
          onSignOut={signOut}
          onResetDemo={resetDemo}
        />

        {view === 'home' && (
          <HomeScreen
            state={state}
            currentUser={currentUser}
            onNavigate={setView}
            onJoinRoom={joinRoom}
            onFollow={toggleFollow}
            onMessageUser={messageUser}
          />
        )}
        {view === 'rooms' && (
          <RoomsScreen
            state={state}
            currentUser={currentUser}
            activeRoom={activeRoom}
            onCreateRoom={createRoom}
            onJoinRoom={joinRoom}
            onSelectRoom={setActiveRoomId}
            onLeaveRoom={leaveRoom}
            onSendRoomMessage={sendRoomMessage}
            onToggleHand={toggleHand}
            onSendGift={sendGift}
          />
        )}
        {view === 'messages' && (
          <MessagesScreen
            threads={state.threads}
            currentUser={currentUser}
            onSendMessage={sendDirectMessage}
          />
        )}
        {view === 'profile' && (
          <ProfileScreen
            state={state}
            currentUser={currentUser}
            onUpdateUser={updateCurrentUser}
            onFollow={toggleFollow}
            onMessageUser={messageUser}
          />
        )}
        {view === 'wallet' && (
          <WalletScreen
            currentUser={currentUser}
            gifts={state.gifts}
            transactions={state.transactions}
            onBuyCoins={buyCoins}
          />
        )}
        {view === 'vip' && (
          <VipScreen currentUser={currentUser} plans={state.vipPlans} onActivateVip={activateVip} />
        )}
        {view === 'games' && (
          <GamesScreen currentUser={currentUser} stats={state.gameStats} onUpdateStats={updateGameStats} />
        )}
        {view === 'admin' && (
          <AdminPanel
            state={state}
            onToggleUserBlock={adminToggleUserBlock}
            onToggleRoomLock={adminToggleRoomLock}
            onEndRoom={adminEndRoom}
            onSaveGift={adminSaveGift}
            onSendAnnouncement={adminSendAnnouncement}
          />
        )}
      </main>
      <MobileNav active={view} onNavigate={setView} />
      {showSimulationNotice && <SimulationNotice onClose={closeSimulationNotice} />}
    </div>
  );
}

function SimulationNotice({ onClose }: { onClose: () => void }) {
  return (
    <div className="simulation-backdrop" role="dialog" aria-modal="true" aria-labelledby="simulation-title">
      <section className="simulation-card">
        <span className="simulation-mark">
          <Sparkles size={24} />
        </span>
        <p className="eyebrow">Stage Mode</p>
        <h2 id="simulation-title">This is a simulation, not a real live app.</h2>
        <p>
          Voxora on GitHub Pages is an interactive prototype. Voice rooms, gifts, coins, VIP,
          messages, payments, and admin actions are demo flows stored in this browser only.
        </p>
        <div className="simulation-strip">
          <span>No real calls</span>
          <span>No real payments</span>
          <span>No public accounts</span>
        </div>
        <button className="primary-action" type="button" onClick={onClose}>
          <Radio size={18} />
          Enter the Simulation
        </button>
      </section>
    </div>
  );
}

function SplashScreen() {
  return (
    <section className="splash-screen">
      <div className="splash-card">
        <img src="assets/brand-mark.png" alt="Voxora mark" />
        <div>
          <p className="eyebrow">Social Voice Network</p>
          <h1>Voxora</h1>
          <span className="loading-bar" aria-hidden="true" />
        </div>
      </div>
    </section>
  );
}

function AuthScreen({ onAuth }: { onAuth: (mode: 'login' | 'register', form: FormData) => void }) {
  const [mode, setMode] = useState<'login' | 'register'>('login');

  const submit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    onAuth(mode, new FormData(event.currentTarget));
  };

  return (
    <main className="auth-layout">
      <section className="auth-visual">
        <img src="assets/room-aurora.png" alt="Abstract live voice room" />
        <div className="auth-brand">
          <img src="assets/brand-mark.png" alt="" />
          <div>
            <p className="eyebrow">Meet Voxora</p>
            <h1>Voice rooms with gifts, games, VIP, and real community energy.</h1>
          </div>
        </div>
      </section>
      <section className="auth-panel">
        <div className="segmented">
          <button className={cx(mode === 'login' && 'active')} onClick={() => setMode('login')} type="button">
            Login
          </button>
          <button className={cx(mode === 'register' && 'active')} onClick={() => setMode('register')} type="button">
            Register
          </button>
        </div>
        <form onSubmit={submit} className="stacked-form">
          {mode === 'register' && (
            <label>
              Display name
              <input name="name" placeholder="Zain Tahir" autoComplete="name" />
            </label>
          )}
          <label>
            Handle
            <input name="handle" placeholder="zain" autoComplete="username" />
          </label>
          {mode === 'register' && (
            <label>
              Bio
              <textarea name="bio" placeholder="What kind of rooms do you host?" rows={4} />
            </label>
          )}
          <button className="primary-action" type="submit">
            <Radio size={18} />
            {mode === 'login' ? 'Enter Voxora' : 'Create Profile'}
          </button>
        </form>
        <div className="auth-note">
          <BadgeCheck size={18} />
          <span>Use handle "zain" for the complete seeded demo account.</span>
        </div>
      </section>
    </main>
  );
}

function Sidebar({ active, onNavigate }: { active: ViewId; onNavigate: (view: ViewId) => void }) {
  return (
    <aside className="sidebar">
      <div className="brand-lockup">
        <img src="assets/brand-mark.png" alt="" />
        <div>
          <strong>Voxora</strong>
          <span>Social Voice</span>
        </div>
      </div>
      <nav>
        {navItems.map((item) => {
          const Icon = item.icon;
          return (
            <button
              key={item.id}
              className={cx('nav-item', active === item.id && 'active')}
              onClick={() => onNavigate(item.id)}
              type="button"
            >
              <Icon size={20} />
              <span>{item.label}</span>
            </button>
          );
        })}
      </nav>
      <div className="sidebar-status">
        <span className="pulse-dot" />
        <div>
          <strong>Demo live</strong>
          <span>Free local mode</span>
        </div>
      </div>
    </aside>
  );
}

function MobileNav({ active, onNavigate }: { active: ViewId; onNavigate: (view: ViewId) => void }) {
  return (
    <nav className="mobile-nav">
      {navItems.slice(0, 5).map((item) => {
        const Icon = item.icon;
        return (
          <button
            key={item.id}
            type="button"
            aria-label={item.label}
            className={cx(active === item.id && 'active')}
            onClick={() => onNavigate(item.id)}
          >
            <Icon size={20} />
          </button>
        );
      })}
    </nav>
  );
}

function Topbar({
  currentUser,
  unreadCount,
  notificationsOpen,
  notifications,
  onToggleNotifications,
  onReadAll,
  onSignOut,
  onResetDemo,
}: {
  currentUser: User;
  unreadCount: number;
  notificationsOpen: boolean;
  notifications: NotificationItem[];
  onToggleNotifications: () => void;
  onReadAll: () => void;
  onSignOut: () => void;
  onResetDemo: () => void;
}) {
  return (
    <header className="topbar">
      <div>
        <p className="eyebrow">Welcome back</p>
        <h2>{currentUser.name}</h2>
      </div>
      <div className="topbar-actions">
        <button className="icon-button" onClick={onResetDemo} type="button" title="Reset demo">
          <RefreshCw size={18} />
        </button>
        <div className="notification-wrap">
          <button className="icon-button" onClick={onToggleNotifications} type="button" title="Notifications">
            <Bell size={18} />
            {unreadCount > 0 && <span className="badge-count">{unreadCount}</span>}
          </button>
          {notificationsOpen && (
            <div className="popover">
              <div className="popover-head">
                <strong>Notifications</strong>
                <button type="button" onClick={onReadAll}>
                  Mark read
                </button>
              </div>
              <div className="notification-list">
                {notifications.slice(0, 8).map((notification) => (
                  <article key={notification.id} className={cx('notification-item', !notification.read && 'unread')}>
                    <span>{notification.title}</span>
                    <p>{notification.body}</p>
                    <small>{formatTime(notification.time)}</small>
                  </article>
                ))}
              </div>
            </div>
          )}
        </div>
        <div className="profile-chip">
          <img src={currentUser.avatar} alt="" />
          <span>{currentUser.vipTier}</span>
        </div>
        <button className="icon-button" onClick={onSignOut} type="button" title="Sign out">
          <LogOut size={18} />
        </button>
      </div>
    </header>
  );
}

function HomeScreen({
  state,
  currentUser,
  onNavigate,
  onJoinRoom,
  onFollow,
  onMessageUser,
}: {
  state: AppState;
  currentUser: User;
  onNavigate: (view: ViewId) => void;
  onJoinRoom: (roomId: string) => void;
  onFollow: (userId: string) => void;
  onMessageUser: (user: User) => void;
}) {
  const liveRooms = state.rooms.filter((room) => room.live);
  const topHosts = [...state.users].sort((a, b) => b.earnings - a.earnings).slice(0, 4);

  return (
    <div className="screen-grid home-grid">
      <section className="hero-panel">
        <img src="assets/room-midnight.png" alt="Voxora live room artwork" />
        <div className="hero-content">
          <p className="eyebrow">Live now on Voxora</p>
          <h1>Rooms, rewards, friends, and host tools in one voice-first space.</h1>
          <div className="hero-actions">
            <button className="primary-action" type="button" onClick={() => onNavigate('rooms')}>
              <Mic size={18} />
              Join a Room
            </button>
            <button className="secondary-action" type="button" onClick={() => onNavigate('wallet')}>
              <Coins size={18} />
              {formatNumber(currentUser.coins)} Coins
            </button>
          </div>
        </div>
      </section>

      <section className="metric-row">
        <Metric icon={Users} label="Users" value={formatNumber(state.users.length)} tone="mint" />
        <Metric icon={Radio} label="Active rooms" value={formatNumber(liveRooms.length)} tone="cyan" />
        <Metric icon={Gift} label="Gift volume" value={formatNumber(state.rooms.reduce((sum, room) => sum + room.giftsReceived, 0))} tone="coral" />
        <Metric icon={Trophy} label="Your level" value={currentUser.level.toString()} tone="gold" />
      </section>

      <section className="content-section span-2">
        <SectionTitle icon={Radio} title="Featured Rooms" action="View all" onAction={() => onNavigate('rooms')} />
        <div className="room-card-grid">
          {liveRooms.slice(0, 3).map((room) => (
            <RoomCard key={room.id} room={room} onJoinRoom={onJoinRoom} />
          ))}
        </div>
      </section>

      <section className="content-section">
        <SectionTitle icon={Trophy} title="Leaderboards" />
        <div className="leader-list">
          {topHosts.map((host, index) => (
            <button className="leader-row" type="button" key={host.id} onClick={() => onMessageUser(host)}>
              <span className="rank">{index + 1}</span>
              <img src={host.avatar} alt="" />
              <div>
                <strong>{host.name}</strong>
                <small>{formatNumber(host.earnings)} host points</small>
              </div>
              <Crown size={18} />
            </button>
          ))}
        </div>
      </section>

      <section className="content-section">
        <SectionTitle icon={UserPlus} title="Suggested Follows" />
        <div className="creator-stack">
          {state.users
            .filter((user) => user.id !== currentUser.id)
            .slice(0, 4)
            .map((user) => {
              const following = currentUser.following.includes(user.id);
              return (
                <article className="creator-card" key={user.id}>
                  <img src={user.avatar} alt="" />
                  <div>
                    <strong>{user.name}</strong>
                    <small>@{user.handle}</small>
                  </div>
                  <button className={cx('pill-button', following && 'active')} onClick={() => onFollow(user.id)} type="button">
                    {following ? <Check size={16} /> : <UserPlus size={16} />}
                    {following ? 'Following' : 'Follow'}
                  </button>
                </article>
              );
            })}
        </div>
      </section>
    </div>
  );
}

function RoomsScreen({
  state,
  currentUser,
  activeRoom,
  onCreateRoom,
  onJoinRoom,
  onSelectRoom,
  onLeaveRoom,
  onSendRoomMessage,
  onToggleHand,
  onSendGift,
}: {
  state: AppState;
  currentUser: User;
  activeRoom: Room | null;
  onCreateRoom: (form: FormData) => void;
  onJoinRoom: (roomId: string) => void;
  onSelectRoom: (roomId: string) => void;
  onLeaveRoom: (roomId: string) => void;
  onSendRoomMessage: (roomId: string, body: string) => void;
  onToggleHand: (roomId: string) => void;
  onSendGift: (roomId: string, giftId: string) => void;
}) {
  const [createOpen, setCreateOpen] = useState(false);
  const [query, setQuery] = useState('');
  const [topic, setTopic] = useState('All');
  const filteredRooms = state.rooms.filter((room) => {
    const matchesTopic = topic === 'All' || room.topic === topic || room.tags.includes(topic);
    const matchesQuery = `${room.title} ${room.hostName} ${room.tags.join(' ')}`
      .toLowerCase()
      .includes(query.toLowerCase());
    return matchesTopic && matchesQuery;
  });

  const submitRoom = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    onCreateRoom(new FormData(event.currentTarget));
    setCreateOpen(false);
    event.currentTarget.reset();
  };

  return (
    <div className="rooms-layout">
      <section className="content-section room-directory">
        <SectionTitle icon={Radio} title="Live Rooms" />
        <div className="toolbar">
          <label className="search-field">
            <Search size={18} />
            <input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Search rooms" />
          </label>
          <button className="primary-action compact" type="button" onClick={() => setCreateOpen(true)}>
            <Plus size={18} />
            Go Live
          </button>
        </div>
        <div className="topic-tabs">
          {topics.map((item) => (
            <button key={item} className={cx(topic === item && 'active')} type="button" onClick={() => setTopic(item)}>
              {item}
            </button>
          ))}
        </div>
        <div className="room-list">
          {filteredRooms.map((room) => (
            <button
              key={room.id}
              type="button"
              onClick={() => {
                onSelectRoom(room.id);
                onJoinRoom(room.id);
              }}
              className={cx('room-list-card', activeRoom?.id === room.id && 'active')}
            >
              <img src={room.cover} alt="" />
              <div>
                <strong>{room.title}</strong>
                <span>{room.hostName}</span>
                <small>{room.participants.length}/{room.capacity} voices</small>
              </div>
              {room.locked ? <Lock size={18} /> : <Radio size={18} />}
            </button>
          ))}
        </div>
      </section>

      {activeRoom ? (
        <RoomExperience
          room={activeRoom}
          currentUser={currentUser}
          gifts={state.gifts}
          onLeaveRoom={onLeaveRoom}
          onSendRoomMessage={onSendRoomMessage}
          onToggleHand={onToggleHand}
          onSendGift={onSendGift}
        />
      ) : (
        <section className="content-section empty-state">
          <Radio size={36} />
          <h3>No room selected</h3>
          <p>Select a live room or create one.</p>
        </section>
      )}

      {createOpen && (
        <div className="modal-backdrop" role="presentation">
          <form className="modal-card stacked-form" onSubmit={submitRoom}>
            <div className="modal-head">
              <h3>Create voice room</h3>
              <button type="button" className="icon-button" onClick={() => setCreateOpen(false)}>
                <X size={18} />
              </button>
            </div>
            <label>
              Room title
              <input name="title" placeholder="After Class Hangout" required />
            </label>
            <div className="two-col">
              <label>
                Topic
                <select name="topic" defaultValue="Music">
                  {topics.filter((item) => item !== 'All').map((item) => (
                    <option key={item}>{item}</option>
                  ))}
                </select>
              </label>
              <label>
                Capacity
                <input name="capacity" type="number" min={4} max={80} defaultValue={18} />
              </label>
            </div>
            <label>
              Mood
              <input name="mood" placeholder="Chill" />
            </label>
            <label>
              Language
              <input name="language" placeholder="Urdu / English" />
            </label>
            <label>
              Tags
              <input name="tags" placeholder="Music, Friends, Stories" />
            </label>
            <label>
              Description
              <textarea name="description" rows={3} placeholder="Room tone and topic" />
            </label>
            <button className="primary-action" type="submit">
              <Radio size={18} />
              Start Room
            </button>
          </form>
        </div>
      )}
    </div>
  );
}

function RoomExperience({
  room,
  currentUser,
  gifts,
  onLeaveRoom,
  onSendRoomMessage,
  onToggleHand,
  onSendGift,
}: {
  room: Room;
  currentUser: User;
  gifts: GiftType[];
  onLeaveRoom: (roomId: string) => void;
  onSendRoomMessage: (roomId: string, body: string) => void;
  onToggleHand: (roomId: string) => void;
  onSendGift: (roomId: string, giftId: string) => void;
}) {
  const [micOn, setMicOn] = useState(false);
  const [message, setMessage] = useState('');
  const { level, status } = useVoiceMeter(micOn);
  const participant = room.participants.find((item) => item.userId === currentUser.id);
  const insideRoom = Boolean(participant);
  const handRaised = room.raisedHands.includes(currentUser.id);

  const submitMessage = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    onSendRoomMessage(room.id, message);
    setMessage('');
  };

  return (
    <section className="content-section room-stage">
      <div className="room-cover">
        <img src={room.cover} alt="" />
        <div>
          <p className="eyebrow">{room.topic} - {room.language}</p>
          <h2>{room.title}</h2>
          <span>{room.description}</span>
        </div>
        <button className="danger-action" type="button" onClick={() => onLeaveRoom(room.id)}>
          <PhoneOff size={18} />
          Leave
        </button>
      </div>

      <div className="stage-meta">
        <Metric icon={Users} label="Voices" value={`${room.participants.length}/${room.capacity}`} tone="mint" />
        <Metric icon={Gift} label="Gifts" value={formatNumber(room.giftsReceived)} tone="coral" />
        <Metric icon={Hand} label="Raised" value={room.raisedHands.length.toString()} tone="gold" />
      </div>

      <div className="participant-grid">
        {room.participants.map((person) => (
          <article className={cx('seat-card', person.speaking && 'speaking')} key={person.userId}>
            <img src={person.avatar} alt="" />
            <strong>{person.name}</strong>
            <span>{person.role}</span>
            <small>{person.vipTier}</small>
            {person.muted ? <MicOff size={16} /> : <Mic size={16} />}
          </article>
        ))}
      </div>

      <div className="control-dock">
        <button className={cx('control-button', micOn && 'active')} type="button" onClick={() => setMicOn((on) => !on)}>
          {micOn ? <Mic size={20} /> : <MicOff size={20} />}
          <span>{micOn ? 'Mic On' : 'Mic Off'}</span>
        </button>
        <button
          className={cx('control-button', handRaised && 'active')}
          type="button"
          onClick={() => onToggleHand(room.id)}
          disabled={!insideRoom}
        >
          <Hand size={20} />
          <span>{handRaised ? 'Hand Raised' : 'Raise Hand'}</span>
        </button>
        <div className="voice-meter" aria-label={`Microphone level ${level}`}>
          <span style={{ width: `${micOn ? level : 0}%` }} />
        </div>
        <small>{status === 'blocked' ? 'Mic permission blocked' : status === 'unsupported' ? 'Mic unsupported' : 'Live audio meter'}</small>
      </div>

      <div className="room-bottom">
        <div className="room-chat">
          <div className="chat-log">
            {room.messages.slice(-8).map((item) => (
              <article key={item.id} className={cx('chat-line', item.kind)}>
                <strong>{item.name}</strong>
                <p>{item.body}</p>
                <small>{formatTime(item.time)}</small>
              </article>
            ))}
          </div>
          <form className="message-form" onSubmit={submitMessage}>
            <input
              value={message}
              onChange={(event) => setMessage(event.target.value)}
              placeholder="Send room chat"
              disabled={!insideRoom}
            />
            <button type="submit" disabled={!message.trim() || !insideRoom}>
              <Send size={18} />
            </button>
          </form>
        </div>

        <div className="gift-shelf">
          <strong>Virtual gifts</strong>
          {gifts.slice(0, 5).map((gift) => (
            <button key={gift.id} type="button" onClick={() => onSendGift(room.id, gift.id)}>
              <span style={{ background: gift.accent }}>{gift.label}</span>
              <div>
                <b>{gift.name}</b>
                <small>{gift.price} coins</small>
              </div>
            </button>
          ))}
        </div>
      </div>
    </section>
  );
}

function MessagesScreen({
  threads,
  currentUser,
  onSendMessage,
}: {
  threads: MessageThread[];
  currentUser: User;
  onSendMessage: (threadId: string, body: string) => void;
}) {
  const [activeThreadId, setActiveThreadId] = useState(threads[0]?.id ?? '');
  const [message, setMessage] = useState('');
  const activeThread = threads.find((thread) => thread.id === activeThreadId) ?? threads[0];

  const submitMessage = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (!activeThread) {
      return;
    }
    onSendMessage(activeThread.id, message);
    setMessage('');
  };

  return (
    <div className="messages-layout">
      <section className="content-section thread-list">
        <SectionTitle icon={MessageCircle} title="Private Messages" />
        {threads.map((thread) => (
          <button
            type="button"
            className={cx('thread-card', activeThread?.id === thread.id && 'active')}
            key={thread.id}
            onClick={() => setActiveThreadId(thread.id)}
          >
            <img src={thread.avatar} alt="" />
            <div>
              <strong>{thread.userName}</strong>
              <span>{thread.lastMessage}</span>
            </div>
            {thread.unread > 0 && <small>{thread.unread}</small>}
          </button>
        ))}
      </section>
      <section className="content-section conversation-panel">
        {activeThread ? (
          <>
            <div className="conversation-head">
              <img src={activeThread.avatar} alt="" />
              <div>
                <h3>{activeThread.userName}</h3>
                <span>Direct chat</span>
              </div>
            </div>
            <div className="conversation-log">
              {activeThread.messages.map((item) => (
                <article className={cx('bubble', item.from === currentUser.id && 'mine')} key={item.id}>
                  <p>{item.body}</p>
                  <small>{formatTime(item.time)}</small>
                </article>
              ))}
            </div>
            <form className="message-form" onSubmit={submitMessage}>
              <input value={message} onChange={(event) => setMessage(event.target.value)} placeholder="Type a message" />
              <button type="submit" disabled={!message.trim()}>
                <Send size={18} />
              </button>
            </form>
          </>
        ) : (
          <div className="empty-state">
            <MessageCircle size={36} />
            <h3>No conversations</h3>
            <p>Start from a profile card.</p>
          </div>
        )}
      </section>
    </div>
  );
}

function ProfileScreen({
  state,
  currentUser,
  onUpdateUser,
  onFollow,
  onMessageUser,
}: {
  state: AppState;
  currentUser: User;
  onUpdateUser: (patch: Partial<User>) => void;
  onFollow: (userId: string) => void;
  onMessageUser: (user: User) => void;
}) {
  const submitProfile = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    onUpdateUser({
      name: String(form.get('name') ?? currentUser.name).trim(),
      bio: String(form.get('bio') ?? currentUser.bio).trim(),
      interests: String(form.get('interests') ?? '')
        .split(',')
        .map((interest) => interest.trim())
        .filter(Boolean),
    });
  };

  return (
    <div className="profile-layout">
      <section className="content-section profile-hero">
        <img className="profile-cover" src={currentUser.cover} alt="" />
        <div className="profile-top">
          <img src={currentUser.avatar} alt="" />
          <div>
            <p className="eyebrow">@{currentUser.handle}</p>
            <h2>{currentUser.name}</h2>
            <span>{currentUser.bio}</span>
          </div>
          <div className="vip-token">
            <Crown size={18} />
            {currentUser.vipTier}
          </div>
        </div>
        <div className="metric-row compact-row">
          <Metric icon={Users} label="Followers" value={formatNumber(currentUser.followers.length)} tone="mint" />
          <Metric icon={UserPlus} label="Following" value={formatNumber(currentUser.following.length)} tone="cyan" />
          <Metric icon={Star} label="Level" value={currentUser.level.toString()} tone="gold" />
          <Metric icon={Activity} label="Activity" value={`${currentUser.activity}%`} tone="coral" />
        </div>
      </section>

      <section className="content-section">
        <SectionTitle icon={BadgeCheck} title="Edit Profile" />
        <form className="stacked-form" onSubmit={submitProfile}>
          <label>
            Display name
            <input name="name" defaultValue={currentUser.name} />
          </label>
          <label>
            Bio
            <textarea name="bio" rows={4} defaultValue={currentUser.bio} />
          </label>
          <label>
            Interests
            <input name="interests" defaultValue={currentUser.interests.join(', ')} />
          </label>
          <button className="primary-action" type="submit">
            <Check size={18} />
            Save Profile
          </button>
        </form>
      </section>

      <section className="content-section">
        <SectionTitle icon={Users} title="Community" />
        <div className="creator-stack">
          {state.users
            .filter((user) => user.id !== currentUser.id)
            .map((user) => {
              const following = currentUser.following.includes(user.id);
              return (
                <article className="creator-card wide" key={user.id}>
                  <img src={user.avatar} alt="" />
                  <div>
                    <strong>{user.name}</strong>
                    <small>{user.bio}</small>
                  </div>
                  <button className={cx('pill-button', following && 'active')} type="button" onClick={() => onFollow(user.id)}>
                    {following ? <Check size={16} /> : <UserPlus size={16} />}
                    {following ? 'Following' : 'Follow'}
                  </button>
                  <button className="icon-button" type="button" onClick={() => onMessageUser(user)}>
                    <MessageCircle size={18} />
                  </button>
                </article>
              );
            })}
        </div>
      </section>
    </div>
  );
}

function WalletScreen({
  currentUser,
  gifts,
  transactions,
  onBuyCoins,
}: {
  currentUser: User;
  gifts: GiftType[];
  transactions: Transaction[];
  onBuyCoins: (pack: (typeof coinPackages)[number]) => void;
}) {
  return (
    <div className="wallet-layout">
      <section className="content-section wallet-balance">
        <SectionTitle icon={WalletCards} title="Wallet" />
        <div className="balance-orb">
          <Coins size={30} />
          <strong>{formatNumber(currentUser.coins)}</strong>
          <span>available coins</span>
        </div>
        <div className="metric-row compact-row">
          <Metric icon={Gift} label="Host earnings" value={formatNumber(currentUser.earnings)} tone="gold" />
          <Metric icon={Crown} label="VIP" value={currentUser.vipTier} tone="coral" />
        </div>
      </section>

      <section className="content-section">
        <SectionTitle icon={WalletCards} title="Coin Packages" />
        <div className="package-grid">
          {coinPackages.map((pack) => (
            <article className="package-card" key={pack.label}>
              <strong>{pack.label}</strong>
              <span>{formatNumber(pack.coins)} coins</span>
              <small>{pack.price}</small>
              <button className="primary-action compact" type="button" onClick={() => onBuyCoins(pack)}>
                <Coins size={18} />
                Add Coins
              </button>
            </article>
          ))}
        </div>
      </section>

      <section className="content-section">
        <SectionTitle icon={Gift} title="Gift Catalog" />
        <div className="gift-grid">
          {gifts.map((gift) => (
            <article className="gift-card" key={gift.id}>
              <span style={{ background: gift.accent }}>{gift.label}</span>
              <strong>{gift.name}</strong>
              <small>{gift.price} coins</small>
            </article>
          ))}
        </div>
      </section>

      <section className="content-section span-2">
        <SectionTitle icon={BarChart3} title="Transactions" />
        <DataTable
          headers={['Type', 'Amount', 'Method', 'Status', 'Date']}
          rows={transactions.slice(0, 10).map((transaction) => [
            transaction.detail,
            `${transaction.amount > 0 ? '+' : ''}${formatNumber(transaction.amount)}`,
            transaction.method,
            transaction.status,
            formatDate(transaction.time),
          ])}
        />
      </section>
    </div>
  );
}

function VipScreen({
  currentUser,
  plans,
  onActivateVip,
}: {
  currentUser: User;
  plans: VipPlan[];
  onActivateVip: (plan: VipPlan) => void;
}) {
  return (
    <div className="vip-layout">
      <section className="content-section vip-head">
        <SectionTitle icon={Crown} title="VIP Membership" />
        <h2>{currentUser.vipTier} tier active</h2>
        <p>Priority visibility, badges, room privileges, and reward boosters are tied to your profile.</p>
      </section>
      <div className="plan-grid">
        {plans.map((plan) => (
          <article className={cx('plan-card', currentUser.vipTier === plan.id && 'active')} key={plan.id}>
            <div className="plan-top">
              <span style={{ background: plan.accent }}>
                <Crown size={18} />
              </span>
              <div>
                <h3>{plan.id}</h3>
                <small>{plan.spotlight}</small>
              </div>
            </div>
            <strong>{formatNumber(plan.price)} coins</strong>
            <ul>
              {plan.benefits.map((benefit) => (
                <li key={benefit}>
                  <Check size={16} />
                  {benefit}
                </li>
              ))}
            </ul>
            <button
              className="primary-action compact"
              type="button"
              onClick={() => onActivateVip(plan)}
              disabled={currentUser.vipTier === plan.id}
            >
              <Sparkles size={18} />
              {currentUser.vipTier === plan.id ? 'Active' : 'Activate'}
            </button>
          </article>
        ))}
      </div>
    </div>
  );
}

function GamesScreen({
  currentUser,
  stats,
  onUpdateStats,
}: {
  currentUser: User;
  stats: AppState['gameStats'];
  onUpdateStats: (patch: Partial<AppState['gameStats']>, coinBonus?: number) => void;
}) {
  const [beatRunning, setBeatRunning] = useState(false);
  const [score, setScore] = useState(0);
  const [seconds, setSeconds] = useState(10);
  const [spinResult, setSpinResult] = useState<string>('Ready');

  useEffect(() => {
    if (!beatRunning) {
      return;
    }

    const timer = window.setInterval(() => {
      setSeconds((value) => {
        if (value <= 1) {
          window.clearInterval(timer);
          setBeatRunning(false);
          const best = Math.max(stats.beatTapBest, score);
          const bonus = score >= best ? 75 : 20;
          onUpdateStats({ beatTapBest: best, dailyStreak: stats.dailyStreak + 1 }, bonus);
          return 10;
        }

        return value - 1;
      });
    }, 1000);

    return () => window.clearInterval(timer);
  }, [beatRunning, onUpdateStats, score, stats.beatTapBest, stats.dailyStreak]);

  const startBeat = () => {
    setScore(0);
    setSeconds(10);
    setBeatRunning(true);
  };

  const spin = () => {
    const rewards = [25, 50, 75, 120, 180];
    const reward = rewards[Math.floor(Math.random() * rewards.length)];
    setSpinResult(`+${reward} coins`);
    onUpdateStats({ spinWins: stats.spinWins + 1 }, reward);
  };

  return (
    <div className="games-layout">
      <section className="content-section game-hero">
        <SectionTitle icon={Gamepad2} title="Mini Games" />
        <div className="metric-row compact-row">
          <Metric icon={Zap} label="Beat best" value={stats.beatTapBest.toString()} tone="cyan" />
          <Metric icon={Flame} label="Streak" value={stats.dailyStreak.toString()} tone="coral" />
          <Metric icon={Coins} label="Coins" value={formatNumber(currentUser.coins)} tone="gold" />
        </div>
      </section>

      <section className="content-section beat-game">
        <SectionTitle icon={Activity} title="Beat Tap" />
        <button
          className={cx('beat-pad', beatRunning && 'active')}
          type="button"
          onClick={() => (beatRunning ? setScore((value) => value + 1) : startBeat())}
        >
          <span>{beatRunning ? score : 'Start'}</span>
        </button>
        <div className="game-controls">
          <span>{seconds}s</span>
          <button className="secondary-action compact" type="button" onClick={startBeat}>
            <Zap size={18} />
            Restart
          </button>
        </div>
      </section>

      <section className="content-section spin-game">
        <SectionTitle icon={Sparkles} title="Lucky Spin" />
        <div className="spin-wheel">
          <Sparkles size={42} />
          <strong>{spinResult}</strong>
        </div>
        <button className="primary-action" type="button" onClick={spin}>
          <RefreshCw size={18} />
          Spin
        </button>
      </section>
    </div>
  );
}

function AdminPanel({
  state,
  onToggleUserBlock,
  onToggleRoomLock,
  onEndRoom,
  onSaveGift,
  onSendAnnouncement,
}: {
  state: AppState;
  onToggleUserBlock: (userId: string) => void;
  onToggleRoomLock: (roomId: string) => void;
  onEndRoom: (roomId: string) => void;
  onSaveGift: (form: FormData) => void;
  onSendAnnouncement: (form: FormData) => void;
}) {
  const giftSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    onSaveGift(new FormData(event.currentTarget));
    event.currentTarget.reset();
  };

  const announcementSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    onSendAnnouncement(new FormData(event.currentTarget));
    event.currentTarget.reset();
  };

  const revenue = state.transactions
    .filter((transaction) => transaction.type === 'purchase')
    .reduce((sum, transaction) => sum + transaction.amount, 0);

  return (
    <div className="admin-layout">
      <section className="metric-row span-2">
        <Metric icon={Users} label="Total users" value={formatNumber(state.users.length)} tone="mint" />
        <Metric icon={Radio} label="Active rooms" value={formatNumber(state.rooms.filter((room) => room.live).length)} tone="cyan" />
        <Metric icon={Coins} label="Revenue" value={formatNumber(revenue)} tone="gold" />
        <Metric icon={Activity} label="Engagement" value={`${Math.round(state.users.reduce((sum, user) => sum + user.activity, 0) / state.users.length)}%`} tone="coral" />
      </section>

      <section className="content-section span-2">
        <SectionTitle icon={Users} title="User Management" />
        <DataTable
          headers={['User', 'VIP', 'Followers', 'Coins', 'Status', 'Action']}
          rows={state.users.map((user) => [
            user.name,
            user.vipTier,
            formatNumber(user.followers.length),
            formatNumber(user.coins),
            user.blocked ? 'Blocked' : 'Active',
            <button key={user.id} className="table-action" type="button" onClick={() => onToggleUserBlock(user.id)}>
              {user.blocked ? <Unlock size={16} /> : <Ban size={16} />}
              {user.blocked ? 'Unblock' : 'Block'}
            </button>,
          ])}
        />
      </section>

      <section className="content-section">
        <SectionTitle icon={Radio} title="Room Management" />
        <div className="admin-card-stack">
          {state.rooms.map((room) => (
            <article className="admin-room" key={room.id}>
              <img src={room.cover} alt="" />
              <div>
                <strong>{room.title}</strong>
                <small>{room.live ? 'Live' : 'Ended'} - {room.participants.length} participants</small>
              </div>
              <button className="icon-button" type="button" onClick={() => onToggleRoomLock(room.id)}>
                {room.locked ? <Unlock size={18} /> : <Lock size={18} />}
              </button>
              <button className="icon-button danger" type="button" onClick={() => onEndRoom(room.id)}>
                <PhoneOff size={18} />
              </button>
            </article>
          ))}
        </div>
      </section>

      <section className="content-section">
        <SectionTitle icon={Gift} title="Gift Management" />
        <form className="stacked-form" onSubmit={giftSubmit}>
          <input name="giftName" placeholder="Gift name" />
          <input name="giftPrice" type="number" min={1} placeholder="Coin price" />
          <button className="primary-action compact" type="submit">
            <Plus size={18} />
            Add Gift
          </button>
        </form>
      </section>

      <section className="content-section">
        <SectionTitle icon={Megaphone} title="Notifications" />
        <form className="stacked-form" onSubmit={announcementSubmit}>
          <input name="title" placeholder="Announcement title" />
          <textarea name="body" rows={4} placeholder="Announcement body" />
          <button className="primary-action compact" type="submit">
            <Send size={18} />
            Send
          </button>
        </form>
      </section>

      <section className="content-section">
        <SectionTitle icon={Crown} title="VIP Control" />
        <div className="admin-card-stack">
          {state.vipPlans.map((plan) => (
            <article className="admin-room" key={plan.id}>
              <span className="plan-dot" style={{ background: plan.accent }} />
              <div>
                <strong>{plan.id}</strong>
                <small>{formatNumber(plan.price)} coins - {plan.benefits.length} benefits</small>
              </div>
            </article>
          ))}
        </div>
      </section>

      <section className="content-section span-2">
        <SectionTitle icon={BarChart3} title="Transactions Management" />
        <DataTable
          headers={['Detail', 'Amount', 'Method', 'Status', 'Date']}
          rows={state.transactions.slice(0, 12).map((transaction) => [
            transaction.detail,
            `${transaction.amount > 0 ? '+' : ''}${formatNumber(transaction.amount)}`,
            transaction.method,
            transaction.status,
            formatDate(transaction.time),
          ])}
        />
      </section>
    </div>
  );
}

function RoomCard({ room, onJoinRoom }: { room: Room; onJoinRoom: (roomId: string) => void }) {
  return (
    <article className="room-card">
      <img src={room.cover} alt="" />
      <div className="room-card-body">
        <span className="live-pill">
          <span />
          {room.live ? 'Live' : 'Ended'}
        </span>
        <h3>{room.title}</h3>
        <p>{room.description}</p>
        <div className="tag-row">
          {room.tags.slice(0, 3).map((tag) => (
            <small key={tag}>{tag}</small>
          ))}
        </div>
        <div className="room-card-foot">
          <span>{room.participants.length}/{room.capacity} inside</span>
          <button className="primary-action compact" type="button" onClick={() => onJoinRoom(room.id)}>
            <Radio size={18} />
            Join
          </button>
        </div>
      </div>
    </article>
  );
}

function Metric({
  icon: Icon,
  label,
  value,
  tone,
}: {
  icon: typeof Users;
  label: string;
  value: string;
  tone: 'mint' | 'cyan' | 'coral' | 'gold';
}) {
  return (
    <article className={cx('metric-card', tone)}>
      <Icon size={20} />
      <div>
        <strong>{value}</strong>
        <span>{label}</span>
      </div>
    </article>
  );
}

function SectionTitle({
  icon: Icon,
  title,
  action,
  onAction,
}: {
  icon: typeof Radio;
  title: string;
  action?: string;
  onAction?: () => void;
}) {
  return (
    <div className="section-title">
      <div>
        <Icon size={20} />
        <h2>{title}</h2>
      </div>
      {action && (
        <button type="button" onClick={onAction}>
          {action}
        </button>
      )}
    </div>
  );
}

function DataTable({
  headers,
  rows,
}: {
  headers: string[];
  rows: Array<Array<ReactNode>>;
}) {
  return (
    <div className="table-wrap">
      <table>
        <thead>
          <tr>
            {headers.map((header) => (
              <th key={header}>{header}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((row, rowIndex) => (
            <tr key={rowIndex}>
              {row.map((cell, cellIndex) => (
                <td key={`${rowIndex}-${cellIndex}`}>{cell}</td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export default App;
