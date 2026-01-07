<script lang="ts">
  import { onMount } from 'svelte';
  import { selectedInstallation } from '../stores';
  import { areTrialBannersEnabled, getTrialDaysRemaining } from '../utils/environment';

  // DEBUG MODE: Set localStorage.setItem('debug_trial_banner', 'true') in console to preview
  // Remove with: localStorage.removeItem('debug_trial_banner')
  const isDebugMode = typeof window !== 'undefined' && localStorage.getItem('debug_trial_banner') === 'true';
  const debugDaysRemaining = 14; // Mock days for debug mode

  // Playful messages that rotate - personality-driven copy
  const messages = [
    {
      headline: "We made pricing stupid cheap.",
      subtext: "Like, half-an-EC2-instance cheap. Help us out here.",
      emoji: "🙏"
    },
    {
      headline: "It's freezing in Amsterdam.",
      subtext: "Your subscription keeps Malcolm & Josh warm.",
      emoji: "🥶"
    },
    {
      headline: "Your trial's winding down.",
      subtext: "But the infrastructure magic doesn't have to stop.",
      emoji: "✨"
    },
    {
      headline: "Two devs, one dream.",
      subtext: "And that dream is you clicking 'Upgrade'.",
      emoji: "🫶"
    },
    {
      headline: "We could've charged more.",
      subtext: "But we like you. Don't make it weird.",
      emoji: "😅"
    }
  ];

  // Pick a random message on mount (stable per session)
  let messageIndex = 0;
  onMount(() => {
    messageIndex = Math.floor(Math.random() * messages.length);
  });

  $: currentMessage = messages[messageIndex];

  // Features included in Regulated tier (that will be lost when dropping to Startup)
  const regulatedFeatures = [
    'API access',
    'CODEOWNERS integration',
    'Role-based access control',
    'Gatekeeper approvals',
    'Centralized config',
    '365-day audit retention'
  ];

  // Features included in Growth tier (also lost when dropping to Startup)
  const growthFeatures = [
    'Scheduled drift detection',
    'Programmatic config generation',
    'Customer-owned plan storage',
    'Apply requirements',
    'Email support',
    '90-day audit retention'
  ];

  // Combined features for display
  const allFeatures = [...growthFeatures, ...regulatedFeatures];

  // Calculate days remaining reactively
  $: daysRemaining = isDebugMode
    ? debugDaysRemaining
    : ($selectedInstallation?.trial_ends_at
        ? getTrialDaysRemaining($selectedInstallation.trial_ends_at)
        : null);

  // Determine if we should show the banner
  // Tier name may include a date suffix like "regulated-2026-01-07"
  $: isRegulatedTier = isDebugMode || ($selectedInstallation?.tier?.name?.toLowerCase().startsWith('regulated') ?? false);

  $: shouldShowBanner =
    isDebugMode ||
    (areTrialBannersEnabled() &&
    isRegulatedTier &&
    daysRemaining !== null &&
    daysRemaining > 0);

  // Format days remaining text
  $: daysText = daysRemaining === 1 ? '1 day' : `${daysRemaining} days`;

  // Urgency level affects styling
  $: urgencyLevel = daysRemaining !== null && daysRemaining <= 3 ? 'critical' : daysRemaining !== null && daysRemaining <= 7 ? 'warning' : 'normal';

  // Show expanded feature list
  let showAllFeatures = false;

  function toggleFeatures(): void {
    showAllFeatures = !showAllFeatures;
  }
</script>

