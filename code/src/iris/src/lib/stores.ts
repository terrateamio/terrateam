import { writable, type Writable } from 'svelte/store';
import type { Installation, Repository, ThemeStore, ThemeMode } from './types';
import type { VCSProvider } from './vcs/types';
import type { ServerConfig } from './types';

// VCS Provider state
export const currentVCSProvider: Writable<VCSProvider> = writable('github');
export const availableProviders: Writable<VCSProvider[]> = writable(['github', 'gitlab']);

// Server config
export const serverConfig: Writable<ServerConfig> = writable();

// Organization/installation state
//
// Installations are hydrated from a last-known-good cache so that a transient
// failure to reach the installations endpoint does not drop the user into
// "demo mode" (which keys off an empty installations list). Only a *successful*
// fetch is authoritative and may overwrite this cache — see loadInstallations()
// in ./installations.
const INSTALLATIONS_CACHE_KEY = 'installations-cache';

function loadCachedInstallations(): Installation[] {
  if (typeof window === 'undefined') return [];
  try {
    const cached = localStorage.getItem(INSTALLATIONS_CACHE_KEY);
    if (!cached) return [];
    const parsed = JSON.parse(cached);
    // Tolerate both the current `{ installations, timestamp }` shape and a
    // legacy bare array.
    const list = Array.isArray(parsed) ? parsed : parsed?.installations;
    if (Array.isArray(list) && list.every((i) => i && typeof i.id === 'string')) {
      return list as Installation[];
    }
  } catch (e) {
    console.warn('Failed to load installations from cache:', e);
  }
  return [];
}

function resolveInitialSelectedInstallation(list: Installation[]): Installation | null {
  if (list.length === 0) return null;
  try {
    const defaultId = localStorage.getItem('defaultInstallationId');
    if (defaultId) {
      const match = list.find((i) => i.id === defaultId);
      if (match) return match;
    }
  } catch (e) {
    console.warn('Failed to resolve default installation:', e);
  }
  return list[0];
}

// Persist the last successfully-fetched installations as the last-known-good set.
export function cacheInstallations(list: Installation[]): void {
  if (typeof window === 'undefined') return;
  try {
    localStorage.setItem(
      INSTALLATIONS_CACHE_KEY,
      JSON.stringify({ installations: list, timestamp: Date.now() })
    );
  } catch (e) {
    console.warn('Failed to cache installations:', e);
  }
}

export function clearInstallationsCache(): void {
  if (typeof window === 'undefined') return;
  try {
    localStorage.removeItem(INSTALLATIONS_CACHE_KEY);
  } catch (e) {
    console.warn('Failed to clear installations cache:', e);
  }
}

const initialInstallations = loadCachedInstallations();

export const installations: Writable<Installation[]> = writable(initialInstallations);
export const selectedInstallation: Writable<Installation | null> = writable(
  resolveInitialSelectedInstallation(initialInstallations)
);
export const installationsLoading: Writable<boolean> = writable(false);
export const installationsError: Writable<string | null> = writable(null);
// Whether installations have been fetched at least once this session. Drives the
// root routing decision and guards against duplicate concurrent loads.
export const installationsInitialized: Writable<boolean> = writable(false);

