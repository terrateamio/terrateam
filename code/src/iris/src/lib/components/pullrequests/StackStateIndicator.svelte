<script lang="ts">
  import type { StackState } from '../../types';

  export let state: StackState;
  export let size: 'sm' | 'md' | 'lg' = 'md';

  // Map states to colors and labels based on UX PDF specification
  function getStateStyles(state: StackState): { bgClass: string; textClass: string; label: string } {
    switch (state) {
      case 'no_changes':
        return {
          bgClass: 'bg-gray-100 dark:bg-gray-700',
          textClass: 'text-gray-800 dark:text-gray-300',
          label: 'No changes'
        };
      case 'plan_failed':
        return {
          bgClass: 'bg-orange-100 dark:bg-orange-900/30',
          textClass: 'text-orange-800 dark:text-orange-400',
          label: 'Plan failed'
        };
      case 'plan_pending':
        return {
          bgClass: 'bg-pink-100 dark:bg-pink-900/30',
          textClass: 'text-pink-800 dark:text-pink-400',
          label: 'Plan pending'
        };
      case 'apply_failed':
        return {
          bgClass: 'bg-red-100 dark:bg-red-900/30',
          textClass: 'text-red-800 dark:text-red-400',
          label: 'Apply failed'
        };
      case 'apply_pending':
        return {
          bgClass: 'bg-purple-100 dark:bg-purple-900/30',
          textClass: 'text-purple-800 dark:text-purple-400',
          label: 'Apply pending'
        };
      case 'apply_ready':
        return {
          bgClass: 'bg-blue-100 dark:bg-blue-900/30',
          textClass: 'text-blue-800 dark:text-blue-400',
          label: 'Apply ready'
        };
      case 'apply_success':
        return {
          bgClass: 'bg-green-100 dark:bg-green-900/30',
          textClass: 'text-green-800 dark:text-green-400',
          label: 'Applied successfully'
        };
      default:
        return {
          bgClass: 'bg-gray-100 dark:bg-gray-700',
          textClass: 'text-gray-800 dark:text-gray-300',
          label: 'Unknown'
        };
    }
  }

  $: stateStyles = getStateStyles(state);

  $: sizeClasses = size === 'sm'
    ? 'px-2 py-1 text-xs'
    : size === 'lg'
    ? 'px-4 py-2 text-base'
    : 'px-3 py-1.5 text-sm';
</script>

<span
  class="inline-flex items-center font-medium rounded-md {stateStyles.bgClass} {stateStyles.textClass} {sizeClasses}"
  role="status"
  aria-label="{stateStyles.label}"
>
  {stateStyles.label}
</span>
