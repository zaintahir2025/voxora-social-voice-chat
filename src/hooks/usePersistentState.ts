import { useEffect, useState } from 'react';
import { loadAppState, saveAppState } from '../lib/storage';
import type { AppState } from '../types/app';

export function usePersistentState() {
  const [state, setState] = useState<AppState>(() => loadAppState());

  useEffect(() => {
    saveAppState(state);
  }, [state]);

  return [state, setState] as const;
}
