<script lang="ts">
  import Card from '../ui/Card.svelte';
  import Button from '../ui/Button.svelte';

  export let isOssMode: boolean = false;
</script>

<Card padding="lg">
  <div class="text-center py-12">
    <!-- Icon -->
    <div class="inline-flex items-center justify-center w-20 h-20 rounded-full bg-purple-100 dark:bg-purple-900/30 mb-6">
      <svg class="w-10 h-10 text-purple-600 dark:text-purple-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1121 9z" />
      </svg>
    </div>

    <!-- Title with Badge -->
    <div class="flex items-center justify-center gap-3 mb-4">
      <h2 class="text-3xl font-bold text-gray-900 dark:text-gray-100">API Access Keys</h2>
      <span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-semibold bg-purple-100 text-purple-800 dark:bg-purple-900/40 dark:text-purple-300">
        ENTERPRISE
      </span>
    </div>

    <!-- Description -->
    <p class="text-xl text-gray-600 dark:text-gray-400 mb-8 max-w-2xl mx-auto">
      {#if isOssMode}
        Programmatic API access is available with Enterprise Edition.
        Upgrade to unlock REST API access for automation and integrations.
      {:else}
        Programmatic API access requires the Enterprise plan.
        Upgrade to unlock REST API access for automation and integrations.
      {/if}
    </p>

    <!-- Feature Grid -->
    <div class="grid md:grid-cols-2 gap-6 max-w-3xl mx-auto mb-8">
      <!-- API Capabilities -->
      <div class="text-left p-6 bg-gray-50 dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700">
        <h3 class="font-semibold text-gray-900 dark:text-gray-100 mb-3">API Capabilities</h3>
        <ul class="space-y-2 text-sm text-gray-700 dark:text-gray-300">
          <li class="flex items-start">
            <svg class="w-4 h-4 text-green-500 mr-2 mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
            </svg>
            Full REST API access
          </li>
          <li class="flex items-start">
            <svg class="w-4 h-4 text-green-500 mr-2 mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
            </svg>
            Token-based authentication
          </li>
          <li class="flex items-start">
            <svg class="w-4 h-4 text-green-500 mr-2 mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
            </svg>
            Scoped permissions
          </li>
          <li class="flex items-start">
            <svg class="w-4 h-4 text-green-500 mr-2 mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
            </svg>
            KV store access
          </li>
        </ul>
      </div>

      <!-- Use Cases -->
      <div class="text-left p-6 bg-gray-50 dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700">
        <h3 class="font-semibold text-gray-900 dark:text-gray-100 mb-3">Use Cases</h3>
        <ul class="space-y-2 text-sm text-gray-700 dark:text-gray-300">
          <li class="flex items-start">
            <svg class="w-4 h-4 text-blue-500 mr-2 mt-0.5 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
              <circle cx="10" cy="10" r="2" />
            </svg>
            CI/CD pipeline integration
          </li>
          <li class="flex items-start">
            <svg class="w-4 h-4 text-blue-500 mr-2 mt-0.5 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
              <circle cx="10" cy="10" r="2" />
            </svg>
            Custom dashboards
          </li>
          <li class="flex items-start">
            <svg class="w-4 h-4 text-blue-500 mr-2 mt-0.5 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
              <circle cx="10" cy="10" r="2" />
            </svg>
            Automated workflows
          </li>
          <li class="flex items-start">
            <svg class="w-4 h-4 text-blue-500 mr-2 mt-0.5 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
              <circle cx="10" cy="10" r="2" />
            </svg>
            Third-party integrations
          </li>
        </ul>
      </div>
    </div>

    <!-- CTA Button -->
    <Button
      variant="accent"
      size="lg"
      on:click={() => {
        if (isOssMode) {
          window.open('https://terrateam.io/contact', '_blank');
        } else {
          window.location.hash = '#/subscription';
        }
      }}
    >
      {isOssMode ? 'Contact Sales' : 'Upgrade to Enterprise'}
    </Button>
  </div>
</Card>
