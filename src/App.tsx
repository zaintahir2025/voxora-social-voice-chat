import { FormEvent, ReactNode, useEffect, useMemo, useRef, useState } from 'react';
import type { Session } from '@supabase/supabase-js';
import {
  Ban,
  Bell,
  Check,
  CircleDollarSign,
  Coins,
  Edit3,
  Lock,
  LogOut,
  MessageCircle,
  Mic,
  MicOff,
  Phone,
  PhoneOff,
  Plus,
  Radio,
  Search,
  Send,
  ShieldCheck,
  UserPlus,
  Users,
  WalletCards,
} from 'lucide-react';
import { isSupabaseConfigured, supabase } from './lib/supabaseClient';
import { cx, formatDate, formatNumber, formatTime } from './lib/format';

type View = 'rooms' | 'messages' | 'people' | 'wallet' | 'profile' | 'admin';

type Profile = {
  id: string;
  email: string | null;
  full_name: string;
  handle: string;
  avatar_url: string | null;
  cover_url: string | null;
  bio: string;
  interests: string[];
  level: number;
  vip_tier: string;
  coins: number;
  earnings: number;
  is_admin: boolean;
  is_blocked: boolean;
  created_at: string;
};

type Room = {
  id: string;
  title: string;
  topic: string;
  description: string;
  host_id: string;
  capacity: number;
  is_live: boolean;
  is_locked: boolean;
  created_at: string;
  ended_at: string | null;
};

type RoomParticipant = {
  room_id: string;
  user_id: string;
  role: 'host' | 'speaker' | 'listener';
  muted: boolean;
  speaking: boolean;
  joined_at: string;
  profiles?: Profile;
};

type RoomMessage = {
  id: string;
  room_id: string;
  sender_id: string;
  body: string;
  kind: 'chat' | 'system' | 'gift';
  created_at: string;
  profiles?: Profile;
};

type GiftItem = {
  id: string;
  name: string;
  label: string;
  price: number;
  accent: string;
  is_active: boolean;
};

type CoinPackage = {
  id: string;
  name: string;
  coins: number;
  amount_pkr: number;
  provider: 'jazzcash' | 'easypaisa' | 'manual';
  is_active: boolean;
};

type CoinPurchase = {
  id: string;
  user_id: string;
  package_id: string;
  provider: string;
  amount_pkr: number;
  coins: number;
  status: 'pending' | 'completed' | 'failed';
  provider_reference: string | null;
  created_at: string;
  completed_at: string | null;
  profiles?: Profile;
};

type ConversationSummary = {
  id: string;
  other: Profile;
  lastMessage: string;
};

type DirectMessage = {
  id: string;
  conversation_id: string;
  sender_id: string;
  body: string;
  created_at: string;
};

const navItems: Array<{ id: View; label: string; icon: typeof Radio }> = [
  { id: 'rooms', label: 'Rooms', icon: Radio },
  { id: 'messages', label: 'Messages', icon: MessageCircle },
  { id: 'people', label: 'People', icon: Users },
  { id: 'wallet', label: 'Wallet', icon: WalletCards },
  { id: 'profile', label: 'Profile', icon: Edit3 },
  { id: 'admin', label: 'Admin', icon: ShieldCheck },
];

const fallbackAvatar = 'assets/avatar-zain.png';
const fallbackCover = 'assets/room-aurora.png';

