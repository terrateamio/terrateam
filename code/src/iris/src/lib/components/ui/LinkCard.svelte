<script lang="ts">
  import type { HTMLAnchorAttributes } from 'svelte/elements';

  interface $$Props extends HTMLAnchorAttributes {
    padding?: 'none' | 'sm' | 'md' | 'lg';
    border?: boolean;
    shadow?: boolean;
    hover?: boolean;
    disabled?: boolean;
  }

  export let padding: $$Props['padding'] = 'md';
  export let border: $$Props['border'] = true;
  export let shadow: $$Props['shadow'] = true;
  export let hover: $$Props['hover'] = true;
  export let disabled: $$Props['disabled'] = false;

  const paddingClasses = {
    none: '',
    sm: 'p-4',
    md: 'p-6',
    lg: 'p-8'
  };

  $: classes = [
    'bg-white dark:!bg-gray-800 rounded-lg w-full text-left block',
    border ? 'border border-gray-200 dark:border-gray-700' : '',
    shadow ? 'shadow-sm dark:shadow-gray-900/20' : '',
    hover && !disabled ? 'hover:shadow-lg dark:hover:shadow-gray-900/40 transition-shadow' : '',
    disabled ? 'opacity-50 cursor-not-allowed pointer-events-none' : 'cursor-pointer',
    'focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 dark:focus:ring-blue-400',
    padding ? paddingClasses[padding] : '',
    $$props.class || ''
  ].filter(Boolean).join(' ');
</script>

<!-- 
  Accessible clickable card using anchor element
  Provides proper keyboard navigation, focus management, screen reader support, and new tab functionality
-->
<a
  {...$$restProps}
  href={$$restProps.href || '#'}
  role={$$restProps.href ? undefined : 'button'}
  tabindex={$$restProps.href ? undefined : 0}
  class={classes}
  on:click
  on:keydown
  on:focus
  on:blur
>
  <slot />
</a>