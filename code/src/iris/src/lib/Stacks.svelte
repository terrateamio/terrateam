<script lang="ts">
  import PageLayout from './components/layout/PageLayout.svelte';
  import StacksPRsView from './components/stacks/StacksPRsView.svelte';
  import StacksRepositoryView from './components/stacks/StacksRepositoryView.svelte';
  import StacksDashboardView from './components/stacks/StacksDashboardView.svelte';
  import StacksTimelineView from './components/stacks/StacksTimelineView.svelte';
  import type { StackWithRuns, PRWithStacks, RepositoryWithStacks, DashboardMetrics, Dirspace, TimelineEvent } from './types';
  import { loadRecentStacksData, groupStacksByPR, groupStacksByRepositoryAndStack, computeDashboardMetrics, generateTimelineData } from './utils/stacksDataLoader';
  import { selectedInstallation } from './stores';
  import { onMount } from 'svelte';

  // Route params (provided by router, may be unused)
  export let params: { installationId?: string } = {};

  // Tab management
  type StacksTab = 'prs' | 'repos' | 'dashboard' | 'timeline';
  let activeTab: StacksTab = 'dashboard';

  // Parse URL hash for initial tab
  const urlParams = new URLSearchParams(window.location.hash.split('?')[1] || '');
  const tabParam = urlParams.get('tab');
  if (tabParam === 'prs' || tabParam === 'repos' || tabParam === 'dashboard' || tabParam === 'timeline') {
    activeTab = tabParam;
  }

  // Update URL when tab changes
  function setActiveTab(tab: StacksTab): void {
    activeTab = tab;
    const currentHash = window.location.hash.split('?')[0];
    const newUrl = `${currentHash}?tab=${tab}`;
    window.history.replaceState({}, '', newUrl);
  }

  // Data state (loaded once, transformed for different views)
  let stacksWithRuns: StackWithRuns[] = [];
  let prsWithStacks: PRWithStacks[] = [];
  let repositoriesWithStacks: RepositoryWithStacks[] = [];
  let dirspaces: Dirspace[] = [];
  let dashboardMetrics: DashboardMetrics | null = null;
  let timelineEvents: TimelineEvent[] = [];
  let isLoading: boolean = true;
  let error: string | null = null;
  let loadErrors: Array<{ prNumber: number; error: string }> = [];

  // Shared filter state (affects all views)
  let searchQuery: string = '';
  let repoFilter: string = '';
  let timeRange: number = 7; // days

  // UI state
  let uniqueRepos: string[] = [];

  /**
   * Loads stacks data from API
   */
  async function loadStacks(): Promise<void> {
    if (!$selectedInstallation) {
      error = 'No installation selected';
      isLoading = false;
      return;
    }

    isLoading = true;
    error = null;
    loadErrors = [];

    try {
      const result = await loadRecentStacksData($selectedInstallation.id, timeRange);

      stacksWithRuns = result.stacksWithRuns;
      dirspaces = result.dirspaces;
      loadErrors = result.errors;

      // Group stacks by PR (for PRs view)
      prsWithStacks = groupStacksByPR(stacksWithRuns);

      // Group stacks by repository, then by stack (for combined Repositories + Stacks view)
      repositoriesWithStacks = groupStacksByRepositoryAndStack(stacksWithRuns);

      // Compute dashboard metrics (for Dashboard view)
      dashboardMetrics = computeDashboardMetrics(stacksWithRuns, prsWithStacks, dirspaces, timeRange);

      // Generate timeline events (for Timeline view)
      timelineEvents = generateTimelineData(dirspaces, stacksWithRuns);

      // Extract unique repositories for filter dropdown
      uniqueRepos = [...new Set(prsWithStacks.map(pr => pr.repo))].sort();
    } catch (err) {
      error = err instanceof Error ? err.message : 'Failed to load stacks';
      console.error('Error loading stacks:', err);
    } finally {
      isLoading = false;
    }
  }

  /**
   * Changes time range and reloads
   */
  function changeTimeRange(days: number): void {
    timeRange = days;
    loadStacks();
  }

  /**
   * Resets shared filters
   */
  function resetFilters(): void {
    searchQuery = '';
    repoFilter = '';
  }

  // Reactive: Load stacks when installation changes
  $: if ($selectedInstallation) {
    loadStacks();
  }

  // Load on mount
  onMount(() => {
    loadStacks();
  });