function App() {
  const [session, setSession] = useState<Session | null>(null);
  const [profile, setProfile] = useState<Profile | null>(null);
  const [profiles, setProfiles] = useState<Profile[]>([]);
  const [rooms, setRooms] = useState<Room[]>([]);
  const [participants, setParticipants] = useState<RoomParticipant[]>([]);
  const [roomMessages, setRoomMessages] = useState<RoomMessage[]>([]);
  const [gifts, setGifts] = useState<GiftItem[]>([]);
  const [coinPackages, setCoinPackages] = useState<CoinPackage[]>([]);
  const [purchases, setPurchases] = useState<CoinPurchase[]>([]);
  const [conversations, setConversations] = useState<ConversationSummary[]>([]);
  const [directMessages, setDirectMessages] = useState<DirectMessage[]>([]);
  const [activeRoomId, setActiveRoomId] = useState<string | null>(null);
  const [activeConversationId, setActiveConversationId] = useState<string | null>(null);
  const [view, setView] = useState<View>('rooms');
  const [loading, setLoading] = useState(true);
  const [notice, setNotice] = useState('');

  const activeRoom = rooms.find((room) => room.id === activeRoomId) ?? rooms[0] ?? null;
  const activeConversation = conversations.find((item) => item.id === activeConversationId) ?? conversations[0] ?? null;
  const roomParticipants = useMemo(
    () => (activeRoom ? participants.filter((item) => item.room_id === activeRoom.id) : []),
    [activeRoom, participants],
  );
  const messagesForRoom = activeRoom ? roomMessages.filter((item) => item.room_id === activeRoom.id) : [];

  const myParticipant = useMemo(
    () => roomParticipants.find((item) => item.user_id === profile?.id) ?? null,
    [profile?.id, roomParticipants],
  );

  useEffect(() => {
    if (!supabase) {
      queueMicrotask(() => setLoading(false));
      return;
    }

    supabase.auth.getSession().then(({ data }) => {
      setSession(data.session);
      setLoading(false);
    });

    const { data } = supabase.auth.onAuthStateChange((_event, nextSession) => {
      setSession(nextSession);
    });

    return () => data.subscription.unsubscribe();
  }, []);

  useEffect(() => {
    if (!supabase || !session?.user.id) {
      queueMicrotask(() => setProfile(null));
      return;
    }

    const client = supabase;
    void loadAppData(session.user.id);

    const channel = client
      .channel('voxora-db')
      .on('postgres_changes', { event: '*', schema: 'public' }, () => {
        void loadAppData(session.user.id, false);
      })
      .subscribe();

    return () => {
      void client.removeChannel(channel);
    };
    // loadAppData intentionally reads latest state when realtime events arrive.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [session?.user.id]);

  async function loadAppData(userId: string, showLoader = true) {
    if (!supabase) {
      return;
    }

    if (showLoader) {
      setLoading(true);
    }

    const [
      profileResult,
      profilesResult,
      roomsResult,
      participantsResult,
      roomMessagesResult,
      giftsResult,
      packagesResult,
      purchasesResult,
    ] = await Promise.all([
      supabase.from('profiles').select('*').eq('id', userId).single(),
      supabase.from('profiles').select('*').order('created_at', { ascending: false }),
      supabase.from('rooms').select('*').order('created_at', { ascending: false }),
      supabase.from('room_participants').select('*, profiles(*)'),
      supabase.from('room_messages').select('*, profiles(*)').order('created_at', { ascending: true }),
      supabase.from('gifts').select('*').eq('is_active', true).order('price', { ascending: true }),
      supabase.from('coin_packages').select('*').eq('is_active', true).order('amount_pkr', { ascending: true }),
      supabase.from('coin_purchases').select('*, profiles(*)').order('created_at', { ascending: false }),
    ]);

    if (profileResult.data) {
      setProfile(profileResult.data as Profile);
    }
    setProfiles((profilesResult.data ?? []) as Profile[]);
    setRooms((roomsResult.data ?? []) as Room[]);
    setParticipants((participantsResult.data ?? []) as RoomParticipant[]);
    setRoomMessages((roomMessagesResult.data ?? []) as RoomMessage[]);
    setGifts((giftsResult.data ?? []) as GiftItem[]);
    setCoinPackages((packagesResult.data ?? []) as CoinPackage[]);
    setPurchases((purchasesResult.data ?? []) as CoinPurchase[]);

    await loadConversations(userId);
    setLoading(false);
  }

  async function loadConversations(userId: string) {
    if (!supabase) {
      return;
    }

    const mine = await supabase.from('conversation_members').select('conversation_id').eq('user_id', userId);
    const ids = [...new Set((mine.data ?? []).map((row) => row.conversation_id))];

    if (!ids.length) {
      setConversations([]);
      setDirectMessages([]);
      return;
    }

    const [memberResult, messageResult] = await Promise.all([
      supabase.from('conversation_members').select('conversation_id, user_id, profiles(*)').in('conversation_id', ids),
      supabase.from('messages').select('*').in('conversation_id', ids).order('created_at', { ascending: true }),
    ]);

    const allMessages = (messageResult.data ?? []) as DirectMessage[];
    const summaries = ids
      .map((id) => {
        const members = (memberResult.data ?? []).filter((member) => member.conversation_id === id);
        const otherMember = members.find((member) => member.user_id !== userId);
        const last = allMessages.filter((message) => message.conversation_id === id).at(-1);
        const otherProfile = Array.isArray(otherMember?.profiles) ? otherMember?.profiles[0] : otherMember?.profiles;
        return otherProfile
          ? {
              id,
              other: otherProfile as unknown as Profile,
              lastMessage: last?.body ?? 'Conversation started',
            }
          : null;
      })
      .filter(Boolean) as ConversationSummary[];

    setConversations(summaries);
    setDirectMessages(allMessages);
    if (!activeConversationId && summaries[0]) {
      setActiveConversationId(summaries[0].id);
    }
  }

  async function signOut() {
    await supabase?.auth.signOut();
    setSession(null);
    setProfile(null);
  }

  async function createRoom(form: FormData) {
    if (!supabase || !profile) {
      return;
    }

    const { data, error } = await supabase
      .from('rooms')
      .insert({
        title: String(form.get('title') ?? '').trim(),
        topic: String(form.get('topic') ?? 'General').trim(),
        description: String(form.get('description') ?? '').trim(),
        capacity: Number(form.get('capacity') ?? 8),
        host_id: profile.id,
      })
      .select()
      .single();

    if (error) {
      setNotice(error.message);
      return;
    }

    setActiveRoomId(data.id);
    setNotice('Room is live.');
  }

  async function joinRoom(room: Room) {
    if (!supabase || !profile) {
      return;
    }

    if (room.is_locked || !room.is_live) {
      setNotice('This room is not accepting new participants.');
      return;
    }

    const count = participants.filter((item) => item.room_id === room.id).length;
    if (count >= room.capacity) {
      setNotice('The room is full.');
      return;
    }

    const { error } = await supabase.from('room_participants').upsert({
      room_id: room.id,
      user_id: profile.id,
      role: room.host_id === profile.id ? 'host' : 'listener',
      muted: room.host_id !== profile.id,
      last_seen_at: new Date().toISOString(),
    });

    if (error) {
      setNotice(error.message);
      return;
    }

    setActiveRoomId(room.id);
  }

  async function leaveRoom(room: Room) {
    if (!supabase || !profile) {
      return;
    }

    await supabase.from('room_participants').delete().eq('room_id', room.id).eq('user_id', profile.id);
    if (room.host_id === profile.id) {
      await supabase.from('rooms').update({ is_live: false, ended_at: new Date().toISOString() }).eq('id', room.id);
    }
  }

  async function sendRoomMessage(roomId: string, body: string) {
    if (!supabase || !profile || !body.trim()) {
      return;
    }

    const { error } = await supabase.from('room_messages').insert({
      room_id: roomId,
      sender_id: profile.id,
      body: body.trim(),
    });

    if (error) {
      setNotice(error.message);
    }
  }

  async function sendGift(roomId: string, giftId: string) {
    if (!supabase || !profile) {
      return;
    }

    const { error } = await supabase.from('gift_transactions').insert({
      room_id: roomId,
      gift_id: giftId,
      sender_id: profile.id,
      receiver_id: profile.id,
      coins: 1,
    });

    if (error) {
      setNotice(error.message);
      return;
    }

    setNotice('Gift sent.');
  }

  async function startConversation(other: Profile) {
    if (!supabase || !profile || other.id === profile.id) {
      return;
    }

    const mine = await supabase.from('conversation_members').select('conversation_id').eq('user_id', profile.id);
    const ids = [...new Set((mine.data ?? []).map((row) => row.conversation_id))];

    if (ids.length) {
      const members = await supabase.from('conversation_members').select('conversation_id, user_id').in('conversation_id', ids);
      const existing = ids.find((id) => {
        const rows = (members.data ?? []).filter((member) => member.conversation_id === id);
        return rows.length === 2 && rows.some((member) => member.user_id === other.id);
      });
      if (existing) {
        setActiveConversationId(existing);
        setView('messages');
        return;
      }
    }

    const conversation = await supabase.from('conversations').insert({ created_by: profile.id }).select().single();
    if (conversation.error) {
      setNotice(conversation.error.message);
      return;
    }

    const conversationId = conversation.data.id;
    const { error } = await supabase.from('conversation_members').insert([
      { conversation_id: conversationId, user_id: profile.id },
      { conversation_id: conversationId, user_id: other.id },
    ]);

    if (error) {
      setNotice(error.message);
      return;
    }

    await loadConversations(profile.id);
    setActiveConversationId(conversationId);
    setView('messages');
  }

  async function sendDirectMessage(conversationId: string, body: string) {
    if (!supabase || !profile || !body.trim()) {
      return;
    }

    const { error } = await supabase.from('messages').insert({
      conversation_id: conversationId,
      sender_id: profile.id,
      body: body.trim(),
    });

    if (error) {
      setNotice(error.message);
    }
  }

  async function updateProfile(form: FormData) {
    if (!supabase || !profile) {
      return;
    }

    const patch = {
      full_name: String(form.get('full_name') ?? '').trim(),
      handle: String(form.get('handle') ?? '').trim().toLowerCase().replace(/[^a-z0-9._-]/g, ''),
      bio: String(form.get('bio') ?? '').trim(),
      interests: String(form.get('interests') ?? '')
        .split(',')
        .map((item) => item.trim())
        .filter(Boolean)
        .slice(0, 8),
    };

    const avatar = form.get('avatar');
    const cover = form.get('cover');
    const uploads: Partial<Profile> = {};

    if (avatar instanceof File && avatar.size > 0) {
      uploads.avatar_url = await uploadProfileFile('avatars', avatar, profile.id);
    }
    if (cover instanceof File && cover.size > 0) {
      uploads.cover_url = await uploadProfileFile('covers', cover, profile.id);
    }

    const { error } = await supabase.from('profiles').update({ ...patch, ...uploads }).eq('id', profile.id);
    setNotice(error ? error.message : 'Profile updated.');
  }

  async function uploadProfileFile(bucket: 'avatars' | 'covers', file: File, userId: string) {
    if (!supabase) {
      return null;
    }
    const extension = file.name.split('.').pop() || 'png';
    const path = `${userId}/${Date.now()}.${extension}`;
    const { error } = await supabase.storage.from(bucket).upload(path, file, { upsert: true });
    if (error) {
      setNotice(error.message);
      return null;
    }
    return supabase.storage.from(bucket).getPublicUrl(path).data.publicUrl;
  }

  async function requestCoinPurchase(pack: CoinPackage, reference: string) {
    if (!supabase || !profile) {
      return;
    }

    const { error } = await supabase.from('coin_purchases').insert({
      user_id: profile.id,
      package_id: pack.id,
      provider: pack.provider,
      amount_pkr: pack.amount_pkr,
      coins: pack.coins,
      provider_reference: reference.trim() || null,
    });

    setNotice(error ? error.message : 'Purchase request submitted. Admin approval credits the coins.');
  }

  async function completePurchase(purchase: CoinPurchase) {
    if (!supabase) {
      return;
    }
    const { error } = await supabase.from('coin_purchases').update({ status: 'completed' }).eq('id', purchase.id);
    setNotice(error ? error.message : 'Purchase completed and coins credited.');
  }

  async function toggleBlockUser(user: Profile) {
    if (!supabase) {
      return;
    }
    const { error } = await supabase.from('profiles').update({ is_blocked: !user.is_blocked }).eq('id', user.id);
    setNotice(error ? error.message : 'User status updated.');
  }

  async function endRoom(room: Room) {
    if (!supabase) {
      return;
    }
    await supabase.from('rooms').update({ is_live: false, is_locked: true, ended_at: new Date().toISOString() }).eq('id', room.id);
  }

  if (!isSupabaseConfigured) {
    return <SetupMissing />;
  }

  if (loading) {
    return <LoadingScreen />;
  }

  if (!session || !profile) {
    return <AuthScreen />;
  }

  return (
    <div className="product-shell">
      <aside className="product-sidebar">
        <div className="brand-block">
          <img src="assets/brand-mark.png" alt="" />
          <div>
            <strong>Voxora</strong>
            <span>Live social audio</span>
          </div>
        </div>
        <nav>
          {navItems
            .filter((item) => item.id !== 'admin' || profile.is_admin)
            .map((item) => {
              const Icon = item.icon;
              return (
                <button key={item.id} className={cx(view === item.id && 'active')} onClick={() => setView(item.id)} type="button">
                  <Icon size={18} />
                  {item.label}
                </button>
              );
            })}
        </nav>
        <button className="sign-out" type="button" onClick={signOut}>
          <LogOut size={18} />
          Sign out
        </button>
      </aside>

      <main className="product-main">
        <header className="product-topbar">
          <div>
            <span className="eyebrow">Signed in as @{profile.handle}</span>
            <h1>{viewTitle(view)}</h1>
          </div>
          <div className="account-pill">
            <Coins size={18} />
            {formatNumber(profile.coins)}
          </div>
        </header>

        {notice && (
          <button className="notice" type="button" onClick={() => setNotice('')}>
            <Bell size={18} />
            {notice}
          </button>
        )}

        {view === 'rooms' && (
          <RoomsView
            profile={profile}
            profiles={profiles}
            rooms={rooms}
            participants={participants}
            messages={messagesForRoom}
            activeRoom={activeRoom}
            gifts={gifts}
            myParticipant={myParticipant}
            onCreateRoom={createRoom}
            onJoinRoom={joinRoom}
            onLeaveRoom={leaveRoom}
            onSelectRoom={setActiveRoomId}
            onSendRoomMessage={sendRoomMessage}
            onSendGift={sendGift}
          />
        )}
        {view === 'messages' && (
          <MessagesView
            profile={profile}
            conversations={conversations}
            activeConversation={activeConversation}
            directMessages={directMessages}
            onSelectConversation={setActiveConversationId}
            onSendMessage={sendDirectMessage}
            onStartConversation={startConversation}
            people={profiles}
          />
        )}
        {view === 'people' && <PeopleView profile={profile} people={profiles} onMessage={startConversation} />}
        {view === 'wallet' && (
          <WalletView
            profile={profile}
            packages={coinPackages}
            purchases={purchases.filter((purchase) => purchase.user_id === profile.id)}
            onRequestPurchase={requestCoinPurchase}
          />
        )}
        {view === 'profile' && <ProfileView profile={profile} onUpdateProfile={updateProfile} />}
        {view === 'admin' && profile.is_admin && (
          <AdminView
            people={profiles}
            rooms={rooms}
            purchases={purchases}
            onCompletePurchase={completePurchase}
            onToggleBlockUser={toggleBlockUser}
            onEndRoom={endRoom}
          />
        )}
      </main>
    </div>
  );
}

function viewTitle(view: View) {
  return {
    rooms: 'Live rooms',
    messages: 'Messages',
    people: 'People',
    wallet: 'Wallet',
    profile: 'Profile settings',
    admin: 'Admin operations',
  }[view];
}

function LoadingScreen() {
  return (
    <main className="center-screen">
      <img src="assets/brand-mark.png" alt="" />
      <h1>Loading Voxora</h1>
    </main>
  );
}

function SetupMissing() {
  return (
    <main className="center-screen setup-screen">
      <img src="assets/brand-mark.png" alt="" />
      <h1>Backend configuration required</h1>
      <p>
        Add `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY` as GitHub repository variables or local environment
        variables. Do not commit service-role keys.
      </p>
    </main>
  );
}

function AuthScreen() {
  const [mode, setMode] = useState<'login' | 'signup'>('signup');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!supabase) {
      return;
    }
    setBusy(true);
    setError('');
    const form = new FormData(event.currentTarget);
    const email = String(form.get('email') ?? '').trim();
    const password = String(form.get('password') ?? '');

    const response =
      mode === 'login'
        ? await supabase.auth.signInWithPassword({ email, password })
        : await supabase.auth.signUp({
            email,
            password,
            options: {
              data: {
                full_name: String(form.get('full_name') ?? '').trim(),
                handle: String(form.get('handle') ?? '').trim().toLowerCase(),
                bio: String(form.get('bio') ?? '').trim(),
                interests: String(form.get('interests') ?? '').trim(),
              },
              emailRedirectTo: `${window.location.origin}${window.location.pathname}`,
            },
          });

    if (response.error) {
      setError(response.error.message);
    }
    setBusy(false);
  }

  return (
    <main className="auth-page">
      <section className="auth-copy">
        <img src="assets/brand-mark.png" alt="" />
        <span className="eyebrow">Production build</span>
        <h1>Real accounts, realtime chat, and live voice rooms for social audio communities.</h1>
        <p>
          Voxora now runs on Supabase Auth, Postgres, Realtime, Storage, and browser WebRTC. Your account data is stored
          in the backend, not local demo state.
        </p>
      </section>
      <section className="auth-card">
        <div className="segmented">
          <button className={cx(mode === 'signup' && 'active')} type="button" onClick={() => setMode('signup')}>
            Sign up
          </button>
          <button className={cx(mode === 'login' && 'active')} type="button" onClick={() => setMode('login')}>
            Log in
          </button>
        </div>
        <form className="form-grid" onSubmit={submit}>
          {mode === 'signup' && (
            <>
              <label>
                Display name
                <input name="full_name" required minLength={2} placeholder="Zain Tahir" />
              </label>
              <label>
                Handle
                <input name="handle" required minLength={3} placeholder="zain" />
              </label>
            </>
          )}
          <label>
            Email
            <input name="email" type="email" required placeholder="you@example.com" autoComplete="email" />
          </label>
          <label>
            Password
            <input
              name="password"
              type="password"
              required
              minLength={8}
              placeholder="At least 8 characters"
              autoComplete={mode === 'login' ? 'current-password' : 'new-password'}
            />
          </label>
          {mode === 'signup' && (
            <>
              <label>
                Bio
                <textarea name="bio" rows={3} placeholder="Tell people what you host or enjoy." />
              </label>
              <label>
                Interests
                <input name="interests" placeholder="Music, study, gaming" />
              </label>
            </>
          )}
          {error && <p className="form-error">{error}</p>}
          <button className="primary-action" type="submit" disabled={busy}>
            <Lock size={18} />
            {busy ? 'Please wait' : mode === 'login' ? 'Log in' : 'Create account'}
          </button>
        </form>
      </section>
    </main>
  );
}

