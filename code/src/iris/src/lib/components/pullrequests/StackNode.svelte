<script lang="ts">
  import type { StackInner, StackOuter } from '../../types';
  import StackStateIndicator from './StackStateIndicator.svelte';

  // Can be either an outer or inner stack
  export let stack: StackOuter | StackInner;
  export let level: number = 0;
  export let forceExpanded: boolean = true;
  export let showWorkspaces: boolean = false;

  let expanded: boolean = true;

  // React to forceExpanded changes
  $: expanded = forceExpanded;

  function isStackOuter(s: StackOuter | StackInner): s is StackOuter {
    return 'stacks' in s && Array.isArray((s as StackOuter).stacks);
  }

  function isStackInner(s: StackOuter | StackInner): s is StackInner {
    return 'dirspaces' in s && Array.isArray((s as StackInner).dirspaces);
  }

  // Get background color class based on state and nesting level
  function getBackgroundClass(level: number): string {
    if (level === 0) {
      // Outer most boxes - darker background
      return 'bg-gray-200 dark:bg-gray-800';
    } else if (level === 1) {
      // Nested boxes - lighter background
      return 'bg-white dark:bg-gray-700';
    } else {
      // Deeper nesting
      return 'bg-gray-50 dark:bg-gray-600';
    }
  }

  // Get border width based on level
  function getBorderClass(level: number): string {
    if (level === 0) {
      return 'border-4';
    } else if (level === 1) {
      return 'border-2';
    } else {
      return 'border';
    }
  }

  // Get state-based border color
  function getBorderColorClass(state: string): string {
    switch (state) {
      case 'no_changes':
        return 'border-gray-300 dark:border-gray-600';
      case 'plan_failed':
        return 'border-orange-400 dark:border-orange-600';
      case 'plan_pending':
        return 'border-pink-400 dark:border-pink-600';
      case 'apply_failed':
        return 'border-red-400 dark:border-red-600';
      case 'apply_pending':
        return 'border-purple-400 dark:border-purple-600';
      case 'apply_ready':
        return 'border-blue-400 dark:border-blue-600';
      case 'apply_success':
        return 'border-green-400 dark:border-green-600';
      default:
        return 'border-gray-300 dark:border-gray-600';
    }
  }

  $: bgClass = getBackgroundClass(level);
  $: borderWidthClass = getBorderClass(level);
  $: borderColorClass = getBorderColorClass(stack.state);

  function toggleExpanded() {
    expanded = !expanded;
  }
</script>

<div
  class="rounded-lg {borderWidthClass} {borderColorClass} {bgClass} p-4 mb-4 transition-all"
  role="article"
  aria-label="Stack {stack.name}"
>
  <!-- Stack header with name and state -->
  {#if isStackOuter(stack) && stack.stacks.length > 0}
    <!-- Expandable stack - entire header is clickable -->
    <button
      on:click={toggleExpanded}
      class="w-full flex items-center justify-between mb-3 text-left focus:outline-none focus:ring-2 focus:ring-brand-primary rounded p-2 -m-2 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
      aria-label="{expanded ? 'Collapse' : 'Expand'} {stack.name}"
      aria-expanded={expanded}
    >
      <div class="flex items-center gap-3">
        <svg
          class="w-5 h-5 transition-transform {expanded ? 'rotate-90' : ''} text-gray-600 dark:text-gray-400"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M9 5l7 7-7 7"
          />
        </svg>
        <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100 {level > 0 ? 'ml-4' : ''}">
          {stack.name}
          {#if isStackInner(stack) && stack.dirspaces.length > 0}
            <span class="ml-2 text-xs font-normal text-gray-500 dark:text-gray-400">
              ({stack.dirspaces.length} workspace{stack.dirspaces.length !== 1 ? 's' : ''})
            </span>
          {/if}
        </h3>
      </div>
      <StackStateIndicator state={stack.state} size="md" />
    </button>
  {:else}
    <!-- Non-expandable stack (leaf node) - not clickable -->
    <div class="flex items-center justify-between mb-3">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100 {level > 0 ? 'ml-4' : ''}">
        {stack.name}
        {#if isStackInner(stack) && stack.dirspaces.length > 0}
          <span class="ml-2 text-xs font-normal text-gray-500 dark:text-gray-400">
            ({stack.dirspaces.length} workspace{stack.dirspaces.length !== 1 ? 's' : ''})
          </span>
        {/if}
      </h3>
      <StackStateIndicator state={stack.state} size="md" />
    </div>
  {/if}

  {#if expanded}
    <!-- Show directory information for all leaf stacks -->
    {#if isStackInner(stack) && stack.dirspaces.length > 0}
      <div class="mb-3 text-sm text-gray-700 dark:text-gray-300 {level > 0 ? 'ml-4' : ''}">
        {#each stack.dirspaces as { dirspace }}
          <p>
            <span class="font-medium">Directory:</span>
            {dirspace.dir}
            {#if dirspace.workspace !== 'default'}
              <span class="ml-1">
                (<span class="font-medium">workspace:</span> {dirspace.workspace})
              </span>
            {/if}
          </p>
        {/each}
      </div>
    {/if}

    <!-- Render nested stacks (for StackOuter) -->
    {#if isStackOuter(stack) && stack.stacks.length > 0}
      <div class="mt-4 space-y-4">
        {#each stack.stacks as innerStack}
          <svelte:self stack={innerStack} level={level + 1} {forceExpanded} {showWorkspaces} />
        {/each}
      </div>
    {/if}

    <!-- Render dirspaces (for StackInner leaf nodes) -->
    {#if isStackInner(stack) && stack.dirspaces.length > 0 && showWorkspaces}
      <div class="mt-3 space-y-2 {level > 0 ? 'ml-4' : ''}">
        <div class="text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
          Workspaces: ({stack.dirspaces.length})
        </div>
        {#each stack.dirspaces as { dirspace, state }}
          <div
            class="flex items-center justify-between p-3 rounded-md bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700"
          >
            <div class="flex-1">
              <div class="text-sm font-medium text-gray-900 dark:text-gray-100">
                {dirspace.dir} / {dirspace.workspace}
              </div>
            </div>
            <StackStateIndicator state={state} size="sm" />
          </div>
        {/each}
      </div>
    {/if}
  {/if}
</div>
