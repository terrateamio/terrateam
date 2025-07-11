<script lang="ts">
  // Auth handled by PageLayout
  import { user, githubUser } from './auth';
  import PageLayout from './components/layout/PageLayout.svelte';
  import { installations, defaultInstallationId, theme, selectedInstallation, currentVCSProvider } from './stores';
  import type { ThemeMode, ServerConfig } from './types';
  import { api } from './api';
  import Card from './components/ui/Card.svelte';
  import LoadingSpinner from './components/ui/LoadingSpinner.svelte';
  import { VCS_PROVIDERS } from './vcs/providers';

  let selectedDefaultInstallation: string | null = $defaultInstallationId;
  let selectedTheme: ThemeMode = $theme;
  
  // Get current VCS provider terminology
  $: currentProvider = $currentVCSProvider || 'github';
  $: terminology = VCS_PROVIDERS[currentProvider]?.terminology || VCS_PROVIDERS.github.terminology;
  
  // Helper functions for proper capitalization and articles
  $: capitalizedOrganization = terminology.organization.charAt(0).toUpperCase() + terminology.organization.slice(1);
  $: articleForOrganization = terminology.organization.match(/^[aeiou]/i) ? 'an' : 'a';
  
  // Connection diagnostics state
  let serverConfig: ServerConfig | null = null;
  let isLoadingDiagnostics = false;
  let diagnosticsError: string | null = null;
  let lastDiagnosticsCheck: Date | null = null;

  function handleSaveSettings(): void {
    defaultInstallationId.set(selectedDefaultInstallation);
    localStorage.setItem('defaultInstallationId', selectedDefaultInstallation || '');
    
    theme.setTheme(selectedTheme);
    
    // Show success message briefly
    const successEl = document.getElementById('success-message');
    if (successEl) {
      successEl.classList.add('block');
      successEl.classList.remove('hidden');
      setTimeout(() => {
        successEl.classList.remove('block');
        successEl.classList.add('hidden');
      }, 3000);
    }
  }

  async function runDiagnostics(): Promise<void> {
    isLoadingDiagnostics = true;
    diagnosticsError = null;
    
    try {
      // Get server configuration
      serverConfig = await api.getServerConfig();
      lastDiagnosticsCheck = new Date();
    } catch (err) {
      console.error('Diagnostics failed:', err);
      diagnosticsError = err instanceof Error ? err.message : 'Failed to run diagnostics';
      serverConfig = null;
    } finally {
      isLoadingDiagnostics = false;
    }
  }

  // Auto-run diagnostics on component mount
  import { onMount } from 'svelte';
  onMount(() => {
    runDiagnostics();
  });
</script>