function RoomsView({
  profile,
  profiles,
  rooms,
  participants,
  messages,
  activeRoom,
  gifts,
  myParticipant,
  onCreateRoom,
  onJoinRoom,
  onLeaveRoom,
  onSelectRoom,
  onSendRoomMessage,
  onSendGift,
}: {
  profile: Profile;
  profiles: Profile[];
  rooms: Room[];
  participants: RoomParticipant[];
  messages: RoomMessage[];
  activeRoom: Room | null;
  gifts: GiftItem[];
  myParticipant: RoomParticipant | null;
  onCreateRoom: (form: FormData) => void;
  onJoinRoom: (room: Room) => void;
  onLeaveRoom: (room: Room) => void;
  onSelectRoom: (roomId: string) => void;
  onSendRoomMessage: (roomId: string, body: string) => void;
  onSendGift: (roomId: string, giftId: string) => void;
}) {
  const [roomChat, setRoomChat] = useState('');
  const [voiceEnabled, setVoiceEnabled] = useState(false);
  const liveRooms = rooms.filter((room) => room.is_live);
  const activeParticipants = activeRoom ? participants.filter((item) => item.room_id === activeRoom.id) : [];

  function submitRoom(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    onCreateRoom(new FormData(event.currentTarget));
    event.currentTarget.reset();
  }

  function submitRoomMessage(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (activeRoom) {
      onSendRoomMessage(activeRoom.id, roomChat);
      setRoomChat('');
    }
  }

  return (
    <div className="two-pane">
      <section className="panel">
        <SectionTitle icon={Radio} title="Rooms" />
        <form className="compact-form" onSubmit={submitRoom}>
          <input name="title" placeholder="Room title" required minLength={3} />
          <input name="topic" placeholder="Topic" defaultValue="General" />
          <input name="capacity" type="number" min={2} max={20} defaultValue={8} />
          <textarea name="description" placeholder="Room description" rows={3} />
          <button className="primary-action compact" type="submit">
            <Plus size={18} />
            Start room
          </button>
        </form>
        <div className="room-list-real">
          {liveRooms.map((room) => {
            const host = profiles.find((item) => item.id === room.host_id);
            const count = participants.filter((item) => item.room_id === room.id).length;
            return (
              <button
                key={room.id}
                className={cx('room-row', activeRoom?.id === room.id && 'active')}
                type="button"
                onClick={() => {
                  onSelectRoom(room.id);
                  onJoinRoom(room);
                }}
              >
                <div>
                  <strong>{room.title}</strong>
                  <span>{host?.full_name ?? 'Host'} · {room.topic}</span>
                </div>
                <small>{count}/{room.capacity}</small>
              </button>
            );
          })}
        </div>
      </section>

      <section className="panel room-panel">
        {activeRoom ? (
          <>
            <div className="room-header-real">
              <div>
                <span className="eyebrow">{activeRoom.topic}</span>
                <h2>{activeRoom.title}</h2>
                <p>{activeRoom.description || 'No room description yet.'}</p>
              </div>
              <div className="room-actions">
                <button className="secondary-action compact" type="button" onClick={() => onJoinRoom(activeRoom)}>
                  <Phone size={18} />
                  Join
                </button>
                <button className="danger-action compact" type="button" onClick={() => onLeaveRoom(activeRoom)}>
                  <PhoneOff size={18} />
                  Leave
                </button>
              </div>
            </div>

            <VoiceRoom room={activeRoom} profile={profile} enabled={voiceEnabled} onToggle={setVoiceEnabled} />

            <div className="participant-strip">
              {activeParticipants.map((participant) => (
                <article key={participant.user_id}>
                  <img src={participant.profiles?.avatar_url || fallbackAvatar} alt="" />
                  <div>
                    <strong>{participant.profiles?.full_name ?? 'Member'}</strong>
                    <span>{participant.role}</span>
                  </div>
                  {participant.muted ? <MicOff size={16} /> : <Mic size={16} />}
                </article>
              ))}
            </div>

            <div className="gift-row">
              {gifts.map((gift) => (
                <button key={gift.id} type="button" onClick={() => onSendGift(activeRoom.id, gift.id)}>
                  <span style={{ background: gift.accent }}>{gift.label}</span>
                  {gift.name}
                  <small>{gift.price}</small>
                </button>
              ))}
            </div>

            <div className="chat-area">
              <div className="message-scroll">
                {messages.map((message) => (
                  <MessageBubble key={message.id} mine={message.sender_id === profile.id}>
                    <strong>{message.profiles?.full_name ?? 'Member'}</strong>
                    <p>{message.body}</p>
                    <small>{formatTime(message.created_at)}</small>
                  </MessageBubble>
                ))}
              </div>
              <form className="send-form" onSubmit={submitRoomMessage}>
                <input
                  value={roomChat}
                  onChange={(event) => setRoomChat(event.target.value)}
                  placeholder={myParticipant ? 'Write to the room' : 'Join the room to chat'}
                  disabled={!myParticipant}
                />
                <button type="submit" disabled={!roomChat.trim() || !myParticipant}>
                  <Send size={18} />
                </button>
              </form>
            </div>
          </>
        ) : (
          <EmptyState icon={Radio} title="No active room" body="Create a room or join one from the list." />
        )}
      </section>
    </div>
  );
}

