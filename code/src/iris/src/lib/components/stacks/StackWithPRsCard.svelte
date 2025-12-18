<script lang="ts">
  import type { StackWithPRs } from '../../types';
  import { navigateToStackDetail } from '../../utils/navigation';

  export let stackWithPRs: StackWithPRs;
  export let expanded: boolean = false;

  // Display logic
  $: displayedPRs = expanded
    ? stackWithPRs.prs
    : stackWithPRs.prs.slice(0, 5);
  $: hasMorePRs = stackWithPRs.prs.length > 5;

  /**
   * Gets color classes for aggregate state border
   */
  function getStateBorderColor(state: string): string {
    switch (state) {
      case 'apply_success':
        return 'border-l-green-500';
      case 'apply_failed':
      case 'plan_failed':
        return 'border-l-red-500';
      case 'apply_pending':
      case 'plan_pending':
        return 'border-l-purple-500';
      case 'apply_ready':
        return 'border-l-blue-500';
      case 'no_changes':
        return 'border-l-gray-400';
      default:
        return 'border-l-gray-300';
    }
  }

  /**
   * Gets badge classes for stack state
   */
  function getStackStateBadgeClasses(state: string): string {
    switch (state) {
      case 'apply_success':
        return 'bg-green-100 dark:bg-green-900/30 text-green-800 dark:text-green-400';
      case 'apply_failed':
      case 'plan_failed':
        return 'bg-red-100 dark:bg-red-900/30 text-red-800 dark:text-red-400';
      case 'apply_pending':
      case 'plan_pending':
        return 'bg-purple-100 dark:bg-purple-900/30 text-purple-800 dark:text-purple-400';
      case 'apply_ready':
        return 'bg-blue-100 dark:bg-blue-900/30 text-blue-800 dark:text-blue-400';
      case 'no_changes':
        return 'bg-gray-100 dark:bg-gray-700 text-gray-800 dark:text-gray-300';
      default:
        return 'bg-gray-100 dark:bg-gray-700 text-gray-800 dark:text-gray-300';
    }
  }

  /**
   * Gets badge classes for PR state
   */
  function getPRStateBadgeClasses(state: string): string {
    switch (state) {
      case 'success':
        return 'bg-green-100 dark:bg-green-900/30 text-green-800 dark:text-green-400';
      case 'failed':
        return 'bg-red-100 dark:bg-red-900/30 text-red-800 dark:text-red-400';
      case 'pending':
        return 'bg-purple-100 dark:bg-purple-900/30 text-purple-800 dark:text-purple-400';
      case 'ready':
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

  /**
   * Formats timestamp as relative time
   */
  function formatRelativeTime(timestamp: string): string {
    try {
      const now = new Date();
      const date = new Date(timestamp);
      const diffMs = now.getTime() - date.getTime();
      const diffMins = Math.floor(diffMs / (1000 * 60));
      const diffHours = Math.floor(diffMs / (1000 * 60 * 60));
      const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));
      const diffWeeks = Math.floor(diffDays / 7);

      if (diffMins < 60) {
        return diffMins === 0 ? 'Just now' : `${diffMins}m ago`;
      } else if (diffHours < 24) {
        return diffHours === 0 ? 'Just now' : `${diffHours}h ago`;
      } else if (diffDays < 7) {
        return `${diffDays}d ago`;
      } else if (diffWeeks < 4) {
        return `${diffWeeks}w ago`;
      } else {
        return date.toLocaleDateString();
      }
    } catch {
      return timestamp;
    }
  }

  /**
   * Toggles expansion
   */
  function toggleExpand(event: MouseEvent): void {
    event.stopPropagation();
    expanded = !expanded;
  }

  /**
   * Navigates to most recent PR's stack detail
   */
  function handleClick(): void {
    if (stackWithPRs.prs.length > 0) {
      // Find most recent PR
      const mostRecentPR = stackWithPRs.prs.reduce((latest, pr) => {
        return new Date(pr.lastActivity) > new Date(latest.lastActivity) ? pr : latest;
      }, stackWithPRs.prs[0]);

      navigateToStackDetail(mostRecentPR.prNumber, stackWithPRs.stackName);
    }
  }
</script>

