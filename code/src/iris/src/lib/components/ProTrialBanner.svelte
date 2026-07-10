<script lang="ts">
  import { onMount } from 'svelte';
  import { selectedInstallation } from '../stores';
  import { areTrialBannersEnabled, getTrialDaysRemaining } from '../utils/environment';

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

  // What's lost when the Pro trial ends and the account drops to Free.
  // Free keeps every feature but is capped at 50 runs/month, 3 users,
  // and 1 private runner.
  const allFeatures = [
    'Unlimited runs (Free: 50/month)',
    'Unlimited users (Free: 3)',
    'Unlimited private runners (Free: 1)',
    'Unlimited concurrency',
    'Priority support (email and Slack)',
    '365-day audit retention (Free: 30-day)'
  ];

  // Calculate days remaining reactively
  $: daysRemaining = $selectedInstallation?.trial_ends_at
    ? getTrialDaysRemaining($selectedInstallation.trial_ends_at)
    : null;

  // Determine if we should show the banner
  // Tier name may include a date suffix like "pro-2026-07-10"
  $: isProTier = $selectedInstallation?.tier?.name?.toLowerCase().startsWith('pro') ?? false;

  $: shouldShowBanner =
    areTrialBannersEnabled() &&
    isProTier &&
    daysRemaining !== null &&
    daysRemaining > 0;

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
  <div class="w-full {urgencyLevel === 'critical' ? 'bg-gradient-to-r from-[var(--sg-orange-bg)] to-[var(--sg-error-bg)] border-b border-[var(--sg-orange)]' : urgencyLevel === 'warning' ? 'bg-gradient-to-r from-[var(--sg-amber-bg)] to-[var(--sg-orange-bg)] border-b border-[var(--sg-amber)]' : 'bg-gradient-to-r from-[var(--sg-indigo-bg)] via-[var(--sg-purple-bg)] to-[var(--sg-pink-bg)] border-b border-[var(--sg-indigo)]'}">
    <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
      <div class="flex items-center justify-between py-3 gap-4">
        <!-- Left side: Emoji + Message -->
        <div class="flex items-center flex-1 min-w-0 gap-3">
          <!-- Emoji -->
          <span class="text-2xl flex-shrink-0" aria-hidden="true">{currentMessage.emoji}</span>

          <!-- Text content -->
          <div class="flex-1 min-w-0">
            <div class="flex flex-wrap items-center gap-x-2 gap-y-1">
              <span class="font-bold {urgencyLevel === 'critical' ? 'text-[var(--sg-orange)]' : urgencyLevel === 'warning' ? 'text-[var(--sg-amber)]' : 'text-[var(--sg-text)]'}">
                {currentMessage.headline}
              </span>
              <span class="text-sm {urgencyLevel === 'critical' ? 'text-[var(--sg-orange)]' : urgencyLevel === 'warning' ? 'text-[var(--sg-amber)]' : 'text-[var(--sg-text-dim)]'}">
                {currentMessage.subtext}
              </span>
            </div>

            <!-- Days countdown + features toggle -->
            <div class="mt-1 flex flex-wrap items-center gap-x-3 gap-y-1 text-xs">
              <span class="inline-flex items-center gap-1 font-semibold {urgencyLevel === 'critical' ? 'text-[var(--sg-error)]' : urgencyLevel === 'warning' ? 'text-[var(--sg-orange)]' : 'text-[var(--sg-indigo)]'}">
                <svg class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                {daysText} left
              </span>
              <button
                type="button"
                on:click={toggleFeatures}
                class="{urgencyLevel === 'critical' ? 'text-[var(--sg-orange)] hover:opacity-80' : urgencyLevel === 'warning' ? 'text-[var(--sg-amber)] hover:opacity-80' : 'text-[var(--sg-indigo)] hover:opacity-80'} hover:underline"
              >
                {showAllFeatures ? 'Hide features' : 'What you\'ll lose →'}
              </button>
            </div>

            <!-- Expandable feature list -->
            {#if showAllFeatures}
              <div class="mt-2 p-2 rounded-md {urgencyLevel === 'critical' ? 'bg-[var(--sg-orange-bg)]' : urgencyLevel === 'warning' ? 'bg-[var(--sg-amber-bg)]' : 'bg-[var(--sg-bg-1)]'}">
                <div class="grid grid-cols-2 md:grid-cols-3 gap-x-4 gap-y-1 text-xs {urgencyLevel === 'critical' ? 'text-[var(--sg-orange)]' : urgencyLevel === 'warning' ? 'text-[var(--sg-amber)]' : 'text-[var(--sg-text-muted)]'}">
                  {#each allFeatures as feature}
                    <span class="flex items-center gap-1">
                      <svg class="h-3 w-3 flex-shrink-0 {urgencyLevel === 'critical' ? 'text-[var(--sg-error)]' : urgencyLevel === 'warning' ? 'text-[var(--sg-orange)]' : 'text-[var(--sg-indigo)]'}" fill="currentColor" viewBox="0 0 20 20">
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
            class="inline-flex items-center gap-1.5 rounded-full {urgencyLevel === 'critical' ? 'bg-[var(--sg-error)] hover:opacity-90' : urgencyLevel === 'warning' ? 'bg-[var(--sg-orange)] hover:opacity-90' : 'bg-[var(--sg-indigo)] hover:opacity-90'} px-4 py-2 text-sm font-semibold text-white shadow-sm focus:outline-none focus:ring-2 focus:ring-offset-2 {urgencyLevel === 'critical' ? 'focus:ring-[var(--sg-error)]' : urgencyLevel === 'warning' ? 'focus:ring-[var(--sg-orange)]' : 'focus:ring-[var(--sg-indigo)]'} transition-all hover:scale-105"
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
