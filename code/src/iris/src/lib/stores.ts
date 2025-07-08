import { writable, get, type Writable } from 'svelte/store';
import type { Installation, Repository, ThemeStore, ThemeMode } from './types';
import type { VCSProvider } from './vcs/types';

// VCS Provider state
export const currentVCSProvider: Writable<VCSProvider> = writable('github');
export const availableProviders: Writable<VCSProvider[]> = writable(['github', 'gitlab']);

// Organization/installation state
export const installations: Writable<Installation[]> = writable([]);
export const selectedInstallation: Writable<Installation | null> = writable(null);
export const installationsLoading: Writable<boolean> = writable(false);
export const installationsError: Writable<string | null> = writable(null);

// Repository caching to avoid redundant API calls
export const repositoryCache: Writable<Record<string, Repository[]>> = writable({});
export const repositoriesLoading: Writable<Record<string, boolean>> = writable({});

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

// Repository loading helper with caching
export async function loadRepositoriesForInstallation(installationId: string): Promise<Repository[]> {
  const { api } = await import('./api');
  
  // Check if already loading
  const currentLoading = get(repositoriesLoading);
  if (currentLoading[installationId]) {
    return []; // Return empty array if already loading
  }
  
  // Check cache first
  const currentCache = get(repositoryCache);
  if (currentCache[installationId]) {
    return currentCache[installationId];
  }
  
  // Mark as loading
  repositoriesLoading.update(loading => ({ ...loading, [installationId]: true }));
  
  try {
    const response = await api.getInstallationRepos(installationId);
    const repos = response && (response as any).repositories ? (response as any).repositories : [];
    
    // Update cache
    repositoryCache.update(cache => ({ ...cache, [installationId]: repos }));
    
    return repos;
  } catch (error) {
    console.error('Error loading repositories:', error);
    return [];
  } finally {
    // Clear loading state
    repositoriesLoading.update(loading => ({ ...loading, [installationId]: false }));
  }
}

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