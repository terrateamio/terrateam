<script lang="ts">
  import PageLayout from './components/layout/PageLayout.svelte';
  import StackTree from './components/pullrequests/StackTree.svelte';
  import Card from './components/ui/Card.svelte';
  import Button from './components/ui/Button.svelte';
  import type { Stacks, Dirspace, PullRequest } from './types';
  import { api } from './api';
  import { selectedInstallation, currentVCSProvider } from './stores';
  import { navigateToPRDetail, navigateToStacks, navigateToRun } from './utils/navigation';
  import { onMount } from 'svelte';

  export let params: {
    prNumber: string;
    stackName: string;
  } = { prNumber: '', stackName: '' };

  // Data state
  let stacks: Stacks | null = null;
  let runs: Dirspace[] = [];
  let prInfo: PullRequest | null = null;
  let isLoadingStacks: boolean = true;
  let isLoadingRuns: boolean = true;
  let isLoadingPR: boolean = true;
  let error: string | null = null;

  /**
   * Loads stack detail data
   */
  async function loadStackDetail(): Promise<void> {
    if (!$selectedInstallation || !params.prNumber) {
      error = 'Missing required parameters';
      isLoadingStacks = false;
      isLoadingRuns = false;
      isLoadingPR = false;
      return;
    }

    const prNumber = parseInt(params.prNumber, 10);
    if (isNaN(prNumber)) {
      error = 'Invalid PR number';
      isLoadingStacks = false;
      isLoadingRuns = false;
      isLoadingPR = false;
      return;
    }

    isLoadingStacks = true;
    isLoadingRuns = true;
    isLoadingPR = true;
    error = null;

    try {
      // Load runs for this PR to get repo info
      const runsQuery = `pr:${prNumber}`;
      const runsParams = {
        tz: Intl.DateTimeFormat().resolvedOptions().timeZone,
        q: runsQuery,
        limit: 50,
      };

      const runsResponse = await api.getInstallationDirspaces(
        $selectedInstallation.id,
        runsParams,
        $currentVCSProvider
      );

      if (runsResponse && 'dirspaces' in runsResponse) {
        runs = runsResponse.dirspaces as Dirspace[];
      }

      isLoadingRuns = false;

      // Get repo ID from first run (using dirspace.id, not run_id)
      if (runs.length > 0 && runs[0].id) {
        const workManifest = await api.getWorkManifest(
          $selectedInstallation.id,
          runs[0].id,
          $currentVCSProvider
        );

        if (workManifest && workManifest.repo_id) {
          // Load stacks for this PR
          stacks = await api.getPullRequestStacks(
            $selectedInstallation.id,
            workManifest.repo_id,
            params.prNumber,
            $currentVCSProvider
          );
        }
      }

      isLoadingStacks = false;

      // Load PR metadata
      try {
        const prResponse = await api.getInstallationPullRequests(
          $selectedInstallation.id,
          { pr: prNumber },
          $currentVCSProvider
        );

        if (prResponse && prResponse.pull_requests && prResponse.pull_requests.length > 0) {
          prInfo = prResponse.pull_requests[0];
        }
      } catch (prError) {
        console.warn('Failed to load PR metadata:', prError);
      }

      isLoadingPR = false;
    } catch (err) {
      error = err instanceof Error ? err.message : 'Failed to load stack detail';
      console.error('Error loading stack detail:', err);
      isLoadingStacks = false;
      isLoadingRuns = false;
      isLoadingPR = false;
    }
  }

  /**
   * Refreshes all data
   */
  function refresh(): void {
    loadStackDetail();
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
   * Gets badge classes for PR state
   */
  function getPRStateBadgeClasses(state: string): string {
    switch (state) {
      case 'open':
        return 'bg-green-100 dark:bg-green-900/30 text-green-800 dark:text-green-400';
      case 'merged':
        return 'bg-purple-100 dark:bg-purple-900/30 text-purple-800 dark:text-purple-400';
      case 'closed':
        return 'bg-gray-100 dark:bg-gray-700 text-gray-800 dark:text-gray-300';
      default:
        return 'bg-gray-100 dark:bg-gray-700 text-gray-800 dark:text-gray-300';
    }
  }

  // Load on mount
  onMount(() => {
    loadStackDetail();
  });
</script>

<PageLayout activeItem="stacks" title="Stack Detail">
  <div class="space-y-6">
    <!-- Breadcrumb navigation -->
    <nav class="flex items-center space-x-2 text-sm text-gray-500 dark:text-gray-400">
      <button
        on:click={() => navigateToStacks()}
        class="hover:text-gray-700 dark:hover:text-gray-300 transition-colors"
      >
        Stacks
      </button>
      <span>/</span>
      <span class="text-gray-900 dark:text-gray-100">
        PR #{params.prNumber}
        {#if params.stackName}
          - {decodeURIComponent(params.stackName)}
        {/if}
      </span>
    </nav>

    <!-- PR Info Card -->
    {#if !isLoadingPR && prInfo}
      <Card padding="md">
        <div class="flex items-start justify-between">
          <div class="flex-1">
            <div class="flex items-center gap-2 mb-2">
              <h2 class="text-xl font-semibold text-gray-900 dark:text-gray-100">
                PR #{prInfo.pull_number}: {prInfo.title || 'Untitled'}
              </h2>
              <span
                class="inline-flex items-center px-2 py-1 rounded-md text-xs font-medium {getPRStateBadgeClasses(
                  prInfo.state
                )}"
              >
                {prInfo.state}
              </span>
            </div>
            <div class="flex items-center gap-4 text-sm text-gray-600 dark:text-gray-400">
              <div>
                <span class="font-medium">Branch:</span> {prInfo.branch} → {prInfo.base_branch}
              </div>
              {#if prInfo.user}
                <div>
                  <span class="font-medium">Author:</span> @{prInfo.user}
                </div>
              {/if}
            </div>
          </div>
          <Button variant="outline" size="sm" on:click={() => navigateToPRDetail(parseInt(params.prNumber, 10))}>
            View Full PR
          </Button>
        </div>
      </Card>
    {/if}

    <!-- Stacks Tree -->
    <Card padding="md">
      <div class="flex items-center justify-between mb-4">
        <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100">
          Infrastructure Stacks
        </h3>
        <Button
          variant="outline"
          size="sm"
          on:click={refresh}
          disabled={isLoadingStacks}
        >
          {#if isLoadingStacks}
            <span class="animate-spin inline-block mr-2">⟳</span>
          {/if}
          Refresh
        </Button>
      </div>

      <StackTree {stacks} loading={isLoadingStacks} {error} />
    </Card>

    <!-- Runs History -->
    <Card padding="md">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-4">
        Run History ({runs.length})
      </h3>

      {#if isLoadingRuns}
        <div class="flex items-center justify-center py-8">
          <div
            class="animate-spin rounded-full h-8 w-8 border-b-2 border-brand-primary"
            role="status"
            aria-label="Loading runs"
          >
            <span class="sr-only">Loading runs...</span>
          </div>
        </div>
      {:else if runs.length > 0}
        <div class="overflow-x-auto">
          <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
            <thead class="bg-gray-50 dark:bg-gray-900/50">
              <tr>
                <th
                  scope="col"
                  class="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider"
                >
                  Time
                </th>
                <th
                  scope="col"
                  class="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider"
                >
                  Type
                </th>
                <th
                  scope="col"
                  class="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider"
                >
                  Directory
                </th>
                <th
                  scope="col"
                  class="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider"
                >
                  Workspace
                </th>
                <th
                  scope="col"
                  class="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider"
                >
                  State
                </th>
                <th
                  scope="col"
                  class="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider"
                >
                  User
                </th>
                <th scope="col" class="relative px-4 py-3">
                  <span class="sr-only">Actions</span>
                </th>
              </tr>
            </thead>
            <tbody class="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
              {#each runs as run}
                <tr class="hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-colors">
                  <td class="px-4 py-3 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100">
                    {formatRelativeTime(run.created_at)}
                  </td>
                  <td class="px-4 py-3 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100">
                    {run.run_type}
                  </td>
                  <td class="px-4 py-3 text-sm font-mono text-gray-900 dark:text-gray-100">
                    {run.dir}
                  </td>
                  <td class="px-4 py-3 whitespace-nowrap text-sm text-gray-700 dark:text-gray-300">
                    {run.workspace}
                  </td>
                  <td class="px-4 py-3 whitespace-nowrap">
                    <span
                      class="inline-flex items-center px-2 py-1 rounded text-xs font-medium {getRunStateBadgeClasses(
                        run.state
                      )}"
                    >
                      {run.state}
                    </span>
                  </td>
                  <td class="px-4 py-3 whitespace-nowrap text-sm text-gray-700 dark:text-gray-300">
                    {#if run.user}
                      @{run.user}
                    {:else}
                      -
                    {/if}
                  </td>
                  <td class="px-4 py-3 whitespace-nowrap text-right text-sm font-medium">
                    {#if run.run_id}
                      <button
                        on:click={() => navigateToRun(run.run_id || '')}
                        class="text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 transition-colors"
                      >
                        View
                      </button>
                    {/if}
                  </td>
                </tr>
              {/each}
            </tbody>
          </table>
        </div>
      {:else}
        <div class="text-center py-8 text-gray-500 dark:text-gray-400">
          No runs found for this pull request.
        </div>
      {/if}
    </Card>

    <!-- Error state -->
    {#if error}
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
              Error loading stack detail
            </h3>
            <div class="mt-2 text-sm text-red-700 dark:text-red-300">
              {error}
            </div>
            <button
              on:click={refresh}
              class="mt-3 text-sm font-medium text-red-800 dark:text-red-400 hover:text-red-900 dark:hover:text-red-300 underline"
            >
              Try again
            </button>
          </div>
        </div>
      </div>
    {/if}
  </div>
</PageLayout>
