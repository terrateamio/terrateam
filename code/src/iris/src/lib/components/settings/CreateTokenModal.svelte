<script lang="ts">
  import { createEventDispatcher } from 'svelte';
  import { api, isApiError } from '../../api';
  import type { AccessTokenCreate, Capability } from '../../types';
  import { installations } from '../../stores';
  import Button from '../ui/Button.svelte';

  const dispatch = createEventDispatcher<{
    cancel: void;
    created: { token: string; name: string };
  }>();

  let tokenName = '';
  let isCreating = false;
  let error: string | null = null;

  // Simple capability checkboxes
  let capabilities: {
    access_token_create: boolean;
    access_token_refresh: boolean;
    kv_store_read: boolean;
    kv_store_write: boolean;
    kv_store_system_read: boolean;
    kv_store_system_write: boolean;
  } = {
    access_token_create: false,
    access_token_refresh: false,
    kv_store_read: false,
    kv_store_write: false,
    kv_store_system_read: false,
    kv_store_system_write: false,
  };

  // Scoping options
  let scopeToInstallation = false;
  let selectedInstallationId: string = '';
  let scopeToVCS = false;
  let selectedVCS: string = '';

  // Reactive computation for validation - must compute inline for proper reactivity
  $: hasCapability = Object.values(capabilities).some(v => v);
  $: isValid = tokenName.trim().length > 0 && hasCapability;

  // Debug logging
  $: {
    console.log('=== Token Creation Validation Debug ===');
    console.log('Token Name:', tokenName);
    console.log('Token Name Length:', tokenName.trim().length);
    console.log('Capabilities Object:', capabilities);
    console.log('Capabilities Values:', Object.values(capabilities));
    console.log('Has Capability:', hasCapability);
    console.log('Is Valid:', isValid);
    console.log('=====================================');
  }

  function buildCapabilitiesArray(): Capability[] {
    const caps: Capability[] = [];

    // Add simple string capabilities
    for (const [key, value] of Object.entries(capabilities)) {
      if (value) {
        caps.push(key as Capability);
      }
    }

    // Add scoped capabilities
    if (scopeToInstallation && selectedInstallationId) {
      caps.push({ name: 'installation_id', id: selectedInstallationId });
    }

    if (scopeToVCS && selectedVCS) {
      caps.push({ name: 'vcs', vcs: selectedVCS });
    }

    return caps;
  }

  async function handleCreate(): Promise<void> {
    if (!isValid) return;

    isCreating = true;
    error = null;

    try {
      const builtCapabilities = buildCapabilitiesArray();
      const tokenData: AccessTokenCreate = {
        name: tokenName.trim(),
        capabilities: builtCapabilities,
      };

      console.log('=== Creating Token ===');
      console.log('Token Name:', tokenData.name);
      console.log('Capabilities Object:', capabilities);
      console.log('Built Capabilities Array:', builtCapabilities);
      console.log('Token Data Being Sent:', JSON.stringify(tokenData, null, 2));
      console.log('====================');

      const response = await api.createAccessToken(tokenData);

      console.log('=== Token Created ===');
      console.log('Response:', response);
      console.log('Token (first 50 chars):', response.refresh_token.substring(0, 50));
      console.log('===================');

      // Emit the created event with the token
      dispatch('created', {
        token: response.refresh_token,
        name: tokenName.trim(),
      });
    } catch (err) {
      console.error('Failed to create token:', err);
      if (isApiError(err)) {
        error = `Failed to create token: ${err.message}`;
      } else {
        error = 'Failed to create token';
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
  <div class="bg-white dark:bg-gray-800 rounded-lg shadow-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
    <!-- Header -->
    <div class="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
      <div class="flex items-center justify-between">
        <h2 class="text-xl font-bold text-gray-900 dark:text-gray-100">Create API Access Token</h2>
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

      <!-- Token Name -->
      <div class="mb-6">
        <label for="token-name" class="block text-sm font-medium text-gray-900 dark:text-gray-100 mb-2">
          Token Name <span class="text-red-500">*</span>
        </label>
        <input
          id="token-name"
          type="text"
          bind:value={tokenName}
          placeholder="e.g., CI/CD Pipeline Token"
          class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100"
          disabled={isCreating}
        />
        <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">
          Choose a descriptive name to identify this token's purpose.
        </p>
      </div>

      <!-- Capabilities Section -->
      <div class="mb-6">
        <h3 class="text-sm font-medium text-gray-900 dark:text-gray-100 mb-3">
          Capabilities <span class="text-red-500">*</span>
        </h3>
        <p class="text-xs text-gray-500 dark:text-gray-400 mb-4">
          Select the permissions this token should have. Grant only the minimum capabilities needed.
        </p>

        <!-- Token Management Capabilities -->
        <div class="mb-4">
          <h4 class="text-xs font-semibold text-gray-700 dark:text-gray-300 uppercase tracking-wider mb-2">
            Token Management
          </h4>
          <div class="space-y-2">
            <label class="flex items-start">
              <input
                type="checkbox"
                bind:checked={capabilities.access_token_create}
                disabled={isCreating}
                class="h-4 w-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500 mt-0.5"
              />
              <span class="ml-3 text-sm text-gray-900 dark:text-gray-100">
                <span class="font-medium">Create access tokens</span>
                <span class="block text-xs text-gray-500 dark:text-gray-400">
                  Allow this token to create new access tokens
                </span>
              </span>
            </label>
            <label class="flex items-start">
              <input
                type="checkbox"
                bind:checked={capabilities.access_token_refresh}
                disabled={isCreating}
                class="h-4 w-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500 mt-0.5"
              />
              <span class="ml-3 text-sm text-gray-900 dark:text-gray-100">
                <span class="font-medium">Refresh access tokens</span>
                <span class="block text-xs text-gray-500 dark:text-gray-400">
                  Allow this token to refresh existing tokens
                </span>
              </span>
            </label>
          </div>
        </div>

        <!-- KV Store Capabilities -->
        <div class="mb-4">
          <h4 class="text-xs font-semibold text-gray-700 dark:text-gray-300 uppercase tracking-wider mb-2">
            Key-Value Store Access
          </h4>
          <div class="space-y-2">
            <label class="flex items-start">
              <input
                type="checkbox"
                bind:checked={capabilities.kv_store_read}
                disabled={isCreating}
                class="h-4 w-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500 mt-0.5"
              />
              <span class="ml-3 text-sm text-gray-900 dark:text-gray-100">
                <span class="font-medium">Read from KV store</span>
                <span class="block text-xs text-gray-500 dark:text-gray-400">
                  Read data from the key-value store
                </span>
              </span>
            </label>
            <label class="flex items-start">
              <input
                type="checkbox"
                bind:checked={capabilities.kv_store_write}
                disabled={isCreating}
                class="h-4 w-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500 mt-0.5"
              />
              <span class="ml-3 text-sm text-gray-900 dark:text-gray-100">
                <span class="font-medium">Write to KV store</span>
                <span class="block text-xs text-gray-500 dark:text-gray-400">
                  Write data to the key-value store
                </span>
              </span>
            </label>
            <label class="flex items-start">
              <input
                type="checkbox"
                bind:checked={capabilities.kv_store_system_read}
                disabled={isCreating}
                class="h-4 w-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500 mt-0.5"
              />
              <span class="ml-3 text-sm text-gray-900 dark:text-gray-100">
                <span class="font-medium">System-level read</span>
                <span class="block text-xs text-gray-500 dark:text-gray-400">
                  Read system-level key-value data (advanced)
                </span>
              </span>
            </label>
            <label class="flex items-start">
              <input
                type="checkbox"
                bind:checked={capabilities.kv_store_system_write}
                disabled={isCreating}
                class="h-4 w-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500 mt-0.5"
              />
              <span class="ml-3 text-sm text-gray-900 dark:text-gray-100">
                <span class="font-medium">System-level write</span>
                <span class="block text-xs text-gray-500 dark:text-gray-400">
                  Write system-level key-value data (advanced)
                </span>
              </span>
            </label>
          </div>
        </div>

        <!-- Scoping Options -->
        <div class="border-t border-gray-200 dark:border-gray-700 pt-4">
          <h4 class="text-xs font-semibold text-gray-700 dark:text-gray-300 uppercase tracking-wider mb-3">
            Scope Restrictions (Optional)
          </h4>
          <p class="text-xs text-gray-500 dark:text-gray-400 mb-3">
            Limit this token to specific installations or VCS providers.
          </p>

          <!-- Installation Scope -->
          <div class="mb-3">
            <label class="flex items-center mb-2">
              <input
                type="checkbox"
                bind:checked={scopeToInstallation}
                disabled={isCreating}
                class="h-4 w-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
              />
              <span class="ml-3 text-sm font-medium text-gray-900 dark:text-gray-100">
                Limit to specific installation
              </span>
            </label>
            {#if scopeToInstallation}
              <select
                bind:value={selectedInstallationId}
                disabled={isCreating}
                class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100 text-sm"
              >
                <option value="">Select installation...</option>
                {#each $installations as installation}
                  <option value={installation.id}>{installation.name}</option>
                {/each}
              </select>
            {/if}
          </div>

          <!-- VCS Scope -->
          <div>
            <label class="flex items-center mb-2">
              <input
                type="checkbox"
                bind:checked={scopeToVCS}
                disabled={isCreating}
                class="h-4 w-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
              />
              <span class="ml-3 text-sm font-medium text-gray-900 dark:text-gray-100">
                Limit to specific VCS provider
              </span>
            </label>
            {#if scopeToVCS}
              <select
                bind:value={selectedVCS}
                disabled={isCreating}
                class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100 text-sm"
              >
                <option value="">Select VCS provider...</option>
                <option value="github">GitHub</option>
                <option value="gitlab">GitLab</option>
              </select>
            {/if}
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
            <p>The token will be shown only once. Make sure to copy and store it securely before closing the modal.</p>
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
          Generate Token
        {/if}
      </Button>
    </div>
  </div>
</div>
