<script lang="ts">
  import { createEventDispatcher, onMount } from 'svelte';
  
  export let kind: 'critical' | 'warning' | 'info' | 'success' = 'info';
  export let headline: string = '';
  export let subtext: string = '';
  export let primaryAction: { label: string; href?: string; onClick?: () => void } | null = null;
  export let secondaryAction: { label: string; href?: string; onClick?: () => void } | null = null;
  export let dismissible: boolean = true;
  export let onDismiss: (() => void) | undefined = undefined;
  export let storageKey: string | null = null;
  export let className: string = '';
  
  const dispatch = createEventDispatcher();
  let dismissed = false;
  
  // Style mappings for each kind - subtle and refined
  const styles = {
    critical: {
      container: 'bg-red-50/80 dark:bg-red-950/10 border-b border-red-100/50 dark:border-red-900/20',
      text: 'text-red-800 dark:text-red-200',
      subtext: 'text-red-600/90 dark:text-red-300/80',
      icon: 'text-red-500 dark:text-red-400',
      dismiss: 'text-red-600/60 hover:text-red-600 dark:text-red-400/60 dark:hover:text-red-400'
    },
    warning: {
      container: 'bg-rose-50 dark:bg-amber-950/10 border-b border-rose-100 dark:border-amber-900/20',
      text: 'text-rose-800 dark:text-amber-200',
      subtext: 'text-rose-600 dark:text-amber-300/80',
      icon: 'text-rose-500 dark:text-amber-400',
      dismiss: 'text-rose-600/60 hover:text-rose-600 dark:text-amber-400/60 dark:hover:text-amber-400'
    },
    info: {
      container: 'bg-blue-50/80 dark:bg-blue-950/10 border-b border-blue-100/50 dark:border-blue-900/20',
      text: 'text-blue-800 dark:text-blue-200',
      subtext: 'text-blue-600/90 dark:text-blue-300/80',
      icon: 'text-blue-500 dark:text-blue-400',
      dismiss: 'text-blue-600/60 hover:text-blue-600 dark:text-blue-400/60 dark:hover:text-blue-400'
    },
    success: {
      container: 'bg-green-50/80 dark:bg-green-950/10 border-b border-green-100/50 dark:border-green-900/20',
      text: 'text-green-800 dark:text-green-200',
      subtext: 'text-green-600/90 dark:text-green-300/80',
      icon: 'text-green-500 dark:text-green-400',
      dismiss: 'text-green-600/60 hover:text-green-600 dark:text-green-400/60 dark:hover:text-green-400'
    }
  };
  
  $: currentStyle = styles[kind];
  
  // Check localStorage on mount
  onMount(() => {
    if (storageKey && typeof window !== 'undefined') {
      try {
        const stored = localStorage.getItem(storageKey);
        if (stored === 'dismissed') {
          dismissed = true;
        }
      } catch (e) {
        // Ignore localStorage errors
      }
    }
  });
  
  function handleDismiss() {
    dismissed = true;
    
    // Persist to localStorage if storageKey provided
    if (storageKey && typeof window !== 'undefined') {
      try {
        localStorage.setItem(storageKey, 'dismissed');
      } catch (e) {
        // Ignore localStorage errors
      }
    }
    
    // Call custom onDismiss handler
    if (onDismiss) {
      onDismiss();
    }
    
    dispatch('dismiss');
  }
  
  function handlePrimaryAction() {
    if (!primaryAction) return;
    
    if (primaryAction.onClick) {
      primaryAction.onClick();
    } else if (primaryAction.href) {
      window.location.hash = primaryAction.href;
    }
    dispatch('action', { type: 'primary' });
  }
  
  function handleSecondaryAction() {
    if (!secondaryAction) return;
    
    if (secondaryAction.onClick) {
      secondaryAction.onClick();
    } else if (secondaryAction.href) {
      window.location.hash = secondaryAction.href;
    }
    dispatch('action', { type: 'secondary' });
  }
  
  // Handle Escape key
  function handleKeydown(event: KeyboardEvent) {
    if (event.key === 'Escape' && dismissible) {
      handleDismiss();
    }
  }
</script>

{#if !dismissed}
  <!-- svelte-ignore a11y-no-noninteractive-element-interactions -->
  <div 
    role="region"
    aria-label={headline}
    on:keydown={handleKeydown}
    tabindex="-1"
    class="w-full {currentStyle.container} {className}"
  >
    <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
      <div class="flex items-center py-2">
        <!-- Left side: Icon + Text -->
        <div class="flex items-center flex-1">
          <!-- Icon -->
          <div class="shrink-0 {currentStyle.icon}" aria-hidden="true">
            {#if kind === 'critical'}
              <!-- AlertTriangle icon -->
              <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
              </svg>
            {:else if kind === 'warning'}
              <!-- AlertCircle icon -->
              <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            {:else if kind === 'info'}
              <!-- Info icon -->
              <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            {:else if kind === 'success'}
              <!-- CheckCircle2 icon -->
              <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            {/if}
          </div>
          
          <!-- Text -->
          <div class="ml-3 flex min-w-0 flex-1 items-center">
            <p class="text-sm {currentStyle.text}">
              <span class="font-medium">{headline}</span>
              {#if subtext}
                <span class="ml-1 {currentStyle.subtext}">{subtext}</span>
              {/if}
            </p>
          </div>
        </div>
        
        <!-- Right side: Actions -->
        <div class="ml-4 flex items-center flex-shrink-0 space-x-4">
          {#if secondaryAction}
            <button
              type="button"
              on:click={handleSecondaryAction}
              class="text-sm text-blue-600 hover:text-blue-500 dark:text-blue-400 dark:hover:text-blue-300"
            >
              {secondaryAction.label}
            </button>
          {/if}
          
          {#if primaryAction}
            <button
              type="button"
              on:click={handlePrimaryAction}
              class="rounded bg-blue-600 px-3 py-1 text-sm font-medium text-white hover:bg-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
            >
              {primaryAction.label}
            </button>
          {/if}
          
          {#if dismissible}
            <button
              type="button"
              on:click={handleDismiss}
              class="ml-auto flex rounded-md p-1 {currentStyle.dismiss} focus:outline-none focus:ring-2 focus:ring-current focus:ring-offset-2"
              aria-label="Dismiss"
            >
              <svg class="h-4 w-4" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
              </svg>
            </button>
          {/if}
        </div>
      </div>
    </div>
  </div>
{/if}