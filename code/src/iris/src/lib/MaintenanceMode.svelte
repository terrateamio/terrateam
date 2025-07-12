<script lang="ts">
  import { onMount } from 'svelte';
  
  interface $$Props {
    message?: string;
  }
  
  export let message: string = 'We are currently performing scheduled maintenance. Please check back shortly.';
  
  let currentTime = new Date().toLocaleString();
  
  onMount(() => {
    // Update time every minute
    const interval = setInterval(() => {
      currentTime = new Date().toLocaleString();
    }, 60000);
    
    return () => clearInterval(interval);
  });
</script>

<div class="min-h-screen bg-gray-50 dark:bg-gray-900 flex items-center justify-center px-4">
  <div class="max-w-md w-full space-y-8 text-center">
    <!-- Terrateam Logo -->
    <div class="flex justify-center">
      <div class="w-20 h-20 flex items-center justify-center">
        <img 
          src="/assets/images/logo-symbol.svg" 
          alt="Terrateam Logo" 
          class="w-16 h-16"
          loading="eager"
        />
      </div>
    </div>
    
    <!-- Maintenance Message -->
    <div class="space-y-6">
      <div>
        <h1 class="text-3xl font-bold text-gray-900 dark:text-white">
          Under Maintenance
        </h1>
        <p class="mt-4 text-lg text-gray-600 dark:text-gray-300">
          {message}
        </p>
      </div>
      
      <!-- Status Indicators -->
      <div class="space-y-4">
        <div class="flex items-center justify-center space-x-2">
          <div class="w-3 h-3 bg-yellow-500 rounded-full animate-pulse" aria-hidden="true"></div>
          <span class="text-sm text-gray-500 dark:text-gray-400">
            System Status: Maintenance Mode
          </span>
        </div>
        
        <div class="text-xs text-gray-400 dark:text-gray-500">
          Last updated: {currentTime}
        </div>
      </div>
      
      <!-- Contact Information -->
      <div class="pt-6 border-t border-gray-200 dark:border-gray-700">
        <p class="text-sm text-gray-500 dark:text-gray-400">
          For urgent issues, please contact our support team:
        </p>
        <div class="mt-2 space-y-1">
          <a 
            href="mailto:support@terrateam.io" 
            class="text-sm text-blue-600 dark:text-blue-400 hover:underline focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 dark:focus:ring-offset-gray-900 rounded"
            aria-label="Contact support via email"
          >
            support@terrateam.io
          </a>
          <br>
          <a 
            href="https://terrateamio.slack.com" 
            target="_blank" 
            rel="noopener noreferrer"
            class="text-sm text-blue-600 dark:text-blue-400 hover:underline focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 dark:focus:ring-offset-gray-900 rounded"
            aria-label="Join our Slack community (opens in new tab)"
          >
            Slack Community
          </a>
        </div>
      </div>
    </div>
  </div>
</div>

