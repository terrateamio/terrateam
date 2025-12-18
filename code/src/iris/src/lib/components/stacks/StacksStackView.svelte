<script lang="ts">
  import StackWithPRsCard from './StackWithPRsCard.svelte';
  import type { StackWithPRs, StackState } from '../../types';

  // Props
  export let stacksWithPRs: StackWithPRs[];
  export let isLoading: boolean;
  export let error: string | null;
  export let loadErrors: Array<{ prNumber: number; error: string }>;
  export let searchQuery: string;
  export let timeRange: number;
  export let onRefresh: () => void;

  // Local state
  export let stateFilter: StackState | '' = '';
  let sortBy: 'state' | 'activity' | 'name' | 'prs' = 'state';
  let filteredStacks: StackWithPRs[] = [];

  /**
   * Applies current filters and sorting
   */
  function applyFiltersAndSort(): void {
    let filtered = [...stacksWithPRs];

    // Filter by stack state
    if (stateFilter) {
      const filterState = stateFilter as StackState;
      filtered = filtered.filter(stack => stack.aggregateState === filterState);
    }

    // Filter by search query (stack name, dir, workspace, PR titles)
    if (searchQuery.trim()) {
      const query = searchQuery.toLowerCase().trim();
      filtered = filtered.filter(stack => {
        // Search in stack name
        if (stack.stackName.toLowerCase().includes(query)) {
          return true;
        }

        // Search in dirspaces
        for (const ds of stack.dirspaces) {
          const dir = ds.dir.toLowerCase();
          const workspace = ds.workspace.toLowerCase();
          if (dir.includes(query) || workspace.includes(query)) {
            return true;
          }
        }

        // Search in PR titles
        for (const pr of stack.prs) {
          if (pr.prTitle && pr.prTitle.toLowerCase().includes(query)) {
            return true;
          }
          // Search in PR number
          if (pr.prNumber.toString().includes(query)) {
            return true;
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
      case 'name':
        // Sort by stack name
        filtered.sort((a, b) => a.stackName.localeCompare(b.stackName));
        break;
      case 'prs':
        // Sort by number of PRs (most PRs first)
        filtered.sort((a, b) => b.totalPRs - a.totalPRs);
        break;
    }

    filteredStacks = filtered;
  }

  /**
   * Gets severity score for stack state
   */
  function getStateSeverity(state: StackState): number {
    const severityMap: Record<StackState, number> = {
      apply_failed: 7,
      plan_failed: 6,
      apply_pending: 5,
      plan_pending: 4,
      apply_ready: 3,
      apply_success: 2,
      no_changes: 1,
    };
    return severityMap[state] || 0;
  }

  /**
   * Resets view-specific filters (not search which is shared)
   */
  function resetFilters(): void {
    stateFilter = '';
    applyFiltersAndSort();
  }

  /**
   * Sets state filter
   */
  function setStateFilter(state: StackState | ''): void {
    stateFilter = state;
    applyFiltersAndSort();
  }

  /**
   * Computes state counts across all stacks
   */
  function computeStateCounts(stacks: StackWithPRs[]): Record<StackState, number> {
    const counts: Record<StackState, number> = {
      apply_success: 0,
      apply_failed: 0,
      apply_pending: 0,
      apply_ready: 0,
      plan_pending: 0,
      plan_failed: 0,
      no_changes: 0,
    };

    for (const stack of stacks) {
      counts[stack.aggregateState]++;
    }

    return counts;
  }

  // Reactive statements
  $: if (stacksWithPRs || searchQuery !== undefined || stateFilter !== undefined || sortBy !== undefined) {
    applyFiltersAndSort();
  }

  $: stateCounts = computeStateCounts(filteredStacks);
  $: hasActiveFilters = stateFilter !== '';
</script>

<!-- State filter buttons -->
<div class="flex items-center gap-2 flex-wrap">
  <span class="text-sm font-medium text-gray-700 dark:text-gray-300">Quick Filters:</span>
  <button
    on:click={() => setStateFilter('')}
    class="px-3 py-1 rounded-md text-sm font-medium transition-colors {stateFilter === ''
      ? 'bg-blue-600 text-white'
      : 'bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600'}"
    aria-label="Show all stacks"
    aria-pressed={stateFilter === ''}
  >
    All ({filteredStacks.length})
  </button>
  <button
    on:click={() => setStateFilter('apply_failed')}
    class="px-3 py-1 rounded-md text-sm font-medium transition-colors {stateFilter === 'apply_failed'
      ? 'bg-red-600 text-white'
      : 'bg-red-100 dark:bg-red-900/30 text-red-800 dark:text-red-400 hover:bg-red-200 dark:hover:bg-red-900/50'}"
    aria-label="Show stacks with apply failures"
    aria-pressed={stateFilter === 'apply_failed'}
  >
    ❌ Apply Failed ({stateCounts.apply_failed})
  </button>
  <button
    on:click={() => setStateFilter('plan_failed')}
    class="px-3 py-1 rounded-md text-sm font-medium transition-colors {stateFilter === 'plan_failed'
      ? 'bg-orange-600 text-white'
      : 'bg-orange-100 dark:bg-orange-900/30 text-orange-800 dark:text-orange-400 hover:bg-orange-200 dark:hover:bg-orange-900/50'}"
    aria-label="Show stacks with plan failures"
    aria-pressed={stateFilter === 'plan_failed'}
  >
    ⚠️ Plan Failed ({stateCounts.plan_failed})
  </button>
  <button
    on:click={() => setStateFilter('apply_pending')}
    class="px-3 py-1 rounded-md text-sm font-medium transition-colors {stateFilter === 'apply_pending'
      ? 'bg-purple-600 text-white'
      : 'bg-purple-100 dark:bg-purple-900/30 text-purple-800 dark:text-purple-400 hover:bg-purple-200 dark:hover:bg-purple-900/50'}"
    aria-label="Show stacks with apply pending"
    aria-pressed={stateFilter === 'apply_pending'}
  >
    ⏳ Apply Pending ({stateCounts.apply_pending})
  </button>
  <button
    on:click={() => setStateFilter('plan_pending')}
    class="px-3 py-1 rounded-md text-sm font-medium transition-colors {stateFilter === 'plan_pending'
      ? 'bg-pink-600 text-white'
      : 'bg-pink-100 dark:bg-pink-900/30 text-pink-800 dark:text-pink-400 hover:bg-pink-200 dark:hover:bg-pink-900/50'}"
    aria-label="Show stacks with plan pending"
    aria-pressed={stateFilter === 'plan_pending'}
  >
    📋 Plan Pending ({stateCounts.plan_pending})
  </button>
  <button
    on:click={() => setStateFilter('apply_ready')}
    class="px-3 py-1 rounded-md text-sm font-medium transition-colors {stateFilter === 'apply_ready'
      ? 'bg-blue-600 text-white'
      : 'bg-blue-100 dark:bg-blue-900/30 text-blue-800 dark:text-blue-400 hover:bg-blue-200 dark:hover:bg-blue-900/50'}"
    aria-label="Show stacks ready to apply"
    aria-pressed={stateFilter === 'apply_ready'}
  >
    ✓ Ready ({stateCounts.apply_ready})
  </button>
  <button
    on:click={() => setStateFilter('apply_success')}
    class="px-3 py-1 rounded-md text-sm font-medium transition-colors {stateFilter === 'apply_success'
      ? 'bg-green-600 text-white'
      : 'bg-green-100 dark:bg-green-900/30 text-green-800 dark:text-green-400 hover:bg-green-200 dark:hover:bg-green-900/50'}"
    aria-label="Show successful stacks"
    aria-pressed={stateFilter === 'apply_success'}
  >
    ✅ Success ({stateCounts.apply_success})
  </button>
  <button
    on:click={() => setStateFilter('no_changes')}
    class="px-3 py-1 rounded-md text-sm font-medium transition-colors {stateFilter === 'no_changes'
      ? 'bg-gray-600 text-white'
      : 'bg-gray-100 dark:bg-gray-700 text-gray-800 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600'}"
    aria-label="Show stacks with no changes"
    aria-pressed={stateFilter === 'no_changes'}
  >
    ○ No Changes ({stateCounts.no_changes})
  </button>
  {#if hasActiveFilters}
    <button
      on:click={resetFilters}
      class="px-3 py-1 rounded-md text-sm font-medium bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600 transition-colors"
    >
      Reset Quick Filters
    </button>
  {/if}
</div>

<!-- Loading state -->
{#if isLoading}
  <div class="flex items-center justify-center py-12">
    <div
      class="animate-spin rounded-full h-12 w-12 border-b-2 border-brand-primary"
      role="status"
      aria-label="Loading stacks"
    >
      <span class="sr-only">Loading stacks...</span>
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
          Error loading stacks
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
          Showing {filteredStacks.length} {filteredStacks.length === 1 ? 'stack' : 'stacks'} that loaded successfully.
        </div>
      </div>
    </div>
  </div>
{/if}

<!-- Stacks grid -->
{#if !isLoading && !error}
  {#if filteredStacks.length > 0}
    <div class="space-y-4">
      {#each filteredStacks as stackWithPRs}
        <StackWithPRsCard {stackWithPRs} />
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
          d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"
        />
      </svg>
      <h3 class="mt-2 text-sm font-semibold text-gray-900 dark:text-gray-100">No stacks found</h3>
      <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
        {#if hasActiveFilters || searchQuery}
          No stacks match your current filters. Try adjusting or resetting your filters.
        {:else}
          No stacks in the last {timeRange} days.
        {/if}
      </p>
    </div>
  {/if}
{/if}
