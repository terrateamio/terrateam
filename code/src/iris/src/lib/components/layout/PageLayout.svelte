<script lang="ts">
  import { isAuthenticated, storeIntendedUrl } from '../../auth';
  import { installations, installationsLoading, currentVCSProvider } from '../../stores';
  import Sidebar from '../../Sidebar.svelte';
  import { VCS_PROVIDERS } from '../../vcs/providers';

  export let activeItem: string;
  export let title: string;
  export let subtitle: string = '';
  export let showHeader: boolean = true;

  // Mobile menu state
  let mobileMenuOpen = false;
  
  // Get current VCS provider terminology
  $: currentProvider = $currentVCSProvider || 'github';
  $: terminology = VCS_PROVIDERS[currentProvider]?.terminology || VCS_PROVIDERS.github.terminology;

  // Redirect to login if not authenticated, storing the intended URL
  $: if (!$isAuthenticated) {
    storeIntendedUrl();
    window.location.hash = '#/login';
  }

  function toggleMobileMenu() {
    mobileMenuOpen = !mobileMenuOpen;
  }

  function closeMobileMenu() {
    mobileMenuOpen = false;
  }
</script>

<div class="min-h-screen bg-gray-50 dark:bg-gray-900">
  <!-- Desktop Sidebar (hidden on mobile) -->
  <div class="hidden md:block">
    <Sidebar {activeItem} />
  </div>

  <!-- Mobile Menu Overlay -->
  {#if mobileMenuOpen}
    <div class="fixed inset-0 z-50 md:hidden">
      <!-- Backdrop -->
      <div 
        class="fixed inset-0 bg-black bg-opacity-50" 
        role="button" 
        tabindex="0"
        aria-label="Close navigation menu"
        on:click={closeMobileMenu}
        on:keydown={(e) => e.key === 'Escape' && closeMobileMenu()}
      ></div>
      <!-- Mobile Sidebar -->
      <div class="fixed left-0 top-0 w-64 h-full z-50">
        <Sidebar {activeItem} mobile={true} on:navigate={closeMobileMenu} />
      </div>
    </div>
  {/if}

  <!-- Main content -->
  <div class="md:ml-64 flex flex-col min-h-screen">
    {#if showHeader}
      <!-- Header -->
      <header class="shadow bg-blue-600 dark:bg-gray-800">
        <div class="px-4 md:px-6 py-4">
          <div class="flex items-center">
            <!-- Mobile menu button -->
            <button
              class="md:hidden mr-4 p-2 rounded-md text-white bg-white bg-opacity-10 hover:bg-opacity-20 focus:outline-none focus:ring-2 focus:ring-white transition-colors"
              on:click={toggleMobileMenu}
              aria-label="Open navigation menu"
            >
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
              </svg>
            </button>
            
            <div class="flex-1">
              <h1 class="text-lg md:text-2xl font-semibold text-white">{title}</h1>
              {#if subtitle}
                <p class="text-xs md:text-sm text-blue-100 mt-1">{subtitle}</p>
              {/if}
            </div>
          </div>
        </div>
      </header>
    {/if}

    <!-- Getting Started Banner (shown when no installations are connected) -->
    {#if !$installationsLoading && $installations.length === 0 && activeItem !== 'getting-started' && activeItem !== 'login'}
      <div class="bg-gradient-to-r from-green-50 to-blue-50 dark:from-green-900/20 dark:to-blue-900/20 border-b border-green-200 dark:border-green-800">
        <div class="px-4 md:px-6 py-3">
          <div class="flex items-center justify-between">
            <div class="flex items-center space-x-3">
              <div class="flex-shrink-0">
                <svg class="w-6 h-6 text-green-600 dark:text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
                </svg>
              </div>
              <div>
                <p class="text-sm font-medium text-green-800 dark:text-green-200">
                  Ready to get started with Terrateam?
                </p>
                <p class="text-xs text-green-700 dark:text-green-300">
                  Connect your {VCS_PROVIDERS[currentProvider].displayName} {terminology.organization.toLowerCase()} to start automating your Terraform workflows
                </p>
              </div>
            </div>
            <button
              class="flex items-center space-x-2 bg-green-600 hover:bg-green-700 dark:bg-green-700 dark:hover:bg-green-600 text-white px-4 py-2 rounded-lg text-sm font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2"
              on:click={() => window.location.hash = '#/getting-started'}
              aria-label="Go to getting started page"
            >
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.746 0 3.332.477 4.5 1.253v13C19.832 18.477 18.246 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
              </svg>
              <span>Get Started</span>
            </button>
          </div>
        </div>
      </div>
    {/if}

    <!-- Content -->
    <main class="flex-1 p-4 md:p-6">
      <slot />
    </main>
  </div>
</div>