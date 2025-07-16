import type { Repository, Installation } from '../types';
import { api } from '../api';
import { cachedRepositories, repositoriesCacheLoading } from '../stores';

export interface RepositoryWithStats extends Repository {
  runCount?: number;
  lastRun?: string;
}

export interface RepositoryLoadResult {
  repositories: RepositoryWithStats[];
  fromCache: boolean;
  error?: string;
}

/**
 * Centralized repository loading service with persistent caching
 */
export class RepositoryService {
  private static instance: RepositoryService;
  private loadingPromises: Map<string, Promise<RepositoryLoadResult>> = new Map();

  private constructor() {}

  static getInstance(): RepositoryService {
    if (!RepositoryService.instance) {
      RepositoryService.instance = new RepositoryService();
    }
    return RepositoryService.instance;
  }

  /**
   * Load all repositories for an installation, using cache if available
   * @param installation The installation to load repositories for
   * @param forceRefresh If true, bypasses cache and loads fresh data
   * @returns Promise with repositories and metadata
   */
  async loadRepositories(
    installation: Installation, 
    forceRefresh: boolean = false
  ): Promise<RepositoryLoadResult> {
    const installationId = installation.id;

    // If already loading for this installation, return the existing promise
    const existingPromise = this.loadingPromises.get(installationId);
    if (existingPromise && !forceRefresh) {
      return existingPromise;
    }

    // Create new loading promise
    const loadPromise = this._loadRepositoriesInternal(installation, forceRefresh);
    this.loadingPromises.set(installationId, loadPromise);

    try {
      const result = await loadPromise;
      return result;
    } finally {
      // Clean up loading promise
      this.loadingPromises.delete(installationId);
    }
  }

  private async _loadRepositoriesInternal(
    installation: Installation,
    forceRefresh: boolean
  ): Promise<RepositoryLoadResult> {
    const installationId = installation.id;

    // Check cache first (unless force refresh)
    if (!forceRefresh) {
      const cachedRepos = cachedRepositories.loadFromCache(installationId);
      if (cachedRepos.length > 0) {
        return {
          repositories: cachedRepos as RepositoryWithStats[],
          fromCache: true
        };
      }
    } else {
      // Clear cache if force refresh
      cachedRepositories.clearCache(installationId);
    }

    // Load from API
    repositoriesCacheLoading.set(true);
    
    try {
      const allRepos: RepositoryWithStats[] = [];
      let cursor: string | undefined;
      let pageCount = 0;
      
      // Load all pages
      do {
        pageCount++;
        
        const response = await api.getInstallationRepos(
          installationId, 
          cursor ? { cursor } : undefined
        );
        
        if (response && response.repositories) {
          const baseRepos = response.repositories;
          
          // Add stats placeholder (we skip expensive run statistics)
          const reposWithStats = baseRepos.map(repo => ({
            ...repo,
            runCount: undefined,
            lastRun: undefined
          } as RepositoryWithStats));
          
          allRepos.push(...reposWithStats);
          
          // Update pagination state
          cursor = response.nextCursor;
          
        } else {
          console.warn('No repositories found in response:', response);
          break;
        }
      } while (cursor);
      
      // Update the persistent cache
      cachedRepositories.set(allRepos, installationId);
      
      return {
        repositories: allRepos,
        fromCache: false
      };
      
    } catch (err) {
      console.error('Error loading repositories:', err);
      return {
        repositories: [],
        fromCache: false,
        error: 'Failed to load repositories'
      };
    } finally {
      repositoriesCacheLoading.set(false);
    }
  }

  /**
   * Get a specific repository from cache
   * @param installationId The installation ID
   * @param repositoryId The repository ID to find
   * @returns The repository if found, null otherwise
   */
  getRepositoryFromCache(installationId: string, repositoryId: string): Repository | null {
    // First ensure we have the cache loaded for this installation
    const cached = cachedRepositories.loadFromCache(installationId);
    return cached.find(repo => repo.id === repositoryId) || null;
  }

  /**
   * Check if repositories are cached for an installation
   * @param installationId The installation ID
   * @returns True if repositories are cached
   */
  hasCachedRepositories(installationId: string): boolean {
    const cached = cachedRepositories.loadFromCache(installationId);
    return cached.length > 0;
  }

  /**
   * Get cache timestamp for an installation
   * @param installationId The installation ID
   * @returns Timestamp or null if not cached
   */
  getCacheTimestamp(installationId: string): number | null {
    return cachedRepositories.getCacheTimestamp(installationId);
  }

  /**
   * Clear repository cache for an installation
   * @param installationId The installation ID
   */
  clearCache(installationId: string): void {
    cachedRepositories.clearCache(installationId);
  }

  /**
   * Clear all repository caches
   */
  clearAllCaches(): void {
    // Get all cache keys from localStorage
    if (typeof window !== 'undefined') {
      const keys = Object.keys(localStorage);
      keys.forEach(key => {
        if (key.startsWith('repositories-cache-')) {
          localStorage.removeItem(key);
        }
      });
      // Clear the store
      cachedRepositories.set([]);
    }
  }
}

// Export singleton instance
export const repositoryService = RepositoryService.getInstance();