</script>

<PageLayout activeItem="stacks" title="Stacks" subtitle="Infrastructure stacks across active pull requests">
  <div class="space-y-4">
    <!-- Shared Filters & Controls -->
    <div class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4">
      <!-- Top row: Time range and Refresh -->
      <div class="flex items-center gap-3 mb-3">
        <span class="text-sm font-medium text-gray-700 dark:text-gray-300">Time:</span>
        <div class="inline-flex rounded-md shadow-sm" role="group">
          <button
            on:click={() => changeTimeRange(7)}
            class="px-3 py-1.5 text-sm font-medium rounded-l-md border {timeRange === 7
              ? 'bg-blue-600 text-white border-blue-600'
              : 'bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-300 border-gray-300 dark:border-gray-600 hover:bg-gray-50 dark:hover:bg-gray-700'}"
            aria-label="Last 7 days"
            aria-pressed={timeRange === 7}
          >
            7d
          </button>
          <button
            on:click={() => changeTimeRange(14)}
            class="px-3 py-1.5 text-sm font-medium border-t border-b {timeRange === 14
              ? 'bg-blue-600 text-white border-blue-600'
              : 'bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-300 border-gray-300 dark:border-gray-600 hover:bg-gray-50 dark:hover:bg-gray-700'}"
            aria-label="Last 14 days"
            aria-pressed={timeRange === 14}
          >
            14d
          </button>
          <button
            on:click={() => changeTimeRange(30)}
            class="px-3 py-1.5 text-sm font-medium rounded-r-md border {timeRange === 30
              ? 'bg-blue-600 text-white border-blue-600'
              : 'bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-300 border-gray-300 dark:border-gray-600 hover:bg-gray-50 dark:hover:bg-gray-700'}"
            aria-label="Last 30 days"
            aria-pressed={timeRange === 30}
          >
            30d
          </button>
        </div>
        <button
          on:click={loadStacks}
          class="ml-auto inline-flex items-center px-3 py-1.5 border border-gray-300 dark:border-gray-600 shadow-sm text-sm font-medium rounded-md text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
          disabled={isLoading}
          aria-label="Refresh stacks"
        >
          <svg class="w-4 h-4 mr-1.5 {isLoading ? 'animate-spin' : ''}" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
          </svg>
          Refresh
        </button>
      </div>

      <!-- Filters row -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
        <!-- Search -->
        <div>
          <label for="search" class="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-1">
            Search
          </label>
          <input
            id="search"
            type="text"
            bind:value={searchQuery}
            placeholder="PR title, number, or stack..."
            class="w-full px-3 py-1.5 text-sm border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 placeholder-gray-500 dark:placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          />
        </div>

        <!-- Repository filter -->
        <div>
          <label for="repo-filter" class="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-1">
            Repository
          </label>
          <select
            id="repo-filter"
            bind:value={repoFilter}
            class="w-full px-3 py-1.5 text-sm border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          >
            <option value="">All repositories</option>
            {#each uniqueRepos as repo}
              <option value={repo}>{repo}</option>
            {/each}
          </select>
        </div>
      </div>

      <!-- Reset button -->
      {#if searchQuery || repoFilter}
        <div class="mt-3">
          <button
            on:click={resetFilters}
            class="text-sm text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 font-medium transition-colors"
          >
            Reset Filters
          </button>
        </div>
      {/if}
    </div>

    <!-- Tab Navigation -->
    <div class="border-b border-gray-200 dark:border-gray-700">
      <nav class="-mb-px flex space-x-8" aria-label="Tabs" role="tablist">
        <button
          on:click={() => setActiveTab('dashboard')}
          class="py-2 px-1 border-b-2 font-medium text-sm transition-colors duration-200 {activeTab === 'dashboard'
            ? 'border-blue-500 text-blue-600 dark:text-blue-400'
            : 'border-transparent text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300 hover:border-gray-300'}"
          role="tab"
          aria-selected={activeTab === 'dashboard'}
          aria-controls="dashboard-panel"
        >
          Dashboard
        </button>
        <button
          on:click={() => setActiveTab('prs')}
          class="py-2 px-1 border-b-2 font-medium text-sm transition-colors duration-200 {activeTab === 'prs'
            ? 'border-blue-500 text-blue-600 dark:text-blue-400'
            : 'border-transparent text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300 hover:border-gray-300'}"
          role="tab"
          aria-selected={activeTab === 'prs'}
          aria-controls="prs-panel"
        >
          Pull Requests
        </button>
        <button
          on:click={() => setActiveTab('repos')}
          class="py-2 px-1 border-b-2 font-medium text-sm transition-colors duration-200 {activeTab === 'repos'
            ? 'border-blue-500 text-blue-600 dark:text-blue-400'
            : 'border-transparent text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300 hover:border-gray-300'}"
          role="tab"
          aria-selected={activeTab === 'repos'}
          aria-controls="repos-panel"
        >
          Repositories
        </button>
        <button
          on:click={() => setActiveTab('timeline')}
          class="py-2 px-1 border-b-2 font-medium text-sm transition-colors duration-200 {activeTab === 'timeline'
            ? 'border-blue-500 text-blue-600 dark:text-blue-400'
            : 'border-transparent text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300 hover:border-gray-300'}"
          role="tab"
          aria-selected={activeTab === 'timeline'}
          aria-controls="timeline-panel"
        >
          Timeline
        </button>
      </nav>
    </div>

    <!-- Tab Panels -->
    <div class="space-y-4">
      {#if activeTab === 'dashboard'}
        <div role="tabpanel" id="dashboard-panel" aria-labelledby="dashboard-tab">
          {#if dashboardMetrics}
            <StacksDashboardView
              metrics={dashboardMetrics}
              {isLoading}
              {error}
              onNavigateToPRs={() => setActiveTab('prs')}
            />
          {:else if isLoading}
            <div class="text-center py-12">
              <div
                class="animate-spin rounded-full h-12 w-12 border-b-2 border-brand-primary mx-auto mb-4"
                role="status"
                aria-label="Loading dashboard"
              >
                <span class="sr-only">Loading dashboard...</span>
              </div>
              <p class="text-gray-500 dark:text-gray-400">Loading dashboard data...</p>
            </div>
          {:else if error}
            <div class="rounded-md bg-red-50 dark:bg-red-900/20 p-4 border border-red-200 dark:border-red-800" role="alert">
              <div class="flex">
                <div class="ml-3">
                  <h3 class="text-sm font-medium text-red-800 dark:text-red-400">Error loading dashboard</h3>
                  <div class="mt-2 text-sm text-red-700 dark:text-red-300">{error}</div>
                </div>
              </div>
            </div>
          {:else}
            <div class="text-center py-12">
              <p class="text-gray-500 dark:text-gray-400">No dashboard data available</p>
            </div>
          {/if}
        </div>
      {:else if activeTab === 'prs'}
        <div role="tabpanel" id="prs-panel" aria-labelledby="prs-tab">
          <StacksPRsView
            {prsWithStacks}
            {isLoading}
            {error}
            {loadErrors}
            {searchQuery}
            {repoFilter}
            {uniqueRepos}
            {timeRange}
            onRefresh={loadStacks}
          />
        </div>
      {:else if activeTab === 'repos'}
        <div role="tabpanel" id="repos-panel" aria-labelledby="repos-tab">
          <StacksRepositoryView
            {repositoriesWithStacks}
            {isLoading}
            {error}
            {loadErrors}
            {searchQuery}
            {timeRange}
            onRefresh={loadStacks}
          />
        </div>
      {:else if activeTab === 'timeline'}
        <div role="tabpanel" id="timeline-panel" aria-labelledby="timeline-tab">
          <StacksTimelineView
            {timelineEvents}
            {isLoading}
            {error}
            {searchQuery}
            {timeRange}
            onRefresh={loadStacks}
          />
        </div>
      {/if}
    </div>
  </div>
</PageLayout>
