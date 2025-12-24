<script lang="ts">
  import type { RepositoryWithStacks } from '../../types';

  // Props
  export let repositoriesWithStacks: RepositoryWithStacks[];
  export let isLoading: boolean;
  export let error: string | null;
  export let loadErrors: Array<{ prNumber: number; error: string }>;
  export let searchQuery: string;
  export let timeRange: number;
  export let onRefresh: () => void;

  // Local state
  let sortBy: 'state' | 'activity' | 'repo' | 'stacks' = 'state';
  let filteredRepos: RepositoryWithStacks[] = [];
  let expandedRepos: Set<string> = new Set();

  /**
   * Toggle repository expansion
   */
  function toggleRepo(repo: string): void {
    if (expandedRepos.has(repo)) {
      expandedRepos.delete(repo);
    } else {
      expandedRepos.add(repo);
    }
    expandedRepos = expandedRepos; // Trigger reactivity
  }

  /**
   * Applies current filters and sorting
   */
  function applyFiltersAndSort(): void {
    let filtered = [...repositoriesWithStacks];

    // Filter by search query (repo name, stack names, PR titles)
    if (searchQuery.trim()) {
      const query = searchQuery.toLowerCase().trim();
      filtered = filtered.filter(repo => {
        // Search in repo name
        if (repo.repo.toLowerCase().includes(query)) {
          return true;
        }

        // Search in stacks
        for (const stack of repo.stacks) {
          if (stack.stackName.toLowerCase().includes(query)) {
            return true;
          }

          // Search in PRs
          for (const pr of stack.prs) {
            if (pr.prTitle && pr.prTitle.toLowerCase().includes(query)) {
              return true;
            }
            if (pr.prNumber.toString().includes(query)) {
              return true;
            }
          }

          // Search in dirspaces
          for (const ds of stack.dirspaces) {
            if (ds.dir.toLowerCase().includes(query) || ds.workspace.toLowerCase().includes(query)) {
              return true;
            }
          }
        }

        return false;
      });
    }

    // Sort
    switch (sortBy) {
      case 'state':
        // Sort by state severity (failed first)
        filtered.sort((a, b) => {
          const severityA = getStateSeverity(a.aggregateState);
          const severityB = getStateSeverity(b.aggregateState);
          return severityB - severityA;
        });
        break;
      case 'activity':
        // Sort by last activity (most recent first)
        filtered.sort((a, b) => {
          const dateA = new Date(a.lastActivity).getTime();
          const dateB = new Date(b.lastActivity).getTime();
          return dateB - dateA;
        });
        break;
      case 'repo':
        // Sort by repository name
        filtered.sort((a, b) => a.repo.localeCompare(b.repo));
        break;
      case 'stacks':
        // Sort by number of stacks (most stacks first)
        filtered.sort((a, b) => b.totalStacks - a.totalStacks);
        break;
    }

    filteredRepos = filtered;
  }

  /**
   * Gets severity score for aggregate state
   */
  function getStateSeverity(state: string): number {
    const severityMap: Record<string, number> = {
      failed: 4,
      pending: 3,
      ready: 2,
      success: 1,
      no_changes: 0,
    };
    return severityMap[state] || 0;
  }

  /**
   * Gets badge classes for state
   */
  function getStateBadgeClasses(state: string): string {
    switch (state) {
      case 'success':
      case 'apply_success':
        return 'bg-green-100 dark:bg-green-900/30 text-green-800 dark:text-green-400';
      case 'failed':
      case 'apply_failed':
      case 'plan_failed':
        return 'bg-red-100 dark:bg-red-900/30 text-red-800 dark:text-red-400';
      case 'pending':
      case 'apply_pending':
      case 'plan_pending':
        return 'bg-purple-100 dark:bg-purple-900/30 text-purple-800 dark:text-purple-400';
      case 'ready':
      case 'apply_ready':
        return 'bg-blue-100 dark:bg-blue-900/30 text-blue-800 dark:text-blue-400';
      case 'no_changes':
        return 'bg-gray-100 dark:bg-gray-700 text-gray-800 dark:text-gray-300';
      default:
        return 'bg-gray-100 dark:bg-gray-700 text-gray-800 dark:text-gray-300';
    }
  }

  /**
   * Formats state name for display
   */
  function formatStateName(state: string): string {
    return state.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
  }

  // Reactive statements
  $: if (repositoriesWithStacks || searchQuery !== undefined || sortBy !== undefined) {
    applyFiltersAndSort();
  }
</script>

