<script lang="ts">
  import type { Repository } from './types';
  // Auth handled by PageLayout
  import { selectedInstallation, currentVCSProvider } from './stores';
  import { repositoryService } from './services/repository-service';
  import PageLayout from './components/layout/PageLayout.svelte';
  import { navigateToRuns, navigateToRepositories } from './utils/navigation';
  import { VCS_PROVIDERS } from './vcs/providers';
  
  export let params: { id: string } = { id: '' };
  
  // Get current VCS provider terminology
  $: currentProvider = $currentVCSProvider || 'github';
  $: terminology = VCS_PROVIDERS[currentProvider]?.terminology || VCS_PROVIDERS.github.terminology;
  
  let repository: Repository | null = null;
  let error: string | null = null;
  let isLoading: boolean = false;
  
  // Load repository when params or installation changes
  $: if (params.id && $selectedInstallation) {
    loadRepository(params.id, $selectedInstallation.id);
  }
  
  async function loadRepository(repoId: string, installationId: string): Promise<void> {
    error = null;
    isLoading = true;
    
    try {
      // First check if it's in cache
      repository = repositoryService.getRepositoryFromCache(installationId, repoId);
      
      if (!repository) {
        // Not in cache, need to load repositories
        const result = await repositoryService.loadRepositories($selectedInstallation!);
        
        if (result.error) {
          error = result.error;
          return;
        }
        
        // Now try to find it again
        repository = repositoryService.getRepositoryFromCache(installationId, repoId);
        
        if (!repository) {
          error = 'Repository not found in the current installation';
        }
      }
    } catch (err) {
      error = 'Failed to load repository';
      console.error('Error loading repository:', err);
    } finally {
      isLoading = false;
    }
  }
  
  function viewAllRuns(): void {
    // Navigate to runs screen with repository filter
    if (repository) {
      navigateToRuns(`repo:${repository.name}`);
    }
  }
  
  function handleGetStarted(): void {
    window.location.hash = '#/getting-started';
  }
</script>

<PageLayout 
  activeItem="repositories" 
  title={repository ? repository.name : 'Repository'} 
  subtitle="Repository configuration and management"
