<script lang="ts">
  import type { Repository, Installation } from './types';
  // Auth handled by PageLayout
  import { api } from './api';
  import { installations, selectedInstallation, installationsLoading, installationsError, currentVCSProvider } from './stores';
  import PageLayout from './components/layout/PageLayout.svelte';
  import Card from './components/ui/Card.svelte';
  import ClickableCard from './components/ui/ClickableCard.svelte';
  import LoadingSpinner from './components/ui/LoadingSpinner.svelte';
  import ErrorMessage from './components/ui/ErrorMessage.svelte';
  import CursorPagination from './components/ui/CursorPagination.svelte';
  import { navigateToRepository } from './utils/navigation';
  import { VCS_PROVIDERS } from './vcs/providers';
  
  interface RepositoryWithStats extends Repository {
    runCount?: number;
    lastRun?: string;
  }
  
  let repositories: RepositoryWithStats[] = [];
  let isLoadingRepos: boolean = false;
  let repoError: string | null = null;
  let isRefreshing: boolean = false;
  let lastRefreshedAt: Date | null = null;
  
  // Cursor-based pagination state
  let currentPage: number = 1;
  let hasMore: boolean = false;
  let cursors: string[] = []; // Stack of cursors to allow backward navigation
  let currentCursor: string | undefined = undefined;
  let isUsingCursorPagination: boolean = false;
  
  // Get current VCS provider terminology
  $: currentProvider = $currentVCSProvider || 'github';
  $: terminology = VCS_PROVIDERS[currentProvider]?.terminology || VCS_PROVIDERS.github.terminology;
  let totalRepositories: number = 0; // Estimated total for display purposes
  
  // Load repositories when selectedInstallation changes
  $: if ($selectedInstallation) {
    // Reset pagination state when installation changes
    currentPage = 1;
    cursors = [];
    currentCursor = undefined;
    hasMore = false;
    isUsingCursorPagination = false;
    loadRepositories($selectedInstallation);
  }
  
  async function loadRepositories(installation: Installation, direction: 'first' | 'next' | 'previous' = 'first'): Promise<void> {
    repoError = null;
    isLoadingRepos = true;
    
    try {
      let cursor: string | undefined;
      
      // Determine which cursor to use based on direction
      if (direction === 'first') {
        cursor = undefined; // Start from beginning
      } else if (direction === 'next') {
        cursor = currentCursor; // Use current cursor to get next page
      } else if (direction === 'previous' && cursors.length > 0) {
        // Go back to previous cursor
        cursors.pop(); // Remove current cursor
        cursor = cursors[cursors.length - 1]; // Use previous cursor
      }

      const response = await api.getInstallationRepos(installation.id, { 
        cursor 
      });
      
      if (response && response.repositories) {
        const baseRepos = response.repositories;
        
        // Enhance repositories with run statistics
        const reposWithStats = await Promise.all(
          baseRepos.map(async (repo) => {
            try {
              // Get run count for each repository
              const runsResponse = await api.getInstallationDirspaces(installation.id, {
                q: `repo:${repo.name}`,
                limit: 1000 // Get a large number to count
              });
              
              const runs = runsResponse?.dirspaces || [];
              const runCount = runs.length;
              
              // Find the most recent run
              const sortedRuns = runs
                .filter(d => d.completed_at)
                .sort((a, b) => new Date(b.completed_at!).getTime() - new Date(a.completed_at!).getTime());
              
              const lastRun = sortedRuns[0]?.completed_at;
              
              return {
                ...repo,
                runCount,
                lastRun
              } as RepositoryWithStats;
            } catch (err) {
              console.warn(`Failed to load run stats for ${repo.name}:`, err);
              return {
                ...repo,
                runCount: 0,
                lastRun: undefined
              } as RepositoryWithStats;
            }
          })
        );
        
        repositories = reposWithStats;
        
        // Update cursor-based pagination state
        hasMore = response.hasMore;
        isUsingCursorPagination = true;
        
        if (direction === 'next' && response.nextCursor) {
          // Moving forward - add current cursor to stack and update to next
          if (currentCursor) {
            cursors.push(currentCursor);
          }
          currentCursor = response.nextCursor;
          currentPage += 1;
        } else if (direction === 'previous') {
          // Moving backward - cursor already updated above
          currentPage = Math.max(1, currentPage - 1);
          currentCursor = response.nextCursor; // Update current cursor for this page
        } else if (direction === 'first') {
          // Starting fresh
          currentPage = 1;
          cursors = [];
          currentCursor = response.nextCursor;
        }
        
        // Update total count estimate for display
        totalRepositories = currentPage * repositories.length + (hasMore ? 10 : 0);
        
      } else {
        console.warn('No repositories found in response:', response);
        repositories = [];
        currentPage = 1;
        hasMore = false;
        cursors = [];
        currentCursor = undefined;
      }
    } catch (err) {
      repoError = 'Failed to load repositories';
      console.error('Error loading repositories:', err);
      repositories = [];
      isUsingCursorPagination = false;
    } finally {
      isLoadingRepos = false;
    }
  }

  function handleSetupRepo(): void {
    window.open('https://docs.terrateam.io/getting-started/quickstart-guide#option-2-set-up-your-own-repository', '_blank');
  }

  function handleNextPage(): void {
    if ($selectedInstallation && hasMore) {
      loadRepositories($selectedInstallation, 'next');
    }
  }
  
  function handlePreviousPage(): void {
    if ($selectedInstallation && currentPage > 1) {
      loadRepositories($selectedInstallation, 'previous');
    }
  }

  function handleRepoClick(repo: RepositoryWithStats): void {
    // Navigate to repository detail page for all repositories
    navigateToRepository(repo.id.toString());
  }
  
  function formatTimeAgo(dateString?: string): string {
    if (!dateString) return 'Never';
    const date = new Date(dateString);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));
    
    if (diffDays === 0) {
      const diffHours = Math.floor(diffMs / (1000 * 60 * 60));
      return diffHours === 0 ? 'Just now' : `${diffHours}h ago`;
    } else if (diffDays === 1) {
      return 'Yesterday';
    } else if (diffDays < 7) {
      return `${diffDays} days ago`;
    } else if (diffDays < 30) {
      const diffWeeks = Math.floor(diffDays / 7);
      return `${diffWeeks} week${diffWeeks !== 1 ? 's' : ''} ago`;
    } else {
      return date.toLocaleDateString();
    }
  }

  async function refreshRepositories(): Promise<void> {
    if (!$selectedInstallation || isRefreshing) return;
    
    isRefreshing = true;
    repoError = null;
    
    try {
      
      // Call the refresh endpoint - this triggers a background job
      const refreshResponse = await api.refreshInstallationRepos($selectedInstallation.id);
      
      // Poll the task status
      let attempts = 0;
      const maxAttempts = 30; // 30 seconds max
      
      while (attempts < maxAttempts) {
        await new Promise(resolve => setTimeout(resolve, 1000)); // Wait 1 second
        
        try {
          const taskStatus = await api.getTask(refreshResponse.id);
          
          if (taskStatus.state === 'completed') {
            // Refresh completed successfully, reload repositories from current position
            lastRefreshedAt = new Date();
            // Reload from the first page to maintain pagination state
            await loadRepositories($selectedInstallation, 'first');
            break;
          } else if (taskStatus.state === 'failed' || taskStatus.state === 'aborted') {
            throw new Error(`Repository refresh ${taskStatus.state}`);
          }
        } catch (taskError) {
          console.warn('Failed to check task status:', taskError);
          // Continue polling even if status check fails
        }
        
        attempts++;
      }
      
      if (attempts >= maxAttempts) {
        // Timeout - still reload repositories as they might have been updated
        lastRefreshedAt = new Date();
        // Reload from the first page to maintain pagination state
        await loadRepositories($selectedInstallation, 'first');
      }
    } catch (err) {
      console.error('Error refreshing repositories:', err);
      repoError = 'Failed to refresh repositories. Please try again.';
    } finally {
      isRefreshing = false;
    }
  }

