<script lang="ts">
  import { createEventDispatcher } from 'svelte';
  import { api, isApiError } from '../../api';
  import { selectedInstallation } from '../../stores';
  import type { ApiUserItem } from '../../types';
  import Card from '../ui/Card.svelte';
  import LoadingSpinner from '../ui/LoadingSpinner.svelte';
  import Button from '../ui/Button.svelte';
  import CreateApiUserModal from './CreateApiUserModal.svelte';
  import ApiUserCreatedModal from './ApiUserCreatedModal.svelte';

  const dispatch = createEventDispatcher<{
    adminStatus: { isAdmin: boolean };
  }>();

  let apiUsers: ApiUserItem[] = [];
  let isLoading = false;
  let error: string | null = null;
  let showCreateModal = false;
  let showCreatedModal = false;
  let createdRefreshToken: string | null = null;
  let createdApiUserName: string | null = null;
  let createdApiUserId: string | null = null;
  let userToDelete: ApiUserItem | null = null;
  let isDeleting = false;
  let isAdmin: boolean | null = null;

  $: installationId = $selectedInstallation?.id;

  let lastLoadedInstallationId: string | undefined = undefined;

  $: if (installationId && installationId !== lastLoadedInstallationId) {
    lastLoadedInstallationId = installationId;
    loadApiUsers();
  }

  async function loadApiUsers(): Promise<void> {
    if (!installationId) return;

    isLoading = true;
    error = null;

    try {
      const response = await api.getApiUsers(installationId);
      apiUsers = response.results;
      isAdmin = true;
      dispatch('adminStatus', { isAdmin: true });
    } catch (err) {
      console.error('Failed to load API users:', err);
      if (isApiError(err) && err.status === 403) {
        isAdmin = false;
        dispatch('adminStatus', { isAdmin: false });
        return;
      }
      if (isApiError(err)) {
        error = `Failed to load API users: ${err.message}`;
      } else {
        error = 'Failed to load API users';
      }
      isAdmin = true;
      dispatch('adminStatus', { isAdmin: true });
    } finally {
      isLoading = false;
    }
  }

  function handleCreateUser(): void {
    showCreateModal = true;
  }

  function handleCancelCreate(): void {
    showCreateModal = false;
  }

  async function handleUserCreated(event: CustomEvent<{ id: string; refreshToken: string; name: string }>): Promise<void> {
    showCreateModal = false;
    createdApiUserId = event.detail.id;
    createdRefreshToken = event.detail.refreshToken;
    createdApiUserName = event.detail.name;
    showCreatedModal = true;

    await loadApiUsers();
  }

  function handleCreatedModalClose(): void {
    showCreatedModal = false;
    createdRefreshToken = null;
    createdApiUserName = null;
    createdApiUserId = null;
  }

  function handleDeleteClick(user: ApiUserItem): void {
    userToDelete = user;
  }

  function handleCancelDelete(): void {
    userToDelete = null;
  }

  async function confirmDelete(): Promise<void> {
    if (!userToDelete || !installationId) return;

    isDeleting = true;
    error = null;

    const idToDelete = userToDelete.id;

    try {
      await api.deleteApiUser(installationId, idToDelete);
      apiUsers = apiUsers.filter(u => u.id !== idToDelete);
      userToDelete = null;
    } catch (err) {
      console.error('Failed to delete API user:', err);
      if (isApiError(err)) {
        error = `Failed to delete API user: ${err.message}`;
      } else {
        error = 'Failed to delete API user';
      }
    } finally {
      isDeleting = false;
    }
  }

  function formatDate(dateStr: string): string {
    try {
      const date = new Date(dateStr);
      return new Intl.DateTimeFormat('en-US', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
      }).format(date);
    } catch {
      return dateStr;
    }
  }
</script>

