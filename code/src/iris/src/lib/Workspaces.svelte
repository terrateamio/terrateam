<script lang="ts">
  import type { Dirspace, Repository } from './types';
  // Auth handled by PageLayout
  import { api } from './api';
  import { selectedInstallation, installationsLoading, currentVCSProvider } from './stores';
  import PageLayout from './components/layout/PageLayout.svelte';
  import { navigateToWorkspace } from './utils/navigation';
  import LoadingSpinner from './components/ui/LoadingSpinner.svelte';
  import ErrorMessage from './components/ui/ErrorMessage.svelte';
  import Card from './components/ui/Card.svelte';
  import ClickableCard from './components/ui/ClickableCard.svelte';
  import { VCS_PROVIDERS } from './vcs/providers';
  
  // Get current VCS provider terminology
  $: currentProvider = $currentVCSProvider || 'github';
  $: terminology = VCS_PROVIDERS[currentProvider]?.terminology || VCS_PROVIDERS.github.terminology;
  
  let repositories: Repository[] = [];
  let isLoadingRepositories: boolean = false;
  let error: string | null = null;

  // Repository workspaces - lazy loaded per repo
  let repoWorkspaces: Record<string, Dirspace[]> = {};
  let loadingRepos: Set<string> = new Set(); // Track which repos are currently loading
  let loadedRepos: Set<string> = new Set(); // Track which repos have been loaded
  let repoErrors: Record<string, string> = {}; // Track loading errors per repo
  let collapsedRepos: Set<string> = new Set(); // Track collapsed state
  
  // Note: Pagination removed because dirspaces API returns operations, not unique workspaces
  // We load all dirspaces at once and deduplicate to show unique workspaces
  
  // Summary stats
  let totalWorkspaceCount: number = 0;
  
  const DIRSPACES_PER_REQUEST = 1000; // Load many dirspaces to find all unique workspaces

  // Load data when installation changes
  let lastInstallationId: string | null = null;
  $: if ($selectedInstallation && $selectedInstallation.id !== lastInstallationId) {
    lastInstallationId = $selectedInstallation.id;
    // Reset state
    repoWorkspaces = {};
    loadedRepos = new Set();
    loadingRepos = new Set();
    repoErrors = {};
    collapsedRepos = new Set();
    totalWorkspaceCount = 0;
    
    loadRepositories();
  }
  
  async function loadRepositories(): Promise<void> {
    if (!$selectedInstallation) return;
    
    repositories = [];
    isLoadingRepositories = true;
    error = null;
    
    try {
      let hasMore = true;
      let cursor: string | undefined = undefined;
      
      // Load all repositories using pagination
      while (hasMore) {
        const response = await api.getInstallationRepos($selectedInstallation.id, { cursor });
        
        if (response && response.repositories) {
          repositories = [...repositories, ...response.repositories];
          cursor = response.nextCursor;
          hasMore = response.hasMore;
        } else {
          hasMore = false;
        }
      }

      // Initialize all repos as collapsed by default
      repositories.forEach(repo => {
        collapsedRepos.add(repo.name);
      });
      collapsedRepos = new Set(collapsedRepos); // Trigger reactivity
      
    } catch (err) {
      console.error('Error loading repositories:', err);
      error = err instanceof Error ? err.message : 'Failed to load repositories';
      repositories = [];
    } finally {
      isLoadingRepositories = false;
    }
  }

  async function loadWorkspacesForRepo(repoName: string): Promise<void> {
    if (!$selectedInstallation) return;
    if (loadedRepos.has(repoName) || loadingRepos.has(repoName)) return;
    
    // Mark as loading
    loadingRepos.add(repoName);
    loadingRepos = new Set(loadingRepos);
    
    try {
      // Load a large number of dirspaces to find all unique workspaces
      // Since dirspaces are operations (not workspace definitions), we need to
      // load many to ensure we capture all unique workspace combinations
      const response = await api.getInstallationDirspaces($selectedInstallation.id, {
        q: `repo:${repoName}`,
        limit: DIRSPACES_PER_REQUEST,
        d: 'desc' // Sort by descending to get newest first
      });
      
      if (response && response.dirspaces && response.dirspaces.length > 0) {
        // Deduplicate workspaces by dir:workspace key
        const uniqueWorkspacesMap = new Map<string, Dirspace>();
        
        response.dirspaces.forEach((dirspace: Dirspace) => {
          const workspaceKey = `${dirspace.dir}:${dirspace.workspace}`;
          
          // Keep the most recent dirspace for each unique workspace
          const existing = uniqueWorkspacesMap.get(workspaceKey);
          if (!existing || (dirspace.completed_at && existing.completed_at && 
              new Date(dirspace.completed_at) > new Date(existing.completed_at))) {
            uniqueWorkspacesMap.set(workspaceKey, dirspace);
          }
        });
        
        // Convert map to array
        const uniqueWorkspaces = Array.from(uniqueWorkspacesMap.values());
        
        // Sort by most recently used (already sorted by API, but ensure consistency)
        uniqueWorkspaces.sort((a, b) => {
          const dateA = a.completed_at ? new Date(a.completed_at).getTime() : 0;
          const dateB = b.completed_at ? new Date(b.completed_at).getTime() : 0;
          return dateB - dateA;
        });
        
        repoWorkspaces[repoName] = uniqueWorkspaces;
        
        // Update total count
        totalWorkspaceCount += uniqueWorkspaces.length;
        
      } else {
        repoWorkspaces[repoName] = [];
      }
      
      // Mark as loaded
      loadedRepos.add(repoName);
      loadedRepos = new Set(loadedRepos);
      
    } catch (err) {
      console.error(`Failed to load workspaces for ${repoName}:`, err);
      repoErrors[repoName] = err instanceof Error ? err.message : 'Failed to load workspaces';
      repoWorkspaces[repoName] = [];
    } finally {
      // Remove from loading
      loadingRepos.delete(repoName);
      loadingRepos = new Set(loadingRepos);
    }
    
    // Trigger reactivity
    repoWorkspaces = { ...repoWorkspaces };
  }

  async function toggleRepoCollapse(repoName: string): Promise<void> {
    const newCollapsed = new Set(collapsedRepos);
    if (newCollapsed.has(repoName)) {
      // Expanding - load workspaces if not already loaded
      newCollapsed.delete(repoName);
      if (!loadedRepos.has(repoName) && !loadingRepos.has(repoName)) {
        await loadWorkspacesForRepo(repoName);
      }
    } else {
      // Collapsing
      newCollapsed.add(repoName);
    }
    collapsedRepos = newCollapsed;
  }
  
  function formatDate(dateString: string): string {
    return new Date(dateString).toLocaleString();
  }
  
  function getStateColor(state: string): string {
    switch (state) {
      case 'success':
        return 'bg-green-100 dark:bg-green-900/30 text-green-800 dark:text-green-400';
      case 'failure':
        return 'bg-red-100 dark:bg-red-900/30 text-red-800 dark:text-red-400';
      case 'running':
        return 'bg-blue-100 dark:bg-blue-900/30 text-blue-800 dark:text-blue-400';
      case 'queued':
        return 'bg-yellow-100 dark:bg-yellow-900/30 text-yellow-800 dark:text-yellow-400';
      case 'aborted':
        return 'bg-gray-100 dark:bg-gray-700 text-gray-800 dark:text-gray-300';
      default:
        return 'bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-400';
    }
  }
  
  function getStateIcon(state: string): string {
    switch (state) {
      case 'success':
        return '✅';
      case 'failure':
        return '❌';
      case 'running':
        return '🔄';
      case 'queued':
        return '⏳';
      case 'aborted':
        return '⚠️';
      default:
        return '❓';
    }
  }
  
  function getRunTypeLabel(runType: string): string {
    switch (runType) {
      case 'plan':
        return '📋 Plan';
      case 'apply':
        return '🚀 Apply';
      case 'index':
        return '📑 Index';
      case 'build-config':
        return '🔧 Build Config';
      case 'build-tree':
        return '🌳 Build Tree';
      default:
        return runType;
    }
  }

  // Get all workspaces from loaded repos
  $: allWorkspaces = Object.values(repoWorkspaces).flat();

  // Calculate summary statistics (only from loaded workspaces)
  $: totalRepositories = repositories.length;
  $: successfulWorkspaces = allWorkspaces.filter(ws => ws.state === 'success').length;
  $: failedWorkspaces = allWorkspaces.filter(ws => ws.state === 'failure').length;
  