</script>

<PageLayout 
  activeItem="repositories" 
  title="Repository Setup & Configuration"
  subtitle="Configure your repositories for Terraform infrastructure automation"
>
  <!-- Quick Setup Banner (for users who haven't set up repositories yet) -->
  {#if $installations.length > 0 && $selectedInstallation && repositories.length === 0 && !isLoadingRepos && !repoError}
    <Card padding="lg" class="mb-6 bg-blue-50 dark:bg-blue-900/20 border-blue-200 dark:border-blue-700">
      <div class="flex items-center justify-between">
        <div class="flex items-start space-x-4">
          <div class="flex-shrink-0">
            <div class="w-10 h-10 bg-blue-100 dark:bg-blue-900/30 rounded-lg flex items-center justify-center">
              <svg class="w-5 h-5 text-blue-600 dark:text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.746 0 3.332.477 4.5 1.253v13C19.832 18.477 18.246 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
              </svg>
            </div>
          </div>
          <div class="flex-1 min-w-0">
            <h3 class="text-lg font-semibold text-blue-900 dark:text-blue-100 mb-2">Ready to add your first repository?</h3>
            <p class="text-sm text-blue-800 dark:text-blue-200">
              Follow our step-by-step setup guide to connect your repositories and enable Terraform automation.
            </p>
          </div>
        </div>
        <button
          on:click={() => window.location.hash = '#/getting-started'}
          class="inline-flex items-center px-4 py-2 text-sm font-medium text-white bg-blue-600 dark:bg-blue-500 rounded-md hover:bg-blue-700 dark:hover:bg-blue-600 transition-colors"
        >
          <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7l5 5m0 0l-5 5m5-5H6" />
          </svg>
          Setup Guide
        </button>
      </div>
    </Card>
  {/if}

  <!-- Repositories List -->
  {#if $installationsLoading}
    <div class="flex justify-center items-center py-12">
      <LoadingSpinner size="lg" />
      <span class="ml-3 text-gray-600 dark:text-gray-400">Loading {terminology.organizations}...</span>
    </div>
  {:else if $installationsError}
    <ErrorMessage type="error" message="Failed to load {terminology.organizations}: {$installationsError}" />
  {:else if $installations.length === 0}
    <Card padding="lg" class="text-center">
      <div class="text-6xl mb-4">🔗</div>
      <h3 class="text-xl font-semibold text-gray-900 dark:text-gray-100 mb-2">No GitHub App Installation</h3>
      <p class="text-gray-600 dark:text-gray-400 mb-6">
        Install the Terrateam GitHub App to connect your repositories and start managing infrastructure.
      </p>
      <button
        on:click={() => window.open('https://github.com/apps/terrateam-action', '_blank')}
        class="px-4 py-2 bg-blue-600 dark:bg-blue-500 text-white rounded-md hover:bg-blue-700 dark:hover:bg-blue-600 transition-colors"
      >
        Install {VCS_PROVIDERS[currentProvider].displayName} App
      </button>
    </Card>
  {:else if $selectedInstallation}
    <Card padding="none">
      <div class="px-6 py-4 border-b border-gray-200 dark:border-gray-600">
        <div class="flex items-center justify-between">
          <div>
            <h2 class="text-lg font-semibold text-gray-900 dark:text-gray-100">
              Repositories in {$selectedInstallation.name}
            </h2>
            <p class="mt-1 text-sm text-gray-600 dark:text-gray-400">
              {#if totalRepositories > 0}
                Showing {repositories.length} of {totalRepositories} repositories
              {:else}
                View run activity and manage repository configuration
              {/if}
            </p>
          </div>
          <button
            on:click={refreshRepositories}
            disabled={isRefreshing}
            class="inline-flex items-center px-3 py-2 text-sm font-medium rounded-md transition-colors
              {isRefreshing 
                ? 'bg-gray-100 dark:bg-gray-700 text-gray-400 cursor-not-allowed' 
                : 'bg-white dark:bg-gray-700 text-gray-700 dark:text-gray-300 border border-gray-300 dark:border-gray-600 hover:bg-gray-50 dark:hover:bg-gray-600 focus:outline-none focus:ring-2 focus:ring-blue-500'}"
          >
            {#if isRefreshing}
              <svg class="animate-spin -ml-0.5 mr-2 h-4 w-4 text-gray-400" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              Refreshing...
            {:else}
              <svg class="-ml-0.5 mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
              </svg>
              Refresh
            {/if}
          </button>
        </div>
        {#if lastRefreshedAt}
          <p class="mt-2 text-xs text-gray-500 dark:text-gray-400">
            Last refreshed: {formatTimeAgo(lastRefreshedAt.toISOString())}
          </p>
        {/if}
      </div>

      {#if isLoadingRepos}
        <div class="flex justify-center items-center py-12">
          <LoadingSpinner size="md" />
          <span class="ml-3 text-gray-600 dark:text-gray-400">Loading repositories and run data...</span>
        </div>
      {:else if repoError}
        <div class="p-6">
          <ErrorMessage type="error" message={repoError} />
        </div>
      {:else if repositories.length === 0}
        <div class="text-center py-12">
          <div class="text-6xl mb-4">📁</div>
          <h3 class="text-xl font-semibold text-gray-900 dark:text-gray-100 mb-2">No Repositories</h3>
          <p class="text-gray-600 dark:text-gray-400 mb-6">
            This organization doesn't have any repositories connected to Terrateam.
          </p>
          <button
            on:click={handleSetupRepo}
            class="px-4 py-2 bg-green-600 dark:bg-green-500 text-white rounded-md hover:bg-green-700 dark:hover:bg-green-600 transition-colors"
          >
            Setup Guide
          </button>
        </div>
      {:else}
        <div class="divide-y divide-gray-200 dark:divide-gray-600">
          {#each repositories as repo}
            <div class="p-6">
              <div class="flex items-center justify-between">
                <div class="flex items-center min-w-0 flex-1">
                  <div class="flex-shrink-0">
                    <div class="w-10 h-10 bg-gray-100 dark:bg-gray-700 rounded-lg flex items-center justify-center">
                      <svg class="w-5 h-5 text-gray-600 dark:text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
                      </svg>
                    </div>
                  </div>
                  <div class="ml-4 min-w-0 flex-1">
                    <div class="flex items-center">
                      <h3 class="text-lg font-medium text-gray-900 dark:text-gray-100 truncate">{repo.name}</h3>
                    </div>
                    <div class="mt-2 flex items-center space-x-6 text-sm text-gray-500 dark:text-gray-400">
                      <div class="flex items-center">
                        <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M9 19l3 3m0 0l3-3m-3 3V10" />
                        </svg>
                        <span class="font-medium">{repo.runCount || 0}</span>
                        <span class="ml-1">runs</span>
                      </div>
                      <div class="flex items-center">
                        <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                        </svg>
                        <span>Last: {formatTimeAgo(repo.lastRun)}</span>
                      </div>
                    </div>
                  </div>
                </div>
                <div class="flex items-center space-x-3">
                  <ClickableCard 
                    padding="sm"
                    hover={true}
                    on:click={() => handleRepoClick(repo)}
                    aria-label="View repository {repo.name} details"
                    class="text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300"
                  >
                    <div class="flex items-center">
                      <span class="text-sm font-medium">View Details</span>
                      <svg class="w-4 h-4 ml-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
                      </svg>
                    </div>
                  </ClickableCard>
                </div>
              </div>
            </div>
          {/each}
        </div>
        
        <!-- Pagination -->
        {#if isUsingCursorPagination && (currentPage > 1 || hasMore)}
          <CursorPagination 
            {currentPage}
            hasNext={hasMore}
            hasPrevious={currentPage > 1}
            isLoading={isLoadingRepos}
            on:next={handleNextPage}
            on:previous={handlePreviousPage}
          />
        {/if}
        {/if}
    </Card>
  {:else}
    <!-- Demo Mode Message -->
    <Card padding="lg" class="border-blue-200 bg-blue-50 dark:bg-blue-900/20 dark:border-blue-800">
      <div class="text-center">
        <div class="flex justify-center mb-4">
          <svg class="w-16 h-16 text-blue-500 dark:text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
          </svg>
        </div>
        <h3 class="text-xl font-semibold text-blue-800 dark:text-blue-200 mb-2">Demo Mode - Repositories</h3>
        <p class="text-blue-700 dark:text-blue-300 mb-6">
          You're viewing the repositories page in demo mode. Once you connect a {VCS_PROVIDERS[currentProvider].displayName} {terminology.organization.toLowerCase()}, you'll see your actual repositories here.
        </p>
        
        <div class="grid gap-4 mb-6">
          <div class="text-sm text-blue-600 dark:text-blue-400 bg-white dark:bg-blue-800/30 rounded-lg p-4 border border-blue-200 dark:border-blue-700">
            <div class="font-semibold mb-2">What you'll see here:</div>
            <ul class="text-left space-y-1">
              <li>• All your connected GitHub repositories</li>
              <li>• Run statistics for each repository</li>
              <li>• Repository configuration status</li>
              <li>• Quick access to repository settings</li>
            </ul>
          </div>
        </div>
        
        <ClickableCard 
          padding="sm"
          hover={true}
          on:click={() => window.location.hash = '#/getting-started'}
          aria-label="Go to getting started to connect a repository"
          class="inline-block bg-white dark:bg-blue-800/30 border-blue-300 dark:border-blue-600 hover:border-blue-400 dark:hover:border-blue-500"
        >
          <div class="flex items-center space-x-2 text-blue-700 dark:text-blue-300">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.746 0 3.332.477 4.5 1.253v13C19.832 18.477 18.246 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
            </svg>
            <span class="font-medium">Connect Your First Repository</span>
          </div>
        </ClickableCard>
      </div>
    </Card>
  {/if}
</PageLayout>
