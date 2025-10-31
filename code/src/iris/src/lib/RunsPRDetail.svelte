<script lang="ts">
  import type { Dirspace, PullRequest, Stacks } from './types';
  import PageLayout from './components/layout/PageLayout.svelte';
  import { Button, Card, LoadingSpinner, ErrorMessage } from './components';
  import { StackTree } from './components/pullrequests';
  import { api, isApiError } from './api';
  import { selectedInstallation } from './stores';
  import { navigateToRuns, navigateToRun } from './utils/navigation';
  import { onMount } from 'svelte';

  export let params: { installationId?: string; prNumber?: string } = {};

  let pullRequest: PullRequest | null = null;
  let stacks: Stacks | null = null;
  let runs: Dirspace[] = [];
  let repoId: string | null = null; // Store repo_id for stacks API

  let isPRLoading: boolean = false;
  let isStacksLoading: boolean = false;
  let isRunsLoading: boolean = false;

  let prError: string | null = null;
  let stacksError: string | null = null;
  let runsError: string | null = null;

  $: prNumber = params.prNumber ? parseInt(params.prNumber) : null;

  // Check if user came from a specific run detail page
  let lastRunId: string | null = null;
  $: if (typeof window !== 'undefined') {
    lastRunId = sessionStorage.getItem('lastRunId');
  }

  // Dynamic back button label based on navigation context
  $: backButtonLabel = lastRunId ? 'Back to Run Details' : 'Back to Runs';

  // Load PR data when installation or PR number changes
  $: if ($selectedInstallation && prNumber) {
    loadPullRequest();
    loadPRRuns();
  }

  async function loadPullRequest(): Promise<void> {
    if (!$selectedInstallation || !prNumber) return;

    isPRLoading = true;
    prError = null;

    try {
      // Get PR metadata using the PR filter
      const response = await api.getInstallationPullRequests($selectedInstallation.id, { pr: prNumber });

      if (response.pull_requests.length > 0) {
        pullRequest = response.pull_requests[0];
        // Don't load stacks yet - we need repo_id from runs first
      } else {
        prError = `Pull request #${prNumber} not found`;
      }
    } catch (err) {
      if (isApiError(err)) {
        prError = `Failed to load pull request: ${err.message}`;
      } else {
        prError = 'An unexpected error occurred while loading pull request';
      }
      console.error('Error loading pull request:', err);
    } finally {
      isPRLoading = false;
    }
  }

  async function loadStacks(repoId: string): Promise<void> {
    if (!$selectedInstallation || !prNumber) return;

    isStacksLoading = true;
    stacksError = null;

    try {
      const prId = prNumber.toString();
      stacks = await api.getPullRequestStacks($selectedInstallation.id, repoId, prId);
    } catch (err) {
      if (isApiError(err)) {
        if (err.status === 404) {
          // No stacks configured for this PR is not really an error
          stacksError = null;
          stacks = { stacks: [] };
        } else {
          stacksError = `Failed to load stacks: ${err.message}`;
        }
      } else {
        stacksError = 'An unexpected error occurred while loading stacks';
        console.error('Unexpected error loading stacks:', err);
      }
    } finally {
      isStacksLoading = false;
    }
  }

  async function loadPRRuns(): Promise<void> {
    if (!$selectedInstallation || !prNumber) return;

    isRunsLoading = true;
    runsError = null;

    try {
      // Use Tag Query Language to filter runs for this PR
      const query = `pr:${prNumber}`;
      const params = {
        tz: Intl.DateTimeFormat().resolvedOptions().timeZone,
        q: query,
        limit: 50
      };

      const response = await api.getInstallationDirspaces($selectedInstallation.id, params);

      if (response && 'dirspaces' in response) {
        runs = response.dirspaces as Dirspace[];

        if (runs.length > 0) {
          // Get repo_id from the first run's work manifest and load stacks
          await loadStacksFromWorkManifest(runs[0].id);
        }
      } else {
        runs = [];
      }
    } catch (err) {
      if (isApiError(err)) {
        runsError = `Failed to load runs: ${err.message}`;
      } else {
        runsError = 'An unexpected error occurred while loading runs';
      }
      console.error('Error loading PR runs:', err);
    } finally {
      isRunsLoading = false;
    }
  }

  async function loadStacksFromWorkManifest(runId: string): Promise<void> {
    try {
      // Get the work manifest to extract repo_id (GitHub's repository ID)
      const workManifest = await api.getInstallationWorkManifest($selectedInstallation!.id, runId);

      if (workManifest && workManifest.repo_id) {
        // Store repo_id for later use (refresh)
        repoId = workManifest.repo_id;

        // Now we have the correct repo_id (GitHub's repo ID), load stacks
        loadStacks(repoId);
      } else {
        stacks = { stacks: [] };
        stacksError = null;
        isStacksLoading = false;
      }
    } catch (err) {
      console.error('Could not load work manifest for repo_id:', err);
      // If we can't get repo_id, just skip loading stacks
      stacks = { stacks: [] };
      stacksError = null;
      isStacksLoading = false;
    }
  }

  function getPRStateBadgeClass(state: string): string {
    switch (state) {
      case 'open':
        return 'bg-green-100 dark:bg-green-900/30 text-green-800 dark:text-green-400';
      case 'closed':
        return 'bg-red-100 dark:bg-red-900/30 text-red-800 dark:text-red-400';
      case 'merged':
        return 'bg-purple-100 dark:bg-purple-900/30 text-purple-800 dark:text-purple-400';
      default:
        return 'bg-gray-100 dark:bg-gray-700 text-gray-800 dark:text-gray-300';
    }
  }

  function getStateColor(state: string): string {
    switch (state) {
      case 'success': return 'bg-green-100 dark:bg-green-900/30 text-green-800 dark:text-green-400';
      case 'failure': return 'bg-red-100 dark:bg-red-900/30 text-red-800 dark:text-red-400';
      case 'running': return 'bg-blue-100 dark:bg-blue-900/30 text-blue-800 dark:text-blue-400';
      case 'pending': return 'bg-yellow-100 dark:bg-yellow-900/30 text-yellow-800 dark:text-yellow-400';
      case 'queued': return 'bg-gray-100 dark:bg-gray-700 text-gray-800 dark:text-gray-300';
      case 'aborted': return 'bg-gray-100 dark:bg-gray-700 text-gray-800 dark:text-gray-300';
      default: return 'bg-gray-100 dark:bg-gray-700 text-gray-800 dark:text-gray-300';
    }
  }

  function formatDateTime(dateString: string): string {
    const date = new Date(dateString);
    const now = new Date();
    const diffInSeconds = Math.floor((now.getTime() - date.getTime()) / 1000);

    if (diffInSeconds < 60) return 'just now';
    if (diffInSeconds < 3600) return `${Math.floor(diffInSeconds / 60)}m ago`;
    if (diffInSeconds < 86400) return `${Math.floor(diffInSeconds / 3600)}h ago`;
    if (diffInSeconds < 604800) return `${Math.floor(diffInSeconds / 86400)}d ago`;

    return date.toLocaleDateString();
  }

  function handleRefreshStacks(): void {
    if (repoId) {
      loadStacks(repoId);
    }
  }

  function handleRefreshRuns(): void {
    loadPRRuns();
  }

  function handleBackToRuns(): void {
    // Check if we have a stored run ID to return to
    const storedRunId = typeof window !== 'undefined' ? sessionStorage.getItem('lastRunId') : null;

    if (storedRunId) {
      // Clear the stored run ID to prevent stale state
      sessionStorage.removeItem('lastRunId');
      // Navigate back to the specific run detail page
      navigateToRun(storedRunId);
    } else {
      // Fall back to runs list with PR filter
      navigateToRuns(`pr:${prNumber}`, $selectedInstallation?.id);
    }
  }

  function getGitHubPRUrl(): string | null {
    if (!pullRequest) return null;
    return `https://github.com/${pullRequest.owner}/${pullRequest.name}/pull/${pullRequest.pull_number}`;
  }

  function getRunDetailHref(runId: string): string {
    if ($selectedInstallation) {
      return `#/i/${$selectedInstallation.id}/runs/${runId}`;
    }
    return `#/runs/${runId}`;
  }

  onMount(() => {
    if ($selectedInstallation && prNumber) {
      loadPullRequest();
      loadPRRuns();
    }
  });
