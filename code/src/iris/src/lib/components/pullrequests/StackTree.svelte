<script lang="ts">
  import type { Stacks, StackOuter, StackInner, StackState } from '../../types';
  import StackNode from './StackNode.svelte';

  export let stacks: Stacks | null = null;
  export let loading: boolean = false;
  export let error: string | null = null;

  let allExpanded: boolean = true;
  let showWorkspaces: boolean = false;
  let searchQuery: string = '';

  // Check if stacks have been loaded (not null) and have data
  $: hasStacks = stacks && stacks.stacks && stacks.stacks.length > 0;

  // Check if stacks have been loaded (API call completed)
  // null = not loaded yet, { stacks: [] } = loaded but empty
  $: stacksLoaded = stacks !== null;

  $: filteredStacks = filterStacks(stacks, searchQuery);

  // Compute state counts for dashboard
  $: stateCounts = computeStateCounts(stacks);

  function computeStateCounts(stacks: Stacks | null): Record<StackState, number> {
    const counts: Record<StackState, number> = {
      'apply_success': 0,
      'apply_failed': 0,
      'apply_pending': 0,
      'apply_ready': 0,
      'no_changes': 0,
      'plan_failed': 0,
      'plan_pending': 0,
    };

    if (!stacks || !stacks.stacks) {
      return counts;
    }

    // Collect all leaf stacks (StackInner) to count their states
    function collectInnerStacks(stack: StackOuter | StackInner): StackInner[] {
      if ('dirspaces' in stack) {
        // This is a StackInner leaf node
        return [stack as StackInner];
      } else if ('stacks' in stack) {
        // This is a StackOuter parent - recurse into children
        const outer = stack as StackOuter;
        return outer.stacks.flatMap(child => collectInnerStacks(child));
      }
      return [];
    }

    const allInnerStacks = stacks.stacks.flatMap(stack => collectInnerStacks(stack));

    // Count states from leaf stacks only
    allInnerStacks.forEach(stack => {
      counts[stack.state]++;
    });

    return counts;
  }

  function toggleExpandAll() {
    allExpanded = !allExpanded;
  }

  function filterStacks(stacks: Stacks | null, query: string): Stacks | null {
    if (!stacks || !stacks.stacks) {
      return stacks;
    }

    const lowerQuery = query.toLowerCase().trim();

    // If no search query, return original
    if (!lowerQuery) {
      return stacks;
    }

    // Recursively filter stacks
    function filterStack(stack: StackOuter | StackInner): StackOuter | StackInner | null {
      const matchesQuery = stack.name.toLowerCase().includes(lowerQuery);

      if ('dirspaces' in stack) {
        // StackInner - leaf node
        return matchesQuery ? stack : null;
      } else if ('stacks' in stack) {
        // StackOuter - parent node

        // If parent matches query, show ALL children (don't filter them)
        if (matchesQuery) {
          return stack;
        }

        // Otherwise, filter children and include parent if any children match
        const filteredChildren = stack.stacks
          .map(child => filterStack(child))
          .filter((child): child is StackInner => child !== null);

        if (filteredChildren.length > 0) {
          return {
            ...stack,
            stacks: filteredChildren
          };
        }
      }

      return null;
    }

    const filteredStackList = stacks.stacks
      .map(stack => filterStack(stack))
      .filter((stack): stack is StackOuter => stack !== null);

    return {
      stacks: filteredStackList
    };
  }
</script>