{#if shouldShowBanner}
  <div class="w-full {urgencyLevel === 'critical' ? 'bg-gradient-to-r from-orange-50 to-red-50 dark:from-orange-950/20 dark:to-red-950/20 border-b border-orange-200 dark:border-orange-900/30' : urgencyLevel === 'warning' ? 'bg-gradient-to-r from-amber-50 to-orange-50 dark:from-amber-950/20 dark:to-orange-950/20 border-b border-amber-200 dark:border-amber-900/30' : 'bg-gradient-to-r from-indigo-50 via-purple-50 to-pink-50 dark:from-indigo-950/20 dark:via-purple-950/20 dark:to-pink-950/20 border-b border-indigo-100 dark:border-indigo-900/30'}">
    <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
      <div class="flex items-center justify-between py-3 gap-4">
        <!-- Left side: Emoji + Message -->
        <div class="flex items-center flex-1 min-w-0 gap-3">
          <!-- Emoji -->
          <span class="text-2xl flex-shrink-0" aria-hidden="true">{currentMessage.emoji}</span>

          <!-- Text content -->
          <div class="flex-1 min-w-0">
            <div class="flex flex-wrap items-center gap-x-2 gap-y-1">
              <span class="font-bold {urgencyLevel === 'critical' ? 'text-orange-900 dark:text-orange-100' : urgencyLevel === 'warning' ? 'text-amber-900 dark:text-amber-100' : 'text-gray-900 dark:text-gray-100'}">
                {currentMessage.headline}
              </span>
              <span class="text-sm {urgencyLevel === 'critical' ? 'text-orange-700 dark:text-orange-300' : urgencyLevel === 'warning' ? 'text-amber-700 dark:text-amber-300' : 'text-gray-600 dark:text-gray-400'}">
                {currentMessage.subtext}
              </span>
            </div>

            <!-- Days countdown + features toggle -->
            <div class="mt-1 flex flex-wrap items-center gap-x-3 gap-y-1 text-xs">
              <span class="inline-flex items-center gap-1 font-semibold {urgencyLevel === 'critical' ? 'text-red-600 dark:text-red-400' : urgencyLevel === 'warning' ? 'text-orange-600 dark:text-orange-400' : 'text-indigo-600 dark:text-indigo-400'}">
                <svg class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                {daysText} left
              </span>
              <button
                type="button"
                on:click={toggleFeatures}
                class="{urgencyLevel === 'critical' ? 'text-orange-600 hover:text-orange-700 dark:text-orange-400 dark:hover:text-orange-300' : urgencyLevel === 'warning' ? 'text-amber-600 hover:text-amber-700 dark:text-amber-400 dark:hover:text-amber-300' : 'text-indigo-600 hover:text-indigo-700 dark:text-indigo-400 dark:hover:text-indigo-300'} hover:underline"
              >
                {showAllFeatures ? 'Hide features' : 'What you\'ll lose →'}
              </button>
            </div>

            <!-- Expandable feature list -->
            {#if showAllFeatures}
              <div class="mt-2 p-2 rounded-md {urgencyLevel === 'critical' ? 'bg-orange-100/50 dark:bg-orange-900/20' : urgencyLevel === 'warning' ? 'bg-amber-100/50 dark:bg-amber-900/20' : 'bg-white/50 dark:bg-gray-800/50'}">
                <div class="grid grid-cols-2 md:grid-cols-3 gap-x-4 gap-y-1 text-xs {urgencyLevel === 'critical' ? 'text-orange-800 dark:text-orange-200' : urgencyLevel === 'warning' ? 'text-amber-800 dark:text-amber-200' : 'text-gray-700 dark:text-gray-300'}">
                  {#each allFeatures as feature}
                    <span class="flex items-center gap-1">
                      <svg class="h-3 w-3 flex-shrink-0 {urgencyLevel === 'critical' ? 'text-red-500' : urgencyLevel === 'warning' ? 'text-orange-500' : 'text-indigo-500'}" fill="currentColor" viewBox="0 0 20 20">
                        <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
                      </svg>
                      {feature}
                    </span>
                  {/each}
                </div>
              </div>
            {/if}
          </div>
        </div>

        <!-- Right side: CTA -->
        <div class="flex-shrink-0">
          <a
            href="#/subscription"
            class="inline-flex items-center gap-1.5 rounded-full {urgencyLevel === 'critical' ? 'bg-red-600 hover:bg-red-500' : urgencyLevel === 'warning' ? 'bg-orange-600 hover:bg-orange-500' : 'bg-indigo-600 hover:bg-indigo-500'} px-4 py-2 text-sm font-semibold text-white shadow-sm focus:outline-none focus:ring-2 focus:ring-offset-2 {urgencyLevel === 'critical' ? 'focus:ring-red-500' : urgencyLevel === 'warning' ? 'focus:ring-orange-500' : 'focus:ring-indigo-500'} transition-all hover:scale-105"
          >
            Keep the magic
            <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M13 7l5 5m0 0l-5 5m5-5H6" />
            </svg>
          </a>
        </div>
      </div>
    </div>
  </div>
{/if}
