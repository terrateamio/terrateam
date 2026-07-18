<script lang="ts">
  import type { Dirspace, PullRequest, Stacks } from './types';
  import PageLayout from './components/layout/PageLayout.svelte';
  import { Button, Card, LoadingSpinner, ErrorMessage } from './components';
  import { StackTree } from './components/pullrequests';
  import { api, isApiError } from './api';
  import { selectedInstallation, currentVCSProvider } from './stores';
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

  // Only surface the Stacks section when the pull request actually has stacks.
  // Reviewers arriving from a pull request comment want the runs; an empty
  // stacks tree is surprising noise.
  $: hasStacks = (stacks?.stacks?.length ?? 0) > 0;

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
      stacks = await api.getPullRequestStacks($selectedInstallation.id, repoId, prId, $currentVCSProvider);
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
      // Get the work manifest to extract repo_id (VCS provider's repository ID)
      const workManifest = await api.getInstallationWorkManifest($selectedInstallation!.id, runId);

      if (workManifest && workManifest.repo_id) {
        // Store repo_id for later use (refresh)
        repoId = workManifest.repo_id;

        // Now we have the correct repo_id, load stacks
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
        return 'bg-[var(--sg-success-bg)] text-[var(--sg-success)]';
      case 'closed':
        return 'bg-[var(--sg-error-bg)] text-[var(--sg-error)]';
      case 'merged':
        return 'bg-[var(--sg-purple-bg)] text-[var(--sg-purple)]';
      default:
        return 'bg-[var(--sg-bg-2)] text-[var(--sg-text)]';
    }
  }

  function getStateColor(state: string): string {
    switch (state) {
      case 'success': return 'bg-[var(--sg-success-bg)] text-[var(--sg-success)]';
      case 'failure': return 'bg-[var(--sg-error-bg)] text-[var(--sg-error)]';
      case 'running': return 'bg-[var(--sg-accent-bg)] text-[var(--sg-accent)]';
      case 'pending': return 'bg-[var(--sg-warning-bg)] text-[var(--sg-warning)]';
      case 'queued': return 'bg-[var(--sg-bg-2)] text-[var(--sg-text)]';
      case 'aborted': return 'bg-[var(--sg-bg-2)] text-[var(--sg-text)]';
      default: return 'bg-[var(--sg-bg-2)] text-[var(--sg-text)]';
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

  function getPRUrl(): string | null {
    if (!pullRequest) return null;

    // GitHub URL format
    if ($currentVCSProvider === 'github') {
      return `https://github.com/${pullRequest.owner}/${pullRequest.name}/pull/${pullRequest.pull_number}`;
    }

    // GitLab URL format
    if ($currentVCSProvider === 'gitlab') {
      return `https://gitlab.com/${pullRequest.owner}/${pullRequest.name}/-/merge_requests/${pullRequest.pull_number}`;
    }

    return null;
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
            <h2 class="text-2xl font-semibold text-[var(--sg-text)]">
              #{pullRequest.pull_number} {pullRequest.title || 'Untitled'}
            </h2>
            <span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium {getPRStateBadgeClass(pullRequest.state)}">
              {pullRequest.state.charAt(0).toUpperCase() + pullRequest.state.slice(1)}
            </span>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
            <div>
              <span class="font-medium text-[var(--sg-text-muted)]">Repository:</span>
              <span class="text-[var(--sg-text-dim)] ml-2">
                {pullRequest.owner}/{pullRequest.name}
              </span>
            </div>

            <div>
              <span class="font-medium text-[var(--sg-text-muted)]">Branches:</span>
              <span class="text-[var(--sg-text-dim)] ml-2">
                {pullRequest.branch} → {pullRequest.base_branch}
              </span>
            </div>

            {#if pullRequest.user}
              <div>
                <span class="font-medium text-[var(--sg-text-muted)]">Author:</span>
                <span class="text-[var(--sg-text-dim)] ml-2">
                  {pullRequest.user}
                </span>
              </div>
            {/if}

            {#if pullRequest.merged_at}
              <div>
                <span class="font-medium text-[var(--sg-text-muted)]">Merged:</span>
                <span class="text-[var(--sg-text-dim)] ml-2">
                  {new Date(pullRequest.merged_at).toLocaleString()}
                </span>
              </div>
            {/if}
          </div>
        </div>
      </div>

      <!-- Quick Actions -->
      <div class="flex flex-wrap gap-3 pt-4 border-t border-[var(--sg-border)]">
        {#if getPRUrl()}
          <Button
            variant="outline"
            size="md"
            on:click={() => {
              const url = getPRUrl();
              if (url) window.open(url, '_blank');
            }}
          >
            <svg class="w-4 h-4 mr-2" fill="currentColor" viewBox="0 0 20 20">
              {#if $currentVCSProvider === 'github'}
                <path fill-rule="evenodd" d="M10 0C4.477 0 0 4.484 0 10.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0110 4.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.203 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.942.359.31.678.921.678 1.856 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0020 10.017C20 4.484 15.522 0 10 0z" clip-rule="evenodd" />
              {:else}
                <path d="M10 0L13.09 3.26L17.27 3.29L15.77 7.03L18.18 10L15.77 12.97L17.27 16.71L13.09 16.74L10 20L6.91 16.74L2.73 16.71L4.23 12.97L1.82 10L4.23 7.03L2.73 3.29L6.91 3.26L10 0Z" />
              {/if}
            </svg>
            View on {$currentVCSProvider === 'github' ? 'GitHub' : 'GitLab'}
          </Button>
        {/if}
        {#if hasStacks}
          <Button variant="outline" size="md" on:click={handleRefreshStacks}>
            <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
            </svg>
            Refresh Stacks
          </Button>
        {/if}
        <Button variant="outline" size="md" on:click={handleRefreshRuns}>
          <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
          </svg>
          Refresh Runs
        </Button>
      </div>
    </Card>

    <!-- Runs Section -->
    <div class="mb-6">
      <div class="flex items-center justify-between mb-4">
        <h2 class="text-xl font-semibold text-[var(--sg-text)]">
          Terraform Runs
        </h2>
      </div>

      {#if isRunsLoading}
        <LoadingSpinner size="xl" />
      {:else if runsError}
        <ErrorMessage type="error" message={runsError} />
      {:else if runs.length === 0}
        <Card padding="md">
          <div class="text-center py-12">
            <svg class="mx-auto h-12 w-12 text-[var(--sg-text-dim)]" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4" />
            </svg>
            <h3 class="mt-2 text-sm font-semibold text-[var(--sg-text)]">No runs found</h3>
            <p class="mt-1 text-sm text-[var(--sg-text-dim)]">
              This pull request doesn't have any Terraform runs yet.
            </p>
          </div>
        </Card>
      {:else}
        <Card padding="none">
          <div class="divide-y divide-[var(--sg-border)]">
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
                class="block w-full text-left p-4 md:p-6 hover:bg-[var(--sg-bg-2)] transition-colors cursor-pointer"
              >
                <div class="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-3">
                  <div class="flex-1">
                    <div class="mb-2">
                      <div class="flex items-start gap-2 flex-wrap">
                        <!-- Plan/Apply Visual Indicator -->
                        {#if run.run_type === 'plan'}
                          <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-[var(--sg-accent-bg)] text-[var(--sg-accent)] border border-[var(--sg-accent)] flex-shrink-0">
                            📋 Plan
                          </span>
                        {:else if run.run_type === 'apply'}
                          <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-[var(--sg-success-bg)] text-[var(--sg-success)] border border-[var(--sg-success)] flex-shrink-0">
                            🚀 Apply
                          </span>
                        {:else}
                          <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-[var(--sg-bg-2)] text-[var(--sg-text-muted)] border border-[var(--sg-border)] flex-shrink-0">
                            {run.run_type}
                          </span>
                        {/if}

                        <!-- Path and details on separate line if needed -->
                        <div class="flex items-center gap-1 flex-wrap">
                          <span class="text-sm text-[var(--sg-text-muted)]">{run.branch}</span>
                          {#if run.dir}
                            <span class="text-xs text-[var(--sg-text-dim)]">•</span>
                            <span class="text-xs text-[var(--sg-text-dim)] font-mono break-all">{run.dir}</span>
                          {/if}
                          {#if run.workspace && run.workspace !== 'default'}
                            <span class="text-xs text-[var(--sg-text-dim)]">•</span>
                            <span class="text-xs text-[var(--sg-text-dim)]">workspace: {run.workspace}</span>
                          {/if}
                          {#if run.environment}
                            <span class="text-xs text-[var(--sg-text-dim)]">•</span>
                            <span class="text-xs text-[var(--sg-text-dim)]">env: {run.environment}</span>
                          {/if}
                        </div>
                      </div>
                    </div>
                    <div class="text-xs text-[var(--sg-text-dim)]">
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
                    <svg class="w-4 h-4 text-[var(--sg-text-dim)] flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
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

    {#if hasStacks}
      <!-- Stacks Section -->
      <div class="mb-6">
        <div class="flex items-center justify-between mb-4">
          <h2 class="text-xl font-semibold text-[var(--sg-text)]">
            Infrastructure Stacks
          </h2>
        </div>

        <StackTree
          {stacks}
          loading={isStacksLoading}
          error={stacksError}
        />
      </div>
    {/if}
  {/if}
</PageLayout>