function VoiceRoom({
  room,
  profile,
  enabled,
  onToggle,
}: {
  room: Room;
  profile: Profile;
  enabled: boolean;
  onToggle: (enabled: boolean) => void;
}) {
  const { status, remoteStreams } = useVoiceRoom(room.id, profile.id, enabled);
  return (
    <div className="voice-console">
      <button className={cx('voice-button', enabled && 'active')} type="button" onClick={() => onToggle(!enabled)}>
        {enabled ? <Mic size={18} /> : <MicOff size={18} />}
        {enabled ? 'Live microphone' : 'Start voice'}
      </button>
      <span>{status}</span>
      {remoteStreams.map(({ peerId, stream }) => (
        <RemoteAudio key={peerId} stream={stream} />
      ))}
    </div>
  );
}

function useVoiceRoom(roomId: string, userId: string, enabled: boolean) {
  const [status, setStatus] = useState('Voice idle');
  const [remoteStreams, setRemoteStreams] = useState<Array<{ peerId: string; stream: MediaStream }>>([]);
  const localStreamRef = useRef<MediaStream | null>(null);
  const peersRef = useRef<Map<string, RTCPeerConnection>>(new Map());

  useEffect(() => {
    if (!enabled || !supabase) {
      queueMicrotask(() => setStatus('Voice idle'));
      return;
    }

    let disposed = false;
    const client = supabase;
    const peers = peersRef.current;
    const channel = client.channel(`voice-room-${roomId}`, { config: { broadcast: { self: false } } });

    const sendSignal = (payload: Record<string, unknown>) =>
      channel.send({ type: 'broadcast', event: 'signal', payload: { ...payload, from: userId } });

    const getPeer = (peerId: string) => {
      const existing = peersRef.current.get(peerId);
      if (existing) {
        return existing;
      }

      const peer = new RTCPeerConnection({ iceServers: [{ urls: 'stun:stun.l.google.com:19302' }] });
      localStreamRef.current?.getTracks().forEach((track) => {
        if (localStreamRef.current) {
          peer.addTrack(track, localStreamRef.current);
        }
      });
      peer.onicecandidate = (event) => {
        if (event.candidate) {
          void sendSignal({ type: 'candidate', to: peerId, candidate: event.candidate });
        }
      };
      peer.ontrack = (event) => {
        const [stream] = event.streams;
        setRemoteStreams((current) => {
          const withoutPeer = current.filter((item) => item.peerId !== peerId);
          return [...withoutPeer, { peerId, stream }];
        });
      };
      peersRef.current.set(peerId, peer);
      return peer;
    };

    async function createOffer(peerId: string) {
      const peer = getPeer(peerId);
      const offer = await peer.createOffer();
      await peer.setLocalDescription(offer);
      await sendSignal({ type: 'offer', to: peerId, description: offer });
    }

    async function start() {
      try {
        localStreamRef.current = await navigator.mediaDevices.getUserMedia({ audio: true });
        setStatus('Connected to room audio');

        channel.on('broadcast', { event: 'signal' }, async ({ payload }) => {
          if (disposed || payload.from === userId || (payload.to && payload.to !== userId)) {
            return;
          }

          const peerId = String(payload.from);
          const peer = getPeer(peerId);

          if (payload.type === 'join') {
            await createOffer(peerId);
          }
          if (payload.type === 'offer') {
            await peer.setRemoteDescription(payload.description as RTCSessionDescriptionInit);
            const answer = await peer.createAnswer();
            await peer.setLocalDescription(answer);
            await sendSignal({ type: 'answer', to: peerId, description: answer });
          }
          if (payload.type === 'answer') {
            await peer.setRemoteDescription(payload.description as RTCSessionDescriptionInit);
          }
          if (payload.type === 'candidate') {
            await peer.addIceCandidate(payload.candidate as RTCIceCandidateInit);
          }
        });

        channel.subscribe((state) => {
          if (state === 'SUBSCRIBED') {
            void sendSignal({ type: 'join' });
          }
        });
      } catch {
        setStatus('Microphone permission is required');
      }
    }

    void start();

    return () => {
      disposed = true;
      void sendSignal({ type: 'leave' });
      localStreamRef.current?.getTracks().forEach((track) => track.stop());
      peers.forEach((peer) => peer.close());
      peers.clear();
      setRemoteStreams([]);
      void client.removeChannel(channel);
    };
  }, [enabled, roomId, userId]);

  return { status, remoteStreams };
}

