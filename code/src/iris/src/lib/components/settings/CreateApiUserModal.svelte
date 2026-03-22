<script lang="ts">
  import { createEventDispatcher } from 'svelte';
  import { api, isApiError } from '../../api';
  import Button from '../ui/Button.svelte';

  export let installationId: string;

  const dispatch = createEventDispatcher<{
    cancel: void;
    created: { id: string; refreshToken: string; name: string };
  }>();

  let apiUserName = '';
  let isCreating = false;
  let error: string | null = null;

  $: isValid = apiUserName.trim().length > 0;

  async function handleCreate(): Promise<void> {
    if (!isValid) return;

    isCreating = true;
    error = null;

    try {
      const response = await api.createApiUser(installationId, {
        name: apiUserName.trim(),
      });

      dispatch('created', {
        id: response.id,
        refreshToken: response.refresh_token,
        name: apiUserName.trim(),
      });
    } catch (err) {
      console.error('Failed to create API user:', err);
      if (isApiError(err)) {
        error = `Failed to create API user: ${err.message}`;
      } else {
        error = 'Failed to create API user';
      }
      isCreating = false;
    }
  }

  function handleCancel(): void {
    dispatch('cancel');
  }

  function handleKeydown(event: KeyboardEvent): void {
    if (event.key === 'Escape') {
      handleCancel();
    }
  }
</script>

<svelte:window on:keydown={handleKeydown} />

<div class="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center p-4 z-50">
  <div class="bg-white dark:bg-gray-800 rounded-lg shadow-xl max-w-lg w-full">
    <!-- Header -->
    <div class="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
      <div class="flex items-center justify-between">
        <h2 class="text-xl font-bold text-gray-900 dark:text-gray-100">Create API User</h2>
        <button
          on:click={handleCancel}
          class="text-gray-400 hover:text-gray-500 dark:hover:text-gray-300"
          aria-label="Close modal"
        >
          <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>
    </div>

    <!-- Body -->
    <div class="px-6 py-4">
      {#if error}
        <div class="mb-4 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4">
          <div class="flex items-center">
            <svg class="w-5 h-5 text-red-400 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <p class="text-sm text-red-700 dark:text-red-300">{error}</p>
          </div>
        </div>
      {/if}

      <!-- API User Name -->
      <div class="mb-6">
        <label for="api-user-name" class="block text-sm font-medium text-gray-900 dark:text-gray-100 mb-2">
          Name <span class="text-red-500">*</span>
        </label>
        <input
          id="api-user-name"
          type="text"
          bind:value={apiUserName}
          placeholder="e.g., CI/CD Pipeline, Monitoring Bot"
          class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100"
          disabled={isCreating}
        />
        <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">
          Choose a descriptive name to identify this API user's purpose.
        </p>
      </div>

      <!-- Capabilities Info -->
      <div class="mb-6 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-4">
        <div class="flex items-start">
          <svg class="w-5 h-5 text-blue-400 mr-3 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <div class="text-sm text-blue-700 dark:text-blue-300">
            <p class="font-medium mb-1">API User Capabilities</p>
            <p class="text-xs">
              API users are automatically granted access to reporting data (work manifests, pull requests, dirspaces) and the ability to initiate drift operations for this installation.
            </p>
          </div>
        </div>
      </div>

      <!-- Security Warning -->
      <div class="mb-6 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg p-4">
        <div class="flex items-start">
          <svg class="w-5 h-5 text-yellow-400 mr-3 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
          </svg>
          <div class="text-xs text-yellow-700 dark:text-yellow-300">
            <p class="font-medium mb-1">Important Security Notice</p>
            <p>The refresh token will be shown only once after creation. Make sure to copy and store it securely before closing.</p>
          </div>
        </div>
      </div>
    </div>

    <!-- Footer -->
    <div class="px-6 py-4 border-t border-gray-200 dark:border-gray-700 flex justify-end gap-3">
      <Button variant="secondary" size="md" on:click={handleCancel} disabled={isCreating}>
        Cancel
      </Button>
      <Button variant="primary" size="md" on:click={handleCreate} loading={isCreating} disabled={!isValid}>
        {#if isCreating}
          Creating...
        {:else}
          Create API User
        {/if}
      </Button>
    </div>
  </div>
</div>
