<script lang="ts">
  import LoadingSpinner from '../ui/LoadingSpinner.svelte';
  import { installations, installationsError, installationsLoading } from '../../stores';
  import { loadInstallations } from '../../installations';

  // Only treat this as a hard error when the load failed AND we have no
  // last-known-good installations to fall back on. With a cache present we
  // never block here — App.svelte routes the user straight to their workspace.
  $: showError = !!$installationsError && !$installationsLoading && $installations.length === 0;

  function retry(): void {
    loadInstallations(true);
  }
</script>

{#if showError}
  <!-- Failed to load installations with nothing cached -->
  <div class="min-h-screen bg-brand-bg flex items-center justify-center">
    <div class="text-center max-w-md px-6">
      <div class="inline-flex items-center justify-center w-16 h-16 rounded-full mb-6 brand-icon-bg">
        <svg class="w-8 h-8 text-[var(--sg-text)]" fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01M5.07 19h13.86c1.54 0 2.5-1.67 1.73-3L13.73 4c-.77-1.33-2.69-1.33-3.46 0L3.34 16c-.77 1.33.19 3 1.73 3z" />
        </svg>
      </div>
      <h2 class="text-2xl font-semibold text-[var(--sg-text)] mb-4">Couldn't load your installations</h2>
      <p class="text-[var(--sg-text-muted)] mb-6">
        We couldn't reach Terrateam to load your organizations. This is usually temporary — please try again.
      </p>
      <button
        on:click={retry}
        class="px-4 py-2 bg-[var(--sg-accent)] text-white rounded-md hover:opacity-90 transition-opacity"
      >
        Try again
      </button>
    </div>
  </div>
{:else}
  <!-- Authentication Loading Screen -->
  <div class="min-h-screen bg-brand-bg flex items-center justify-center">
    <div class="text-center">
      <div class="inline-flex items-center justify-center w-16 h-16 rounded-full mb-6 brand-icon-bg">
        <svg class="w-8 h-8 text-[var(--sg-text)]" fill="currentColor" viewBox="0 0 24 24">
          <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/>
        </svg>
      </div>
      <h2 class="text-2xl font-semibold text-[var(--sg-text)] mb-4">Setting up your workspace...</h2>
      <LoadingSpinner size="md" />
      <p class="text-[var(--sg-text-muted)] mt-4">Loading your installations and preferences</p>
    </div>
  </div>
{/if}