function RemoteAudio({ stream }: { stream: MediaStream }) {
  const ref = useRef<HTMLAudioElement | null>(null);
  useEffect(() => {
    if (ref.current) {
      ref.current.srcObject = stream;
    }
  }, [stream]);
  return <audio ref={ref} autoPlay playsInline />;
}

function MessagesView({
  profile,
  conversations,
  activeConversation,
  directMessages,
  onSelectConversation,
  onSendMessage,
  onStartConversation,
  people,
}: {
  profile: Profile;
  conversations: ConversationSummary[];
  activeConversation: ConversationSummary | null;
  directMessages: DirectMessage[];
  onSelectConversation: (id: string) => void;
  onSendMessage: (conversationId: string, body: string) => void;
  onStartConversation: (profile: Profile) => void;
  people: Profile[];
}) {
  const [message, setMessage] = useState('');
  const [search, setSearch] = useState('');
  const messages = activeConversation ? directMessages.filter((item) => item.conversation_id === activeConversation.id) : [];
  const candidates = people.filter(
    (person) =>
      person.id !== profile.id &&
      `${person.full_name} ${person.handle}`.toLowerCase().includes(search.toLowerCase()),
  );

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (activeConversation) {
      onSendMessage(activeConversation.id, message);
      setMessage('');
    }
  }

  return (
    <div className="two-pane">
      <section className="panel">
        <SectionTitle icon={MessageCircle} title="Conversations" />
        <label className="search-box">
          <Search size={18} />
          <input value={search} onChange={(event) => setSearch(event.target.value)} placeholder="Find people" />
        </label>
        {search ? (
          <div className="stack">
            {candidates.map((person) => (
              <PersonRow key={person.id} person={person} action="Message" onAction={() => onStartConversation(person)} />
            ))}
          </div>
        ) : (
          <div className="stack">
            {conversations.map((conversation) => (
              <button
                className={cx('conversation-row', activeConversation?.id === conversation.id && 'active')}
                key={conversation.id}
                type="button"
                onClick={() => onSelectConversation(conversation.id)}
              >
                <img src={conversation.other.avatar_url || fallbackAvatar} alt="" />
                <div>
                  <strong>{conversation.other.full_name}</strong>
                  <span>{conversation.lastMessage}</span>
                </div>
              </button>
            ))}
          </div>
        )}
      </section>
      <section className="panel conversation-panel-real">
        {activeConversation ? (
          <>
            <div className="conversation-title">
              <img src={activeConversation.other.avatar_url || fallbackAvatar} alt="" />
              <div>
                <h2>{activeConversation.other.full_name}</h2>
                <span>@{activeConversation.other.handle}</span>
              </div>
            </div>
            <div className="message-scroll">
              {messages.map((item) => (
                <MessageBubble key={item.id} mine={item.sender_id === profile.id}>
                  <p>{item.body}</p>
                  <small>{formatTime(item.created_at)}</small>
                </MessageBubble>
              ))}
            </div>
            <form className="send-form" onSubmit={submit}>
              <input value={message} onChange={(event) => setMessage(event.target.value)} placeholder="Type a message" />
              <button type="submit" disabled={!message.trim()}>
                <Send size={18} />
              </button>
            </form>
          </>
        ) : (
          <EmptyState icon={MessageCircle} title="No conversation selected" body="Search for someone and start a real chat." />
        )}
      </section>
    </div>
  );
}

