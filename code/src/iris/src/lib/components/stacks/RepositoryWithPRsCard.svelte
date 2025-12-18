<script lang="ts">
  import type { RepositoryWithPRs } from '../../types';
  import { navigateToStackDetail } from '../../utils/navigation';

  export let repositoryWithPRs: RepositoryWithPRs;
  export let expanded: boolean = false;

  // Display logic
  $: displayedPRs = expanded
    ? repositoryWithPRs.prs
    : repositoryWithPRs.prs.slice(0, 5);
  $: hasMorePRs = repositoryWithPRs.prs.length > 5;

  /**
   * Gets color classes for aggregate state border
   */
  function getStateBorderColor(state: string): string {
    switch (state) {
      case 'success':
        return 'border-l-green-500';
      case 'failed':
        return 'border-l-red-500';
      case 'pending':
        return 'border-l-purple-500';
      case 'ready':
        return 'border-l-blue-500';
      case 'no_changes':
        return 'border-l-gray-400';
      default:
        return 'border-l-gray-300';
    }
  }

  /**
   * Gets badge classes for aggregate state
   */
  function getStateBadgeClasses(state: string): string {
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
   * Navigates to first PR's stack detail
   */
  function handleClick(): void {
    // Navigate to first PR in the repository
    if (repositoryWithPRs.prs.length > 0) {
      const firstPR = repositoryWithPRs.prs[0];
      if (firstPR.stacks.length > 0) {
        const firstStackName = `${firstPR.stacks[0].stackOuter.name}/${firstPR.stacks[0].stackInner.name}`;
        navigateToStackDetail(firstPR.prNumber, firstStackName);
      }
    }
  }
</script>

<button
  class="w-full text-left bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 border-l-4 {getStateBorderColor(
    repositoryWithPRs.aggregateState
  )} shadow-sm dark:shadow-gray-900/20 hover:shadow-lg dark:hover:shadow-gray-900/40 transition-shadow cursor-pointer"
  aria-label="View {repositoryWithPRs.repo} repository with {repositoryWithPRs.totalPRs} PRs and {repositoryWithPRs.totalStacks} stacks"
  on:click={handleClick}
>
  <div class="p-6">
    <!-- Header: Repository info and aggregate state -->
    <div class="flex items-start justify-between mb-4">
      <div class="flex-1 min-w-0">
        <div class="flex items-center gap-2 mb-2">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100">
            {repositoryWithPRs.repo}
          </h3>
        </div>
        <div class="flex items-center gap-2 text-sm text-gray-600 dark:text-gray-400">
          <span>
            {repositoryWithPRs.totalPRs} {repositoryWithPRs.totalPRs === 1 ? 'PR' : 'PRs'}
          </span>
          <span>•</span>
          <span>
            {repositoryWithPRs.totalStacks} {repositoryWithPRs.totalStacks === 1 ? 'Stack' : 'Stacks'}
          </span>
        </div>
      </div>
      <div class="flex-shrink-0 ml-4">
        <span
          class="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium {getStateBadgeClasses(
            repositoryWithPRs.aggregateState
          )}"
        >
          {formatStateName(repositoryWithPRs.aggregateState)}
        </span>
      </div>
    </div>

    <!-- Stack summary counts -->
    <div class="mb-4 bg-gray-50 dark:bg-gray-900/50 rounded-md p-3">
      <div class="flex items-center justify-between flex-wrap gap-2">
        <div class="text-sm font-medium text-gray-900 dark:text-gray-100">
          Stack States
        </div>
        <div class="flex items-center gap-3 text-xs flex-wrap">
          {#if repositoryWithPRs.stackStateCounts.apply_failed > 0}
            <div class="flex items-center gap-1 text-red-600 dark:text-red-400">
              <span class="w-2 h-2 rounded-full bg-red-500"></span>
              <span>{repositoryWithPRs.stackStateCounts.apply_failed} apply failed</span>
            </div>
          {/if}
          {#if repositoryWithPRs.stackStateCounts.plan_failed > 0}
            <div class="flex items-center gap-1 text-orange-600 dark:text-orange-400">
              <span class="w-2 h-2 rounded-full bg-orange-500"></span>
              <span>{repositoryWithPRs.stackStateCounts.plan_failed} plan failed</span>
            </div>
          {/if}
          {#if repositoryWithPRs.stackStateCounts.apply_pending > 0}
            <div class="flex items-center gap-1 text-purple-600 dark:text-purple-400">
              <span class="w-2 h-2 rounded-full bg-purple-500"></span>
              <span>{repositoryWithPRs.stackStateCounts.apply_pending} apply pending</span>
            </div>
          {/if}
          {#if repositoryWithPRs.stackStateCounts.plan_pending > 0}
            <div class="flex items-center gap-1 text-pink-600 dark:text-pink-400">
              <span class="w-2 h-2 rounded-full bg-pink-500"></span>
              <span>{repositoryWithPRs.stackStateCounts.plan_pending} plan pending</span>
            </div>
          {/if}
          {#if repositoryWithPRs.stackStateCounts.apply_ready > 0}
            <div class="flex items-center gap-1 text-blue-600 dark:text-blue-400">
              <span class="w-2 h-2 rounded-full bg-blue-500"></span>
              <span>{repositoryWithPRs.stackStateCounts.apply_ready} ready</span>
            </div>
          {/if}
          {#if repositoryWithPRs.stackStateCounts.apply_success > 0}
            <div class="flex items-center gap-1 text-green-600 dark:text-green-400">
              <span class="w-2 h-2 rounded-full bg-green-500"></span>
              <span>{repositoryWithPRs.stackStateCounts.apply_success} successful</span>
            </div>
          {/if}
          {#if repositoryWithPRs.stackStateCounts.no_changes > 0}
            <div class="flex items-center gap-1 text-gray-600 dark:text-gray-400">
              <span class="w-2 h-2 rounded-full bg-gray-400"></span>
              <span>{repositoryWithPRs.stackStateCounts.no_changes} no changes</span>
            </div>
          {/if}
        </div>
      </div>
    </div>

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
          </div>
          <div class="flex items-center gap-2 flex-shrink-0">
            <span class="text-xs text-gray-600 dark:text-gray-400">
              {pr.stacks.length} {pr.stacks.length === 1 ? 'stack' : 'stacks'}
            </span>
            <span
              class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium {getStateBadgeClasses(
                pr.aggregateState
              )}"
            >
              {formatStateName(pr.aggregateState)}
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
            : `Show all ${repositoryWithPRs.prs.length} PRs (+${repositoryWithPRs.prs.length - 5} more)`}
        </button>
      {/if}
    </div>

    <!-- Metrics footer -->
    <div
      class="flex items-center gap-4 pt-3 border-t border-gray-200 dark:border-gray-700 text-xs text-gray-600 dark:text-gray-400"
    >
      {#if repositoryWithPRs.lastActivity}
        <div class="flex items-center gap-1">
          <span class="font-medium">Last activity:</span>
          <span>{formatRelativeTime(repositoryWithPRs.lastActivity)}</span>
          {#if repositoryWithPRs.lastUser}
            <span>by @{repositoryWithPRs.lastUser}</span>
          {/if}
        </div>
      {/if}
    </div>
  </div>
</button>
