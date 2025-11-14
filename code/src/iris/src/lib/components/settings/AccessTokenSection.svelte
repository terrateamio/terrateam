<script lang="ts">
  import { onMount } from 'svelte';
  import { api, isApiError } from '../../api';
  import type { AccessTokenItem, Capability } from '../../types';
  import Card from '../ui/Card.svelte';
  import LoadingSpinner from '../ui/LoadingSpinner.svelte';
  import Button from '../ui/Button.svelte';
  import CreateTokenModal from './CreateTokenModal.svelte';
  import TokenCreatedModal from './TokenCreatedModal.svelte';

  let tokens: AccessTokenItem[] = [];
  let isLoading = false;
  let error: string | null = null;
  let showCreateModal = false;
  let showTokenCreatedModal = false;
  let createdToken: string | null = null;
  let createdTokenName: string | null = null;
  let tokenToDelete: AccessTokenItem | null = null;
  let isDeleting = false;

  onMount(async () => {
    await loadTokens();
  });

  async function loadTokens(): Promise<void> {
    isLoading = true;
    error = null;

    try {
      const response = await api.getAccessTokens();
      tokens = response.results;
    } catch (err) {
      console.error('Failed to load access tokens:', err);
      if (isApiError(err)) {
        error = `Failed to load tokens: ${err.message}`;
      } else {
        error = 'Failed to load access tokens';
      }
    } finally {
      isLoading = false;
    }
  }

  function handleCreateToken(): void {
    showCreateModal = true;
  }

  function handleCancelCreate(): void {
    showCreateModal = false;
  }

  async function handleTokenCreated(event: CustomEvent<{ token: string; name: string }>): Promise<void> {
    showCreateModal = false;
    createdToken = event.detail.token;
    createdTokenName = event.detail.name;
    showTokenCreatedModal = true;

    // Reload tokens to show the new one in the list
    await loadTokens();
  }

  function handleTokenCreatedModalClose(): void {
    showTokenCreatedModal = false;
    createdToken = null;
    createdTokenName = null;
  }

  function handleDeleteClick(token: AccessTokenItem): void {
    tokenToDelete = token;
  }

  function handleCancelDelete(): void {
    tokenToDelete = null;
  }

  async function confirmDelete(): Promise<void> {
    if (!tokenToDelete) return;

    isDeleting = true;
    error = null;

    const tokenIdToDelete = tokenToDelete.id;

    try {
      await api.deleteAccessToken(tokenIdToDelete);
      tokens = tokens.filter(t => t.id !== tokenIdToDelete);
      tokenToDelete = null;
    } catch (err) {
      console.error('Failed to delete token:', err);
      if (isApiError(err)) {
        error = `Failed to delete token: ${err.message}`;
      } else {
        error = 'Failed to delete token';
      }
    } finally {
      isDeleting = false;
    }
  }

  function formatCapability(cap: Capability): string {
    if (typeof cap === 'string') {
      // Convert snake_case to Title Case
      return cap
        .split('_')
        .map((word: string) => word.charAt(0).toUpperCase() + word.slice(1))
        .join(' ');
    } else if (cap.name === 'installation_id') {
      return `Installation: ${cap.id.substring(0, 8)}...`;
    } else if (cap.name === 'vcs') {
      return `VCS: ${cap.vcs}`;
    }
    return String(cap);
  }

  function getCapabilityClass(cap: Capability): string {
    if (typeof cap === 'string') {
      if (cap.includes('read')) {
        return 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-400';
      } else if (cap.includes('write')) {
        return 'bg-orange-100 text-orange-800 dark:bg-orange-900/30 dark:text-orange-400';
      } else if (cap.includes('token')) {
        return 'bg-purple-100 text-purple-800 dark:bg-purple-900/30 dark:text-purple-400';
      }
    } else {
      return 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300';
    }
    return 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300';
  }
</script>