function PeopleView({ profile, people, onMessage }: { profile: Profile; people: Profile[]; onMessage: (person: Profile) => void }) {
  return (
    <section className="panel">
      <SectionTitle icon={Users} title="Members" />
      <div className="people-grid">
        {people
          .filter((person) => person.id !== profile.id)
          .map((person) => (
            <article className="person-card" key={person.id}>
              <img className="cover" src={person.cover_url || fallbackCover} alt="" />
              <img className="avatar" src={person.avatar_url || fallbackAvatar} alt="" />
              <h3>{person.full_name}</h3>
              <span>@{person.handle}</span>
              <p>{person.bio || 'No bio yet.'}</p>
              <button className="secondary-action compact" type="button" onClick={() => onMessage(person)}>
                <MessageCircle size={18} />
                Message
              </button>
            </article>
          ))}
      </div>
    </section>
  );
}

function WalletView({
  profile,
  packages,
  purchases,
  onRequestPurchase,
}: {
  profile: Profile;
  packages: CoinPackage[];
  purchases: CoinPurchase[];
  onRequestPurchase: (pack: CoinPackage, reference: string) => void;
}) {
  const [references, setReferences] = useState<Record<string, string>>({});

  return (
    <div className="wallet-grid-real">
      <section className="panel wallet-balance-real">
        <SectionTitle icon={WalletCards} title="Balance" />
        <strong>{formatNumber(profile.coins)}</strong>
        <span>available coins</span>
        <p>
          Coin purchases are stored in the database. JazzCash/EasyPaisa provider verification is completed by an admin or
          payment function before coins are credited.
        </p>
      </section>
      <section className="panel">
        <SectionTitle icon={CircleDollarSign} title="Buy coins" />
        <div className="package-list-real">
          {packages.map((pack) => (
            <article key={pack.id}>
              <div>
                <strong>{pack.name}</strong>
                <span>{formatNumber(pack.coins)} coins · PKR {formatNumber(pack.amount_pkr)} · {pack.provider}</span>
              </div>
              <input
                value={references[pack.id] ?? ''}
                onChange={(event) => setReferences((current) => ({ ...current, [pack.id]: event.target.value }))}
                placeholder="Payment reference"
              />
              <button className="primary-action compact" type="button" onClick={() => onRequestPurchase(pack, references[pack.id] ?? '')}>
                <Coins size={18} />
                Request purchase
              </button>
            </article>
          ))}
        </div>
      </section>
      <section className="panel span-2">
        <SectionTitle icon={Coins} title="Purchase history" />
        <DataTable
          headers={['Package', 'Coins', 'Amount', 'Provider', 'Status', 'Date']}
          rows={purchases.map((purchase) => [
            purchase.package_id.slice(0, 8),
            formatNumber(purchase.coins),
            `PKR ${formatNumber(purchase.amount_pkr)}`,
            purchase.provider,
            purchase.status,
            formatDate(purchase.created_at),
          ])}
        />
      </section>
    </div>
  );
}

