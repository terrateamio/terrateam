<script lang="ts">
  import type { DashboardMetrics, PRWithStacks } from '../../types';
  import { navigateToPRDetail, navigateToStackDetail } from '../../utils/navigation';
  import { EmptyState, LoadingSpinner } from '../index';
  import { onMount } from 'svelte';

  // Props
  export let metrics: DashboardMetrics;
  export let prsWithStacks: PRWithStacks[] = [];
  export let isLoading: boolean;
  export let error: string | null;
  export let onNavigateToPRs: () => void;

  // Expand state for PRs (using object for better Svelte reactivity)
  let expandedPRs: Record<number, boolean> = {};
  let autoExpandMostRecent: boolean = true;
  let preferenceLoaded: boolean = false;

  // localStorage key for preference
  const EXPAND_PREF_KEY = 'terrateam:stacks:autoExpandMostRecent';

  // Load preference from localStorage
  function loadExpandPreference(): void {
    try {
      const saved = localStorage.getItem(EXPAND_PREF_KEY);
      if (saved !== null) {
        autoExpandMostRecent = saved === 'true';
      }
      preferenceLoaded = true;
    } catch {
      preferenceLoaded = true;
      // Ignore localStorage errors
    }
  }

  // Save preference to localStorage
  function saveExpandPreference(value: boolean): void {
    try {
      localStorage.setItem(EXPAND_PREF_KEY, String(value));
    } catch {
      // Ignore localStorage errors
    }
  }

  // Toggle auto-expand preference
  function toggleAutoExpand(): void {
    autoExpandMostRecent = !autoExpandMostRecent;
    saveExpandPreference(autoExpandMostRecent);

    // Apply immediately - expand or collapse based on new value
    if (mostRecentPR) {
      expandedPRs = { ...expandedPRs, [mostRecentPR.prNumber]: autoExpandMostRecent };
    }
  }

  // Toggle individual PR expansion
  function togglePRExpand(prNumber: number): void {
    expandedPRs = { ...expandedPRs, [prNumber]: !expandedPRs[prNumber] };
  }

  // Get full PR data for a given PR number
  function getFullPRData(prNumber: number): PRWithStacks | undefined {
    return prsWithStacks.find(pr => pr.prNumber === prNumber);
  }

  // Computed: Most recent PR by lastActivity
  $: mostRecentPR = prsWithStacks.length > 0
    ? prsWithStacks.reduce((latest, current) => {
        const latestDate = new Date(latest.lastActivity).getTime();
        const currentDate = new Date(current.lastActivity).getTime();
        return currentDate > latestDate ? current : latest;
      })
    : null;

  // Auto-expand most recent PR when data changes (only if preference loaded and not already set by user)
  $: if (preferenceLoaded && autoExpandMostRecent && mostRecentPR && !(mostRecentPR.prNumber in expandedPRs)) {
    expandedPRs = { ...expandedPRs, [mostRecentPR.prNumber]: true };
  }

  onMount(() => {
    loadExpandPreference();
  });

  /**
   * Formats percentage
   */
  function formatPercentage(value: number): string {
    return value.toFixed(1);
  }

  /**
   * Formats date for display
   */
  function formatDate(dateStr: string): string {
    try {
      const date = new Date(dateStr);
      return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
    } catch {
      return dateStr;
    }
  }

  /**
   * Gets badge classes for PR state
   */
  function getStateBadgeClasses(state: string): string {
    switch (state) {
      case 'success':
        return 'bg-[var(--sg-success-bg)] text-[var(--sg-success)]';
      case 'failed':
        return 'bg-[var(--sg-error-bg)] text-[var(--sg-error)]';
      case 'pending':
        return 'bg-[var(--sg-purple-bg)] text-[var(--sg-purple)]';
      case 'ready':
        return 'bg-[var(--sg-accent-bg)] text-[var(--sg-accent)]';
      case 'no_changes':
        return 'bg-[var(--sg-bg-2)] text-[var(--sg-text)]';
      default:
        return 'bg-[var(--sg-bg-2)] text-[var(--sg-text)]';
    }
  }

  /**
   * Formats state name for display
   */
  function formatStateName(state: string): string {
    return state.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
  }

  /**
   * Formats relative time
   */
  function formatRelativeTime(timestamp: string): string {
    try {
      const date = new Date(timestamp);
      const now = new Date();
      const diffMs = now.getTime() - date.getTime();
      const diffMins = Math.floor(diffMs / 60000);
      const diffHours = Math.floor(diffMs / 3600000);
      const diffDays = Math.floor(diffMs / 86400000);

      if (diffMins < 60) {
        return `${diffMins}m ago`;
      } else if (diffHours < 24) {
        return `${diffHours}h ago`;
      } else if (diffDays < 7) {
        return `${diffDays}d ago`;
      } else {
        return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
      }
    } catch {
      return timestamp;
    }
  }

  /**
   * Gets color for failure rate indicator
   */
  function getFailureRateColor(rate: number): string {
    if (rate >= 25) return 'text-[var(--sg-error)]';
    if (rate >= 10) return 'text-[var(--sg-orange)]';
    return 'text-[var(--sg-success)]';
  }

  /**
   * Calculates percentage for state distribution
   */
  function getStatePercentage(count: number, total: number): number {
    return total > 0 ? (count / total) * 100 : 0;
  }

  /**
   * Gets badge classes for stack state
   */
  function getStackStateBadgeClasses(state: string): string {
    switch (state) {
      case 'apply_success':
        return 'bg-[var(--sg-success-bg)] text-[var(--sg-success)]';
      case 'apply_failed':
      case 'plan_failed':
        return 'bg-[var(--sg-error-bg)] text-[var(--sg-error)]';
      case 'apply_pending':
      case 'plan_pending':
        return 'bg-[var(--sg-purple-bg)] text-[var(--sg-purple)]';
      case 'apply_ready':
        return 'bg-[var(--sg-accent-bg)] text-[var(--sg-accent)]';
      case 'no_changes':
        return 'bg-[var(--sg-bg-2)] text-[var(--sg-text)]';
      default:
        return 'bg-[var(--sg-bg-2)] text-[var(--sg-text)]';
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
   * Gets border color for aggregate state
   */
  function getStateBorderColor(state: string): string {
    switch (state) {
      case 'success':
        return 'border-l-[var(--sg-success)]';
      case 'failed':
        return 'border-l-[var(--sg-error)]';
      case 'pending':
        return 'border-l-[var(--sg-purple)]';
      case 'ready':
        return 'border-l-[var(--sg-accent)]';
      case 'no_changes':
        return 'border-l-[var(--sg-text-dim)]';
      default:
        return 'border-l-[var(--sg-text-dim)]';
    }
  }
</script>

<!-- Loading state -->
{#if isLoading}
  <LoadingSpinner size="xl" />

<!-- Error state -->
{:else if error}
  <div
    class="rounded-md bg-[var(--sg-error-bg)] p-4 border border-[var(--sg-error)]"
    role="alert"
  >
    <div class="flex">
      <div class="flex-shrink-0">
        <svg class="h-5 w-5 text-[var(--sg-error)]" fill="currentColor" viewBox="0 0 20 20">
          <path
            fill-rule="evenodd"
            d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
            clip-rule="evenodd"
          />
        </svg>
      </div>
      <div class="ml-3">
        <h3 class="text-sm font-medium text-[var(--sg-error)]">
          Error loading dashboard
        </h3>
        <div class="mt-2 text-sm text-[var(--sg-error)]">
          {error}
        </div>
      </div>
    </div>
  </div>

<!-- Dashboard content -->
{:else}
  <div class="space-y-6">
    <!-- KPI Cards -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
      <!-- Total PRs -->
      <div class="bg-[var(--sg-bg-1)] rounded-lg border border-[var(--sg-border)] p-4 shadow-sm">
        <div class="text-sm font-medium text-[var(--sg-text-dim)] mb-1">Total PRs</div>
        <div class="text-3xl font-bold text-[var(--sg-text)]">{metrics.totalPRs}</div>
      </div>

      <!-- Total Stacks -->
      <div class="bg-[var(--sg-bg-1)] rounded-lg border border-[var(--sg-border)] p-4 shadow-sm">
        <div class="text-sm font-medium text-[var(--sg-text-dim)] mb-1">Total Stacks</div>
        <div class="text-3xl font-bold text-[var(--sg-text)]">{metrics.totalStacks}</div>
      </div>

      <!-- Total Runs -->
      <div class="bg-[var(--sg-bg-1)] rounded-lg border border-[var(--sg-border)] p-4 shadow-sm">
        <div class="text-sm font-medium text-[var(--sg-text-dim)] mb-1">Total Runs</div>
        <div class="text-3xl font-bold text-[var(--sg-text)]">{metrics.totalRuns}</div>
      </div>

      <!-- Repositories -->
      <div class="bg-[var(--sg-bg-1)] rounded-lg border border-[var(--sg-border)] p-4 shadow-sm">
        <div class="text-sm font-medium text-[var(--sg-text-dim)] mb-1">Repositories</div>
        <div class="text-3xl font-bold text-[var(--sg-text)]">{metrics.uniqueRepos}</div>
      </div>

      <!-- Failure Rate -->
      <div class="bg-[var(--sg-bg-1)] rounded-lg border border-[var(--sg-border)] p-4 shadow-sm">
        <div class="text-sm font-medium text-[var(--sg-text-dim)] mb-1">Failure Rate</div>
        <div class="text-3xl font-bold {getFailureRateColor(metrics.failureRate)}">
          {formatPercentage(metrics.failureRate)}%
        </div>
      </div>
    </div>

    <!-- Stack State Distribution -->
    <div class="bg-[var(--sg-bg-1)] rounded-lg border border-[var(--sg-border)] p-6 shadow-sm">
      <h3 class="text-lg font-semibold text-[var(--sg-text)] mb-4">Stack State Distribution</h3>
      <div class="space-y-3">
        {#if metrics.totalStacks > 0}
          <!-- Stacked bar visualization -->
          <div class="flex h-8 rounded-md overflow-hidden">
            {#if metrics.stackStateCounts.apply_failed > 0}
              <div
                class="bg-[var(--sg-error)]"
                style="width: {getStatePercentage(metrics.stackStateCounts.apply_failed, metrics.totalStacks)}%"
                title="Apply Failed: {metrics.stackStateCounts.apply_failed}"
              ></div>
            {/if}
            {#if metrics.stackStateCounts.plan_failed > 0}
              <div
                class="bg-[var(--sg-orange)]"
                style="width: {getStatePercentage(metrics.stackStateCounts.plan_failed, metrics.totalStacks)}%"
                title="Plan Failed: {metrics.stackStateCounts.plan_failed}"
              ></div>
            {/if}
            {#if metrics.stackStateCounts.apply_pending > 0}
              <div
                class="bg-[var(--sg-purple)]"
                style="width: {getStatePercentage(metrics.stackStateCounts.apply_pending, metrics.totalStacks)}%"
                title="Apply Pending: {metrics.stackStateCounts.apply_pending}"
              ></div>
            {/if}
            {#if metrics.stackStateCounts.plan_pending > 0}
              <div
                class="bg-[var(--sg-pink)]"
                style="width: {getStatePercentage(metrics.stackStateCounts.plan_pending, metrics.totalStacks)}%"
                title="Plan Pending: {metrics.stackStateCounts.plan_pending}"
              ></div>
            {/if}
            {#if metrics.stackStateCounts.apply_ready > 0}
              <div
                class="bg-[var(--sg-accent)]"
                style="width: {getStatePercentage(metrics.stackStateCounts.apply_ready, metrics.totalStacks)}%"
                title="Apply Ready: {metrics.stackStateCounts.apply_ready}"
              ></div>
            {/if}
            {#if metrics.stackStateCounts.apply_success > 0}
              <div
                class="bg-[var(--sg-success)]"
                style="width: {getStatePercentage(metrics.stackStateCounts.apply_success, metrics.totalStacks)}%"
                title="Apply Success: {metrics.stackStateCounts.apply_success}"
              ></div>
            {/if}
            {#if metrics.stackStateCounts.no_changes > 0}
              <div
                class="bg-[var(--sg-text-dim)]"
                style="width: {getStatePercentage(metrics.stackStateCounts.no_changes, metrics.totalStacks)}%"
                title="No Changes: {metrics.stackStateCounts.no_changes}"
              ></div>
            {/if}
          </div>

          <!-- Legend -->
          <div class="grid grid-cols-2 md:grid-cols-4 gap-2 text-xs">
            <div class="flex items-center gap-2">
              <span class="w-3 h-3 rounded bg-[var(--sg-error)]"></span>
              <span class="text-[var(--sg-text-muted)]">Apply Failed: {metrics.stackStateCounts.apply_failed}</span>
            </div>
            <div class="flex items-center gap-2">
              <span class="w-3 h-3 rounded bg-[var(--sg-orange)]"></span>
              <span class="text-[var(--sg-text-muted)]">Plan Failed: {metrics.stackStateCounts.plan_failed}</span>
            </div>
            <div class="flex items-center gap-2">
              <span class="w-3 h-3 rounded bg-[var(--sg-purple)]"></span>
              <span class="text-[var(--sg-text-muted)]">Apply Pending: {metrics.stackStateCounts.apply_pending}</span>
            </div>
            <div class="flex items-center gap-2">
              <span class="w-3 h-3 rounded bg-[var(--sg-pink)]"></span>
              <span class="text-[var(--sg-text-muted)]">Plan Pending: {metrics.stackStateCounts.plan_pending}</span>
            </div>
            <div class="flex items-center gap-2">
              <span class="w-3 h-3 rounded bg-[var(--sg-accent)]"></span>
              <span class="text-[var(--sg-text-muted)]">Ready: {metrics.stackStateCounts.apply_ready}</span>
            </div>
            <div class="flex items-center gap-2">
              <span class="w-3 h-3 rounded bg-[var(--sg-success)]"></span>
              <span class="text-[var(--sg-text-muted)]">Success: {metrics.stackStateCounts.apply_success}</span>
            </div>
            <div class="flex items-center gap-2">
              <span class="w-3 h-3 rounded bg-[var(--sg-text-dim)]"></span>
              <span class="text-[var(--sg-text-muted)]">No Changes: {metrics.stackStateCounts.no_changes}</span>
            </div>
          </div>
        {:else}
          <EmptyState title="No stack state data available" />
        {/if}
      </div>
    </div>

    <!-- Two-column layout for tables -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <!-- Top Failing Stacks -->
      <div class="bg-[var(--sg-bg-1)] rounded-lg border border-[var(--sg-border)] p-6 shadow-sm">
        <h3 class="text-lg font-semibold text-[var(--sg-text)] mb-4">Top Failing Stacks</h3>
        {#if metrics.topFailingStacks.length > 0}
          <div class="space-y-2">
            {#each metrics.topFailingStacks as stack}
              <div class="flex items-center justify-between p-3 rounded-md bg-[var(--sg-bg-0)]">
                <div class="flex-1 min-w-0">
                  <div class="font-medium text-[var(--sg-text)] truncate">{stack.stackName}</div>
                  <div class="text-xs text-[var(--sg-text-dim)]">{stack.prCount} {stack.prCount === 1 ? 'PR' : 'PRs'}</div>
                </div>
                <div class="flex-shrink-0 ml-4">
                  <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-[var(--sg-error-bg)] text-[var(--sg-error)]">
                    {stack.failureCount} {stack.failureCount === 1 ? 'failure' : 'failures'}
                  </span>
                </div>
              </div>
            {/each}
          </div>
        {:else}
          <p class="text-[var(--sg-text-dim)] text-sm">No failures in this time range</p>
        {/if}
      </div>

      <!-- Top Failing Repos -->
      <div class="bg-[var(--sg-bg-1)] rounded-lg border border-[var(--sg-border)] p-6 shadow-sm">
        <h3 class="text-lg font-semibold text-[var(--sg-text)] mb-4">Top Failing Repositories</h3>
        {#if metrics.topFailingRepos.length > 0}
          <div class="space-y-2">
            {#each metrics.topFailingRepos as repo}
              <div class="flex items-center justify-between p-3 rounded-md bg-[var(--sg-bg-0)]">
                <div class="flex-1 min-w-0">
                  <div class="font-medium text-[var(--sg-text)] truncate">{repo.repo}</div>
                  <div class="text-xs text-[var(--sg-text-dim)]">{repo.prCount} {repo.prCount === 1 ? 'PR' : 'PRs'}</div>
                </div>
                <div class="flex-shrink-0 ml-4">
                  <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-[var(--sg-error-bg)] text-[var(--sg-error)]">
                    {repo.failureCount} {repo.failureCount === 1 ? 'failure' : 'failures'}
                  </span>
                </div>
              </div>
            {/each}
          </div>
        {:else}
          <p class="text-[var(--sg-text-dim)] text-sm">No failures in this time range</p>
        {/if}
      </div>
    </div>

    <!-- Open PRs -->
    <div class="bg-[var(--sg-bg-1)] rounded-lg border border-[var(--sg-border)] p-6 shadow-sm">
      <div class="flex items-center justify-between mb-4">
        <h3 class="text-lg font-semibold text-[var(--sg-text)]">Open Pull Requests</h3>
        <div class="flex items-center gap-4">
          <!-- Auto-expand toggle -->
          <div class="inline-flex items-center gap-2">
            <span class="text-sm text-[var(--sg-text-dim)]">Auto-expand latest</span>
            <button
              type="button"
              role="switch"
              aria-checked={autoExpandMostRecent}
              on:click={toggleAutoExpand}
              class="relative inline-flex h-5 w-9 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-[var(--sg-accent)] focus:ring-offset-2 {autoExpandMostRecent ? 'bg-[var(--sg-accent-button)]' : 'bg-[var(--sg-bg-2)]'}"
            >
              <span
                aria-hidden="true"
                class="pointer-events-none inline-block h-4 w-4 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out {autoExpandMostRecent ? 'translate-x-4' : 'translate-x-0'}"
              ></span>
            </button>
          </div>
          <button
            on:click={onNavigateToPRs}
            class="text-sm text-[var(--sg-accent)] hover:text-[var(--sg-accent-hover)] font-medium transition-colors"
          >
            View All →
          </button>
        </div>
      </div>
      {#if metrics.openPRs.length > 0}
        <div class="space-y-3">
          {#each metrics.openPRs as pr (pr.prNumber)}
            {@const fullPRData = getFullPRData(pr.prNumber)}
            {@const isMostRecent = mostRecentPR?.prNumber === pr.prNumber}
            <div class="rounded-lg border border-[var(--sg-border)] border-l-4 {getStateBorderColor(pr.state)} overflow-hidden">
              <!-- PR Header Row -->
              <button
                on:click={() => togglePRExpand(pr.prNumber)}
                class="w-full p-3 bg-[var(--sg-bg-0)] hover:bg-[var(--sg-bg-2)] transition-colors text-left"
              >
                <div class="flex items-start justify-between gap-3">
                  <div class="flex items-center gap-2">
                    <!-- Expand/Collapse chevron -->
                    <svg
                      class="w-4 h-4 text-[var(--sg-text-dim)] transition-transform {expandedPRs[pr.prNumber] ? 'rotate-90' : ''}"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
                    </svg>
                    <div class="flex-1 min-w-0">
                      <div class="flex items-center gap-2 mb-1">
                        {#if isMostRecent}
                          <span class="text-xs font-medium text-[var(--sg-accent)] bg-[var(--sg-accent-bg)] px-1.5 py-0.5 rounded">Latest</span>
                        {/if}
                        <span class="font-medium text-[var(--sg-text)]">
                          #{pr.prNumber}
                        </span>
                        <span class="text-sm text-[var(--sg-text-dim)] truncate">
                          {pr.prTitle}
                        </span>
                      </div>
                      <div class="flex items-center gap-3 text-xs text-[var(--sg-text-dim)]">
                        <span class="font-mono">{pr.repo}</span>
                        <span>•</span>
                        <span>{pr.stackCount} {pr.stackCount === 1 ? 'stack' : 'stacks'}</span>
                        <span>•</span>
                        <span>{formatRelativeTime(pr.lastActivity)}</span>
                      </div>
                    </div>
                  </div>
                  <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium {getStateBadgeClasses(pr.state)} flex-shrink-0">
                    {formatStateName(pr.state)}
                  </span>
                </div>
              </button>

              <!-- Expanded Content -->
              {#if expandedPRs[pr.prNumber] && fullPRData}
                <div class="p-4 bg-[var(--sg-bg-1)] border-t border-[var(--sg-border)]">
                  <!-- Stack summary counts -->
                  <div class="mb-4 bg-[var(--sg-bg-0)] rounded-md p-3">
                    <div class="flex items-center justify-between flex-wrap gap-2">
                      <div class="text-sm font-medium text-[var(--sg-text)]">
                        {fullPRData.stacks.length} {fullPRData.stacks.length === 1 ? 'Stack' : 'Stacks'}
                      </div>
                      <div class="flex items-center gap-3 text-xs flex-wrap">
                        {#if fullPRData.stackStateCounts.apply_failed > 0}
                          <div class="flex items-center gap-1 text-[var(--sg-error)]">
                            <span class="w-2 h-2 rounded-full bg-[var(--sg-error)]"></span>
                            <span>{fullPRData.stackStateCounts.apply_failed} apply failed</span>
                          </div>
                        {/if}
                        {#if fullPRData.stackStateCounts.plan_failed > 0}
                          <div class="flex items-center gap-1 text-[var(--sg-orange)]">
                            <span class="w-2 h-2 rounded-full bg-[var(--sg-orange)]"></span>
                            <span>{fullPRData.stackStateCounts.plan_failed} plan failed</span>
                          </div>
                        {/if}
                        {#if fullPRData.stackStateCounts.apply_pending > 0}
                          <div class="flex items-center gap-1 text-[var(--sg-purple)]">
                            <span class="w-2 h-2 rounded-full bg-[var(--sg-purple)]"></span>
                            <span>{fullPRData.stackStateCounts.apply_pending} apply pending</span>
                          </div>
                        {/if}
                        {#if fullPRData.stackStateCounts.apply_ready > 0}
                          <div class="flex items-center gap-1 text-[var(--sg-accent)]">
                            <span class="w-2 h-2 rounded-full bg-[var(--sg-accent)]"></span>
                            <span>{fullPRData.stackStateCounts.apply_ready} ready</span>
                          </div>
                        {/if}
                        {#if fullPRData.stackStateCounts.apply_success > 0}
                          <div class="flex items-center gap-1 text-[var(--sg-success)]">
                            <span class="w-2 h-2 rounded-full bg-[var(--sg-success)]"></span>
                            <span>{fullPRData.stackStateCounts.apply_success} success</span>
                          </div>
                        {/if}
                      </div>
                    </div>
                  </div>

                  <!-- Stacks list -->
                  <div class="space-y-2 mb-4">
                    <h4 class="text-sm font-medium text-[var(--sg-text-muted)]">Stacks</h4>
                    {#each fullPRData.stacks as stack}
                      <button
                        on:click={() => navigateToStackDetail(pr.prNumber, `${stack.stackOuter.name}/${stack.stackInner.name}`)}
                        class="w-full flex items-center justify-between p-2 rounded-md bg-[var(--sg-bg-0)] hover:bg-[var(--sg-bg-2)] transition-colors text-left"
                      >
                        <div class="flex items-center gap-2 min-w-0 flex-1">
                          <span class="flex-shrink-0 text-base" aria-hidden="true">
                            {getStackStateIcon(stack.state)}
                          </span>
                          <span class="font-medium text-[var(--sg-text)] truncate">
                            {stack.stackOuter.name}
                            {#if stack.stackOuter.name !== stack.stackInner.name}
                              <span class="text-[var(--sg-text-dim)]">/</span>
                              {stack.stackInner.name}
                            {/if}
                          </span>
                        </div>
                        <div class="flex items-center gap-2 flex-shrink-0">
                          {#if stack.recentRunsCount > 0}
                            <span class="text-xs text-[var(--sg-text-dim)]">
                              {stack.recentRunsCount} {stack.recentRunsCount === 1 ? 'run' : 'runs'}
                            </span>
                          {/if}
                          <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium {getStackStateBadgeClasses(stack.state)}">
                            {formatStateName(stack.state)}
                          </span>
                        </div>
                      </button>
                    {/each}
                  </div>

                  <!-- Footer actions -->
                  <div class="flex items-center justify-between pt-3 border-t border-[var(--sg-border)]">
                    <div class="text-xs text-[var(--sg-text-dim)]">
                      {#if fullPRData.lastUser}
                        Last activity by @{fullPRData.lastUser}
                      {/if}
                    </div>
                    <button
                      on:click={() => navigateToPRDetail(pr.prNumber, pr.repo)}
                      class="text-sm text-[var(--sg-accent)] hover:text-[var(--sg-accent-hover)] font-medium transition-colors"
                    >
                      View Full PR →
                    </button>
                  </div>
                </div>
              {/if}
            </div>
          {/each}
        </div>
      {:else}
        <EmptyState title="No open pull requests" />
      {/if}
    </div>

    <!-- Activity Over Time -->
    <div class="bg-[var(--sg-bg-1)] rounded-lg border border-[var(--sg-border)] p-6 shadow-sm">
      <h3 class="text-lg font-semibold text-[var(--sg-text)] mb-4">Activity Over Time ({metrics.timeRange} days)</h3>
      {#if metrics.activityByDay.length > 0}
        <!-- Simple bar chart using CSS -->
        <div class="space-y-2">
          {#each metrics.activityByDay as day}
            {@const maxRuns = Math.max(...metrics.activityByDay.map(d => d.runs))}
            {@const barWidth = maxRuns > 0 ? (day.runs / maxRuns) * 100 : 0}
            <div class="flex items-center gap-3">
              <div class="text-xs text-[var(--sg-text-dim)] w-20 flex-shrink-0">{formatDate(day.date)}</div>
              <div class="flex-1">
                <div class="flex items-center gap-2">
                  <div class="flex-1 bg-[var(--sg-bg-2)] rounded-full h-6 overflow-hidden">
                    <div
                      class="bg-[var(--sg-accent)] h-full rounded-full transition-all duration-300"
                      style="width: {barWidth}%"
                    ></div>
                  </div>
                  <div class="text-xs text-[var(--sg-text-muted)] w-16 text-right">
                    {day.runs} runs
                  </div>
                </div>
              </div>
            </div>
          {/each}
        </div>
      {:else}
        <EmptyState title="No activity data available" />
      {/if}
    </div>
  </div>
{/if}