</script>

<PageLayout
  activeItem="runs"
  title={pullRequest ? `PR #${pullRequest.pull_number}` : `PR #${prNumber || ''}`}
  subtitle={pullRequest?.title || 'Loading pull request details...'}
>
  <!-- Back Button -->
  <div class="mb-4">
    <Button variant="ghost" size="sm" on:click={handleBackToRuns}>
      <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
      </svg>
      {backButtonLabel}
    </Button>
  </div>

  {#if isPRLoading}
    <LoadingSpinner size="lg" centered={true} />
  {:else if prError}
    <ErrorMessage type="error" message={prError} />
  {:else if pullRequest}
    <!-- PR Information Card -->
    <Card padding="md" class="mb-6">
      <div class="flex items-start justify-between mb-4">
        <div class="flex-1">
          <div class="flex items-center gap-3 mb-3">
            <h2 class="text-2xl font-semibold text-gray-900 dark:text-gray-100">
              #{pullRequest.pull_number} {pullRequest.title || 'Untitled'}
            </h2>
            <span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium {getPRStateBadgeClass(pullRequest.state)}">
              {pullRequest.state.charAt(0).toUpperCase() + pullRequest.state.slice(1)}
            </span>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
            <div>
              <span class="font-medium text-gray-700 dark:text-gray-300">Repository:</span>
              <span class="text-gray-600 dark:text-gray-400 ml-2">
                {pullRequest.owner}/{pullRequest.name}
              </span>
            </div>

            <div>
              <span class="font-medium text-gray-700 dark:text-gray-300">Branches:</span>
              <span class="text-gray-600 dark:text-gray-400 ml-2">
                {pullRequest.branch} → {pullRequest.base_branch}
              </span>
            </div>

            {#if pullRequest.user}
              <div>
                <span class="font-medium text-gray-700 dark:text-gray-300">Author:</span>
                <span class="text-gray-600 dark:text-gray-400 ml-2">
                  {pullRequest.user}
                </span>
              </div>
            {/if}

            {#if pullRequest.merged_at}
              <div>
                <span class="font-medium text-gray-700 dark:text-gray-300">Merged:</span>
                <span class="text-gray-600 dark:text-gray-400 ml-2">
                  {new Date(pullRequest.merged_at).toLocaleString()}
                </span>
              </div>
            {/if}
          </div>
        </div>
      </div>

      <!-- Quick Actions -->
      <div class="flex flex-wrap gap-3 pt-4 border-t border-gray-200 dark:border-gray-700">
        {#if getGitHubPRUrl()}
          <Button
            variant="outline"
            size="md"
            on:click={() => {
              const url = getGitHubPRUrl();
              if (url) window.open(url, '_blank');
            }}
          >
            <svg class="w-4 h-4 mr-2" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M10 0C4.477 0 0 4.484 0 10.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0110 4.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.203 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.942.359.31.678.921.678 1.856 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0020 10.017C20 4.484 15.522 0 10 0z" clip-rule="evenodd" />
            </svg>
            View on GitHub
          </Button>
        {/if}
        <Button variant="outline" size="md" on:click={handleRefreshStacks}>
          <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
          </svg>
          Refresh Stacks
        </Button>
        <Button variant="outline" size="md" on:click={handleRefreshRuns}>
          <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
          </svg>
          Refresh Runs
        </Button>
      </div>
    </Card>

    <!-- Stacks Section -->
    <div class="mb-6">
      <div class="flex items-center justify-between mb-4">
        <h2 class="text-xl font-semibold text-gray-900 dark:text-gray-100">
          Infrastructure Stacks
        </h2>
      </div>

      <StackTree
        {stacks}
        loading={isStacksLoading}
        error={stacksError}
      />
    </div>

    <!-- Runs Section -->
    <div class="mb-6">
      <div class="flex items-center justify-between mb-4">
        <h2 class="text-xl font-semibold text-gray-900 dark:text-gray-100">
          Terraform Runs
        </h2>
      </div>

      {#if isRunsLoading}
        <div class="flex justify-center py-12">
          <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-brand-primary"></div>
        </div>
      {:else if runsError}
        <ErrorMessage type="error" message={runsError} />
      {:else if runs.length === 0}
        <Card padding="md">
          <div class="text-center py-12">
            <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4" />
            </svg>
            <h3 class="mt-2 text-sm font-semibold text-gray-900 dark:text-gray-100">No runs found</h3>
            <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
              This pull request doesn't have any Terraform runs yet.
            </p>
          </div>
        </Card>
      {:else}
        <Card padding="none">
          <div class="divide-y divide-gray-200 dark:divide-gray-700">
            {#each runs as run}
              <a
                href={getRunDetailHref(run.id)}
                on:click={(e) => {
                  // Allow middle-click and Ctrl/Cmd+click to open in new tab
                  if (e.button !== 0 || e.ctrlKey || e.metaKey) {
                    return;
                  }
                  e.preventDefault();
                  navigateToRun(run.id);
                }}
                class="block w-full text-left p-4 md:p-6 hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors cursor-pointer"
              >
                <div class="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-3">
                  <div class="flex-1">
                    <div class="mb-2">
                      <div class="flex items-start gap-2 flex-wrap">
                        <!-- Plan/Apply Visual Indicator -->
                        {#if run.run_type === 'plan'}
                          <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300 border border-blue-200 dark:border-blue-700 flex-shrink-0">
                            📋 Plan
                          </span>
                        {:else if run.run_type === 'apply'}
                          <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-300 border border-green-200 dark:border-green-700 flex-shrink-0">
                            🚀 Apply
                          </span>
                        {:else}
                          <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 border border-gray-200 dark:border-gray-600 flex-shrink-0">
                            {run.run_type}
                          </span>
                        {/if}

                        <!-- Path and details on separate line if needed -->
                        <div class="flex items-center gap-1 flex-wrap">
                          <span class="text-sm text-gray-700 dark:text-gray-300">{run.branch}</span>
                          {#if run.dir}
                            <span class="text-xs text-gray-400 dark:text-gray-500">•</span>
                            <span class="text-xs text-gray-600 dark:text-gray-400 font-mono break-all">{run.dir}</span>
                          {/if}
                          {#if run.workspace && run.workspace !== 'default'}
                            <span class="text-xs text-gray-400 dark:text-gray-500">•</span>
                            <span class="text-xs text-gray-600 dark:text-gray-400">workspace: {run.workspace}</span>
                          {/if}
                          {#if run.environment}
                            <span class="text-xs text-gray-400 dark:text-gray-500">•</span>
                            <span class="text-xs text-gray-600 dark:text-gray-400">env: {run.environment}</span>
                          {/if}
                        </div>
                      </div>
                    </div>
                    <div class="text-xs text-gray-500 dark:text-gray-400">
                      {formatDateTime(run.created_at)}
                      {#if run.user}
                        • by {run.user}
                      {/if}
                    </div>
                  </div>
                  <div class="flex items-center gap-2 self-start">
                    <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium {getStateColor(run.state)}">
                      {run.state}
                    </span>
                    <svg class="w-4 h-4 text-gray-400 dark:text-gray-500 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
                    </svg>
                  </div>
                </div>
              </a>
            {/each}
          </div>
        </Card>
      {/if}
    </div>
  {/if}
</PageLayout>
