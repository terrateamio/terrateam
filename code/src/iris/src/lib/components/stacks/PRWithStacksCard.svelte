<script lang="ts">
  import type { PRWithStacks } from '../../types';
  import { navigateToStackDetail } from '../../utils/navigation';

  export let prWithStacks: PRWithStacks;
  export let expanded: boolean = false;

  // Display logic
  $: displayedStacks = expanded
    ? prWithStacks.stacks
    : prWithStacks.stacks.slice(0, 5);
  $: hasMoreStacks = prWithStacks.stacks.length > 5;

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
   * Gets badge classes for individual stack state
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
   * Gets icon for stack state
   */
  function getStackStateIcon(state: string): string {
    switch (state) {
      case 'apply_success':
        return '✅';
      case 'apply_failed':
      case 'plan_failed':
        return '❌';
      case 'apply_pending':
      case 'plan_pending':
        return '⏳';
      case 'apply_ready':
        return '✓';
      case 'no_changes':
        return '○';
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
   * Toggles expansion
   */
  function toggleExpand(event: MouseEvent): void {
    event.stopPropagation();
    expanded = !expanded;
  }

  /**
   * Navigates to stack detail for this PR
   */
  function handleClick(): void {
    // Navigate to PR's stack detail page
    // Using first stack name as default (user can navigate to specific stacks from detail page)
    if (prWithStacks.stacks.length > 0) {
      const firstStackName = `${prWithStacks.stacks[0].stackOuter.name}/${prWithStacks.stacks[0].stackInner.name}`;
      navigateToStackDetail(prWithStacks.prNumber, firstStackName);
    }
  }
</script>

<button
  class="w-full text-left bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 border-l-4 {getStateBorderColor(
    prWithStacks.aggregateState
  )} shadow-sm dark:shadow-gray-900/20 hover:shadow-lg dark:hover:shadow-gray-900/40 transition-shadow cursor-pointer"
  aria-label="View PR #{prWithStacks.prNumber} in {prWithStacks.repo} with {prWithStacks.stacks.length} stacks"
  on:click={handleClick}
