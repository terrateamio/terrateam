<script lang="ts">
  import LoadingSpinner from '../ui/LoadingSpinner.svelte';
</script>

<!-- Authentication Loading Screen -->
<div class="min-h-screen bg-brand-bg flex items-center justify-center">
  <div class="text-center">
    <div class="inline-flex items-center justify-center w-16 h-16 rounded-full mb-6" style="background-color: rgba(0, 155, 255, 0.1);">
      <svg class="w-8 h-8 text-brand-primary" fill="currentColor" viewBox="0 0 24 24">
        <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/>
      </svg>
    </div>
    <h2 class="text-2xl font-semibold text-brand-primary mb-4">Setting up your workspace...</h2>
    <LoadingSpinner size="md" />
    <p class="text-brand-secondary mt-4">Loading your installations and preferences</p>
  </div>
</div>