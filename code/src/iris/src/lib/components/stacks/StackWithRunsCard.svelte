<script lang="ts">
  import type { StackWithRuns } from '../../types';
  import { navigateToPRDetail } from '../../utils/navigation';

  export let stackWithRuns: StackWithRuns;
  export let expanded: boolean = false;

  // Display logic
  $: recentRuns = expanded
    ? stackWithRuns.recentRuns
    : stackWithRuns.recentRuns.slice(0, 3);
  $: hasMoreRuns = stackWithRuns.recentRuns.length > 3;

  /**
   * Gets color classes for stack state border
   */
  function getStateBorderColor(state: string): string {
    switch (state) {
      case 'apply_success':
        return 'border-l-green-500';
      case 'apply_failed':
        return 'border-l-red-500';
      case 'apply_pending':
        return 'border-l-purple-500';
      case 'apply_ready':
        return 'border-l-blue-500';
      case 'plan_pending':
        return 'border-l-pink-500';
      case 'plan_failed':
        return 'border-l-orange-500';
      case 'no_changes':
        return 'border-l-gray-400';
      default:
        return 'border-l-gray-300';
    }
  }

  /**
   * Gets badge classes for stack state
   */
  function getStateBadgeClasses(state: string): string {
    switch (state) {
      case 'apply_success':
        return 'bg-green-100 dark:bg-green-900/30 text-green-800 dark:text-green-400';
      case 'apply_failed':
        return 'bg-red-100 dark:bg-red-900/30 text-red-800 dark:text-red-400';
      case 'apply_pending':
        return 'bg-purple-100 dark:bg-purple-900/30 text-purple-800 dark:text-purple-400';
      case 'apply_ready':
        return 'bg-blue-100 dark:bg-blue-900/30 text-blue-800 dark:text-blue-400';
      case 'plan_pending':
        return 'bg-pink-100 dark:bg-pink-900/30 text-pink-800 dark:text-pink-400';
      case 'plan_failed':
        return 'bg-orange-100 dark:bg-orange-900/30 text-orange-800 dark:text-orange-400';
      case 'no_changes':
        return 'bg-gray-100 dark:bg-gray-700 text-gray-800 dark:text-gray-300';
      default:
        return 'bg-gray-100 dark:bg-gray-700 text-gray-800 dark:text-gray-300';
    }
  }

  /**
   * Gets badge classes for run state
   */
  function getRunStateBadgeClasses(state: string): string {
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
        return 'bg-gray-100 dark:bg-gray-700 text-gray-800 dark:text-gray-300';
    }
  }

  /**
   * Gets icon for run type
   */
  function getRunTypeIcon(runType: string): string {
    switch (runType) {
      case 'apply':
        return '🚀';
      case 'plan':
        return '📋';
      case 'index':
        return '📑';
      default:
        return '▪️';
    }
  }

  /**
   * Gets icon for run state
   */
  function getRunStateIcon(state: string): string {
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
        return '▪️';
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
   * Navigates to PR detail page
   */
  function handlePRClick(event: MouseEvent): void {
    event.stopPropagation();
    navigateToPRDetail(stackWithRuns.prNumber);
  }

  /**
   * Toggles expansion
   */
  function toggleExpand(event: MouseEvent): void {
    event.stopPropagation();
    expanded = !expanded;
  }
</script>

<div
  class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 border-l-4 {getStateBorderColor(
    stackWithRuns.state
  )} shadow-sm dark:shadow-gray-900/20 hover:shadow-lg dark:hover:shadow-gray-900/40 transition-shadow"
  role="article"
  aria-label="Stack {stackWithRuns.stackInner.name} from PR #{stackWithRuns.prNumber} in {stackWithRuns.repo}"
>
  <div class="p-6">
    <!-- Header: Stack name and state -->
    <div class="flex items-start justify-between mb-4">
      <div class="flex-1 min-w-0">
        <div class="flex items-center gap-2 mb-1">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100 truncate">
            {stackWithRuns.stackOuter.name}
            {#if stackWithRuns.stackOuter.name !== stackWithRuns.stackInner.name}
              <span class="text-gray-500 dark:text-gray-400">/</span>
              {stackWithRuns.stackInner.name}
            {/if}
          </h3>
        </div>
        <div class="flex items-center gap-2 flex-wrap">
          <span
            class="inline-flex items-center px-2 py-1 rounded-md text-xs font-medium bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300"
          >
            {stackWithRuns.repo}
          </span>
          <button
            on:click={handlePRClick}
            class="inline-flex items-center px-2 py-1 rounded-md text-xs font-medium bg-blue-100 dark:bg-blue-900/30 text-blue-800 dark:text-blue-400 hover:bg-blue-200 dark:hover:bg-blue-900/50 transition-colors"
            aria-label="View PR #{stackWithRuns.prNumber}"
          >
            PR #{stackWithRuns.prNumber}
            {#if stackWithRuns.prTitle}
              : {stackWithRuns.prTitle}
            {/if}
          </button>
        </div>
      </div>
      <div class="flex-shrink-0 ml-4">
        <span
          class="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium {getStateBadgeClasses(
            stackWithRuns.state
          )}"
        >
          {formatStateName(stackWithRuns.state)}
        </span>
      </div>
    </div>

    <!-- Dirspaces info -->
    {#if stackWithRuns.stackInner.dirspaces && stackWithRuns.stackInner.dirspaces.length > 0}
      <div class="mb-4 bg-gray-50 dark:bg-gray-900/50 rounded-md p-3">
        <div class="text-xs font-medium text-gray-700 dark:text-gray-300 mb-2">
          Workspaces ({stackWithRuns.stackInner.dirspaces.length}):
        </div>
        <div class="space-y-1">
          {#each stackWithRuns.stackInner.dirspaces.slice(0, 3) as { dirspace }}
            <div class="flex items-center gap-2 text-xs">
              <span class="font-mono text-gray-900 dark:text-gray-100">{dirspace.dir}</span>
              <span class="text-gray-500 dark:text-gray-400">:</span>
              <span class="text-gray-700 dark:text-gray-300">{dirspace.workspace}</span>
            </div>
          {/each}
          {#if stackWithRuns.stackInner.dirspaces.length > 3}
            <div class="text-xs text-gray-500 dark:text-gray-400">
              +{stackWithRuns.stackInner.dirspaces.length - 3} more...
            </div>
          {/if}
        </div>
      </div>
    {/if}

    <!-- Recent runs -->
    {#if stackWithRuns.recentRuns.length > 0}
      <div class="mb-3">
        <div class="flex items-center justify-between mb-2">
          <h4 class="text-sm font-medium text-gray-900 dark:text-gray-100">
            Recent Runs ({stackWithRuns.recentRuns.length})
          </h4>
          {#if hasMoreRuns}
            <button
              on:click={toggleExpand}
              class="text-xs text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 font-medium transition-colors"
              aria-label="{expanded ? 'Show fewer' : 'Show all'} runs"
              aria-expanded={expanded}
            >
              {expanded ? 'Show less' : `Show all (${stackWithRuns.recentRuns.length})`}
            </button>
          {/if}
        </div>
        <div class="space-y-2">
          {#each recentRuns as run}
            <div
              class="flex items-center gap-3 text-sm p-2 rounded-md bg-gray-50 dark:bg-gray-900/50 hover:bg-gray-100 dark:hover:bg-gray-900/70 transition-colors"
            >
              <span class="flex-shrink-0 text-base" aria-hidden="true">
                {getRunStateIcon(run.state)}
              </span>
              <span class="flex-shrink-0 text-xs" aria-hidden="true">
                {getRunTypeIcon(run.run_type)}
              </span>
              <span class="font-medium text-gray-900 dark:text-gray-100 min-w-0 flex-shrink-0">
                {run.run_type}
              </span>
              <span
                class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium {getRunStateBadgeClasses(
                  run.state
                )}"
              >
                {run.state}
              </span>
              <span class="text-gray-500 dark:text-gray-400 text-xs truncate flex-1">
                {formatRelativeTime(run.created_at)}
              </span>
              {#if run.user}
                <span class="text-gray-600 dark:text-gray-400 text-xs flex-shrink-0">
                  @{run.user}
                </span>
              {/if}
            </div>
          {/each}
        </div>
      </div>
    {:else}
      <div class="text-sm text-gray-500 dark:text-gray-400 text-center py-4">
        No recent runs
      </div>
    {/if}

    <!-- Metrics footer -->
    <div class="flex items-center gap-4 pt-3 border-t border-gray-200 dark:border-gray-700 text-xs text-gray-600 dark:text-gray-400">
      {#if stackWithRuns.lastActivity}
        <div class="flex items-center gap-1">
          <span class="font-medium">Last activity:</span>
          <span>{formatRelativeTime(stackWithRuns.lastActivity)}</span>
          {#if stackWithRuns.lastUser}
            <span>by @{stackWithRuns.lastUser}</span>
          {/if}
        </div>
      {/if}
      {#if stackWithRuns.runningCount > 0}
        <div class="flex items-center gap-1">
          <span class="w-2 h-2 rounded-full bg-blue-500"></span>
          <span>{stackWithRuns.runningCount} running</span>
        </div>
      {/if}
      {#if stackWithRuns.failureCount > 0}
        <div class="flex items-center gap-1">
          <span class="w-2 h-2 rounded-full bg-red-500"></span>
          <span>{stackWithRuns.failureCount} failed</span>
        </div>
      {/if}
      {#if stackWithRuns.successCount > 0}
        <div class="flex items-center gap-1">
          <span class="w-2 h-2 rounded-full bg-green-500"></span>
          <span>{stackWithRuns.successCount} successful</span>
        </div>
      {/if}
    </div>
  </div>
</div>
