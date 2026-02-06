<script lang="ts">
  import { selectedInstallation } from './stores';
  import { analytics } from './analytics';
  import { isSaasBillingMode } from './utils/environment';
  import PageLayout from './components/layout/PageLayout.svelte';
  import Button from './components/ui/Button.svelte';
  import Card from './components/ui/Card.svelte';

  // Make subscription mode reactive
  $: isInSaasMode = isSaasBillingMode();

  function handleManageBilling(): void {
    analytics.trackBillingAction('manage_billing_clicked');
    window.open('https://billing.stripe.com/p/login/00geXngL2cQR0YofYY', '_blank');
  }

  function handleContactSales(): void {
    analytics.trackBillingAction('contact_sales_clicked');
    window.open('https://terrateam.io/contact', '_blank');
  }
</script>

<svelte:head>
  <script async src="https://js.stripe.com/v3/pricing-table.js"></script>
</svelte:head>

<PageLayout
  activeItem="subscription"
  title={isInSaasMode
    ? ($selectedInstallation
      ? `Manage billing for ${$selectedInstallation.name}`
      : "Manage your subscription and billing")
    : "Enterprise options for self-hosted users"}
>
  <div class="max-w-[1664px] mx-auto">

    <!-- Self-hosted Environment Message -->
    {#if !isInSaasMode}
      <div class="text-center py-16">
        <!-- Hero Icon -->
        <div class="inline-flex items-center justify-center w-24 h-24 rounded-full bg-gradient-to-br from-blue-100 to-indigo-100 dark:from-blue-900/30 dark:to-indigo-900/30 mb-8">
          <svg class="w-12 h-12 text-blue-600 dark:text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z" />
          </svg>
        </div>

        <!-- Hero Content -->
        <h1 class="text-4xl font-bold text-gray-900 dark:text-gray-100 mb-4">
          Self-Hosted Terrateam
        </h1>
        <p class="text-xl text-gray-600 dark:text-gray-400 mb-12 max-w-3xl mx-auto">
          You're running the open-source version. Unlock enterprise features with centralized configuration,
          advanced security, and dedicated support.
        </p>

        <!-- Plan Comparison -->
        <div class="grid lg:grid-cols-2 gap-8 max-w-5xl mx-auto mb-12">

          <!-- Current Plan -->
          <Card padding="lg" class="text-left relative">
            <div class="mb-6">
              <div class="flex items-center mb-4">
                <div class="w-12 h-12 bg-green-100 dark:bg-green-900/30 rounded-lg flex items-center justify-center mr-4">
                  <svg class="w-6 h-6 text-green-600 dark:text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                  </svg>
                </div>
                <div>
                  <h3 class="text-2xl font-bold text-gray-900 dark:text-gray-100">Open Source</h3>
                  <p class="text-sm text-gray-500 dark:text-gray-400">What you're using now</p>
                </div>
              </div>
            </div>

            <div class="space-y-4">
              <div class="flex items-start">
                <svg class="w-5 h-5 text-green-500 mr-3 mt-1 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                </svg>
                <span class="text-gray-700 dark:text-gray-300">Core Terraform automation</span>
              </div>
              <div class="flex items-start">
                <svg class="w-5 h-5 text-green-500 mr-3 mt-1 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                </svg>
                <span class="text-gray-700 dark:text-gray-300">Full infrastructure control</span>
              </div>
              <div class="flex items-start">
                <svg class="w-5 h-5 text-green-500 mr-3 mt-1 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                </svg>
                <span class="text-gray-700 dark:text-gray-300">Private environment hosting</span>
              </div>
              <div class="flex items-start">
                <svg class="w-5 h-5 text-green-500 mr-3 mt-1 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                </svg>
                <span class="text-gray-700 dark:text-gray-300">Community support</span>
              </div>
            </div>
          </Card>

          <!-- Enterprise Plan -->
          <Card padding="lg" class="text-left relative bg-gradient-to-br from-blue-50 to-indigo-50 dark:from-blue-900/20 dark:to-indigo-900/20 border-2 border-blue-200 dark:border-blue-700">
            <!-- Popular Badge -->
            <div class="absolute -top-3 left-6">
              <span class="bg-blue-600 text-white px-4 py-1 rounded-full text-xs font-semibold uppercase tracking-wide">
                Recommended
              </span>
            </div>

            <div class="mb-6 pt-2">
              <div class="flex items-center mb-4">
                <div class="w-12 h-12 bg-blue-100 dark:bg-blue-900/30 rounded-lg flex items-center justify-center mr-4">
                  <svg class="w-6 h-6 text-blue-600 dark:text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
                  </svg>
                </div>
                <div>
                  <h3 class="text-2xl font-bold text-gray-900 dark:text-gray-100">Enterprise Self-Hosted</h3>
                  <p class="text-sm text-blue-600 dark:text-blue-400 font-medium">Scale with confidence</p>
                </div>
              </div>
            </div>

            <div class="space-y-4">
              <div class="flex items-start">
                <svg class="w-5 h-5 text-blue-500 mr-3 mt-1 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                </svg>
                <span class="text-gray-700 dark:text-gray-300"><strong>Everything in Open Source</strong></span>
              </div>
              <div class="flex items-start">
                <svg class="w-5 h-5 text-blue-500 mr-3 mt-1 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                </svg>
                <span class="text-gray-700 dark:text-gray-300">Centralized configuration management</span>
              </div>
              <div class="flex items-start">
                <svg class="w-5 h-5 text-blue-500 mr-3 mt-1 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                </svg>
                <span class="text-gray-700 dark:text-gray-300">Advanced RBAC and security</span>
              </div>
              <div class="flex items-start">
                <svg class="w-5 h-5 text-blue-500 mr-3 mt-1 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                </svg>
                <span class="text-gray-700 dark:text-gray-300">Priority support with SLA</span>
              </div>
              <div class="flex items-start">
                <svg class="w-5 h-5 text-blue-500 mr-3 mt-1 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                </svg>
                <span class="text-gray-700 dark:text-gray-300">Custom integrations</span>
              </div>
            </div>
          </Card>

        </div>

        <!-- CTA Button -->
        <div class="flex justify-center gap-4">
          <Button
            variant="accent"
            size="lg"
            on:click={handleContactSales}
            class="min-w-[200px]"
          >
            Contact Sales
          </Button>
        </div>
      </div>
    {:else}
      <!-- SaaS Mode - Show Stripe Pricing Table -->
      <div class="py-8">
        <!-- Current Subscription Info -->
        {#if $selectedInstallation}
          <div class="mb-8 text-center">
            <h2 class="text-2xl font-bold text-gray-900 dark:text-gray-100 mb-4">
              Subscription for {$selectedInstallation.name}
            </h2>
            {#if $selectedInstallation.tier?.name}
              <p class="text-gray-600 dark:text-gray-400">
                Current tier: <span class="font-semibold capitalize">{$selectedInstallation.tier.name}</span>
              </p>
            {/if}
          </div>
        {/if}

        <!-- Manage Billing Button -->
        <div class="mb-8 text-center">
          <Button
            variant="primary"
            size="md"
            on:click={handleManageBilling}
          >
            Manage Billing Portal
          </Button>
        </div>

        <!-- Stripe Pricing Table -->
        <div class="max-w-6xl mx-auto">
          <stripe-pricing-table
            pricing-table-id="prctbl_1SxvXECgvqrOzjiX8RSDgkcO"
            publishable-key="pk_live_51L5snICgvqrOzjiXc1uOhAIpPQxNO8ohf4ew34zsilOHF1ZTT7fqjhTob6BccqNmKjreh3f0dsj6JWQVsKfqUewj00DFDgiz87"
          >
          </stripe-pricing-table>
        </div>
      </div>
    {/if}

  </div>
</PageLayout>

<style>
  /* Ensure Stripe pricing table is visible and styled correctly */
  :global(stripe-pricing-table) {
    width: 100%;
  }
</style>