{#if isAdmin === false}
  <!-- Non-admin: render nothing -->
{:else if !installationId}
  <Card padding="md" class="mb-6">
    <div class="text-center py-8">
      <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
      </svg>
      <h3 class="mt-2 text-sm font-medium text-gray-900 dark:text-gray-100">No organization selected</h3>
      <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
        Select an organization from the sidebar to manage API users.
      </p>
    </div>
  </Card>
{:else}
  <Card padding="md" class="mb-6">
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-6">
      <div class="flex items-center">
        <div class="inline-flex items-center justify-center w-10 h-10 md:w-12 md:h-12 rounded-lg mr-3 md:mr-4 brand-icon-bg">
          <svg class="w-6 h-6 brand-icon-color" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
          </svg>
        </div>
        <div>
          <div class="flex items-center gap-2">
            <h2 class="text-lg md:text-xl font-bold text-gray-900 dark:text-gray-100">API Users</h2>
            <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-purple-100 text-purple-800 dark:bg-purple-900/30 dark:text-purple-400">
              ENTERPRISE
            </span>
          </div>
          <p class="text-xs md:text-sm text-gray-600 dark:text-gray-400">
            Create and manage system API users for programmatic access
          </p>
        </div>
      </div>
      <Button variant="primary" size="md" on:click={handleCreateUser}>
        <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
        </svg>
        Create API User
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
        <span class="ml-3 text-gray-600 dark:text-gray-400">Loading API users...</span>
      </div>
    {:else if apiUsers.length === 0}
      <div class="text-center py-8">
        <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
        </svg>
        <h3 class="mt-2 text-sm font-medium text-gray-900 dark:text-gray-100">No API users</h3>
        <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
          Get started by creating a new API user for programmatic access.
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
                Created
              </th>
              <th scope="col" class="px-6 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                Actions
              </th>
            </tr>
          </thead>
          <tbody class="bg-white dark:bg-gray-900 divide-y divide-gray-200 dark:divide-gray-700">
            {#each apiUsers as user (user.id)}
              <tr>
                <td class="px-6 py-4 whitespace-nowrap">
                  <div class="text-sm font-medium text-gray-900 dark:text-gray-100">{user.name}</div>
                  <div class="text-xs text-gray-500 dark:text-gray-400 font-mono">{user.id.substring(0, 12)}...</div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <div class="text-sm text-gray-600 dark:text-gray-400">{formatDate(user.created_at)}</div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                  <button
                    on:click={() => handleDeleteClick(user)}
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

    <!-- Info Notice -->
    <div class="mt-6 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-4">
      <div class="flex items-start">
        <svg class="w-5 h-5 text-blue-400 mr-3 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        <div class="text-sm text-blue-700 dark:text-blue-300">
          <p class="font-medium mb-1">About API Users</p>
          <ul class="list-disc list-inside space-y-1 text-xs">
            <li>API users enable programmatic access to Terrateam for automation and integrations.</li>
            <li>Each API user can access reporting data and initiate drift operations for this organization.</li>
            <li>Only organization admins can create, list, and delete API users.</li>
            <li>Delete an API user immediately if its token is compromised.</li>
          </ul>
        </div>
      </div>
    </div>
  </Card>
{/if}

<!-- Create API User Modal -->
{#if showCreateModal && installationId}
  <CreateApiUserModal
    {installationId}
    on:cancel={handleCancelCreate}
    on:created={handleUserCreated}
  />
{/if}

<!-- API User Created Modal -->
{#if showCreatedModal && createdRefreshToken && createdApiUserName && createdApiUserId}
  <ApiUserCreatedModal
    refreshToken={createdRefreshToken}
    apiUserName={createdApiUserName}
    apiUserId={createdApiUserId}
    on:close={handleCreatedModalClose}
  />
{/if}

<!-- Delete Confirmation Modal -->
{#if userToDelete}
  <div class="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center p-4 z-50">
    <div class="bg-white dark:bg-gray-800 rounded-lg shadow-xl max-w-md w-full p-6">
      <div class="flex items-start mb-4">
        <div class="flex-shrink-0">
          <svg class="h-6 w-6 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
          </svg>
        </div>
        <div class="ml-3 flex-1">
          <h3 class="text-lg font-medium text-gray-900 dark:text-gray-100">Delete API User</h3>
          <div class="mt-2 text-sm text-gray-500 dark:text-gray-400">
            <p>Are you sure you want to delete the API user <span class="font-semibold">{userToDelete.name}</span>?</p>
            <p class="mt-2">Any applications using this user's token will immediately lose access. This action cannot be undone.</p>
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
            Delete API User
          {/if}
        </Button>
      </div>
    </div>
  </div>
{/if}
