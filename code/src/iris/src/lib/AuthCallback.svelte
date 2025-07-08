<script lang="ts">
  import { onMount } from 'svelte';
  import { handleAuthCallback } from './auth';
  
  let isLoading: boolean = true;
  let error: string | null = null;
  
  onMount(async () => {
    try {
      await handleAuthCallback();
      // handleAuthCallback now handles redirects internally
    } catch (err: unknown) {
      error = err instanceof Error ? err.message : 'Authentication failed';
      console.error('Auth callback error:', err);
    } finally {
      isLoading = false;
    }
  });
</script>

<div class="min-h-screen bg-gray-50 flex flex-col justify-center py-12 sm:px-6 lg:px-8">
  <div class="sm:mx-auto sm:w-full sm:max-w-md">
    <div class="bg-white py-8 px-4 shadow sm:rounded-lg sm:px-10">
      {#if isLoading}
        <div class="text-center">
          <div class="animate-spin rounded-full h-8 w-8 border-b-2 mx-auto" style="border-color: #009bff;"></div>
          <p class="mt-4 text-sm text-gray-600">Completing authentication...</p>
        </div>
      {:else if error}
        <div class="text-center">
          <svg class="mx-auto h-12 w-12 text-red-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.732-.833-2.5 0L4.321 15.5c-.77.833.192 2.5 1.732 2.5z" />
          </svg>
          <h3 class="mt-2 text-sm font-medium text-gray-900">Authentication failed</h3>
          <p class="mt-1 text-sm text-gray-500">{error}</p>
          <div class="mt-6">
            <a 
              href="/" 
              class="text-sm font-medium transition-colors accent-link"
            >
              Try again
            </a>
          </div>
        </div>
      {/if}
    </div>
  </div>
</div>