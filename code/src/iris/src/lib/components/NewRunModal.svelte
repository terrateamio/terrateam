<script lang="ts">
  import { onMount, createEventDispatcher } from 'svelte';
  import { api, isApiError } from '../api';
  import type { Repository } from '../types';
  import Button from './ui/Button.svelte';

  export let installationId: string;

  const dispatch = createEventDispatcher<{
    close: void;
    created: { work_manifest_id?: string };
  }>();

  let repositories: Repository[] = [];
  let isLoadingRepos: boolean = true;
  let selectedRepo: string = '';
  let branch: string = '';
  let tagQuery: string = '';
  let isSubmitting: boolean = false;
  let error: string | null = null;

  onMount(async () => {
    try {
      const response = await api.getInstallationRepos(installationId);
      repositories = response.repositories;
    } catch (err) {
      error = 'Failed to load repositories. Please try again.';
    } finally {
      isLoadingRepos = false;
    }
  });

  $: isValid = selectedRepo.length > 0;

  async function handleSubmit(): Promise<void> {
    if (!isValid) return;

    isSubmitting = true;
    error = null;

    try {
      const params: { repo_name: string; branch?: string; operation: 'plan'; tag_query?: string } = {
        repo_name: selectedRepo,
        operation: 'plan',
      };

      if (branch.trim()) {
        params.branch = branch.trim();
      }

      if (tagQuery.trim()) {
        params.tag_query = tagQuery.trim();
      }

      const result = await api.createAdhocRun(installationId, params);

      if (result.work_manifest_id) {
        window.location.hash = `#/i/${installationId}/runs/${result.work_manifest_id}`;
      }
      dispatch('created', { work_manifest_id: result.work_manifest_id });
    } catch (err) {
      console.error('Failed to create ad-hoc run:', err);
      if (isApiError(err)) {
        if (err.status === 403) {
          error = 'You do not have permission to create runs for this repository.';
        } else if (err.status === 404) {
          error = 'Repository not found. Please check the repository name and try again.';
        } else {
          error = `Failed to create run: ${err.message}`;
        }
      } else {
        error = 'An unexpected error occurred. Please check your network connection and try again.';
      }
      isSubmitting = false;
    }
  }

  function handleClose(): void {
    dispatch('close');
  }

  function handleKeydown(event: KeyboardEvent): void {
    if (event.key === 'Escape' && !isSubmitting) {
      handleClose();
    }
  }
</script>

<svelte:window on:keydown={handleKeydown} />

<div class="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center p-4 z-50">
  <div class="bg-white dark:bg-gray-800 rounded-lg shadow-xl max-w-lg w-full max-h-[90vh] overflow-y-auto">
    <!-- Header -->
    <div class="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
      <div class="flex items-center justify-between">
        <h2 class="text-xl font-bold text-gray-900 dark:text-gray-100">New Plan</h2>
        {#if !isSubmitting}
          <button
            on:click={handleClose}
            class="text-gray-400 hover:text-gray-500 dark:hover:text-gray-300"
            aria-label="Close modal"
          >
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        {/if}
      </div>
      <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
        Run a Terraform plan on any branch. Apply from the run detail page after the plan completes.
        Runs use your <code class="text-xs bg-gray-100 dark:bg-gray-700 px-1 py-0.5 rounded">.terrateam/config.yml</code> workflows.
      </p>
    </div>

    <!-- Body -->
    <div class="px-6 py-4">
      {#if error}
        <div class="mb-4 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4">
          <div class="flex items-center">
            <svg class="w-5 h-5 text-red-400 mr-3 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <p class="text-sm text-red-700 dark:text-red-300">{error}</p>
          </div>
        </div>
      {/if}

      {#if isSubmitting}
        <div class="mb-4 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-4">
          <div class="flex items-center">
            <div class="animate-spin rounded-full h-4 w-4 border-b-2 border-blue-600 mr-3 flex-shrink-0"></div>
            <p class="text-sm text-blue-700 dark:text-blue-300">Starting plan...</p>
          </div>
        </div>
      {/if}

      <!-- Repository -->
      <div class="mb-4">
        <label for="new-run-repo" class="block text-sm font-medium text-gray-900 dark:text-gray-100 mb-2">
          Repository <span class="text-red-500">*</span>
        </label>
        <select
          id="new-run-repo"
          bind:value={selectedRepo}
          class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100"
          disabled={isSubmitting || isLoadingRepos}
        >
          {#if isLoadingRepos}
            <option value="">Loading repositories...</option>
          {:else if repositories.length === 0}
            <option value="">No repositories found</option>
          {:else}
            <option value="">Select a repository...</option>
            {#each repositories as repo}
              <option value={repo.name}>{repo.name}</option>
            {/each}
          {/if}
        </select>
      </div>

      <!-- Branch -->
      <div class="mb-4">
        <label for="new-run-branch" class="block text-sm font-medium text-gray-900 dark:text-gray-100 mb-2">
          Branch
        </label>
        <input
          id="new-run-branch"
          type="text"
          bind:value={branch}
          placeholder="Default branch"
          class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100"
          disabled={isSubmitting}
        />
        <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">
          Leave empty to use the repository's default branch.
        </p>
      </div>

      <!-- Tag Query -->
      <div class="mb-4">
        <label for="new-run-tag-query" class="block text-sm font-medium text-gray-900 dark:text-gray-100 mb-2">
          Tag Query
        </label>
        <input
          id="new-run-tag-query"
          type="text"
          bind:value={tagQuery}
          placeholder="e.g., dir:modules/vpc"
          class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100"
          disabled={isSubmitting}
        />
        <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">
          Optional. Filter which directories to include in the plan.
        </p>
      </div>
    </div>

    <!-- Footer -->
    <div class="px-6 py-4 border-t border-gray-200 dark:border-gray-700 flex justify-end gap-3">
      <Button variant="secondary" size="md" on:click={handleClose} disabled={isSubmitting}>
        Cancel
      </Button>
      <Button variant="primary" size="md" on:click={handleSubmit} loading={isSubmitting} disabled={!isValid}>
        {#if isSubmitting}
          Starting Plan...
        {:else}
          Start Plan
        {/if}
      </Button>
    </div>
  </div>
</div>