function ProfileView({ profile, onUpdateProfile }: { profile: Profile; onUpdateProfile: (form: FormData) => void }) {
  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    onUpdateProfile(new FormData(event.currentTarget));
  }

  return (
    <div className="profile-grid-real">
      <section className="panel profile-preview-real">
        <img className="cover" src={profile.cover_url || fallbackCover} alt="" />
        <img className="avatar" src={profile.avatar_url || fallbackAvatar} alt="" />
        <h2>{profile.full_name}</h2>
        <span>@{profile.handle}</span>
        <p>{profile.bio || 'No bio yet.'}</p>
        <div className="interest-row">
          {profile.interests.map((item) => (
            <small key={item}>{item}</small>
          ))}
        </div>
      </section>
      <section className="panel">
        <SectionTitle icon={Edit3} title="Customize profile" />
        <form className="form-grid" onSubmit={submit}>
          <label>
            Display name
            <input name="full_name" defaultValue={profile.full_name} required />
          </label>
          <label>
            Handle
            <input name="handle" defaultValue={profile.handle} required />
          </label>
          <label>
            Bio
            <textarea name="bio" defaultValue={profile.bio} rows={4} />
          </label>
          <label>
            Interests
            <input name="interests" defaultValue={profile.interests.join(', ')} />
          </label>
          <label>
            Avatar image
            <input name="avatar" type="file" accept="image/png,image/jpeg,image/webp" />
          </label>
          <label>
            Cover image
            <input name="cover" type="file" accept="image/png,image/jpeg,image/webp" />
          </label>
          <button className="primary-action" type="submit">
            <Check size={18} />
            Save changes
          </button>
        </form>
      </section>
    </div>
  );
}

