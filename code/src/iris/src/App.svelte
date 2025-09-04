<script lang="ts">
  import { onMount } from 'svelte';
  import router from 'svelte-spa-router';
  import { isAuthenticated, isLoading, getCurrentUser, redirectToIntendedUrl } from './lib/auth';
  import { api, isApiError } from './lib/api';
  import {
    installations,
    selectedInstallation,
    installationsLoading,
    installationsError,
    defaultInstallationId,
    theme,
    hasVisitedBefore,
    markAsVisited,
    currentVCSProvider,
    serverConfig
  } from './lib/stores';
  import { getMaintenanceConfig } from './lib/utils/maintenance';
  import MaintenanceMode from './lib/MaintenanceMode.svelte';
  import Login from './lib/Login.svelte';
  import Dashboard from './lib/Dashboard.svelte';
  import GettingStarted from './lib/GettingStarted.svelte';
  import Repositories from './lib/Repositories.svelte';
  import RepositoryDetail from './lib/RepositoryDetail.svelte';
  import Workspaces from './lib/Workspaces.svelte';
  import WorkspaceDetail from './lib/WorkspaceDetail.svelte';
  import Runs from './lib/Runs.svelte';
  import RunDetail from './lib/RunDetail.svelte';
  import Configuration from './lib/Configuration.svelte';
  import Subscription from './lib/Subscription.svelte';
  import Support from './lib/Support.svelte';
  import Settings from './lib/Settings.svelte';
  import AuthCallback from './lib/AuthCallback.svelte';
  import Analytics from './lib/Analytics.svelte';
  import AuditTrail from './lib/AuditTrail.svelte';
  import RootHandler from './lib/components/layout/RootHandler.svelte';
  
  // Check for maintenance mode
  const maintenanceConfig = getMaintenanceConfig();
  
  // Define routes - installation-scoped routes with fallbacks for demo mode
  const routes = {
    '/': RootHandler,
    '/login': Login,
    '/getting-started': GettingStarted,
    '/settings': Settings,
    '/support': Support,
    '/auth/callback': AuthCallback,
    
    // Non-installation-scoped routes for demo mode (when no installations)
    '/dashboard': Dashboard,
    '/repositories': Repositories,
    '/repositories/:id': RepositoryDetail,
    '/workspaces': Workspaces,
    '/workspaces/:repo/:dir/:workspace': WorkspaceDetail,
    '/runs': Runs,
    '/runs/:id': RunDetail,
    '/configuration': Configuration,
    '/subscription': Subscription,
    '/analytics': Analytics,
    '/audit-trail': AuditTrail,
    
    // Installation-scoped routes (when installations exist)
    '/i/:installationId/dashboard': Dashboard,
    '/i/:installationId/repositories': Repositories,
    '/i/:installationId/repositories/:id': RepositoryDetail,
    '/i/:installationId/workspaces': Workspaces,
    '/i/:installationId/workspaces/:repo/:dir/:workspace': WorkspaceDetail,
    '/i/:installationId/runs': Runs,
    '/i/:installationId/runs/:id': RunDetail,
    '/i/:installationId/configuration': Configuration,
    '/i/:installationId/subscription': Subscription,
    '/i/:installationId/analytics': Analytics,
    '/i/:installationId/audit-trail': AuditTrail,
  };
  
  // Auto-redirect authenticated users based on intended URL or whether they've visited before
  // Only redirect when we have all the data we need (auth + installations loaded)
  $: if (!maintenanceConfig.isMaintenanceMode && $isAuthenticated && !$isLoading && installationsInitialized && !$installationsLoading && (window.location.hash === '#/' || window.location.hash === '')) {
    
    // First priority: Check for stored intended URL
    const redirectedToIntended = redirectToIntendedUrl();
    if (redirectedToIntended) {
    } else {
      // Fallback: Based on whether they've visited before  
      // We now know installations are loaded, so we can make the decision
      if ($installations.length === 0) {
        // User has no installations, redirect to getting started regardless
        window.location.hash = '#/getting-started';
        if (!$hasVisitedBefore) {
          markAsVisited();
        }
      } else if ($selectedInstallation) {
        // User has installations and one is selected
        if ($hasVisitedBefore) {
          window.location.hash = `#/i/${$selectedInstallation.id}/dashboard`;
        } else {
          window.location.hash = '#/getting-started';
          markAsVisited(); // Mark as visited when they first see getting started
        }
      } else {
        // Installations exist but none selected yet - wait for selection to complete
      }
    }
  }
  
  // Load installations when user is authenticated (only once)
  let installationsInitialized = false;
  $: if (!maintenanceConfig.isMaintenanceMode && $isAuthenticated && !$isLoading && !installationsInitialized) {
    installationsInitialized = true;
    loadInstallations();
  }

  async function loadServerConfig() {
    try {
      const config = await api.getServerConfig();
      serverConfig.set(config);
    } catch (err) {
      console.error('Failed to load server config:', err);
      // Non-critical, continue without server config
    }
  }

  async function loadInstallations() {
    if ($installationsLoading) return;
    
    installationsLoading.set(true);
    installationsError.set(null);
    
    try {
      const provider = $currentVCSProvider;
      const response = await api.getUserInstallations(provider);
      
      if (response && response.installations) {
        installations.set(response.installations);
        
        // Auto-select installation based on default setting or first available
        if (response.installations.length > 0 && !$selectedInstallation) {
          let installationToSelect = response.installations[0];
          
          // Try to find the default installation if one is set
          if ($defaultInstallationId) {
            const defaultInstallation = response.installations.find(inst => inst.id === $defaultInstallationId);
            if (defaultInstallation) {
              installationToSelect = defaultInstallation;
            } else {
            }
          } else {
          }
          
          selectedInstallation.set(installationToSelect);
        }
      } else {
        console.warn('No installations found in response:', response);
        installations.set([]);
      }
    } catch (err) {
      console.error('Error loading installations:', err);
      
      // For GitLab, if we get a 404, treat it as "no installations" rather than an error
      // This handles the case where the GitLab installations endpoint isn't implemented yet
      if ($currentVCSProvider === 'gitlab' && isApiError(err) && err.status === 404) {
        installations.set([]);
        installationsError.set(null);
      } else {
        installationsError.set('Failed to load installations');
        installations.set([]);
      }
    } finally {
      installationsLoading.set(false);
    }
  }
  
  // Handle legacy URL redirects
  function handleLegacyUrlRedirect() {
    const path = window.location.pathname;
    
    // Check for installation-scoped URLs (both shallow and deep)
    // Example: /i/{installation_id} → #/i/{installation_id}/dashboard
    // Example: /i/{installation_id}/runs/{run_id} → #/i/{installation_id}/runs/{run_id}
    const legacyInstallationMatch = path.match(/^\/i\/(\d+)(\/.*)?$/i);
    if (legacyInstallationMatch) {
      const [, installationId, restOfPath] = legacyInstallationMatch;
      
      // Store installation ID for auto-selection
      try {
        sessionStorage.setItem('legacy_redirect_installation_id', installationId);
      } catch (e) {
        console.warn('Could not store installation ID in session storage:', e);
      }
      
      // If there's a deeper path (like /runs/xxx), preserve it in the hash
      if (restOfPath && restOfPath !== '/') {
        window.location.replace(`${window.location.origin}/#/i/${installationId}${restOfPath}`);
      } else {
        // Just /i/{id} or /i/{id}/ - redirect to root and let auto-redirect handle it
        window.location.replace(`${window.location.origin}/#/`);
      }
      return true;
    }
    
    return false;
  }

  onMount(async () => {
    // Skip all initialization if in maintenance mode
    if (maintenanceConfig.isMaintenanceMode) {
      return;
    }
    
    // Initialize theme on app start
    theme.init();
    
    // Handle legacy URL redirects before anything else
    if (handleLegacyUrlRedirect()) {
      return; // Exit early if we're redirecting
    }

    await loadServerConfig();
    await getCurrentUser();
  });
</script>

{#if maintenanceConfig.isMaintenanceMode}
  <MaintenanceMode message={maintenanceConfig.message} />
{:else if $isLoading}
  <div class="min-h-screen bg-gray-50 dark:bg-gray-900 flex items-center justify-center">
    <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 dark:border-blue-400"></div>
  </div>
{:else}
  <svelte:component this={router} {routes} />
{/if}
