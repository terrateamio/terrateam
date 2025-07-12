<script lang="ts">
  import { isAuthenticated, isLoading } from '../../auth';
  import AuthenticationLoader from './AuthenticationLoader.svelte';
  import Login from '../../Login.svelte';

  // Show different components based on auth state
  $: {
    if ($isLoading) {
      // Still checking auth status - show loading
    } else if (!$isAuthenticated) {
      // Not authenticated - redirect to login
      window.location.hash = '#/login';
    }
    // If authenticated, show AuthenticationLoader which will be replaced by App.svelte redirect logic
  }
</script>

{#if $isLoading}
  <!-- Auth status still loading -->
  <AuthenticationLoader />
{:else if !$isAuthenticated}
  <!-- Not authenticated - this shouldn't show since we redirect above, but just in case -->
  <Login />
{:else}
  <!-- Authenticated - show loader while installations load -->
  <AuthenticationLoader />
{/if}