function AdminView({
  people,
  rooms,
  purchases,
  onCompletePurchase,
  onToggleBlockUser,
  onEndRoom,
}: {
  people: Profile[];
  rooms: Room[];
  purchases: CoinPurchase[];
  onCompletePurchase: (purchase: CoinPurchase) => void;
  onToggleBlockUser: (profile: Profile) => void;
  onEndRoom: (room: Room) => void;
}) {
  return (
    <div className="admin-grid-real">
      <section className="panel span-2">
        <SectionTitle icon={ShieldCheck} title="Pending purchases" />
        <DataTable
          headers={['User', 'Coins', 'Amount', 'Provider', 'Reference', 'Action']}
          rows={purchases
            .filter((purchase) => purchase.status === 'pending')
            .map((purchase) => [
              purchase.profiles?.full_name ?? purchase.user_id.slice(0, 8),
              formatNumber(purchase.coins),
              `PKR ${formatNumber(purchase.amount_pkr)}`,
              purchase.provider,
              purchase.provider_reference ?? '-',
              <button className="table-action" type="button" onClick={() => onCompletePurchase(purchase)}>
                Complete
              </button>,
            ])}
        />
      </section>
      <section className="panel">
        <SectionTitle icon={Users} title="Users" />
        <div className="stack">
          {people.map((person) => (
            <PersonRow
              key={person.id}
              person={person}
              action={person.is_blocked ? 'Unblock' : 'Block'}
              onAction={() => onToggleBlockUser(person)}
              blocked={person.is_blocked}
            />
          ))}
        </div>
      </section>
      <section className="panel">
        <SectionTitle icon={Radio} title="Rooms" />
        <div className="stack">
          {rooms.map((room) => (
            <article className="admin-room-real" key={room.id}>
              <div>
                <strong>{room.title}</strong>
                <span>{room.is_live ? 'Live' : 'Ended'}</span>
              </div>
              {room.is_live && (
                <button className="danger-action compact" type="button" onClick={() => onEndRoom(room)}>
                  End
                </button>
              )}
            </article>
          ))}
        </div>
      </section>
    </div>
  );
}

function PersonRow({
  person,
  action,
  onAction,
  blocked,
}: {
  person: Profile;
  action: string;
  onAction: () => void;
  blocked?: boolean;
}) {
  return (
    <article className={cx('person-row', blocked && 'blocked')}>
      <img src={person.avatar_url || fallbackAvatar} alt="" />
      <div>
        <strong>{person.full_name}</strong>
        <span>@{person.handle}</span>
      </div>
      <button className="secondary-action compact" type="button" onClick={onAction}>
        {blocked ? <Ban size={18} /> : <UserPlus size={18} />}
        {action}
      </button>
    </article>
  );
}

function SectionTitle({ icon: Icon, title }: { icon: typeof Radio; title: string }) {
  return (
    <div className="section-title">
      <div>
        <Icon size={20} />
        <h2>{title}</h2>
      </div>
    </div>
  );
}

function MessageBubble({ mine, children }: { mine?: boolean; children: ReactNode }) {
  return <article className={cx('message-bubble-real', mine && 'mine')}>{children}</article>;
}

function EmptyState({ icon: Icon, title, body }: { icon: typeof Radio; title: string; body: string }) {
  return (
    <div className="empty-state">
      <Icon size={34} />
      <h3>{title}</h3>
      <p>{body}</p>
    </div>
  );
}

function DataTable({ headers, rows }: { headers: string[]; rows: ReactNode[][] }) {
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
          {rows.length ? (
            rows.map((row, rowIndex) => (
              <tr key={rowIndex}>
                {row.map((cell, cellIndex) => (
                  <td key={`${rowIndex}-${cellIndex}`}>{cell}</td>
                ))}
              </tr>
            ))
          ) : (
            <tr>
              <td colSpan={headers.length}>No records yet.</td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
}

export default App;