>
  <!-- Back Navigation -->
  <div class="mb-6">
    <button 
      on:click={() => navigateToRepositories()}
      class="inline-flex items-center text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 font-medium"
    >
      <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
      </svg>
      Back to Repositories
    </button>
  </div>
      {#if isLoading}
        <div class="flex justify-center py-12">
          <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-brand-primary"></div>
          <span class="ml-3 text-gray-600 dark:text-gray-400">Loading repository data...</span>
        </div>
      {:else if error}
        <div class="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-md p-4">
          <div class="flex">
            <div class="flex-shrink-0">
              <svg class="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
              </svg>
            </div>
            <div class="ml-3">
              <h3 class="text-sm font-medium text-red-800 dark:text-red-400">Error</h3>
              <div class="mt-2 text-sm text-red-700 dark:text-red-400">
                <p>{error}</p>
              </div>
            </div>
          </div>
        </div>
      {:else if repository}
        <div class="space-y-6">
          <!-- Repository Configuration -->
          <div class="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
            <h2 class="text-lg font-semibold text-brand-primary mb-4">Repository Configuration</h2>
            <dl class="grid grid-cols-1 gap-x-4 gap-y-6 sm:grid-cols-2">
              <div>
                <dt class="text-sm font-medium text-gray-600 dark:text-gray-400">Repository Name</dt>
                <dd class="mt-1 text-sm text-gray-900 dark:text-gray-100 font-mono">{repository.name}</dd>
              </div>
              <div>
                <dt class="text-sm font-medium text-gray-600 dark:text-gray-400">Repository ID</dt>
                <dd class="mt-1 text-sm text-gray-900 dark:text-gray-100">#{repository.id}</dd>
              </div>
              <div>
                <dt class="text-sm font-medium text-gray-600 dark:text-gray-400">{terminology.organization}</dt>
                <dd class="mt-1 text-sm text-gray-900 dark:text-gray-100">{$selectedInstallation?.name || 'Unknown'}</dd>
              </div>
            </dl>
          </div>

          <!-- Actions -->
          <div class="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
            <h3 class="text-lg font-semibold text-brand-primary mb-4">Actions</h3>
            <div class="space-y-4">
              <!-- View Runs -->
              <div class="flex items-center justify-between p-4 border border-gray-200 dark:border-gray-600 rounded-lg">
                <div class="flex items-center">
                  <svg class="w-5 h-5 text-blue-600 dark:text-blue-400 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M9 19l3 3m0 0l3-3m-3 3V10" />
                  </svg>
                  <div>
                    <h4 class="text-sm font-medium text-gray-900 dark:text-gray-100">View All Runs</h4>
                    <p class="text-sm text-gray-600 dark:text-gray-400">Search and manage Terraform operations for this repository</p>
                  </div>
                </div>
                <button
                  on:click={viewAllRuns}
                  class="px-4 py-2 bg-blue-600 dark:bg-blue-500 text-white text-sm rounded-md hover:bg-blue-700 dark:hover:bg-blue-600 transition-colors"
                >
                  View Runs
                </button>
              </div>

              <!-- Setup Repository (if not configured) -->
              {#if !repository.setup}
                <div class="flex items-center justify-between p-4 border border-yellow-200 dark:border-yellow-700 rounded-lg bg-yellow-50 dark:bg-yellow-900/20">
                  <div class="flex items-center">
                    <svg class="w-5 h-5 text-yellow-600 dark:text-yellow-400 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                    </svg>
                    <div>
                      <h4 class="text-sm font-medium text-yellow-800 dark:text-yellow-400">Configure Terrateam</h4>
                      <p class="text-sm text-yellow-700 dark:text-yellow-300">This repository needs to be configured to use Terrateam</p>
                    </div>
                  </div>
                  <button
                    on:click={handleGetStarted}
                    class="px-4 py-2 bg-yellow-600 dark:bg-yellow-500 text-white text-sm rounded-md hover:bg-yellow-700 dark:hover:bg-yellow-600 transition-colors"
                  >
                    Getting Started
                  </button>
                </div>
              {/if}

              <!-- Disable Repository -->
              <div class="flex items-start justify-between p-4 border border-gray-200 dark:border-gray-600 rounded-lg">
                <div class="flex items-start">
                  <svg class="w-5 h-5 text-gray-600 dark:text-gray-400 mr-3 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728L5.636 5.636m12.728 12.728L5.636 5.636" />
                  </svg>
                  <div class="flex-1">
                    <h4 class="text-sm font-medium text-gray-900 dark:text-gray-100 mb-1">Disable Terrateam Operations</h4>
                    <p class="text-sm text-gray-600 dark:text-gray-400 mb-3">
                      Disable Terrateam on this repository while keeping GitHub App permissions. Useful for module repositories that other repos need to access but don't need their own Terraform operations.
                    </p>
                    <div class="bg-gray-50 dark:bg-gray-700 border border-gray-200 dark:border-gray-600 rounded-md p-3">
                      <p class="text-xs font-medium text-gray-700 dark:text-gray-300 mb-2">Add to <code class="px-1 py-0.5 bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 rounded text-xs">.terrateam/config.yml</code>:</p>
                      <code class="block text-xs font-mono text-gray-800 dark:text-gray-200 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-600 rounded px-2 py-1">enabled: false</code>
                    </div>
                  </div>
                </div>
              </div>

            </div>
          </div>

          <!-- Quick Info -->
          {#if repository.setup}
            <div class="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
              <h3 class="text-lg font-semibold text-brand-primary mb-4">Quick Info</h3>
              <div class="text-sm text-gray-600 dark:text-gray-400 space-y-2">
                <p>• This repository is connected to Terrateam and ready for infrastructure management</p>
                <p>• You can create pull requests to trigger Terraform plans and applies</p>
                <p>• Use the <strong>Runs</strong> screen to search and monitor all operations</p>
              </div>
            </div>
          {/if}
      </div>
    {/if}
</PageLayout>