<button
  class="w-full text-left bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 border-l-4 {getStateBorderColor(
    stackWithPRs.aggregateState
  )} shadow-sm dark:shadow-gray-900/20 hover:shadow-lg dark:hover:shadow-gray-900/40 transition-shadow cursor-pointer"
  aria-label="View {stackWithPRs.stackName} stack with {stackWithPRs.totalPRs} PRs"
  on:click={handleClick}
>
  <div class="p-6">
    <!-- Header: Stack info and aggregate state -->
    <div class="flex items-start justify-between mb-4">
      <div class="flex-1 min-w-0">
        <div class="flex items-center gap-2 mb-2">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100">
            {stackWithPRs.stackName}
          </h3>
        </div>
        <div class="flex items-center gap-2 text-sm text-gray-600 dark:text-gray-400">
          <span>
            {stackWithPRs.totalPRs} {stackWithPRs.totalPRs === 1 ? 'PR' : 'PRs'}
          </span>
          <span>•</span>
          <span>
            {stackWithPRs.dirspaces.length} {stackWithPRs.dirspaces.length === 1 ? 'dirspace' : 'dirspaces'}
          </span>
        </div>
      </div>
      <div class="flex-shrink-0 ml-4">
        <span
          class="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium {getStackStateBadgeClasses(
            stackWithPRs.aggregateState
          )}"
        >
          {formatStateName(stackWithPRs.aggregateState)}
        </span>
      </div>
    </div>

    <!-- Dirspaces list -->
    {#if stackWithPRs.dirspaces.length > 0}
      <div class="mb-4 bg-gray-50 dark:bg-gray-900/50 rounded-md p-3">
        <div class="text-sm font-medium text-gray-900 dark:text-gray-100 mb-2">
          Dirspaces
        </div>
        <div class="flex flex-wrap gap-2">
          {#each stackWithPRs.dirspaces as dirspace}
            <span class="inline-flex items-center px-2 py-1 rounded text-xs font-mono bg-gray-100 dark:bg-gray-800 text-gray-700 dark:text-gray-300">
              {dirspace.dir}:{dirspace.workspace}
            </span>
          {/each}
        </div>
      </div>
    {/if}

    <!-- PRs list -->
    <div class="space-y-2 mb-4">
      {#each displayedPRs as pr}
        <div
          class="flex items-center justify-between p-2 rounded-md bg-gray-50 dark:bg-gray-900/50 hover:bg-gray-100 dark:hover:bg-gray-900/70 transition-colors"
        >
          <div class="flex items-center gap-2 min-w-0 flex-1">
            <span class="font-medium text-gray-900 dark:text-gray-100">
              PR #{pr.prNumber}
            </span>
            {#if pr.prTitle}
              <span class="text-gray-600 dark:text-gray-400 truncate">
                {pr.prTitle}
              </span>
            {/if}
            <span class="text-xs text-gray-500 dark:text-gray-500">
              ({pr.repo})
            </span>
          </div>
          <div class="flex items-center gap-2 flex-shrink-0">
            <span class="text-xs text-gray-600 dark:text-gray-400">
              {pr.runCount} {pr.runCount === 1 ? 'run' : 'runs'}
            </span>
            <span
              class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium {getPRStateBadgeClasses(
                pr.state
              )}"
            >
              {formatStateName(pr.state)}
            </span>
          </div>
        </div>
      {/each}

      {#if hasMorePRs}
        <button
          on:click={toggleExpand}
          class="w-full text-center text-sm text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 font-medium transition-colors py-2"
          aria-label="{expanded ? 'Show fewer' : 'Show all'} PRs"
          aria-expanded={expanded}
        >
          {expanded
            ? 'Show less'
            : `Show all ${stackWithPRs.prs.length} PRs (+${stackWithPRs.prs.length - 5} more)`}
        </button>
      {/if}
    </div>

    <!-- Metrics footer -->
    <div
      class="flex items-center gap-4 pt-3 border-t border-gray-200 dark:border-gray-700 text-xs text-gray-600 dark:text-gray-400"
    >
      {#if stackWithPRs.lastActivity}
        <div class="flex items-center gap-1">
          <span class="font-medium">Last activity:</span>
          <span>{formatRelativeTime(stackWithPRs.lastActivity)}</span>
          {#if stackWithPRs.lastUser}
            <span>by @{stackWithPRs.lastUser}</span>
          {/if}
        </div>
      {/if}
    </div>
  </div>
</button>
