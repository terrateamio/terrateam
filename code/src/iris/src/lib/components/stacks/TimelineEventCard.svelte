<script lang="ts">
  import type { TimelineEvent } from '../../types';
  import { navigateToStackDetail } from '../../utils/navigation';

  export let event: TimelineEvent;

  /**
   * Handles click on timeline entry
   */
  function handleClick(): void {
    // If we have PR number and stack name, navigate to stack detail
    if (event.prNumber && event.stackName) {
      navigateToStackDetail(event.prNumber, event.stackName);
    }
    // Could add fallback navigation to runs page or PR page if needed
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
        return '🔍';
      case 'build-config':
        return '⚙️';
      case 'build-tree':
        return '🌳';
      default:
        return '▪️';
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
        return 'bg-purple-100 dark:bg-purple-900/30 text-purple-800 dark:text-purple-400';
      case 'aborted':
        return 'bg-orange-100 dark:bg-orange-900/30 text-orange-800 dark:text-orange-400';
      default:
        return 'bg-gray-100 dark:bg-gray-700 text-gray-800 dark:text-gray-300';
    }
  }

  /**
   * Formats state name for display
   */
  function formatStateName(state: string): string {
    return state.charAt(0).toUpperCase() + state.slice(1);
  }

  /**
   * Formats run type for display
   */
  function formatRunType(runType: string): string {
    return runType.replace(/-/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
  }

  /**
   * Formats timestamp
   */
  function formatTime(timestamp: string): string {
    try {
      const date = new Date(timestamp);
      return date.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' });
    } catch {
      return timestamp;
    }
  }

  /**
   * Formats full timestamp for tooltip
   */
  function formatFullTimestamp(timestamp: string): string {
    try {
      const date = new Date(timestamp);
      return date.toLocaleString();
    } catch {
      return timestamp;
    }
  }
</script>

<tr
  class="hover:bg-gray-50 dark:hover:bg-gray-900/30 border-b border-gray-200 dark:border-gray-700 cursor-pointer transition-colors"
  on:click={handleClick}
  role="button"
  tabindex="0"
  on:keydown={(e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); handleClick(); } }}
  aria-label="View details for {event.runType} run {event.prNumber ? `on PR #${event.prNumber}` : `in ${event.repo}`}"
>
  <!-- Time -->
  <td class="px-3 py-2 text-xs text-gray-600 dark:text-gray-400 whitespace-nowrap" title={formatFullTimestamp(event.timestamp)}>
    {formatTime(event.timestamp)}
  </td>

  <!-- Type -->
  <td class="px-3 py-2">
    <div class="flex items-center gap-2">
      <span class="text-base" aria-hidden="true">{getRunTypeIcon(event.runType)}</span>
      <span class="text-xs font-medium text-gray-700 dark:text-gray-300">{formatRunType(event.runType)}</span>
    </div>
  </td>

  <!-- State -->
  <td class="px-3 py-2">
    <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium {getRunStateBadgeClasses(event.runState)}">
      {formatStateName(event.runState)}
    </span>
  </td>

  <!-- PR -->
  <td class="px-3 py-2 text-xs text-gray-700 dark:text-gray-300">
    {#if event.prNumber}
      <div class="flex flex-col">
        <span class="font-medium">#{event.prNumber}</span>
        {#if event.prTitle}
          <span class="text-gray-500 dark:text-gray-500 truncate max-w-xs">{event.prTitle}</span>
        {/if}
      </div>
    {:else}
      <span class="text-gray-400 dark:text-gray-600">-</span>
    {/if}
  </td>

  <!-- Repo -->
  <td class="px-3 py-2 text-xs font-mono text-gray-600 dark:text-gray-400">
    {event.repo}
  </td>

  <!-- Stack / Dir:Workspace -->
  <td class="px-3 py-2">
    <div class="flex flex-col gap-0.5">
      {#if event.stackName}
        <span class="text-xs font-medium text-gray-700 dark:text-gray-300">{event.stackName}</span>
      {/if}
      <span class="text-xs font-mono bg-gray-100 dark:bg-gray-900/50 px-1.5 py-0.5 rounded text-gray-600 dark:text-gray-400 inline-block">
        {event.dir}:{event.workspace}
      </span>
    </div>
  </td>

  <!-- User -->
  <td class="px-3 py-2 text-xs text-gray-600 dark:text-gray-400">
    {#if event.user}
      @{event.user}
    {:else}
      <span class="text-gray-400 dark:text-gray-600">-</span>
    {/if}
  </td>
</tr>
