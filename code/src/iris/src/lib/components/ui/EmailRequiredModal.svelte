<script lang="ts">
  import { createEventDispatcher } from 'svelte';
  import { selectedInstallation, currentVCSProvider } from '../../stores';
  import { api } from '../../api';
  import { VCS_PROVIDERS } from '../../vcs/providers';
  import Button from './Button.svelte';

  export let dismissible: boolean = false;

  const dispatch = createEventDispatcher();

  let email: string = '';
  let isSaving = false;
  let error: string | null = null;

  // Get current VCS provider terminology
  $: currentProvider = $currentVCSProvider || 'github';
  $: terminology = VCS_PROVIDERS[currentProvider]?.terminology || VCS_PROVIDERS.github.terminology;

  function handleClose() {
    if (dismissible) {
      dispatch('close');
    }
  }

  async function handleSubmit(): Promise<void> {
    if (!$selectedInstallation) {
      error = 'No installation selected';
      return;
    }

    // Validate email
    if (!email || !email.trim()) {
      error = 'Email address is required';
      return;
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email.trim())) {
      error = 'Please enter a valid email address';
      return;
    }

    isSaving = true;
    error = null;

    try {
      await api.updateInstallationEmail($selectedInstallation.id, email.trim(), currentProvider);

      // Update the selected installation in the store
      if ($selectedInstallation) {
        $selectedInstallation.email = email.trim();
        selectedInstallation.set($selectedInstallation);
      }

      // Dispatch submitted event so parent can clear localStorage
      dispatch('submitted');
    } catch (err) {
      console.error('Failed to save email:', err);
      error = err instanceof Error ? err.message : 'Failed to save email address';
      isSaving = false;
    }
    // Note: Don't set isSaving = false on success, the modal will just disappear
  }
</script>

<!-- Full-screen overlay that blocks everything -->
<div class="fixed inset-0 bg-gray-900 bg-opacity-95 flex items-center justify-center z-50">
  <div class="bg-white dark:bg-gray-800 rounded-lg shadow-2xl max-w-md w-full mx-4 p-8 relative">
    {#if dismissible}
      <!-- Close button (X) -->
      <button
        class="absolute top-4 right-4 text-gray-400 hover:text-gray-600 dark:text-gray-500 dark:hover:text-gray-300 transition-colors focus:outline-none focus:ring-2 focus:ring-brand-primary rounded"
        on:click={handleClose}
        aria-label="Close modal"
        type="button"
      >
        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
        </svg>
      </button>
    {/if}

    <!-- Icon -->
    <div class="flex justify-center mb-6">
      <div class="w-16 h-16 bg-brand-primary bg-opacity-10 rounded-full flex items-center justify-center">
        <svg class="w-8 h-8 text-brand-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
        </svg>
      </div>
    </div>

    <!-- Title -->
    <h2 class="text-2xl font-bold text-gray-900 dark:text-white text-center mb-2">
      Contact email required for {$selectedInstallation?.name || 'your ' + terminology.organization}
    </h2>

    <!-- Description -->
    <p class="text-gray-600 dark:text-gray-300 text-center mb-6">
      {#if dismissible}
        An organization-level contact email is required for <span class="font-semibold">{$selectedInstallation?.name || 'your ' + terminology.organization}</span>. We need this for billing notifications, critical security alerts, and legal notices.
      {:else}
        An organization-level contact email is required for <span class="font-semibold">{$selectedInstallation?.name || 'your ' + terminology.organization}</span>. This is necessary for billing, security, and service notifications.
      {/if}
    </p>

    <!-- Info callout -->
    <div class="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-700 rounded-lg p-3 mb-6">
      <div class="flex items-start space-x-2">
        <svg class="w-5 h-5 text-blue-600 dark:text-blue-400 flex-shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        <div class="text-sm text-blue-800 dark:text-blue-200">
          <strong>One email per organization:</strong> This email will be used for all members of {$selectedInstallation?.name || 'your ' + terminology.organization}.
        </div>
      </div>
    </div>

    <!-- Form -->
    <form on:submit|preventDefault={handleSubmit} class="space-y-4">
      <div>
        <label for="email" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
          Organization email address
        </label>
        <input
          id="email"
          type="email"
          bind:value={email}
          disabled={isSaving}
          required
          placeholder="team@example.com"
          class="w-full px-4 py-3 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-brand-primary focus:border-transparent bg-white dark:bg-gray-700 text-gray-900 dark:text-white placeholder-gray-400 dark:placeholder-gray-500"
        />
      </div>

      {#if error}
        <div class="bg-red-50 dark:bg-red-900 dark:bg-opacity-20 border border-red-200 dark:border-red-800 rounded-lg p-3">
          <p class="text-sm text-red-600 dark:text-red-400">{error}</p>
        </div>
      {/if}

      <Button
        type="submit"
        variant="accent"
        size="lg"
        disabled={isSaving}
        loading={isSaving}
        class="w-full"
      >
        {#if isSaving}
          Saving...
        {:else}
          Save email
        {/if}
      </Button>

      {#if dismissible}
        <button
          type="button"
          class="w-full text-sm text-gray-600 dark:text-gray-400 hover:text-gray-800 dark:hover:text-gray-200 font-medium transition-colors focus:outline-none focus:underline"
          on:click={handleClose}
        >
          I'll add this later
        </button>
      {/if}
    </form>

    <!-- Privacy note -->
    <p class="text-xs text-gray-500 dark:text-gray-400 text-center mt-4">
      We only send operational messages. You can change this later in Settings.
    </p>
  </div>
</div>
