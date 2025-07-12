<script lang="ts">
  export let title: string = 'Error';
  export let message: string;
  export let type: 'error' | 'warning' | 'info' = 'error';

  const typeStyles = {
    error: {
      container: 'bg-red-50 border border-red-200',
      icon: 'text-red-400',
      title: 'text-red-800',
      text: 'text-red-700'
    },
    warning: {
      container: 'bg-yellow-50 border border-yellow-200',
      icon: 'text-yellow-400',
      title: 'text-yellow-800',
      text: 'text-yellow-700'
    },
    info: {
      container: 'bg-blue-50 border border-blue-200',
      icon: 'text-blue-400',
      title: 'text-blue-800',
      text: 'text-blue-700'
    }
  };

  $: styles = typeStyles[type];
</script>

<div class="rounded-md p-4 {styles.container}">
  <div class="flex">
    <div class="flex-shrink-0">
      <svg class="h-5 w-5 {styles.icon}" viewBox="0 0 20 20" fill="currentColor">
        {#if type === 'error'}
          <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
        {:else if type === 'warning'}
          <path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
        {:else}
          <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd" />
        {/if}
      </svg>
    </div>
    <div class="ml-3">
      <h3 class="text-sm font-medium {styles.title}">{title}</h3>
      <div class="mt-2 text-sm {styles.text}">
        <p>{message}</p>
      </div>
    </div>
  </div>
</div>