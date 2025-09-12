<script lang="ts">
  import { selectedInstallation } from '../stores';
  import { areUpgradeNudgesEnabled, getRunLimitThreshold, getRunLimit70Threshold, getRunLimit90Threshold, getBillingPeriodDates } from '../utils/environment';
  import { api } from '../api';
  import { onMount, onDestroy } from 'svelte';
  import AlertBanner from './ui/AlertBanner.svelte';
  
  let runLimitAlertLevel: '70' | '90' | 'over' | null = null;
  let totalRunCount: number = 0;
  let isLoading: boolean = false;
  let checkInterval: NodeJS.Timeout | null = null;
  let isCollapsed: boolean = false;
  let daysRemaining: number = 0;
  
  // Check run count periodically
  async function checkRunCount(): Promise<void> {
    if (!$selectedInstallation || !areUpgradeNudgesEnabled()) {
      runLimitAlertLevel = null;
      return;
    }
    
    // Only check for Free tier
    if ($selectedInstallation?.tier?.name?.toLowerCase() !== 'free') {
      runLimitAlertLevel = null;
      return;
    }
    
    isLoading = true;
    
    try {
      // Calculate current billing period based on installation creation date
      if (!$selectedInstallation.created_at) {
        // Fallback to rolling 30-day window if no created_at
        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
        const dateFilter = thirtyDaysAgo.toISOString().split('T')[0];
        
        const params = { 
          tz: Intl.DateTimeFormat().resolvedOptions().timeZone,
          q: `created_at:${dateFilter}..`,
          limit: 100 // API caps at 100
        };
        
        const response = await api.getInstallationDirspaces($selectedInstallation.id, params);
        
        if (response && 'dirspaces' in response) {
          totalRunCount = response.dirspaces.length;
        }
      } else {
        // Use billing period based on installation creation date
        const billingPeriod = getBillingPeriodDates($selectedInstallation.created_at);
        daysRemaining = billingPeriod.daysRemaining;
        
        // Format dates for API query
        const startDate = billingPeriod.start.toISOString().split('T')[0];
        const endDate = billingPeriod.end.toISOString().split('T')[0];
        
        const params = { 
          tz: Intl.DateTimeFormat().resolvedOptions().timeZone,
          q: `created_at:${startDate}..${endDate}`,
          limit: 100 // API caps at 100
        };
        
        const response = await api.getInstallationDirspaces($selectedInstallation.id, params);
        
        if (response && 'dirspaces' in response) {
          totalRunCount = response.dirspaces.length;
        }
      }
      
      // Determine alert level based on thresholds
      if (totalRunCount >= getRunLimitThreshold()) {
        runLimitAlertLevel = 'over';
      } else if (totalRunCount >= getRunLimit90Threshold()) {
        runLimitAlertLevel = '90';
      } else if (totalRunCount >= getRunLimit70Threshold()) {
        runLimitAlertLevel = '70';
      } else {
        runLimitAlertLevel = null;
      }
    } catch (err) {
      console.error('Error checking run count for upgrade nudge:', err);
      runLimitAlertLevel = null;
    } finally {
      isLoading = false;
    }
  }
  
  // Check when installation changes
  $: if ($selectedInstallation) {
    checkRunCount();
  }
  
  onMount(() => {
    // Initial check
    checkRunCount();
    
    // Check every 5 minutes
    checkInterval = setInterval(() => {
      checkRunCount();
    }, 5 * 60 * 1000);
  });
  
  onDestroy(() => {
    if (checkInterval) {
      clearInterval(checkInterval);
      checkInterval = null;
    }
  });
  
  // Handle dismissal/snooze based on alert level
  function handleDismiss() {
    if (runLimitAlertLevel === '70') {
      // Snooze for 7 days
      const snoozeUntil = new Date();
      snoozeUntil.setDate(snoozeUntil.getDate() + 7);
      if (typeof window !== 'undefined') {
        try {
          localStorage.setItem('terrateam-upgrade-nudge-70-snooze', snoozeUntil.toISOString());
        } catch (e) {
          // Ignore localStorage errors
        }
      }
    }
  }
  
  function handleCollapse() {
    isCollapsed = !isCollapsed;
  }
  
  // Check if 70% warning is snoozed
  function isWarningSnozzed(): boolean {
    if (typeof window !== 'undefined') {
      try {
        const snoozeUntil = localStorage.getItem('terrateam-upgrade-nudge-70-snooze');
        if (snoozeUntil) {
          const snoozeDate = new Date(snoozeUntil);
          if (snoozeDate > new Date()) {
            return true;
          } else {
            // Snooze expired, clear it
            localStorage.removeItem('terrateam-upgrade-nudge-70-snooze');
          }
        }
      } catch (e) {
        // Ignore localStorage errors
      }
    }
    return false;
  }
  
  // Determine if we should show the alert
  $: shouldShowAlert = runLimitAlertLevel && !isLoading && 
    !(runLimitAlertLevel === '70' && isWarningSnozzed());
</script>

{#if shouldShowAlert}
  {#if runLimitAlertLevel === '90' && isCollapsed}
    <!-- Collapsed chip for 90% state -->
    <div class="w-full bg-rose-50 dark:bg-amber-950/10 border-b border-rose-100 dark:border-amber-900/20">
      <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div class="flex items-center justify-between py-1">
          <button
            on:click={handleCollapse}
            class="flex items-center gap-2 text-sm text-rose-800 dark:text-amber-200 hover:opacity-80"
          >
            <svg class="h-3 w-3 text-rose-500 dark:text-amber-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <span class="font-medium">{getRunLimitThreshold() - totalRunCount} runs left</span>
            <span class="text-rose-600 dark:text-amber-300/80">· {daysRemaining} days left in billing period</span>
            <svg class="h-3 w-3 ml-1" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
            </svg>
          </button>
          <a
            href="#/subscription"
            class="text-sm font-medium text-blue-600 hover:text-blue-500 dark:text-blue-400 dark:hover:text-blue-300"
          >
            Upgrade
          </a>
        </div>
      </div>
    </div>
  {:else if runLimitAlertLevel}
    <!-- Full alert banner with custom collapse for 90% -->
    <div class="relative">
      <AlertBanner
        kind={runLimitAlertLevel === 'over' ? 'critical' : 'warning'}
        headline={runLimitAlertLevel === 'over' 
          ? 'Free plan is out of runs for this billing period.'
          : runLimitAlertLevel === '90'
          ? `Only ${getRunLimitThreshold() - totalRunCount} runs left this period.`
          : `${totalRunCount} of ${getRunLimitThreshold()} runs used this period.`}
        subtext={runLimitAlertLevel === 'over' 
          ? 'Upgrade to keep running operations.'
          : runLimitAlertLevel === '90'
          ? 'Upgrade to avoid interruptions.'
          : 'Upgrade for unlimited runs.'}
        primaryAction={{ label: 'Upgrade now', href: '#/subscription' }}
        secondaryAction={null}
        dismissible={runLimitAlertLevel === '70' || runLimitAlertLevel === '90'}
        onDismiss={runLimitAlertLevel === '70' ? handleDismiss : runLimitAlertLevel === '90' ? handleCollapse : undefined}
        storageKey={null}
      />
    </div>
  {/if}
{/if}