<!-- Loading state -->
{#if isLoading}
  <div class="flex items-center justify-center py-12">
    <div
      class="animate-spin rounded-full h-12 w-12 border-b-2 border-brand-primary"
      role="status"
      aria-label="Loading repositories"
    >
      <span class="sr-only">Loading repositories...</span>
    </div>
  </div>

<!-- Error state -->
{:else if error}
  <div
    class="rounded-md bg-red-50 dark:bg-red-900/20 p-4 border border-red-200 dark:border-red-800"
    role="alert"
  >
    <div class="flex">
      <div class="flex-shrink-0">
        <svg class="h-5 w-5 text-red-400" fill="currentColor" viewBox="0 0 20 20">
          <path
            fill-rule="evenodd"
            d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
            clip-rule="evenodd"
          />
        </svg>
      </div>
      <div class="ml-3">
        <h3 class="text-sm font-medium text-red-800 dark:text-red-400">
          Error loading repositories
        </h3>
        <div class="mt-2 text-sm text-red-700 dark:text-red-300">
          {error}
        </div>
        <button
          on:click={onRefresh}
          class="mt-3 text-sm font-medium text-red-800 dark:text-red-400 hover:text-red-900 dark:hover:text-red-300 underline"
        >
          Try again
        </button>
      </div>
    </div>
  </div>

<!-- Partial errors warning -->
{:else if loadErrors.length > 0}
  <div
    class="rounded-md bg-yellow-50 dark:bg-yellow-900/20 p-4 border border-yellow-200 dark:border-yellow-800"
    role="alert"
  >
    <div class="flex">
      <div class="flex-shrink-0">
        <svg class="h-5 w-5 text-yellow-400" fill="currentColor" viewBox="0 0 20 20">
          <path
            fill-rule="evenodd"
            d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z"
            clip-rule="evenodd"
          />
        </svg>
      </div>
      <div class="ml-3">
        <h3 class="text-sm font-medium text-yellow-800 dark:text-yellow-400">
          Some stacks could not be loaded
        </h3>
        <div class="mt-2 text-sm text-yellow-700 dark:text-yellow-300">
          Failed to load stacks for {loadErrors.length} PR{loadErrors.length > 1 ? 's' : ''}.
          Showing {filteredRepos.length} {filteredRepos.length === 1 ? 'repository' : 'repositories'} that loaded successfully.
        </div>
      </div>
    </div>
  </div>
{/if}

<!-- Repositories grid with stacks -->
{#if !isLoading && !error}
  {#if filteredRepos.length > 0}
    <div class="space-y-4">
      {#each filteredRepos as repo}
        <div class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 shadow-sm">
          <!-- Repository header (clickable to expand/collapse) -->
          <button
            on:click={() => toggleRepo(repo.repo)}
            class="w-full px-6 py-4 text-left hover:bg-gray-50 dark:hover:bg-gray-900/30 transition-colors rounded-t-lg"
          >
            <div class="flex items-start justify-between">
              <div class="flex-1 min-w-0">
                <div class="flex items-center gap-3 mb-2">
                  <span class="text-lg">
                    {expandedRepos.has(repo.repo) ? '▼' : '▶'}
                  </span>
                  <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100">
                    {repo.repo}
                  </h3>
                  <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium {getStateBadgeClasses(repo.aggregateState)}">
                    {formatStateName(repo.aggregateState)}
                  </span>
                </div>
                <div class="flex items-center gap-4 text-sm text-gray-600 dark:text-gray-400 ml-8">
                  <span>{repo.totalStacks} {repo.totalStacks === 1 ? 'stack' : 'stacks'}</span>
                  <span>•</span>
                  <span>{repo.totalPRs} {repo.totalPRs === 1 ? 'PR' : 'PRs'}</span>
                </div>
              </div>
            </div>
          </button>

          <!-- Stacks list (expanded) -->
          {#if expandedRepos.has(repo.repo)}
            <div class="border-t border-gray-200 dark:border-gray-700 p-4 space-y-2 bg-gray-50 dark:bg-gray-900/20">
              {#each repo.stacks as stack}
                <div class="p-3 rounded-md bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
                  <div class="flex items-center justify-between">
                    <div class="flex-1 min-w-0">
                      <div class="font-medium text-gray-900 dark:text-gray-100 mb-1">
                        {stack.stackName}
                      </div>
                      <div class="flex flex-wrap gap-1.5 text-xs">
                        {#each stack.dirspaces as ds}
                          <span class="font-mono bg-gray-100 dark:bg-gray-900/50 px-1.5 py-0.5 rounded text-gray-600 dark:text-gray-400">
                            {ds.dir}:{ds.workspace}
                          </span>
                        {/each}
                      </div>
                      {#if stack.prs.length > 0}
                        <div class="text-xs text-gray-500 dark:text-gray-500 mt-1">
                          PRs: {stack.prs.map(pr => `#${pr.prNumber}`).join(', ')}
                        </div>
                      {/if}
                    </div>
                    <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium {getStateBadgeClasses(stack.state)} ml-3">
                      {formatStateName(stack.state)}
                    </span>
                  </div>
                </div>
              {/each}
            </div>
          {/if}
        </div>
      {/each}
    </div>
  {:else}
    <!-- Empty state -->
    <div class="text-center py-12">
      <svg
        class="mx-auto h-12 w-12 text-gray-400"
        fill="none"
        stroke="currentColor"
        viewBox="0 0 24 24"
      >
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          stroke-width="2"
          d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z"
        />
      </svg>
      <h3 class="mt-2 text-sm font-semibold text-gray-900 dark:text-gray-100">No repositories found</h3>
      <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
        {#if searchQuery}
          No repositories match your search. Try adjusting your search query.
        {:else}
          No repositories with stacks in the last {timeRange} days.
        {/if}
      </p>
    </div>
  {/if}
{/if}