>
  <div class="p-6">
    <!-- Header: PR info and aggregate state -->
    <div class="flex items-start justify-between mb-4">
      <div class="flex-1 min-w-0">
        <div class="flex items-center gap-2 mb-2">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100">
            PR #{prWithStacks.prNumber}
            {#if prWithStacks.prTitle}
              <span class="text-gray-600 dark:text-gray-400">: {prWithStacks.prTitle}</span>
            {/if}
          </h3>
        </div>
        <div class="flex items-center gap-2">
          <span
            class="inline-flex items-center px-2 py-1 rounded-md text-xs font-medium bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300"
          >
            {prWithStacks.repo}
          </span>
        </div>
      </div>
      <div class="flex-shrink-0 ml-4">
        <span
          class="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium {getStateBadgeClasses(
            prWithStacks.aggregateState
          )}"
        >
          {formatStateName(prWithStacks.aggregateState)}
        </span>
      </div>
    </div>

    <!-- Stack summary counts -->
    <div class="mb-4 bg-gray-50 dark:bg-gray-900/50 rounded-md p-3">
      <div class="flex items-center justify-between flex-wrap gap-2">
        <div class="text-sm font-medium text-gray-900 dark:text-gray-100">
          {prWithStacks.stacks.length} {prWithStacks.stacks.length === 1 ? 'Stack' : 'Stacks'}
        </div>
        <div class="flex items-center gap-3 text-xs flex-wrap">
          {#if prWithStacks.stackStateCounts.apply_failed > 0}
            <div class="flex items-center gap-1 text-red-600 dark:text-red-400">
              <span class="w-2 h-2 rounded-full bg-red-500"></span>
              <span>{prWithStacks.stackStateCounts.apply_failed} apply failed</span>
            </div>
          {/if}
          {#if prWithStacks.stackStateCounts.plan_failed > 0}
            <div class="flex items-center gap-1 text-orange-600 dark:text-orange-400">
              <span class="w-2 h-2 rounded-full bg-orange-500"></span>
              <span>{prWithStacks.stackStateCounts.plan_failed} plan failed</span>
            </div>
          {/if}
          {#if prWithStacks.stackStateCounts.apply_pending > 0}
            <div class="flex items-center gap-1 text-purple-600 dark:text-purple-400">
              <span class="w-2 h-2 rounded-full bg-purple-500"></span>
              <span>{prWithStacks.stackStateCounts.apply_pending} apply pending</span>
            </div>
          {/if}
          {#if prWithStacks.stackStateCounts.plan_pending > 0}
            <div class="flex items-center gap-1 text-pink-600 dark:text-pink-400">
              <span class="w-2 h-2 rounded-full bg-pink-500"></span>
              <span>{prWithStacks.stackStateCounts.plan_pending} plan pending</span>
            </div>
          {/if}
          {#if prWithStacks.stackStateCounts.apply_ready > 0}
            <div class="flex items-center gap-1 text-blue-600 dark:text-blue-400">
              <span class="w-2 h-2 rounded-full bg-blue-500"></span>
              <span>{prWithStacks.stackStateCounts.apply_ready} ready</span>
            </div>
          {/if}
          {#if prWithStacks.stackStateCounts.apply_success > 0}
            <div class="flex items-center gap-1 text-green-600 dark:text-green-400">
              <span class="w-2 h-2 rounded-full bg-green-500"></span>
              <span>{prWithStacks.stackStateCounts.apply_success} successful</span>
            </div>
          {/if}
          {#if prWithStacks.stackStateCounts.no_changes > 0}
            <div class="flex items-center gap-1 text-gray-600 dark:text-gray-400">
              <span class="w-2 h-2 rounded-full bg-gray-400"></span>
              <span>{prWithStacks.stackStateCounts.no_changes} no changes</span>
            </div>
          {/if}
        </div>
      </div>
    </div>

    <!-- Stacks list -->
    <div class="space-y-2 mb-4">
      {#each displayedStacks as stack}
        <div
          class="flex items-center justify-between p-2 rounded-md bg-gray-50 dark:bg-gray-900/50 hover:bg-gray-100 dark:hover:bg-gray-900/70 transition-colors"
        >
          <div class="flex items-center gap-2 min-w-0 flex-1">
            <span class="flex-shrink-0 text-base" aria-hidden="true">
              {getStackStateIcon(stack.state)}
            </span>
            <span class="font-medium text-gray-900 dark:text-gray-100 truncate">
              {stack.stackOuter.name}
              {#if stack.stackOuter.name !== stack.stackInner.name}
                <span class="text-gray-500 dark:text-gray-400">/</span>
                {stack.stackInner.name}
              {/if}
            </span>
          </div>
          <div class="flex items-center gap-2 flex-shrink-0">
            {#if stack.recentRunsCount > 0}
              <span class="text-xs text-gray-600 dark:text-gray-400">
                {stack.recentRunsCount} {stack.recentRunsCount === 1 ? 'run' : 'runs'}
              </span>
            {/if}
            <span
              class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium {getStackStateBadgeClasses(
                stack.state
              )}"
            >
              {formatStateName(stack.state)}
            </span>
          </div>
        </div>
      {/each}

      {#if hasMoreStacks}
        <button
          on:click={toggleExpand}
          class="w-full text-center text-sm text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 font-medium transition-colors py-2"
          aria-label="{expanded ? 'Show fewer' : 'Show all'} stacks"
          aria-expanded={expanded}
        >
          {expanded
            ? 'Show less'
            : `Show all ${prWithStacks.stacks.length} stacks (+${prWithStacks.stacks.length - 5} more)`}
        </button>
      {/if}
    </div>

    <!-- Metrics footer -->
    <div
      class="flex items-center gap-4 pt-3 border-t border-gray-200 dark:border-gray-700 text-xs text-gray-600 dark:text-gray-400"
    >
      {#if prWithStacks.lastActivity}
        <div class="flex items-center gap-1">
          <span class="font-medium">Last activity:</span>
          <span>{formatRelativeTime(prWithStacks.lastActivity)}</span>
          {#if prWithStacks.lastUser}
            <span>by @{prWithStacks.lastUser}</span>
          {/if}
        </div>
      {/if}
      {#if prWithStacks.totalRunningCount > 0}
        <div class="flex items-center gap-1">
          <span class="w-2 h-2 rounded-full bg-blue-500"></span>
          <span>{prWithStacks.totalRunningCount} running</span>
        </div>
      {/if}
      {#if prWithStacks.totalFailureCount > 0}
        <div class="flex items-center gap-1">
          <span class="w-2 h-2 rounded-full bg-red-500"></span>
          <span>{prWithStacks.totalFailureCount} failed runs</span>
        </div>
      {/if}
      {#if prWithStacks.totalSuccessCount > 0}
        <div class="flex items-center gap-1">
          <span class="w-2 h-2 rounded-full bg-green-500"></span>
          <span>{prWithStacks.totalSuccessCount} successful runs</span>
        </div>
      {/if}
    </div>
  </div>
</button>
