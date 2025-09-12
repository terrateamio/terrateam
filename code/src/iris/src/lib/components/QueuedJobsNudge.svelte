<script lang="ts">
  import { selectedInstallation } from '../stores';
  import { areUpgradeNudgesEnabled } from '../utils/environment';
  import { api } from '../api';
  import { onMount, onDestroy } from 'svelte';
  import AlertBanner from './ui/AlertBanner.svelte';
  
  let runningCount: number = 0;
  let isLoading: boolean = false;
  let checkInterval: NodeJS.Timeout | null = null;
  let isDismissed: boolean = false;
  
  // Check for running jobs
  async function checkRunningJobs(): Promise<void> {
    if (!$selectedInstallation || !areUpgradeNudgesEnabled()) {
      runningCount = 0;
      return;
    }
    
    // Only check for Free tier
    if ($selectedInstallation?.tier?.name?.toLowerCase() !== 'free') {
      runningCount = 0;
      return;
    }
    
    isLoading = true;
    
    try {
      const response = await api.getInstallationDirspaces($selectedInstallation.id, {
        tz: Intl.DateTimeFormat().resolvedOptions().timeZone,
        q: 'state:running',
        limit: 10
      });
      
      if (response && 'dirspaces' in response) {
        runningCount = response.dirspaces.length;
      }
    } catch (err) {
      console.error('Error checking running jobs for worker limit nudge:', err);
      runningCount = 0;
    } finally {
      isLoading = false;
    }
  }
  
  // Check when installation changes
  $: if ($selectedInstallation) {
    checkRunningJobs();
  }
  
  onMount(() => {
    // Initial check
    checkRunningJobs();
    
    // Check every 30 seconds for running jobs
    checkInterval = setInterval(() => {
      if (!isDismissed) {
        checkRunningJobs();
      }
    }, 30 * 1000);
  });
  
  onDestroy(() => {
    if (checkInterval) {
      clearInterval(checkInterval);
      checkInterval = null;
    }
  });
  
  function handleDismiss() {
    isDismissed = true;
    // Session-based dismissal - will show again on page refresh
  }
  
  // Determine if we should show the alert
  $: shouldShowAlert = !isLoading && !isDismissed && runningCount > 1;
  
  // Calculate "queued" jobs (fake - just running minus 1)
  $: queuedCount = Math.max(0, runningCount - 1);
</script>

{#if shouldShowAlert}
  <AlertBanner
    kind="info"
    headline={queuedCount === 1 
      ? "Job queued due to worker limit."
      : `${queuedCount} jobs queued due to worker limit.`}
    subtext="Upgrade to Basic for 5 concurrent workers."
    primaryAction={{ label: 'Upgrade now', href: '#/subscription' }}
    secondaryAction={null}
    dismissible={true}
    onDismiss={handleDismiss}
    storageKey={null}
  />
{/if}

