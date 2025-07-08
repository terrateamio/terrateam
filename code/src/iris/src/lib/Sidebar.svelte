<script lang="ts">
  import { user, githubUser, logout } from './auth';
  import { installations, selectedInstallation, installationsLoading, installationsError, theme, currentVCSProvider } from './stores';
  import type { Installation } from './types';
  import { analytics } from './analytics';
  import { sentryService } from './sentry';
  import { shouldShowSubscriptionMenu } from './utils/environment';
  import { createEventDispatcher } from 'svelte';
  import { VCS_PROVIDERS } from './vcs/providers';

  export let activeItem: string = 'getting-started';
  export let mobile: boolean = false;

  const dispatch = createEventDispatcher();
  
  // Get current VCS provider terminology
  $: currentProvider = $currentVCSProvider || 'github';
  $: terminology = VCS_PROVIDERS[currentProvider]?.terminology || VCS_PROVIDERS.github.terminology;

  async function handleLogout(): Promise<void> {
    await logout();
    window.location.hash = '#/login';
  }

  function handleInstallationChange(e: Event): void {
    const target = e.target as HTMLSelectElement;
    const installation: Installation | undefined = $installations.find(inst => inst.id === target.value);
    if (installation) {
      // Track installation switch
      analytics.trackInstallationSwitch(installation.id, installation.name);
      
      // Update user properties
      analytics.setUserProperties({
        installation_id: installation.id,
        organization: installation.name,
        tier: installation.tier?.name
      });
      
      // Set Sentry installation context
      try {
        sentryService.setInstallationContext(
          installation.id,
          installation.name,
          installation.tier?.name
        );
        sentryService.trackUserAction('installation_switched', {
          installation_id: installation.id,
          installation_name: installation.name
        });
      } catch (sentryError) {
        console.warn('Sentry context update failed:', sentryError);
      }
      
      selectedInstallation.set(installation);
      
      // Navigate to the new installation-scoped URL
      const currentHash = window.location.hash;
      const currentInstallationMatch = currentHash.match(/^#\/i\/[^\/]+(.*)$/);
      
      if (currentInstallationMatch) {
        // User is currently on an installation-scoped page, preserve the path
        const remainingPath = currentInstallationMatch[1] || '/dashboard';
        window.location.hash = `#/i/${installation.id}${remainingPath}`;
      } else {
        // User is on a global page or unrecognized route, go to dashboard
        window.location.hash = `#/i/${installation.id}/dashboard`;
      }
    }
  }

  // Clear URL parameters when navigating away from screens that use them
  function clearURLParamsAndNavigate(path: string): void {
    // Global pages that should NOT be installation-scoped
    const globalPages = ['/getting-started', '/login', '/settings', '/support', '/auth/callback'];
    const isGlobalPage = globalPages.some(globalPath => path.includes(globalPath));
    
    // Build path - use installation-scoped path only if we have a selected installation
    // Otherwise use non-installation-scoped path for demo mode
    let finalPath: string;
    if (isGlobalPage) {
      finalPath = path;
    } else if ($selectedInstallation) {
      finalPath = `#/i/${$selectedInstallation.id}${path.replace('#', '')}`;
    } else {
      // No installation selected - use non-installation-scoped route
      finalPath = path;
    }
    
    // Don't clear parameters for runs page
    if (!path.includes('/runs') && typeof window !== 'undefined') {
      const url = new URL(window.location.href);
      url.searchParams.delete('q'); // Clear run search parameters
      window.history.replaceState({}, '', url.toString());
    }
    
    // Track navigation
    const from = activeItem;
    const to = path.replace('#/', '');
    analytics.trackNavigation(from, to);
    
    // Add Sentry breadcrumb for navigation
    try {
      sentryService.trackPageNavigation(from, to);
    } catch (sentryError) {
      console.warn('Sentry navigation tracking failed:', sentryError);
    }
    
    // Close mobile menu if on mobile
    if (mobile) {
      dispatch('navigate');
    }
    
    window.location.hash = finalPath;
  }

  // Reactive logo path based on theme
  // Note: The file naming is counterintuitive:
  // - logo-wordmark-light.svg = dark logo (for light backgrounds)
  // - logo-wordmark-dark.svg = light logo (for dark backgrounds)
  $: logoPath = (() => {
    if ($theme === 'dark') {
      return '/assets/images/logo-wordmark-dark.svg';  // light logo for dark background
    } else if ($theme === 'light') {
      return '/assets/images/logo-wordmark-light.svg'; // dark logo for light background
    } else {
      // System theme - check if dark mode is currently active
      const isDarkMode = document.documentElement.classList.contains('dark');
      return isDarkMode ? '/assets/images/logo-wordmark-dark.svg' : '/assets/images/logo-wordmark-light.svg';
    }
  })();
</script>

<div class="{mobile ? 'bg-white dark:bg-gray-900 shadow-xl' : 'bg-white dark:bg-gray-800'} fixed left-0 top-0 w-64 h-screen border-r border-gray-200 dark:border-gray-700 flex flex-col overflow-y-auto">
  <!-- Logo and Mobile Close Button -->
  <div class="flex items-center justify-between px-6 py-6 border-b border-gray-200 dark:border-gray-700">
    <a href="/" class="block">
      <img src={logoPath} alt="Terrateam" class="h-12" />
    </a>
    {#if mobile}
      <button
        on:click={() => dispatch('navigate')}
        class="md:hidden p-2 rounded-md text-gray-500 hover:text-gray-900 dark:text-gray-400 dark:hover:text-gray-100 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
        aria-label="Close navigation menu"
      >
        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
        </svg>
      </button>
    {/if}
  </div>
  
  <!-- Organization Selector -->
  {#if !$installationsLoading && $installations.length > 0}
    <div class="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
      <!-- Label -->
      <label for="organization-select" class="block text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-2">
        {terminology.organization}
      </label>
      
      <!-- Selector -->
      <div class="relative">
        <select
          id="organization-select"
          class="appearance-none relative block w-full px-3 py-2.5 bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 text-gray-900 dark:text-gray-100 rounded-lg shadow-sm hover:border-gray-400 dark:hover:border-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-colors text-sm font-medium"
          on:change={handleInstallationChange}
          value={$selectedInstallation?.id || ''}
        >
          <option value="" disabled>Select {terminology.organization}...</option>
          {#each $installations as installation}
            <option value={installation.id}>
              {installation.name}
            </option>
          {/each}
        </select>
        <div class="absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none">
          <svg class="h-4 w-4 text-gray-500 dark:text-gray-400" fill="none" viewBox="0 0 20 20" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 7l3-3 3 3m0 6l-3 3-3-3" />
          </svg>
        </div>
      </div>
      
      <!-- Organization Info -->
      {#if $selectedInstallation}
        <div class="mt-3 space-y-2">
          <!-- First row: Tier and Trial Info -->
          <div class="flex items-center space-x-2 text-xs">
            <!-- Tier Badge -->
            {#if $selectedInstallation.tier && $selectedInstallation.tier.name.toLowerCase() !== 'unknown'}
              <span class="inline-flex items-center px-2 py-0.5 rounded-full font-medium
                {$selectedInstallation.tier.name.toLowerCase() === 'enterprise' ? 'bg-purple-100 text-purple-800 dark:bg-purple-900/30 dark:text-purple-400' : 
                 $selectedInstallation.tier.name.toLowerCase() === 'pro' ? 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-400' : 
                 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300'}">
                {$selectedInstallation.tier.name}
              </span>
            {:else if currentProvider === 'gitlab'}
              <!-- For GitLab, show a default plan badge when tier is unknown -->
              <span class="inline-flex items-center px-2 py-0.5 rounded-full font-medium bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300">
                Free
              </span>
            {/if}
            
            <!-- Organization/Group Count -->
            <span class="text-gray-500 dark:text-gray-400 text-xs">
              {$installations.length} {$installations.length === 1 ? 
                (currentProvider === 'github' ? 'org' : 'group') : 
                (currentProvider === 'github' ? 'orgs' : 'groups')}
            </span>
          </div>
          
          <!-- Second row: Trial Badge (if exists) -->
          {#if $selectedInstallation.trial_ends_at}
            {@const daysLeft = Math.ceil((new Date($selectedInstallation.trial_ends_at).getTime() - Date.now()) / (1000 * 60 * 60 * 24))}
            {#if daysLeft > 0}
              <div>
                <span class="inline-flex items-center px-2 py-0.5 rounded-full font-medium bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400 text-xs">
                  Trial: {daysLeft} days left
                </span>
              </div>
            {/if}
          {/if}
        </div>
      {/if}
    </div>
  {:else if $installationsLoading}
    <div class="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
      <div class="animate-pulse">
        <div class="h-2 w-20 bg-gray-200 dark:bg-gray-700 rounded mb-2"></div>
        <div class="h-10 bg-gray-200 dark:bg-gray-700 rounded"></div>
      </div>
    </div>
  {:else if $installationsError}
    <div class="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
      <div class="text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-2">
        {terminology.organization}
      </div>
      <div class="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-3">
        <div class="flex items-center">
          <svg class="w-4 h-4 text-red-500 dark:text-red-400 mr-2 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.882 16.5c-.77.833.192 2.5 1.732 2.5z" />
          </svg>
          <span class="text-xs text-red-600 dark:text-red-400">
            Failed to load {terminology.organizations}
          </span>
        </div>
      </div>
    </div>
  {:else}
    <!-- No installations - demo mode -->
    <div class="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
      <div class="text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-2">
        {terminology.organization}
      </div>
      <div class="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-3">
        <div class="flex items-center">
          <svg class="w-4 h-4 text-blue-500 dark:text-blue-400 mr-2 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <span class="text-xs text-blue-600 dark:text-blue-400">
            Demo mode - No {terminology.organizations} connected
          </span>
        </div>
      </div>
    </div>
  {/if}
  
  <!-- Navigation -->
  <nav class="flex-1 px-4 py-6 space-y-2">
    <!-- Setup Section -->
    <div class="px-3 mb-2">
      <h3 class="text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider">Setup</h3>
    </div>
    <button 
      on:click={() => clearURLParamsAndNavigate('#/getting-started')}
      class="flex items-center px-3 py-2 text-sm font-medium rounded-md w-full text-left {activeItem === 'getting-started' ? '' : 'text-gray-600 dark:text-gray-300 hover:text-gray-900 dark:hover:text-gray-100 hover:bg-gray-50 dark:hover:bg-gray-700'}"
      style={activeItem === 'getting-started' ? 'color: #009bff; background-color: rgba(0, 155, 255, 0.1);' : ''}
    >
      <svg class="w-5 h-5 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.746 0 3.332.477 4.5 1.253v13C19.832 18.477 18.246 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
      </svg>
      Getting Started
    </button>
    <button 
      on:click={() => clearURLParamsAndNavigate('#/configuration')}
      class="flex items-center px-3 py-2 text-sm font-medium rounded-md w-full text-left {activeItem === 'configuration' ? '' : 'text-gray-600 dark:text-gray-300 hover:text-gray-900 dark:hover:text-gray-100 hover:bg-gray-50 dark:hover:bg-gray-700'}"
      style={activeItem === 'configuration' ? 'color: #009bff; background-color: rgba(0, 155, 255, 0.1);' : ''}
    >
      <svg class="w-5 h-5 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
      </svg>
      Configuration
    </button>
    <button 
      on:click={() => clearURLParamsAndNavigate('#/repositories')}
      class="flex items-center px-3 py-2 text-sm font-medium rounded-md w-full text-left {activeItem === 'repositories' ? '' : 'text-gray-600 dark:text-gray-300 hover:text-gray-900 dark:hover:text-gray-100 hover:bg-gray-50 dark:hover:bg-gray-700'}"
      style={activeItem === 'repositories' ? 'color: #009bff; background-color: rgba(0, 155, 255, 0.1);' : ''}
    >
      <svg class="w-5 h-5 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
      </svg>
      Repositories
    </button>
    
    <!-- Operations Section -->
    <div class="px-3 mt-6 mb-2">
      <h3 class="text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider">Operations</h3>
    </div>
    <button 
      on:click={() => clearURLParamsAndNavigate('#/dashboard')}
      class="flex items-center px-3 py-2 text-sm font-medium rounded-md w-full text-left {activeItem === 'dashboard' ? '' : 'text-gray-600 dark:text-gray-300 hover:text-gray-900 dark:hover:text-gray-100 hover:bg-gray-50 dark:hover:bg-gray-700'}"
      style={activeItem === 'dashboard' ? 'color: #009bff; background-color: rgba(0, 155, 255, 0.1);' : ''}
    >
      <svg class="w-5 h-5 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2H5a2 2 0 00-2-2z" />
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 5a2 2 0 012-2h4a2 2 0 012 2v6H8V5z" />
      </svg>
      Dashboard
    </button>
    <button 
      on:click={() => clearURLParamsAndNavigate('#/workspaces')}
      class="flex items-center px-3 py-2 text-sm font-medium rounded-md w-full text-left {activeItem === 'workspaces' ? '' : 'text-gray-600 dark:text-gray-300 hover:text-gray-900 dark:hover:text-gray-100 hover:bg-gray-50 dark:hover:bg-gray-700'}"
      style={activeItem === 'workspaces' ? 'color: #009bff; background-color: rgba(0, 155, 255, 0.1);' : ''}
    >
      <svg class="w-5 h-5 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 7v10c0 2.21 3.582 4 8 4s8-1.79 8-4V7M4 7c0 2.21 3.582 4 8 4s8-1.79 8-4M4 7c0-2.21 3.582-4 8-4s8 1.79 8 4m0 5c0 2.21-3.582 4-8 4s-8-1.79-8-4" />
      </svg>
      Workspaces
    </button>
    <button 
      on:click={() => clearURLParamsAndNavigate('#/runs')}
      class="flex items-center px-3 py-2 text-sm font-medium rounded-md w-full text-left {activeItem === 'runs' ? '' : 'text-gray-600 dark:text-gray-300 hover:text-gray-900 dark:hover:text-gray-100 hover:bg-gray-50 dark:hover:bg-gray-700'}"
      style={activeItem === 'runs' ? 'color: #009bff; background-color: rgba(0, 155, 255, 0.1);' : ''}
    >
      <svg class="w-5 h-5 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z" />
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
      Runs
    </button>
    <button 
      on:click={() => clearURLParamsAndNavigate('#/analytics')}
      class="flex items-center px-3 py-2 text-sm font-medium rounded-md w-full text-left {activeItem === 'analytics' ? '' : 'text-gray-600 dark:text-gray-300 hover:text-gray-900 dark:hover:text-gray-100 hover:bg-gray-50 dark:hover:bg-gray-700'}"
      style={activeItem === 'analytics' ? 'color: #009bff; background-color: rgba(0, 155, 255, 0.1);' : ''}
    >
      <svg class="w-5 h-5 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
      </svg>
      Analytics
    </button>
    
    <!-- Administration Section -->
    <div class="px-3 mt-6 mb-2">
      <h3 class="text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider">Administration</h3>
    </div>
    <!-- Subscription - Hide if subscription UI is disabled -->
    {#if shouldShowSubscriptionMenu()}
      <button 
        on:click={() => clearURLParamsAndNavigate('#/subscription')}
        class="flex items-center px-3 py-2 text-sm font-medium rounded-md w-full text-left {activeItem === 'subscription' ? '' : 'text-gray-600 dark:text-gray-300 hover:text-gray-900 dark:hover:text-gray-100 hover:bg-gray-50 dark:hover:bg-gray-700'}"
        style={activeItem === 'subscription' ? 'color: #009bff; background-color: rgba(0, 155, 255, 0.1);' : ''}
      >
        <svg class="w-5 h-5 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z" />
        </svg>
        Subscription
      </button>
    {/if}
    <button 
      on:click={() => clearURLParamsAndNavigate('#/support')}
      class="flex items-center px-3 py-2 text-sm font-medium rounded-md w-full text-left {activeItem === 'support' ? '' : 'text-gray-600 dark:text-gray-300 hover:text-gray-900 dark:hover:text-gray-100 hover:bg-gray-50 dark:hover:bg-gray-700'}"
      style={activeItem === 'support' ? 'color: #009bff; background-color: rgba(0, 155, 255, 0.1);' : ''}
    >
      <svg class="w-5 h-5 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
      Support
    </button>
    <button 
      on:click={() => clearURLParamsAndNavigate('#/settings')}
      class="flex items-center px-3 py-2 text-sm font-medium rounded-md w-full text-left {activeItem === 'settings' ? '' : 'text-gray-600 dark:text-gray-300 hover:text-gray-900 dark:hover:text-gray-100 hover:bg-gray-50 dark:hover:bg-gray-700'}"
      style={activeItem === 'settings' ? 'color: #009bff; background-color: rgba(0, 155, 255, 0.1);' : ''}
    >
      <svg class="w-5 h-5 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
      </svg>
      Settings
    </button>
  </nav>
  
  <!-- User section -->
  <div class="border-t border-gray-200 dark:border-gray-700 p-4">
    {#if $user}
      <div class="flex items-center justify-between">
        <div class="flex items-center flex-1">
          {#if $githubUser?.avatar_url}
            <img class="h-8 w-8 rounded-full" src={$githubUser.avatar_url} alt={$githubUser.username} />
          {:else}
            <div class="flex-shrink-0 w-8 h-8 bg-blue-600 rounded-full flex items-center justify-center">
              <span class="text-white text-sm font-medium">
                {$githubUser?.username?.charAt(0)?.toUpperCase() || $user.id.charAt(0).toUpperCase()}
              </span>
            </div>
          {/if}
          <div class="ml-3 flex-1">
            <p class="text-sm font-medium text-gray-900 dark:text-gray-100">
              {$githubUser?.username || `${$user.id.substring(0, 8)}...`}
            </p>
            <button
              on:click={handleLogout}
              class="text-xs text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300"
            >
              Sign out
            </button>
          </div>
        </div>
        
        <!-- Theme Toggle -->
        <div class="relative ml-3">
          <button
            on:click={() => {
              const newTheme = $theme === 'dark' ? 'light' : 'dark';
              theme.setTheme(newTheme);
            }}
            class="p-2 rounded-md text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
            aria-label="Toggle theme"
            title={$theme === 'dark' ? 'Switch to light mode' : 'Switch to dark mode'}
          >
            {#if $theme === 'dark'}
              <!-- Sun icon for dark mode (click to go to light) -->
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z" />
              </svg>
            {:else}
              <!-- Moon icon for light mode (click to go to dark) -->
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z" />
              </svg>
            {/if}
          </button>
        </div>
      </div>
    {/if}
  </div>
</div>
