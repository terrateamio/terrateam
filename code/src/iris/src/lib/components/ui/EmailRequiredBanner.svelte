<script lang="ts">
  import { onMount } from 'svelte';
  import { selectedInstallation } from '../../stores';
  import EmailRequiredModal from './EmailRequiredModal.svelte';

  const MAX_DISMISSALS = 3;
  let dismissCount = 0;
  let showModal = false;
  let showBanner = true;

  // Get localStorage key for current installation
  $: storageKey = $selectedInstallation ? `email-banner-dismissed-${$selectedInstallation.id}` : null;

  // Load dismiss count from localStorage
  onMount(() => {
    if (storageKey && typeof window !== 'undefined') {
      const stored = localStorage.getItem(storageKey);
      if (stored) {
        dismissCount = parseInt(stored, 10);
      }
    }
  });

  // Check if we should show modal instead of banner
  $: shouldShowModal = dismissCount >= MAX_DISMISSALS;

  function handleDismiss() {
    if (!storageKey) return;

    dismissCount += 1;
    if (typeof window !== 'undefined') {
      localStorage.setItem(storageKey, dismissCount.toString());
    }

    if (dismissCount >= MAX_DISMISSALS) {
      showBanner = false;
      showModal = true;
    } else {
      showBanner = false;
    }
  }

  function handleAddEmail() {
    showBanner = false;
    showModal = true;
  }

  function handleModalClose() {
    showModal = false;
  }

  function handleEmailSubmitted() {
    // Clear localStorage when email is successfully submitted
    if (storageKey && typeof window !== 'undefined') {
      localStorage.removeItem(storageKey);
    }
    showModal = false;
    showBanner = false;
  }
</script>

{#if shouldShowModal || showModal}
  <!-- Show dismissible modal after max dismissals or when user clicks "Add Email" -->
  <EmailRequiredModal
    dismissible={true}
    on:close={handleModalClose}
    on:submitted={handleEmailSubmitted}
  />
{:else if showBanner}
  <!-- Persistent banner at top of page -->
  <div class="bg-orange-50 dark:bg-orange-900/30 border-b border-orange-200 dark:border-orange-800">
    <div class="px-4 md:px-6 py-3">
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
        <!-- Message -->
        <div class="flex items-start space-x-3">
          <div class="flex-shrink-0 mt-0.5">
            <svg class="w-5 h-5 text-orange-600 dark:text-orange-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
            </svg>
          </div>
          <div class="flex-1">
            <p class="text-sm font-semibold text-orange-900 dark:text-orange-100">
              Contact email required for {$selectedInstallation?.name || 'your organization'}
            </p>
            <p class="text-xs text-orange-800 dark:text-orange-300 mt-0.5">
              An organization-level contact email is required under our Terms of Service for billing notifications, critical security alerts, and service notices.
            </p>
          </div>
        </div>

        <!-- Actions -->
        <div class="flex items-center space-x-3 sm:flex-shrink-0">
          <button
            class="text-sm text-orange-700 dark:text-orange-400 hover:text-orange-900 dark:hover:text-orange-200 font-medium transition-colors focus:outline-none focus:underline"
            on:click={handleDismiss}
            aria-label="Remind me later"
          >
            Remind me later
          </button>
          <button
            class="bg-orange-600 hover:bg-orange-700 dark:bg-orange-700 dark:hover:bg-orange-600 text-white px-4 py-2 rounded-lg text-sm font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-orange-500 focus:ring-offset-2"
            on:click={handleAddEmail}
            aria-label="Add contact email"
          >
            Add Email
          </button>
        </div>
      </div>
    </div>
  </div>
{/if}
