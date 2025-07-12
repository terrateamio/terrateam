<script lang="ts">
  import { onMount } from 'svelte';
  import { getServerConfig, initializeGitHubLogin, authError } from './auth';
  import type { ServerConfig } from './types';
  import type { VCSProvider } from './vcs/types';
  import { VCS_PROVIDERS } from './vcs/providers';
  import { setVCSProvider } from './stores';
  import { Icon } from './components';
  
  let isLoading: boolean = true;
  let error: string | null = null;
  let serverConfig: ServerConfig | null = null;
  let availableProviders: VCSProvider[] = [];
  
  onMount(async () => {
    try {
      serverConfig = await getServerConfig();
      
      // Determine available providers based on server config
      const providers: VCSProvider[] = [];
      if (serverConfig.github) {
        providers.push('github');
      }
      if (serverConfig.gitlab) {
        providers.push('gitlab');
      }
      availableProviders = providers;
      
      // If no providers are configured in server config, show GitHub as fallback
      // This handles the case where the backend doesn't return provider config
      if (availableProviders.length === 0) {
        console.warn('No providers configured in server config, defaulting to GitHub');
        availableProviders = ['github'];
      }
      
    } catch (err) {
      error = 'Failed to load server configuration';
      console.error('Error loading server config:', err);
    } finally {
      isLoading = false;
    }
  });
  
  async function handleProviderLogin(provider: VCSProvider): Promise<void> {
    setVCSProvider(provider);
    
    if (provider === 'github') {
      if (serverConfig?.github) {
        const clientId = serverConfig.github.app_client_id;
        try {
          initializeGitHubLogin(clientId);
        } catch (err) {
          console.error('Error in initializeGitHubLogin:', err);
        }
      } else {
        // Fallback: Try legacy endpoint for GitHub client ID
        try {
          const response = await fetch('/api/v1/github/client_id');
          const data = await response.json();
          if (data.client_id) {
            initializeGitHubLogin(data.client_id);
          } else {
            error = 'GitHub client ID not available';
          }
        } catch (err) {
          console.error('Failed to get GitHub client ID:', err);
          error = 'Failed to initialize GitHub login';
        }
      }
    } else if (provider === 'gitlab') {
      if (serverConfig?.gitlab) {
        const appId = serverConfig.gitlab.app_id;
        const redirectUrl = serverConfig.gitlab.redirect_url;
        try {
          // GitLab OAuth flow
          const params = new URLSearchParams({
            client_id: appId,
            redirect_uri: redirectUrl,
            response_type: 'code',
            scope: 'api',
            state: 'gitlab_login'
          });
          window.location.href = `${serverConfig.gitlab.web_base_url}/oauth/authorize?${params.toString()}`;
        } catch (err) {
          console.error('Error in GitLab login:', err);
          error = 'Failed to initialize GitLab login';
        }
      } else {
        console.error('No GitLab configuration available');
        error = 'GitLab login is not configured';
      }
    } else {
      console.error(`No ${provider} configuration available`);
    }
  }
  
</script>

<div class="min-h-screen bg-gray-50 flex flex-col justify-center py-12 sm:px-6 lg:px-8">
  <div class="sm:mx-auto sm:w-full sm:max-w-md">
    <div class="text-center">
      <img src="/assets/images/logo-wordmark.svg" alt="Logo" class="h-12 mx-auto mb-4" />
      <h2 class="text-xl text-gray-600">Sign in to your account</h2>
    </div>
  </div>

  <div class="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
    <div class="bg-white py-8 px-4 shadow sm:rounded-lg sm:px-10">
      {#if isLoading}
        <div class="flex justify-center py-12">
          <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-brand-primary"></div>
        </div>
      {:else if error}
        <div class="bg-red-50 border border-red-200 rounded-md p-4 mb-6">
          <div class="flex">
            <div class="flex-shrink-0">
              <svg class="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
              </svg>
            </div>
            <div class="ml-3">
              <h3 class="text-sm font-medium text-red-800">Authentication Error</h3>
              <div class="mt-2 text-sm text-red-700">
                <p>{error}</p>
              </div>
            </div>
          </div>
        </div>
      {/if}

      <div class="space-y-4">
        {#if availableProviders.length === 0}
          <div class="text-center text-gray-600">
            No authentication providers configured.
          </div>
        {:else if availableProviders.length === 1}
          <!-- Single provider - show direct login button -->
          {#if availableProviders[0] === 'github'}
            <button
              on:click={() => handleProviderLogin('github')}
              disabled={!serverConfig?.github}
              class="w-full flex justify-center items-center px-4 py-3 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-gray-900 hover:bg-gray-800 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-500 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <Icon icon="mdi:github" class="mr-3" width="20" />
              Sign in with GitHub
            </button>
          {:else if availableProviders[0] === 'gitlab'}
            <button
              on:click={() => handleProviderLogin('gitlab')}
              disabled={!serverConfig?.gitlab}
              class="w-full flex justify-center items-center px-4 py-3 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-orange-600 hover:bg-orange-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-orange-500 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <Icon icon="mdi:gitlab" class="mr-3" width="20" />
              Sign in with GitLab
            </button>
          {/if}
        {:else}
          <!-- Multiple providers - show selection -->
          <div class="text-center text-sm text-gray-600 mb-4">
            Choose your version control provider:
          </div>
          {#each availableProviders as provider}
            {@const config = VCS_PROVIDERS[provider]}
            <button
              on:click={() => handleProviderLogin(provider)}
              class="w-full flex justify-center items-center px-4 py-3 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-brand-primary transition-colors"
            >
              <Icon icon={config.icon} class="mr-3" width="20" />
              Sign in with {config.displayName}
            </button>
          {/each}
        {/if}

        {#if $authError}
          <div class="bg-red-50 border border-red-200 rounded-md p-4">
            <div class="text-sm text-red-700">
              <p><strong>Authentication failed:</strong> {$authError}</p>
            </div>
          </div>
        {/if}

      </div>
      
      <div class="mt-6">
        <div class="text-center text-sm text-gray-600">
          Secure authentication powered by OAuth
        </div>
      </div>
    </div>
  </div>
</div>
