<script lang="ts">
  import type { Installation, ServerConfig } from './types';
  // Auth handled by PageLayout
  import { installations, selectedInstallation, installationsLoading, installationsError, currentVCSProvider } from './stores';
  import { repositoryService, type RepositoryWithStats } from './services/repository-service';
  import { api } from './api';
  import PageLayout from './components/layout/PageLayout.svelte';
  import Card from './components/ui/Card.svelte';
  import ClickableCard from './components/ui/ClickableCard.svelte';
  import LoadingSpinner from './components/ui/LoadingSpinner.svelte';
  import ErrorMessage from './components/ui/ErrorMessage.svelte';
  import { navigateToRepository } from './utils/navigation';
  import { VCS_PROVIDERS } from './vcs/providers';
  import { onMount } from 'svelte';
  
  // Router props (external reference only)
  export const params = {};
  
  // Server configuration
  let serverConfig: ServerConfig | null = null;
  let githubAppUrl: string = 'https://github.com/apps/terrateam-action'; // fallback URL
  
  // Repository cache - stores ALL repositories once loaded
  let allRepositories: RepositoryWithStats[] = [];
  let isLoadingRepos: boolean = false;
  let repoError: string | null = null;
  let isRefreshing: boolean = false;
  let lastRefreshedAt: Date | null = null;
  let loadProgress: { current: number; total?: number } = { current: 0 };
  
  // Filter/search state
  let filteredRepositories: RepositoryWithStats[] = [];
  let sortBy: 'name' | 'updated' = 'name'; // Default to alphabetical
  let showConfiguredOnly: boolean = false; // Filter to show only configured repos
  let searchQuery: string = ''; // Now we can search ALL repos!
  
  // Client-side pagination state for display
  let currentDisplayPage: number = 1;
  let itemsPerPage: number = 20;
  let paginatedRepositories: RepositoryWithStats[] = [];
  let totalPages: number = 0;
  
  // Get current VCS provider terminology
  $: currentProvider = $currentVCSProvider || 'github';
  $: terminology = VCS_PROVIDERS[currentProvider]?.terminology || VCS_PROVIDERS.github.terminology;
  
  onMount(async () => {
    // Fetch server config to get GitHub app URL
    try {
      serverConfig = await api.getServerConfig();
      if (serverConfig?.github?.app_url) {
        githubAppUrl = serverConfig.github.app_url;
      }
    } catch (error) {
      console.error('Failed to fetch server config:', error);
      // Will use fallback URL
    }
  });
  
  // Filter and sort repositories from cache
  $: {
    let filtered = allRepositories;
    
    // Apply search filter
    if (searchQuery.trim()) {
      const query = searchQuery.toLowerCase();
      filtered = filtered.filter(repo => 
        repo.name.toLowerCase().includes(query)
      );
    }
    
    // Apply configured filter
    if (showConfiguredOnly) {
      filtered = filtered.filter(repo => repo.setup);
    }
    
    // Apply sorting
    filteredRepositories = [...filtered].sort((a, b) => {
      switch (sortBy) {
        case 'updated':
          // Sort by updated_at date (most recent first)
          const aDate = new Date(a.updated_at).getTime();
          const bDate = new Date(b.updated_at).getTime();
          return bDate - aDate;
        case 'name':
        default:
          // Sort alphabetically
          return a.name.localeCompare(b.name);
      }
    });
  }
  
  // Client-side pagination for display
  $: {
    totalPages = Math.ceil(filteredRepositories.length / itemsPerPage);
    
    // Reset to page 1 if current page is beyond total pages
    if (currentDisplayPage > totalPages && totalPages > 0) {
      currentDisplayPage = 1;
    }
    
    // Calculate paginated slice
    const startIndex = (currentDisplayPage - 1) * itemsPerPage;
    const endIndex = startIndex + itemsPerPage;
    paginatedRepositories = filteredRepositories.slice(startIndex, endIndex);
  }
  
  // Load all repositories when selectedInstallation changes
  $: if ($selectedInstallation) {
    loadRepositories($selectedInstallation);
  }
  
  async function loadRepositories(installation: Installation, forceRefresh: boolean = false): Promise<void> {
    repoError = null;
    isLoadingRepos = true;
    loadProgress = { current: 0 };
    
    try {
      const result = await repositoryService.loadRepositories(installation, forceRefresh);
      
      allRepositories = result.repositories;
      
      if (result.error) {
        repoError = result.error;
      }
      
      // Update last refreshed time if this was a fresh load
      if (!result.fromCache && !result.error) {
        lastRefreshedAt = new Date();
      }
    } catch (err) {
      repoError = 'Failed to load repositories';
      console.error('Error loading repositories:', err);
      allRepositories = [];
    } finally {
      isLoadingRepos = false;
      loadProgress = { current: 0 };
    }
  }

  function handleSetupRepo(): void {
    window.open('https://docs.terrateam.io/getting-started/quickstart-guide#option-2-set-up-your-own-repository', '_blank');
  }
  
  function goToPage(page: number): void {
    if (page >= 1 && page <= totalPages) {
      currentDisplayPage = page;
    }
  }
  
  function goToNextPage(): void {
    if (currentDisplayPage < totalPages) {
      currentDisplayPage++;
    }
  }
  
  function goToPreviousPage(): void {
    if (currentDisplayPage > 1) {
      currentDisplayPage--;
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
      // Check if this is a GitLab installation
      const currentProvider = $currentVCSProvider;
      
      if (currentProvider === 'gitlab') {
        // GitLab doesn't have a refresh endpoint, just reload the repositories
        await loadRepositories($selectedInstallation, true);
        lastRefreshedAt = new Date();
        isRefreshing = false;
        return;
      }
      
      // Call the refresh endpoint for GitHub - this triggers a background job to sync
      const refreshResponse = await api.refreshInstallationRepos($selectedInstallation.id, currentProvider);
      
      // Poll the task status
      let attempts = 0;
      const maxAttempts = 30; // 30 seconds max
      
      while (attempts < maxAttempts) {
        await new Promise(resolve => setTimeout(resolve, 1000)); // Wait 1 second
        
        try {
          const taskStatus = await api.getTask(refreshResponse.id);
          
          if (taskStatus.state === 'completed') {
            // Refresh completed successfully, reload with fresh data
            await loadRepositories($selectedInstallation, true);
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
        await loadRepositories($selectedInstallation, true);
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
  {#if $installations.length > 0 && $selectedInstallation && allRepositories.length === 0 && !isLoadingRepos && !repoError}
    <Card padding="lg" class="mb-6 bg-blue-50 dark:bg-blue-900/20 border-blue-200 dark:border-blue-700">
      <div class="flex flex-col md:flex-row md:items-center md:justify-between space-y-4 md:space-y-0">
        <div class="flex items-start space-x-4 flex-1">
          <div class="flex-shrink-0">
            <div class="w-10 h-10 bg-blue-100 dark:bg-blue-900/30 rounded-lg flex items-center justify-center">
              <svg class="w-5 h-5 text-blue-600 dark:text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.746 0 3.332.477 4.5 1.253v13C19.832 18.477 18.246 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
              </svg>
            </div>
          </div>
          <div class="flex-1 min-w-0">
            <h3 class="text-base md:text-lg font-semibold text-blue-900 dark:text-blue-100 mb-2">Ready to add your first repository?</h3>
            <p class="text-sm text-blue-800 dark:text-blue-200">
              Follow our step-by-step setup guide to connect your repositories and enable Terraform automation.
            </p>
          </div>
        </div>
        <button
          on:click={() => window.location.hash = '#/getting-started'}
          class="inline-flex items-center px-3 md:px-4 py-2 text-sm font-medium text-white bg-blue-600 dark:bg-blue-500 rounded-md hover:bg-blue-700 dark:hover:bg-blue-600 transition-colors whitespace-nowrap"
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
        on:click={() => window.open(githubAppUrl, '_blank')}
        class="px-4 py-2 bg-blue-600 dark:bg-blue-500 text-white rounded-md hover:bg-blue-700 dark:hover:bg-blue-600 transition-colors"
      >
        Install {VCS_PROVIDERS[currentProvider].displayName} App
      </button>
    </Card>
  {:else if $selectedInstallation}
    <Card padding="none">
      <div class="px-4 md:px-6 py-4 border-b border-gray-200 dark:border-gray-600">
        <div class="flex flex-col md:flex-row md:items-center md:justify-between space-y-2 md:space-y-0">
          <div>
            <h2 class="text-lg font-semibold text-gray-900 dark:text-gray-100">
              Repositories in {$selectedInstallation.name}
            </h2>
            <p class="mt-1 text-sm text-gray-600 dark:text-gray-400">
              {#if isLoadingRepos}
                Loading repositories... (page {loadProgress.current})
              {:else if allRepositories.length > 0}
                {#if searchQuery.trim() || showConfiguredOnly}
                  Showing {paginatedRepositories.length} of {filteredRepositories.length} repositories
                  {#if searchQuery.trim()}
                    matching "{searchQuery}"
                  {/if}
                  {#if showConfiguredOnly}
                    (configured only)
                  {/if}
                  {#if totalPages > 1}
                    • Page {currentDisplayPage} of {totalPages}
                  {/if}
                {:else}
                  Showing {paginatedRepositories.length} of {allRepositories.length} repositories
                  {#if totalPages > 1}
                    • Page {currentDisplayPage} of {totalPages}
                  {/if}
                {/if}
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
        {:else if allRepositories.length > 0}
          <p class="mt-2 text-xs text-gray-500 dark:text-gray-400">
            Data loaded from cache
          </p>
        {/if}
      </div>
      
      <!-- Search and Filter bar -->
      {#if allRepositories.length > 0 || isLoadingRepos}
        <div class="px-6 py-4 border-b border-gray-200 dark:border-gray-600">
          <div class="flex flex-col md:flex-row md:items-center md:justify-between md:space-x-4 space-y-4 md:space-y-0">
            <div class="flex flex-col md:flex-row md:items-center md:space-x-4 space-y-4 md:space-y-0 flex-1">
              <!-- Search input -->
              <div class="flex-1 w-full md:max-w-md">
                <div class="relative">
                  <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <svg class="h-5 w-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                    </svg>
                  </div>
                  <input
                    type="text"
                    placeholder="Search repositories..."
                    bind:value={searchQuery}
                    disabled={isLoadingRepos}
                    class="block w-full pl-10 pr-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md leading-5 bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100 placeholder-gray-500 dark:placeholder-gray-400 focus:outline-none focus:ring-1 focus:ring-blue-500 focus:border-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
                  />
                </div>
              </div>
              
              <!-- Sort and filter controls -->
              <div class="flex flex-col sm:flex-row sm:items-center sm:space-x-4 space-y-2 sm:space-y-0">
                <div class="flex items-center space-x-2">
                  <span class="text-sm text-gray-700 dark:text-gray-300">Sort by:</span>
                  <select
                    bind:value={sortBy}
                    disabled={isLoadingRepos}
                    class="text-sm border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100 focus:ring-blue-500 focus:border-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    <option value="name">Name (A-Z)</option>
                    <option value="updated">Recently Updated</option>
                  </select>
                </div>
                <label class="flex items-center space-x-2 text-sm">
                  <input
                    type="checkbox"
                    bind:checked={showConfiguredOnly}
                    disabled={isLoadingRepos}
                    class="rounded border-gray-300 dark:border-gray-600 text-blue-600 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
                  />
                  <span class="text-gray-700 dark:text-gray-300">Configured only</span>
                </label>
              </div>
            </div>
            
            <!-- Clear search button -->
            {#if searchQuery.trim()}
              <button
                on:click={() => searchQuery = ''}
                class="inline-flex items-center px-2 py-1 text-sm text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-200 transition-colors"
              >
                <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                </svg>
                Clear
              </button>
            {/if}
          </div>
        </div>
      {/if}

      {#if isLoadingRepos}
        <div class="flex justify-center items-center py-12">
          <LoadingSpinner size="md" />
          <span class="ml-3 text-gray-600 dark:text-gray-400">
            Loading repositories... (page {loadProgress.current})
          </span>
        </div>
      {:else if repoError}
        <div class="p-6">
          <ErrorMessage type="error" message={repoError} />
        </div>
      {:else if paginatedRepositories.length === 0 && (showConfiguredOnly || searchQuery.trim()) && allRepositories.length > 0}
        <div class="text-center py-12">
          <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.172 16.172a4 4 0 015.656 0M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
          </svg>
          <h3 class="mt-2 text-sm font-medium text-gray-900 dark:text-gray-100">No repositories found</h3>
          <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
            {#if searchQuery.trim() && showConfiguredOnly}
              No configured repositories match "{searchQuery}"
            {:else if searchQuery.trim()}
              No repositories match "{searchQuery}"
            {:else if showConfiguredOnly}
              No configured repositories found
            {/if}
          </p>
          <div class="mt-6">
            <div class="flex justify-center space-x-3">
              {#if searchQuery.trim()}
                <button
                  on:click={() => searchQuery = ''}
                  class="inline-flex items-center px-3 py-2 border border-gray-300 shadow-sm text-sm leading-4 font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 dark:border-gray-600 dark:text-gray-300 dark:bg-gray-700 dark:hover:bg-gray-600"
                >
                  Clear search
                </button>
              {/if}
              {#if showConfiguredOnly}
                <button
                  on:click={() => showConfiguredOnly = false}
                  class="inline-flex items-center px-3 py-2 border border-gray-300 shadow-sm text-sm leading-4 font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 dark:border-gray-600 dark:text-gray-300 dark:bg-gray-700 dark:hover:bg-gray-600"
                >
                  Show all repositories
                </button>
              {/if}
            </div>
          </div>
        </div>
      {:else if allRepositories.length === 0}
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
          {#each paginatedRepositories as repo}
            <div class="p-4 md:p-6">
              <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between space-y-3 sm:space-y-0">
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
                      <h3 class="text-base md:text-lg font-medium text-gray-900 dark:text-gray-100 truncate">{repo.name}</h3>
                    </div>
                    {#if repo.setup}
                      <div class="mt-1 flex items-center text-sm text-green-600 dark:text-green-400">
                        <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                        </svg>
                        <span>Configured</span>
                      </div>
                    {:else}
                      <div class="mt-1 flex items-center text-sm text-gray-500 dark:text-gray-400">
                        <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                        </svg>
                        <span>Not configured</span>
                      </div>
                    {/if}
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
        
        <!-- Pagination Controls -->
        {#if totalPages > 1}
          <div class="px-4 md:px-6 py-4 border-t border-gray-200 dark:border-gray-600">
            <div class="flex flex-col md:flex-row md:items-center md:justify-between space-y-3 md:space-y-0">
              <div class="flex items-center text-xs md:text-sm text-gray-700 dark:text-gray-300">
                <span>
                  Showing {((currentDisplayPage - 1) * itemsPerPage) + 1} to {Math.min(currentDisplayPage * itemsPerPage, filteredRepositories.length)} of {filteredRepositories.length} repositories
                </span>
              </div>
              <div class="flex items-center space-x-2">
                <button
                  on:click={goToPreviousPage}
                  disabled={currentDisplayPage === 1}
                  class="px-3 py-1 text-sm border border-gray-300 dark:border-gray-600 rounded-md hover:bg-gray-50 dark:hover:bg-gray-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                >
                  Previous
                </button>
                
                <!-- Page numbers -->
                {#each Array(Math.min(5, totalPages)) as _, i}
                  {@const pageNum = Math.max(1, Math.min(totalPages - 4, currentDisplayPage - 2)) + i}
                  {#if pageNum <= totalPages}
                    <button
                      on:click={() => goToPage(pageNum)}
                      class="px-3 py-1 text-sm border border-gray-300 dark:border-gray-600 rounded-md transition-colors {pageNum === currentDisplayPage ? 'bg-blue-600 text-white border-blue-600' : 'hover:bg-gray-50 dark:hover:bg-gray-700'}"
                    >
                      {pageNum}
                    </button>
                  {/if}
                {/each}
                
                <button
                  on:click={goToNextPage}
                  disabled={currentDisplayPage === totalPages}
                  class="px-3 py-1 text-sm border border-gray-300 dark:border-gray-600 rounded-md hover:bg-gray-50 dark:hover:bg-gray-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                >
                  Next
                </button>
              </div>
            </div>
          </div>
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