// Global repository cache for the current installation with persistence
function createPersistentRepositoryCache() {
  const { subscribe, set, update } = writable<Repository[]>([]);
  
  // Cache key includes installation ID to keep caches separate
  const getCacheKey = (installationId: string) => `repositories-cache-${installationId}`;
  
  return {
    subscribe,
    set: (value: Repository[], installationId?: string) => {
      set(value);
      if (installationId && typeof window !== 'undefined') {
        try {
          const cacheData = {
            repositories: value,
            timestamp: Date.now()
          };
          localStorage.setItem(getCacheKey(installationId), JSON.stringify(cacheData));
        } catch (e) {
          console.warn('Failed to save repositories to localStorage:', e);
        }
      }
    },
    update,
    loadFromCache: (installationId: string): Repository[] => {
      if (typeof window === 'undefined') return [];
      
      try {
        const cached = localStorage.getItem(getCacheKey(installationId));
        if (cached) {
          const cacheData = JSON.parse(cached);
          
          // Handle both old format (direct array) and new format (with timestamp)
          const repositories = Array.isArray(cacheData) ? cacheData : cacheData.repositories;
          const timestamp = Array.isArray(cacheData) ? null : cacheData.timestamp;
          
          // Check if cache is expired (24 hours)
          if (timestamp) {
            const cacheAge = Date.now() - timestamp;
            const twentyFourHours = 24 * 60 * 60 * 1000;
            if (cacheAge > twentyFourHours) {
              // Cache is expired, clear it
              localStorage.removeItem(getCacheKey(installationId));
              return [];
            }
          }
          
          if (repositories && Array.isArray(repositories)) {
            set(repositories);
            return repositories;
          }
        }
      } catch (e) {
        console.warn('Failed to load repositories from localStorage:', e);
      }
      return [];
    },
    clearCache: (installationId: string) => {
      set([]);
      if (typeof window !== 'undefined') {
        try {
          localStorage.removeItem(getCacheKey(installationId));
        } catch (e) {
          console.warn('Failed to clear repositories cache:', e);
        }
      }
    },
    getCacheTimestamp: (installationId: string): number | null => {
      if (typeof window === 'undefined') return null;
      
      try {
        const cached = localStorage.getItem(getCacheKey(installationId));
        if (cached) {
          const cacheData = JSON.parse(cached);
          return cacheData.timestamp || null;
        }
      } catch (e) {
        console.warn('Failed to get cache timestamp:', e);
      }
      return null;
    }
  };
}

export const cachedRepositories = createPersistentRepositoryCache();
export const repositoriesCacheLoading: Writable<boolean> = writable(false);

// Settings state
export const defaultInstallationId: Writable<string | null> = writable(
  localStorage.getItem('defaultInstallationId') || null
);

// First-time user tracking
export const hasVisitedBefore: Writable<boolean> = writable(
  localStorage.getItem('hasVisitedBefore') === 'true'
);

// Function to mark user as having visited
export function markAsVisited(): void {
  localStorage.setItem('hasVisitedBefore', 'true');
  hasVisitedBefore.set(true);
}

// VCS Provider persistence
export function setVCSProvider(provider: VCSProvider): void {
  localStorage.setItem('vcsProvider', provider);
  currentVCSProvider.set(provider);
}

// Initialize VCS provider from localStorage
if (typeof window !== 'undefined') {
  const savedProvider = localStorage.getItem('vcsProvider') as VCSProvider;
  if (savedProvider && (savedProvider === 'github' || savedProvider === 'gitlab')) {
    currentVCSProvider.set(savedProvider);
  }
}

// Theme state
function createThemeStore(): ThemeStore {
  const { subscribe, set } = writable<ThemeMode>('system');
  
  // Initialize from localStorage or default to 'system'
  const savedTheme = (localStorage.getItem('theme') as ThemeMode) || 'system';
  set(savedTheme);
  
  return {
    subscribe,
    setTheme: (theme: ThemeMode) => {
      localStorage.setItem('theme', theme);
      set(theme);
      applyTheme(theme);
    },
    init: () => {
      const savedTheme = (localStorage.getItem('theme') as ThemeMode) || 'system';
      set(savedTheme);
      applyTheme(savedTheme);
    }
  };
}

function applyTheme(theme: ThemeMode): void {
  const root = document.documentElement;
  
  if (theme === 'system') {
    // Use system preference
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    if (prefersDark) {
      root.classList.add('dark');
    } else {
      root.classList.remove('dark');
    }
  } else if (theme === 'dark') {
    root.classList.add('dark');
  } else {
    root.classList.remove('dark');
  }
}

export const theme = createThemeStore();


// Auto-update theme when system preference changes
if (typeof window !== 'undefined') {
  window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => {
    // Get current theme setting
    const currentTheme = localStorage.getItem('theme') as ThemeMode;
    if (currentTheme === 'system' || !currentTheme) {
      applyTheme('system');
    }
  });
}

