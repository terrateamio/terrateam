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
export const installations: Writable<Installation[]> = writable([]);
export const selectedInstallation: Writable<Installation | null> = writable(null);
export const installationsLoading: Writable<boolean> = writable(false);
export const installationsError: Writable<string | null> = writable(null);

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