</script>

<PageLayout 
  activeItem="workspaces" 
  title="Workspaces"
  subtitle="Manage Terraform directories and workspace combinations across your repositories"
>
  <!-- Summary Cards -->
  <div class="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
    <Card padding="lg" class="text-center">
      <div class="text-3xl font-bold text-brand-primary">{totalWorkspaceCount}</div>
      <div class="text-sm text-gray-600 dark:text-gray-400 mt-1">Workspaces Loaded</div>
    </Card>
    <Card padding="lg" class="text-center">
      <div class="text-3xl font-bold text-brand-primary">{totalRepositories}</div>
      <div class="text-sm text-gray-600 dark:text-gray-400 mt-1">Repositories</div>
    </Card>
    <Card padding="lg" class="text-center">
      <div class="text-3xl font-bold text-green-600 dark:text-green-400">{successfulWorkspaces}</div>
      <div class="text-sm text-gray-600 dark:text-gray-400 mt-1">Successful</div>
    </Card>
    <Card padding="lg" class="text-center">
      <div class="text-3xl font-bold text-red-600 dark:text-red-400">{failedWorkspaces}</div>
      <div class="text-sm text-gray-600 dark:text-gray-400 mt-1">Failed</div>
    </Card>
  </div>

  <!-- Lazy loading info -->
  {#if repositories.length > 0 && totalWorkspaceCount === 0 && !isLoadingRepositories}
    <div class="mb-6 text-sm text-gray-600 dark:text-gray-400 text-center">
      <p>Click on a repository below to load its workspaces</p>
    </div>
  {/if}

  <!-- Content -->
  {#if $installationsLoading}
    <!-- Loading installations -->
    <div class="flex flex-col items-center py-12">
      <LoadingSpinner size="lg" />
      <div class="mt-4 text-center">
        <p class="text-gray-600 dark:text-gray-400">Loading installations...</p>
      </div>
    </div>
  {:else if !$selectedInstallation}
    <!-- Demo Mode Message -->
    <Card padding="lg" class="border-blue-200 bg-blue-50 dark:bg-blue-900/20 dark:border-blue-800">
      <div class="text-center">
        <div class="flex justify-center mb-4">
          <svg class="w-16 h-16 text-blue-500 dark:text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 7v10c0 2.21 3.582 4 8 4s8-1.79 8-4V7M4 7c0 2.21 3.582 4 8 4s8-1.79 8-4M4 7c0-2.21 3.582-4 8-4s8 1.79 8 4m0 5c0 2.21-3.582 4-8 4s-8-1.79-8-4" />
          </svg>
        </div>
        <h3 class="text-xl font-semibold text-blue-800 dark:text-blue-200 mb-2">Demo Mode - Workspaces</h3>
        <p class="text-blue-700 dark:text-blue-300 mb-6">
          You're viewing the workspaces page in demo mode. Once you connect a {VCS_PROVIDERS[currentProvider].displayName} {terminology.organization.toLowerCase()}, you'll see your actual Terraform workspaces and their status.
        </p>
        
        <div class="grid gap-4 mb-6">
          <div class="text-sm text-blue-600 dark:text-blue-400 bg-white dark:bg-blue-800/30 rounded-lg p-4 border border-blue-200 dark:border-blue-700">
            <div class="font-semibold mb-2">What you'll see here:</div>
            <ul class="text-left space-y-1">
              <li>• All your Terraform workspaces across repositories</li>
              <li>• Workspace status and last run information</li>
              <li>• Quick access to workspace-specific operations</li>
              <li>• Environment-based organization of your infrastructure</li>
              <li>• Real-time status tracking for all workspaces</li>
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
  {:else if isLoadingRepositories}
    <div class="flex flex-col items-center py-12">
      <LoadingSpinner size="lg" />
      <div class="mt-4 text-center">
        <p class="text-gray-600 dark:text-gray-400">Loading repositories...</p>
      </div>
    </div>
  {:else if error}
    <ErrorMessage type="error" message={error} />
  {:else if repositories.length === 0}
    <Card padding="lg" class="text-center">
      <div class="text-6xl mb-4">📦</div>
      <h3 class="text-xl font-semibold text-gray-900 dark:text-gray-100 mb-2">No Repositories Found</h3>
      <p class="text-gray-600 dark:text-gray-400 mb-6">
        No repositories are connected to this installation yet.
      </p>
    </Card>
  {:else}
    <!-- Repository Listings -->
    <div class="space-y-6">
      {#each repositories as repository}
        {@const repoName = repository.name}
        {@const workspaces = repoWorkspaces[repoName] || []}
        {@const isLoading = loadingRepos.has(repoName)}
        {@const hasError = repoErrors[repoName]}
        
        <Card padding="none" class="overflow-hidden">
          <!-- Repository Header -->
          <button
            on:click={() => toggleRepoCollapse(repoName)}
            class="w-full px-6 py-4 bg-gray-50 dark:bg-gray-700 border-b border-gray-200 dark:border-gray-600 flex items-center justify-between hover:bg-gray-100 dark:hover:bg-gray-600 transition-colors"
          >
            <div class="flex items-center space-x-3">
              <div class="text-lg">
                {collapsedRepos.has(repoName) ? '▶️' : '🔽'}
              </div>
              <div class="text-left">
                <h3 class="text-lg font-semibold text-brand-primary">{repoName}</h3>
                <p class="text-sm text-gray-600 dark:text-gray-400">
                  {#if loadedRepos.has(repoName)}
                    {workspaces.length} workspace{workspaces.length !== 1 ? 's' : ''}
                  {:else if isLoading}
                    Loading...
                  {:else}
                    Click to load workspaces
                  {/if}
                </p>
              </div>
            </div>
            <div class="flex items-center space-x-2">
              {#if isLoading}
                <LoadingSpinner size="sm" />
              {:else if loadedRepos.has(repoName) && workspaces.length > 0}
                <!-- Status summary for this repo -->
                <span class="text-xs px-2 py-1 bg-green-100 dark:bg-green-900/30 text-green-800 dark:text-green-400 rounded-full">
                  {workspaces.filter(ws => ws.state === 'success').length} ✅
                </span>
                <span class="text-xs px-2 py-1 bg-red-100 dark:bg-red-900/30 text-red-800 dark:text-red-400 rounded-full">
                  {workspaces.filter(ws => ws.state === 'failure').length} ❌
                </span>
              {/if}
            </div>
          </button>
          
          <!-- Workspace List -->
          {#if !collapsedRepos.has(repoName)}
            {#if hasError}
              <div class="p-4 bg-red-50 dark:bg-red-900/20">
                <ErrorMessage type="error" message={`Failed to load workspaces: ${hasError}`} />
              </div>
            {:else if isLoading}
              <div class="p-8 text-center">
                <LoadingSpinner size="md" />
                <p class="text-sm text-gray-600 dark:text-gray-400 mt-2">Loading workspaces...</p>
              </div>
            {:else if !loadedRepos.has(repoName)}
              <div class="p-8 text-center text-gray-500 dark:text-gray-400">
                <p class="text-sm">Click the repository header to load workspaces</p>
              </div>
            {:else if workspaces.length === 0}
              <div class="p-8 text-center text-gray-500 dark:text-gray-400">
                <p>No workspaces found for this repository</p>
              </div>
            {:else}
              <div class="divide-y divide-gray-200 dark:divide-gray-600">
                {#each workspaces as workspace}
                <button
                  on:click={() => navigateToWorkspace(workspace.repo, workspace.dir, workspace.workspace)}
                  class="w-full p-6 text-left hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors cursor-pointer"
                >
                  <div class="flex items-start justify-between">
                    <div class="flex-1">
                      <div class="flex items-center space-x-3 mb-2">
                        <h4 class="text-lg font-medium text-gray-900 dark:text-gray-100 hover:text-blue-600 dark:hover:text-blue-400 transition-colors">
                          📁 {workspace.dir}
                        </h4>
                        <span class="text-sm px-2 py-1 bg-blue-100 dark:bg-blue-900/30 text-blue-800 dark:text-blue-400 rounded-full font-mono">
                          {workspace.workspace}
                        </span>
                        <span class={`text-xs px-2 py-1 rounded-full font-medium ${getStateColor(workspace.state)}`}>
                          {getStateIcon(workspace.state)} {workspace.state}
                        </span>
                        <svg class="w-4 h-4 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
                        </svg>
                      </div>
                      
                      <div class="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm text-gray-600 dark:text-gray-400">
                        <div>
                          <span class="font-medium">Environment:</span>
                          <span class="ml-1">{workspace.environment || 'default'}</span>
                        </div>
                        <div>
                          <span class="font-medium">Last Run:</span>
                          <span class="ml-1">{getRunTypeLabel(workspace.run_type)}</span>
                        </div>
                        <div>
                          <span class="font-medium">Updated:</span>
                          <span class="ml-1">{formatDate(workspace.created_at)}</span>
                        </div>
                      </div>
                      
                      {#if workspace.user}
                        <div class="mt-2 text-sm text-gray-600 dark:text-gray-400">
                          <span class="font-medium">Last User:</span>
                          <span class="ml-1">{workspace.user}</span>
                        </div>
                      {/if}
                      
                      {#if workspace.branch && workspace.branch !== workspace.base_branch}
                        <div class="mt-2 text-sm text-gray-600 dark:text-gray-400">
                          <span class="font-medium">Branch:</span>
                          <span class="ml-1 font-mono">{workspace.branch}</span>
                          <span class="mx-2">→</span>
                          <span class="font-mono">{workspace.base_branch}</span>
                        </div>
                      {/if}
                    </div>
                    
                    <div class="flex items-center space-x-2">
                      <span class="text-sm text-gray-500 dark:text-gray-400">Click for details →</span>
                    </div>
                  </div>
                </button>
                {/each}
              </div>
              
            {/if}
          {/if}
        </Card>
      {/each}
    </div>
  {/if}
</PageLayout>