<PageLayout activeItem="settings" title="Settings">
    <main class="flex-1 p-6">
      <div class="max-w-4xl mx-auto">
        <!-- Success Message (hidden by default) -->
        <div id="success-message" class="mb-6 bg-green-50 border border-green-200 rounded-lg p-4" style="display: none;">
          <div class="flex items-center">
            <svg class="w-5 h-5 text-green-400 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <p class="text-green-800 font-medium">Settings saved successfully!</p>
          </div>
        </div>

        <!-- {terminology.organization} Settings Card -->
        <div class="card-bg rounded-lg shadow border mb-6">
          <div class="px-6 py-8">
            <!-- Settings Icon -->
            <div class="inline-flex items-center justify-center w-16 h-16 rounded-full mb-6" style="background-color: rgba(0, 155, 255, 0.1);">
              <svg class="w-8 h-8" style="color: #009bff;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
              </svg>
            </div>
            
            <h2 class="text-2xl font-bold text-brand-primary mb-6">{capitalizedOrganization} Settings</h2>
            
            <!-- Default {terminology.organization} Selection -->
            <div class="mb-8">
              <label for="default-{terminology.organization.toLowerCase()}" class="block text-sm font-medium text-brand-secondary mb-3">
                Default {terminology.organization}
              </label>
              <p class="text-sm text-brand-secondary mb-4">
                Select which {terminology.organization.toLowerCase()} should be selected by default when you login. This helps streamline your workflow by automatically switching to your preferred {terminology.organization.toLowerCase()}.
              </p>
              <select
                id="default-{terminology.organization.toLowerCase()}"
                bind:value={selectedDefaultInstallation}
                class="w-full max-w-md px-3 py-2 border border-brand-primary rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 bg-brand-primary text-brand-primary"
              >
                <option value="">Select {articleForOrganization} {terminology.organization.toLowerCase()}...</option>
                {#each $installations as installation}
                  <option value={installation.id}>{installation.name}</option>
                {/each}
              </select>
            </div>

            <!-- Theme Selection -->
            <div class="mb-8">
              <label for="theme-selection" class="block text-sm font-medium text-brand-secondary mb-3">
                Theme Appearance
              </label>
              <p class="text-sm text-brand-secondary mb-4">
                Choose how the interface should appear. System default will automatically match your operating system's theme preference.
              </p>
              <div class="space-y-3">
                <label class="flex items-center">
                  <input
                    type="radio"
                    bind:group={selectedTheme}
                    value="system"
                    class="h-4 w-4 text-blue-600 border-gray-300 focus:ring-blue-500"
                  />
                  <span class="ml-3 text-sm text-brand-primary">
                    <span class="font-medium">System default</span>
                    <span class="block text-brand-secondary">Automatically match your device's theme</span>
                  </span>
                </label>
                <label class="flex items-center">
                  <input
                    type="radio"
                    bind:group={selectedTheme}
                    value="light"
                    class="h-4 w-4 text-blue-600 border-gray-300 focus:ring-blue-500"
                  />
                  <span class="ml-3 text-sm text-brand-primary">
                    <span class="font-medium">Light mode</span>
                    <span class="block text-brand-secondary">Use the light theme</span>
                  </span>
                </label>
                <label class="flex items-center">
                  <input
                    type="radio"
                    bind:group={selectedTheme}
                    value="dark"
                    class="h-4 w-4 text-blue-600 border-gray-300 focus:ring-blue-500"
                  />
                  <span class="ml-3 text-sm text-brand-primary">
                    <span class="font-medium">Dark mode</span>
                    <span class="block text-brand-secondary">Use the dark theme</span>
                  </span>
                </label>
              </div>
            </div>

            <!-- Save Button -->
            <button
              on:click={handleSaveSettings}
              class="inline-flex items-center px-6 py-3 font-semibold text-base rounded-lg transition-colors shadow-lg hover:shadow-xl transform hover:-translate-y-0.5 accent-bg"
            >
              <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-3m-1 4l-3 3m0 0l-3-3m3 3V4" />
              </svg>
              Save Settings
            </button>
          </div>
        </div>

        <!-- Connection Diagnostics Card -->
        <Card padding="lg" class="mb-6">
          <div class="flex items-center justify-between mb-6">
            <div class="flex items-center">
              <div class="inline-flex items-center justify-center w-12 h-12 rounded-lg mr-4" style="background-color: rgba(0, 155, 255, 0.1);">
                <svg class="w-6 h-6" style="color: #009bff;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                </svg>
              </div>
              <div>
                <h2 class="text-xl font-bold text-gray-900 dark:text-gray-100">Connection Diagnostics</h2>
                <p class="text-sm text-gray-600 dark:text-gray-400">
                  {VCS_PROVIDERS[currentProvider].displayName} integration status and API connectivity
                </p>
              </div>
            </div>
            <button
              on:click={runDiagnostics}
              disabled={isLoadingDiagnostics}
              class="inline-flex items-center px-3 py-2 text-sm font-medium rounded-md transition-colors
                {isLoadingDiagnostics 
                  ? 'bg-gray-100 text-gray-400 cursor-not-allowed' 
                  : 'bg-white text-gray-700 border border-gray-300 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500'}"
            >
              {#if isLoadingDiagnostics}
                <svg class="animate-spin -ml-0.5 mr-2 h-4 w-4" fill="none" viewBox="0 0 24 24">
                  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                  <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
                Checking...
              {:else}
                <svg class="-ml-0.5 mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                </svg>
                Refresh
              {/if}
            </button>
          </div>

          {#if isLoadingDiagnostics}
            <div class="flex justify-center items-center py-8">
              <LoadingSpinner size="md" />
              <span class="ml-3 text-gray-600 dark:text-gray-400">Running diagnostics...</span>
            </div>
          {:else if diagnosticsError}
            <div class="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4">
              <div class="flex items-center">
                <svg class="w-5 h-5 text-red-400 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                <div>
                  <p class="font-medium text-red-800 dark:text-red-400">Connection Failed</p>
                  <p class="text-sm text-red-700 dark:text-red-300">{diagnosticsError}</p>
                </div>
              </div>
            </div>
          {:else if serverConfig}
            <div class="space-y-4">
              <!-- Overall Status -->
              <div class="bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg p-4">
                <div class="flex items-center">
                  <svg class="w-5 h-5 text-green-400 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                  <div>
                    <p class="font-medium text-green-800 dark:text-green-400">All Systems Operational</p>
                    <p class="text-sm text-green-700 dark:text-green-300">Successfully connected to Terrateam services</p>
                  </div>
                </div>
              </div>

              <!-- Integration Details -->
              <div class="grid md:grid-cols-2 gap-4">
                <!-- User Authentication -->
                <div class="bg-gray-50 dark:bg-gray-800 rounded-lg p-4">
                  <div class="flex items-center justify-between mb-3">
                    <h4 class="font-medium text-gray-900 dark:text-gray-100">User Authentication</h4>
                    <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400">
                      Connected
                    </span>
                  </div>
                  <div class="space-y-2 text-sm text-gray-600 dark:text-gray-400">
                    <div class="flex justify-between">
                      <span>User ID:</span>
                      <span class="font-mono">{$user?.id?.substring(0, 8)}...</span>
                    </div>
                    <div class="flex justify-between">
                      <span>{VCS_PROVIDERS[currentProvider].displayName} User:</span>
                      <span>{$githubUser?.username || 'Unknown'}</span>
                    </div>
                  </div>
                </div>

                <!-- Provider Integration -->
                {#if serverConfig.github && currentProvider === 'github'}
                  <div class="bg-gray-50 dark:bg-gray-800 rounded-lg p-4">
                    <div class="flex items-center justify-between mb-3">
                      <h4 class="font-medium text-gray-900 dark:text-gray-100">GitHub Integration</h4>
                      <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400">
                        Active
                      </span>
                    </div>
                    <div class="space-y-2 text-sm text-gray-600 dark:text-gray-400">
                      <div class="flex justify-between">
                        <span>App Client ID:</span>
                        <span class="font-mono">{serverConfig.github.app_client_id}</span>
                      </div>
                      <div class="flex justify-between">
                        <span>API Base:</span>
                        <span class="font-mono">{serverConfig.github.api_base_url}</span>
                      </div>
                    </div>
                  </div>
                {:else if serverConfig.gitlab && currentProvider === 'gitlab'}
                  <div class="bg-gray-50 dark:bg-gray-800 rounded-lg p-4">
                    <div class="flex items-center justify-between mb-3">
                      <h4 class="font-medium text-gray-900 dark:text-gray-100">GitLab Integration</h4>
                      <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400">
                        Active
                      </span>
                    </div>
                    <div class="space-y-2 text-sm text-gray-600 dark:text-gray-400">
                      <div class="flex justify-between">
                        <span>App ID:</span>
                        <span class="font-mono">{serverConfig.gitlab.app_id.length > 12 ? serverConfig.gitlab.app_id.substring(0, 12) + '...' : serverConfig.gitlab.app_id}</span>
                      </div>
                      <div class="flex justify-between">
                        <span>API Base:</span>
                        <span class="font-mono">{serverConfig.gitlab.api_base_url.length > 20 ? serverConfig.gitlab.api_base_url.substring(0, 20) + '...' : serverConfig.gitlab.api_base_url}</span>
                      </div>
                      <div class="flex justify-between">
                        <span>Web Base:</span>
                        <span class="font-mono">{serverConfig.gitlab.web_base_url.length > 20 ? serverConfig.gitlab.web_base_url.substring(0, 20) + '...' : serverConfig.gitlab.web_base_url}</span>
                      </div>
                    </div>
                  </div>
                {:else}
                  <div class="bg-gray-50 dark:bg-gray-800 rounded-lg p-4">
                    <div class="flex items-center justify-between mb-3">
                      <h4 class="font-medium text-gray-900 dark:text-gray-100">{VCS_PROVIDERS[currentProvider].displayName} Integration</h4>
                      <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400">
                        Not Configured
                      </span>
                    </div>
                    <div class="text-sm text-gray-600 dark:text-gray-400">
                      Server configuration not available for {VCS_PROVIDERS[currentProvider].displayName}
                    </div>
                  </div>
                {/if}

                <!-- {terminology.organizations} -->
                <div class="bg-gray-50 dark:bg-gray-800 rounded-lg p-4">
                  <div class="flex items-center justify-between mb-3">
                    <h4 class="font-medium text-gray-900 dark:text-gray-100">{terminology.organizations}</h4>
                    <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-400">
                      {$installations.length} Connected
                    </span>
                  </div>
                  <div class="space-y-1 text-sm text-gray-600 dark:text-gray-400">
                    {#each $installations.slice(0, 3) as installation}
                      <div class="flex justify-between">
                        <span>{installation.name}</span>
                        <span class="text-xs text-gray-500">{installation.tier?.name || 'Free'}</span>
                      </div>
                    {/each}
                    {#if $installations.length > 3}
                      <div class="text-xs text-gray-500">
                        +{$installations.length - 3} more {terminology.organizations.toLowerCase()}
                      </div>
                    {/if}
                  </div>
                </div>

                <!-- Current Session -->
                <div class="bg-gray-50 dark:bg-gray-800 rounded-lg p-4">
                  <div class="flex items-center justify-between mb-3">
                    <h4 class="font-medium text-gray-900 dark:text-gray-100">Current Session</h4>
                    <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400">
                      Active
                    </span>
                  </div>
                  <div class="space-y-2 text-sm text-gray-600 dark:text-gray-400">
                    <div class="flex justify-between">
                      <span>Selected Org:</span>
                      <span>{$selectedInstallation?.name || 'None'}</span>
                    </div>
                    <div class="flex justify-between">
                      <span>Last Check:</span>
                      <span>{lastDiagnosticsCheck ? new Intl.DateTimeFormat('en-US', { 
                        hour: '2-digit', 
                        minute: '2-digit',
                        second: '2-digit'
                      }).format(lastDiagnosticsCheck) : 'Never'}</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          {/if}
        </Card>

        <!-- Settings Information -->
        <div class="bg-brand-tertiary rounded-lg p-6 border border-brand-secondary">
          <div class="flex items-start">
            <div class="flex-shrink-0">
              <svg class="w-6 h-6" style="color: #009bff;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <div class="ml-4">
              <h3 class="text-lg font-semibold text-brand-primary mb-2">About Default {capitalizedOrganization}</h3>
              <p class="text-brand-secondary">
                When you set a default {terminology.organization.toLowerCase()}, it will be automatically selected when you log in or refresh the application. 
                You can still switch between {terminology.organizations.toLowerCase()} at any time using the dropdown in the sidebar. 
                Your preference is saved locally in your browser.
              </p>
            </div>
          </div>
      </div>
    </div>
</PageLayout>