{#if loading || !stacksLoaded}
  <!-- Show loading spinner while loading OR if stacks haven't been loaded yet (null) -->
  <div class="flex items-center justify-center py-12">
    <div
      class="animate-spin rounded-full h-12 w-12 border-b-2 border-brand-primary"
      role="status"
      aria-label="Loading stacks"
    >
      <span class="sr-only">Loading stacks...</span>
    </div>
  </div>
{:else if error}
  <div
    class="rounded-md bg-red-50 dark:bg-red-900/20 p-4 border border-red-200 dark:border-red-800"
    role="alert"
  >
    <div class="flex">
      <div class="flex-shrink-0">
        <svg
          class="h-5 w-5 text-red-400"
          fill="currentColor"
          viewBox="0 0 20 20"
        >
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
      </div>
    </div>
  </div>
{:else if hasStacks}
  <!-- Status Dashboard -->
  <div class="mb-4 bg-gray-50 dark:bg-gray-800 rounded-lg p-4 border border-gray-200 dark:border-gray-700">
    <h3 class="text-sm font-medium text-gray-700 dark:text-gray-300 mb-3">Stack Status Summary</h3>
    <div class="flex flex-col gap-2">
      <div class="flex items-center gap-2">
        <div class="w-3 h-3 rounded-full bg-green-500"></div>
        <span class="text-sm text-gray-900 dark:text-gray-100">
          <span class="font-semibold">{stateCounts.apply_success}</span> Apply success
        </span>
      </div>
      <div class="flex items-center gap-2">
        <div class="w-3 h-3 rounded-full bg-red-500"></div>
        <span class="text-sm text-gray-900 dark:text-gray-100">
          <span class="font-semibold">{stateCounts.apply_failed}</span> Apply failed
        </span>
      </div>
      <div class="flex items-center gap-2">
        <div class="w-3 h-3 rounded-full bg-blue-500"></div>
        <span class="text-sm text-gray-900 dark:text-gray-100">
          <span class="font-semibold">{stateCounts.apply_ready}</span> Apply ready
        </span>
      </div>
      <div class="flex items-center gap-2">
        <div class="w-3 h-3 rounded-full bg-purple-500"></div>
        <span class="text-sm text-gray-900 dark:text-gray-100">
          <span class="font-semibold">{stateCounts.apply_pending}</span> Apply pending
        </span>
      </div>
      <div class="flex items-center gap-2">
        <div class="w-3 h-3 rounded-full bg-pink-500"></div>
        <span class="text-sm text-gray-900 dark:text-gray-100">
          <span class="font-semibold">{stateCounts.plan_pending}</span> Plan pending
        </span>
      </div>
      <div class="flex items-center gap-2">
        <div class="w-3 h-3 rounded-full bg-orange-500"></div>
        <span class="text-sm text-gray-900 dark:text-gray-100">
          <span class="font-semibold">{stateCounts.plan_failed}</span> Plan failed
        </span>
      </div>
      <div class="flex items-center gap-2">
        <div class="w-3 h-3 rounded-full bg-gray-400"></div>
        <span class="text-sm text-gray-900 dark:text-gray-100">
          <span class="font-semibold">{stateCounts.no_changes}</span> No changes
        </span>
      </div>
    </div>
  </div>

  <!-- Search Bar -->
  <div class="mb-4">
    <div class="relative">
      <input
        type="text"
        bind:value={searchQuery}
        placeholder="Search stacks by name..."
        class="w-full px-4 py-2 pl-10 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 placeholder-gray-500 dark:placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-brand-primary focus:border-transparent"
      />
      <svg
        class="absolute left-3 top-2.5 h-5 w-5 text-gray-400"
        fill="none"
        stroke="currentColor"
        viewBox="0 0 24 24"
      >
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          stroke-width="2"
          d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
        />
      </svg>
    </div>
  </div>

  <!-- Controls bar -->
  <div class="mb-4 flex items-center gap-4 pb-4 border-b border-gray-200 dark:border-gray-700">
    <button
      on:click={toggleExpandAll}
      class="inline-flex items-center px-3 py-2 border border-gray-300 dark:border-gray-600 shadow-sm text-sm font-medium rounded-md text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-brand-primary transition-colors"
      aria-label="{allExpanded ? 'Collapse' : 'Expand'} all stacks"
    >
      <svg
        class="w-4 h-4 mr-2 transition-transform {allExpanded ? 'rotate-90' : ''}"
        fill="none"
        stroke="currentColor"
        viewBox="0 0 24 24"
      >
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          stroke-width="2"
          d="M9 5l7 7-7 7"
        />
      </svg>
      {allExpanded ? 'Collapse All' : 'Expand All'}
    </button>

    <label class="inline-flex items-center cursor-pointer">
      <input
        type="checkbox"
        bind:checked={showWorkspaces}
        class="h-4 w-4 rounded border-gray-300 dark:border-gray-600 text-brand-primary focus:ring-brand-primary focus:ring-offset-0 cursor-pointer"
      />
      <span class="ml-2 text-sm font-medium text-gray-700 dark:text-gray-300">
        Show Workspaces
      </span>
    </label>
  </div>

  <!-- Render stacks vertically layered -->
  {#if filteredStacks && filteredStacks.stacks && filteredStacks.stacks.length > 0}
    <div class="space-y-6" role="list" aria-label="Stack list">
      {#each filteredStacks.stacks as stack}
        <StackNode {stack} level={0} forceExpanded={allExpanded} {showWorkspaces} />
      {/each}
    </div>
  {:else if searchQuery}
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
          d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
        />
      </svg>
      <h3 class="mt-2 text-sm font-semibold text-gray-900 dark:text-gray-100">No matching stacks</h3>
      <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
        No stacks found matching "{searchQuery}".
      </p>
      <button
        on:click={() => searchQuery = ''}
        class="mt-4 px-4 py-2 text-sm font-medium text-brand-primary hover:text-brand-primary/80 transition-colors"
      >
        Clear search
      </button>
    </div>
  {/if}
{:else}
  <!-- Empty state: no stacks configured -->
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
        d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
      />
    </svg>
    <h3 class="mt-2 text-sm font-semibold text-gray-900 dark:text-gray-100">No stacks found</h3>
    <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
      This pull request doesn't have any stacks configured yet.
    </p>
  </div>
{/if}
