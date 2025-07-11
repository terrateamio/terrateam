<script lang="ts">
  export let padding: 'none' | 'sm' | 'md' | 'lg' = 'md';
  export let hover: boolean = false;
  export let border: boolean = true;
  export let shadow: boolean = true;

  const paddingClasses = {
    none: '',
    sm: 'p-4',
    md: 'p-6',
    lg: 'p-8'
  };

  $: classes = [
    'bg-white dark:!bg-gray-800 rounded-lg',
    border ? 'border border-gray-200 dark:border-gray-700' : '',
    shadow ? 'shadow-sm dark:shadow-gray-900/20' : '',
    hover ? 'hover:shadow-lg dark:hover:shadow-gray-900/40 transition-shadow cursor-pointer' : '',
    paddingClasses[padding],
    $$props.class || ''
  ].filter(Boolean).join(' ');
</script>

<div class={classes} on:click on:keydown role={$$props.role}>
  <slot />
</div>