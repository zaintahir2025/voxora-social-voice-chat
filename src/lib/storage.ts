import { createInitialState } from './seed';
import type { AppState } from '../types/app';

const STORAGE_KEY = 'voxora-state-v1';

export const uid = (prefix: string) => {
  if (typeof crypto !== 'undefined' && 'randomUUID' in crypto) {
    return `${prefix}-${crypto.randomUUID()}`;
  }

  return `${prefix}-${Date.now()}-${Math.random().toString(36).slice(2)}`;
};

export const formatTime = (iso: string) =>
  new Intl.DateTimeFormat(undefined, {
    hour: 'numeric',
    minute: '2-digit',
  }).format(new Date(iso));

export const formatDate = (iso: string) =>
  new Intl.DateTimeFormat(undefined, {
    month: 'short',
    day: 'numeric',
  }).format(new Date(iso));

export const formatNumber = (value: number) =>
  new Intl.NumberFormat(undefined, { notation: value > 9999 ? 'compact' : 'standard' }).format(value);

export const cx = (...classes: Array<string | false | null | undefined>) => classes.filter(Boolean).join(' ');

const normalizeState = (state: AppState): AppState => {
  const seed = createInitialState();

  return {
    ...seed,
    ...state,
    users: state.users?.length ? state.users : seed.users,
    rooms: state.rooms?.length ? state.rooms : seed.rooms,
    gifts: state.gifts?.length ? state.gifts : seed.gifts,
    threads: state.threads ?? seed.threads,
    transactions: state.transactions ?? seed.transactions,
    notifications: state.notifications ?? seed.notifications,
    announcements: state.announcements ?? seed.announcements,
    vipPlans: state.vipPlans?.length ? state.vipPlans : seed.vipPlans,
    gameStats: state.gameStats ?? seed.gameStats,
  };
};

export const loadAppState = (): AppState => {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) {
      return createInitialState();
    }

    return normalizeState(JSON.parse(raw) as AppState);
  } catch {
    return createInitialState();
  }
};

export const saveAppState = (state: AppState) => {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
};

export const resetAppState = () => {
  localStorage.removeItem(STORAGE_KEY);
  return createInitialState();
};
