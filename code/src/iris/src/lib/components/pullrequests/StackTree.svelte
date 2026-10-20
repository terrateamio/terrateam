<script lang="ts">
  import type { Stacks, StackOuter, StackInner, StackState } from '../../types';
  import StackNode from './StackNode.svelte';
  import { EmptyState, LoadingSpinner } from '../index';
  import { aggregateStacks } from '../../utils/stackAggregation';
  import { latestPlanQuery, runDirspacePath } from '../../utils/planLink';
  import { navigateToInstallationPath } from '../../utils/navigation';
  import { api } from '../../api';
  import { selectedInstallation } from '../../stores';

  export let stacks: Stacks | null = null;
  export let loading: boolean = false;
  export let error: string | null = null;
  // With both set, each workspace row opens its latest plan run.
  export let prNumber: number | null = null;
  export let repo: string | null = null;

  let allExpanded: boolean = true;
  let showWorkspaces: boolean = false;
  let searchQuery: string = '';

  // Aggregate stacks with the same name before rendering
  $: aggregatedStacks = aggregateStacks(stacks);

  // Check if stacks have been loaded (not null) and have data
  $: hasStacks = aggregatedStacks && aggregatedStacks.stacks && aggregatedStacks.stacks.length > 0;

  // Check if stacks have been loaded (API call completed)
  // null = not loaded yet, { stacks: [] } = loaded but empty
  $: stacksLoaded = stacks !== null;

  $: filteredStacks = filterStacks(aggregatedStacks, searchQuery);

  // Compute state counts for dashboard
  $: stateCounts = computeStateCounts(aggregatedStacks);

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

  // Resolves to false when the dirspace has no plan run on this pull request.
  async function openPlan(dir: string, workspace: string): Promise<boolean> {
    if (!$selectedInstallation || prNumber === null || !repo) return false;
    const response = await api.getInstallationDirspaces($selectedInstallation.id, {
      tz: Intl.DateTimeFormat().resolvedOptions().timeZone,
      q: latestPlanQuery(prNumber, repo, dir, workspace),
      limit: 1,
    });
    const run = response.dirspaces[0];
    if (!run) return false;
    navigateToInstallationPath(runDirspacePath(run.id, dir, workspace));
    return true;
  }

  $: planOpener = Number.isInteger(prNumber) && repo ? openPlan : null;

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
  <LoadingSpinner size="xl" />
{:else if error}
  <div
    class="rounded-md bg-[var(--sg-error-bg)] p-4 border border-[var(--sg-error)]"
    role="alert"
  >
    <div class="flex">
      <div class="flex-shrink-0">
        <svg
          class="h-5 w-5 text-[var(--sg-error)]"
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
        <h3 class="text-sm font-medium text-[var(--sg-error)]">
          Error loading stacks
        </h3>
        <div class="mt-2 text-sm text-[var(--sg-error)]">
          {error}
        </div>
      </div>
    </div>
  </div>
{:else if hasStacks}
  <!-- Status Dashboard -->
  <div class="mb-4 bg-[var(--sg-bg-0)] rounded-lg p-4 border border-[var(--sg-border)]">
    <h3 class="text-sm font-medium text-[var(--sg-text-muted)] mb-3">Stack Status Summary</h3>
    <div class="flex flex-col gap-2">
      <div class="flex items-center gap-2">
        <div class="w-3 h-3 rounded-full bg-[var(--sg-text-dim)]"></div>
        <span class="text-sm text-[var(--sg-text)]">
          <span class="font-semibold">{stateCounts.no_changes}</span> No changes
        </span>
      </div>
      <div class="flex items-center gap-2">
        <div class="w-3 h-3 rounded-full bg-[var(--sg-pink)]"></div>
        <span class="text-sm text-[var(--sg-text)]">
          <span class="font-semibold">{stateCounts.plan_pending}</span> Plan pending
        </span>
      </div>
      <div class="flex items-center gap-2">
        <div class="w-3 h-3 rounded-full bg-[var(--sg-orange)]"></div>
        <span class="text-sm text-[var(--sg-text)]">
          <span class="font-semibold">{stateCounts.plan_failed}</span> Plan failed
        </span>
      </div>
      <div class="flex items-center gap-2">
        <div class="w-3 h-3 rounded-full bg-[var(--sg-accent)]"></div>
        <span class="text-sm text-[var(--sg-text)]">
          <span class="font-semibold">{stateCounts.apply_ready}</span> Apply ready
        </span>
      </div>
      <div class="flex items-center gap-2">
        <div class="w-3 h-3 rounded-full bg-[var(--sg-purple)]"></div>
        <span class="text-sm text-[var(--sg-text)]">
          <span class="font-semibold">{stateCounts.apply_pending}</span> Apply pending
        </span>
      </div>
      <div class="flex items-center gap-2">
        <div class="w-3 h-3 rounded-full bg-[var(--sg-success)]"></div>
        <span class="text-sm text-[var(--sg-text)]">
          <span class="font-semibold">{stateCounts.apply_success}</span> Apply success
        </span>
      </div>
      <div class="flex items-center gap-2">
        <div class="w-3 h-3 rounded-full bg-[var(--sg-error)]"></div>
        <span class="text-sm text-[var(--sg-text)]">
          <span class="font-semibold">{stateCounts.apply_failed}</span> Apply failed
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
        class="w-full px-4 py-2 pl-10 border border-[var(--sg-border)] rounded-md bg-[var(--sg-bg-1)] text-[var(--sg-text)] placeholder-[var(--sg-text-dim)] focus:outline-none focus:ring-2 focus:ring-[var(--sg-accent)] focus:border-transparent"
      />
      <svg
        class="absolute left-3 top-2.5 h-5 w-5 text-[var(--sg-text-dim)]"
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
  <div class="mb-4 flex items-center gap-4 pb-4 border-b border-[var(--sg-border)]">
    <button
      on:click={toggleExpandAll}
      class="inline-flex items-center px-3 py-2 border border-[var(--sg-border)] shadow-sm text-sm font-medium rounded-md text-[var(--sg-text-muted)] bg-[var(--sg-bg-1)] hover:bg-[var(--sg-bg-2)] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[var(--sg-accent)] transition-colors"
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
        class="h-4 w-4 rounded border-[var(--sg-border)] text-[var(--sg-accent)] focus:ring-[var(--sg-accent)] focus:ring-offset-0 cursor-pointer"
      />
      <span class="ml-2 text-sm font-medium text-[var(--sg-text-muted)]">
        Show Workspaces
      </span>
    </label>
  </div>

  <!-- Render stacks vertically layered -->
  {#if filteredStacks && filteredStacks.stacks && filteredStacks.stacks.length > 0}
    <div class="space-y-6" role="list" aria-label="Stack list">
      {#each filteredStacks.stacks as stack}
        <StackNode {stack} level={0} forceExpanded={allExpanded} {showWorkspaces} openPlan={planOpener} />
      {/each}
    </div>
  {:else if searchQuery}
    <EmptyState
      icon="mdi:magnify"
      title="No matching stacks"
      description={`No stacks found matching "${searchQuery}".`}
    >
      <button
        on:click={() => searchQuery = ''}
        class="mt-4 px-4 py-2 text-sm font-medium text-[var(--sg-accent)] hover:text-[var(--sg-accent-hover)] transition-colors"
      >
        Clear search
      </button>
    </EmptyState>
  {/if}
{:else}
  <!-- Empty state: no stacks configured -->
  <EmptyState
    icon="mdi:file-document-outline"
    title="No stacks found"
    description="This pull request doesn't have any stacks configured yet."
  />
{/if}