<!-- API Access Tokens Card -->
<Card padding="md" class="mb-6">
  <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-6">
    <div class="flex items-center">
      <div class="inline-flex items-center justify-center w-10 h-10 md:w-12 md:h-12 rounded-lg mr-3 md:mr-4 brand-icon-bg">
        <svg class="w-6 h-6 brand-icon-color" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1121 9z" />
        </svg>
      </div>
      <div>
        <div class="flex items-center gap-2">
          <h2 class="text-lg md:text-xl font-bold text-gray-900 dark:text-gray-100">API Access Tokens</h2>
          <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-purple-100 text-purple-800 dark:bg-purple-900/30 dark:text-purple-400">
            BETA
          </span>
        </div>
        <p class="text-xs md:text-sm text-gray-600 dark:text-gray-400">
          Create and manage API tokens for programmatic access
        </p>
      </div>
    </div>
    <Button variant="primary" size="md" on:click={handleCreateToken}>
      <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
      </svg>
      Create Token
    </Button>
  </div>

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

  {#if isLoading}
    <div class="flex justify-center items-center py-8">
      <LoadingSpinner size="md" />
      <span class="ml-3 text-gray-600 dark:text-gray-400">Loading tokens...</span>
    </div>
  {:else if tokens.length === 0}
    <div class="text-center py-8">
      <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1121 9z" />
      </svg>
      <h3 class="mt-2 text-sm font-medium text-gray-900 dark:text-gray-100">No API tokens</h3>
      <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
        Get started by creating a new API access token.
      </p>
    </div>
  {:else}
    <div class="overflow-x-auto">
      <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
        <thead class="bg-gray-50 dark:bg-gray-800">
          <tr>
            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
              Name
            </th>
            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
              Capabilities
            </th>
            <th scope="col" class="px-6 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
              Actions
            </th>
          </tr>
        </thead>
        <tbody class="bg-white dark:bg-gray-900 divide-y divide-gray-200 dark:divide-gray-700">
          {#each tokens as token (token.id)}
            <tr>
              <td class="px-6 py-4 whitespace-nowrap">
                <div class="text-sm font-medium text-gray-900 dark:text-gray-100">{token.name}</div>
                <div class="text-xs text-gray-500 dark:text-gray-400 font-mono">{token.id.substring(0, 12)}...</div>
              </td>
              <td class="px-6 py-4">
                <div class="flex flex-wrap gap-2">
                  {#each token.capabilities.filter(cap => typeof cap === 'string') as capability}
                    <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium {getCapabilityClass(capability)}">
                      {formatCapability(capability)}
                    </span>
                  {/each}
                </div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                <button
                  on:click={() => handleDeleteClick(token)}
                  class="text-red-600 hover:text-red-900 dark:text-red-400 dark:hover:text-red-300"
                >
                  Delete
                </button>
              </td>
            </tr>
          {/each}
        </tbody>
      </table>
    </div>
  {/if}

  <!-- API Usage Documentation -->
  <div class="mt-6 bg-purple-50 dark:bg-purple-900/20 border border-purple-200 dark:border-purple-800 rounded-lg p-4">
    <div class="flex items-start">
      <svg class="w-5 h-5 text-purple-400 mr-3 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
      </svg>
      <div class="text-sm text-purple-700 dark:text-purple-300">
        <p class="font-medium mb-1">API Usage</p>
        <p class="mb-2">
          Learn how to use your access tokens to interact with the Terrateam API.
          <a
            href="https://docs.terrateam.io/reference/api"
            target="_blank"
            rel="noopener noreferrer"
            class="inline-flex items-center font-medium text-purple-600 dark:text-purple-400 hover:text-purple-800 dark:hover:text-purple-300 underline ml-1"
          >
            See the docs
            <svg class="w-3 h-3 ml-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
            </svg>
          </a>
        </p>
        <p class="text-xs bg-purple-100 dark:bg-purple-900/40 border border-purple-200 dark:border-purple-700 rounded px-2 py-1.5">
          <strong>Beta Notice:</strong> The API is in beta. Some operations may not yet require explicit capabilities, but this may change in future updates. API endpoints and capability requirements are subject to change.
        </p>
      </div>
    </div>
  </div>

  <!-- Security Notice -->
  <div class="mt-4 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-4">
    <div class="flex items-start">
      <svg class="w-5 h-5 text-blue-400 mr-3 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
      <div class="text-sm text-blue-700 dark:text-blue-300">
        <p class="font-medium mb-1">Security Best Practices</p>
        <ul class="list-disc list-inside space-y-1">
          <li>Tokens are shown only once upon creation. Store them securely.</li>
          <li>Grant only the minimum capabilities needed for your use case.</li>
          <li>Rotate tokens regularly and delete unused ones.</li>
          <li>Never commit tokens to version control or share them publicly.</li>
        </ul>
      </div>
    </div>
  </div>
</Card>

<!-- Create Token Modal -->
{#if showCreateModal}
  <CreateTokenModal
    on:cancel={handleCancelCreate}
    on:created={handleTokenCreated}
  />
{/if}

<!-- Token Created Modal -->
{#if showTokenCreatedModal && createdToken && createdTokenName}
  <TokenCreatedModal
    token={createdToken}
    tokenName={createdTokenName}
    on:close={handleTokenCreatedModalClose}
  />
{/if}

<!-- Delete Confirmation Modal -->
{#if tokenToDelete}
  <div class="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center p-4 z-50">
    <div class="bg-white dark:bg-gray-800 rounded-lg shadow-xl max-w-md w-full p-6">
      <div class="flex items-start mb-4">
        <div class="flex-shrink-0">
          <svg class="h-6 w-6 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
          </svg>
        </div>
        <div class="ml-3 flex-1">
          <h3 class="text-lg font-medium text-gray-900 dark:text-gray-100">Delete API Token</h3>
          <div class="mt-2 text-sm text-gray-500 dark:text-gray-400">
            <p>Are you sure you want to delete the token <span class="font-semibold">{tokenToDelete.name}</span>?</p>
            <p class="mt-2">Any applications using this token will immediately lose access. This action cannot be undone.</p>
          </div>
        </div>
      </div>
      <div class="flex justify-end gap-3">
        <Button variant="secondary" size="md" on:click={handleCancelDelete} disabled={isDeleting}>
          Cancel
        </Button>
        <Button variant="accent" size="md" on:click={confirmDelete} loading={isDeleting}>
          {#if isDeleting}
            Deleting...
          {:else}
            Delete Token
          {/if}
        </Button>
      </div>
    </div>
  </div>
{/if}
