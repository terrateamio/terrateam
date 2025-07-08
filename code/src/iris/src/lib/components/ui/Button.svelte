<script lang="ts">
  import type { HTMLButtonAttributes } from 'svelte/elements';

  interface $$Props extends HTMLButtonAttributes {
    variant?: 'primary' | 'secondary' | 'accent' | 'outline' | 'ghost';
    size?: 'sm' | 'md' | 'lg';
    loading?: boolean;
    disabled?: boolean;
    fullWidth?: boolean;
  }

  export let variant: $$Props['variant'] = 'primary';
  export let size: $$Props['size'] = 'md';
  export let loading: $$Props['loading'] = false;
  export let disabled: $$Props['disabled'] = false;
  export let fullWidth: $$Props['fullWidth'] = false;

  const baseClasses = 'inline-flex items-center justify-center font-semibold rounded-lg transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2';
  
  const variantClasses = {
    primary: 'bg-brand-primary text-brand-primary border border-brand-primary hover:bg-brand-tertiary focus:ring-blue-500',
    secondary: 'bg-brand-secondary text-brand-primary border border-brand-secondary hover:bg-brand-tertiary focus:ring-gray-500',
    accent: 'accent-bg hover:bg-accent-hover focus:ring-yellow-500',
    outline: 'bg-transparent text-brand-primary border border-brand-primary hover:bg-brand-tertiary focus:ring-blue-500',
    ghost: 'bg-transparent text-brand-primary hover:bg-brand-tertiary focus:ring-blue-500'
  };

  const sizeClasses = {
    sm: 'px-3 py-1 text-sm',
    md: 'px-4 py-2 text-sm',
    lg: 'px-6 py-3 text-base'
  };

  $: classes = [
    baseClasses,
    variant ? variantClasses[variant] : '',
    size ? sizeClasses[size] : '',
    fullWidth ? 'w-full' : '',
    (disabled || loading) ? 'opacity-50 cursor-not-allowed' : '',
    $$props.class || ''
  ].filter(Boolean).join(' ');

  $: isDisabled = disabled || loading;
</script>

<button
  {...$$restProps}
  class={classes}
  disabled={isDisabled}
  on:click
  on:mouseenter
  on:mouseleave
  on:focus
  on:blur
>
  {#if loading}
    <svg class="animate-spin -ml-1 mr-2 h-4 w-4" fill="none" viewBox="0 0 24 24">
      <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
      <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
    </svg>
  {/if}
  <slot />
</button>

