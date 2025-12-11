<script lang="ts">
  import type { StackPath, StackState } from '../../types';

  export let paths: StackPath[];
  export let state: StackState;
  export let stackName: string; // Current stack name to filter out

  // Filter out the current stack from all paths and flatten
  function getDependencies(paths: StackPath[], currentStackName: string): string[] {
    const deps = new Set<string>();

    for (const path of paths) {
      for (const name of path) {
        if (name !== currentStackName) {
          deps.add(name);
        }
      }
    }

    return Array.from(deps);
  }

  $: dependencies = getDependencies(paths, stackName);
  $: shouldShow = (state === 'apply_pending' || state === 'plan_pending') && dependencies.length > 0;

  // Determine label based on state
  function getDependencyLabel(state: StackState): string {
    if (state === 'plan_pending') {
      return 'Pending plan of:';
    } else if (state === 'apply_pending') {
      return 'Pending apply of:';
    }
    return 'Pending:';
  }

  // Get state-specific icon
  function getStateIcon(state: StackState): string {
    if (state === 'apply_pending' || state === 'plan_pending') {
      return 'M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z'; // Clock icon
    }
    return '';
  }

  // Get state-specific color classes
  function getColorClasses(state: StackState) {
    if (state === 'plan_pending') {
      return {
        bg: 'bg-pink-50 dark:bg-pink-900/20',
        border: 'border-pink-200 dark:border-pink-800',
        icon: 'text-pink-600 dark:text-pink-400',
        label: 'text-pink-800 dark:text-pink-300',
        tag: 'bg-white dark:bg-pink-900/40 border-pink-300 dark:border-pink-700 text-pink-900 dark:text-pink-200'
      };
    } else {
      // apply_pending
      return {
        bg: 'bg-purple-50 dark:bg-purple-900/20',
        border: 'border-purple-200 dark:border-purple-800',
        icon: 'text-purple-600 dark:text-purple-400',
        label: 'text-purple-800 dark:text-purple-300',
        tag: 'bg-white dark:bg-purple-900/40 border-purple-300 dark:border-purple-700 text-purple-900 dark:text-purple-200'
      };
    }
  }

  $: label = getDependencyLabel(state);
  $: iconPath = getStateIcon(state);
  $: colors = getColorClasses(state);
</script>

{#if shouldShow}
  <div class="mt-3 p-3 rounded-md {colors.bg} border {colors.border}">
    <!-- Header with icon and explanation -->
    <div class="flex items-start gap-2">
      <svg
        class="w-5 h-5 {colors.icon} flex-shrink-0 mt-0.5"
        fill="none"
        stroke="currentColor"
        viewBox="0 0 24 24"
        aria-hidden="true"
      >
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          stroke-width="2"
          d={iconPath}
        />
      </svg>
      <div class="flex-1">
        <!-- Dependency label and list -->
        <div>
          <p class="text-xs font-semibold {colors.label} mb-1.5">
            {label}
          </p>
          <div class="flex flex-wrap gap-1.5">
            {#each dependencies as depName}
              <span class="inline-flex items-center px-2 py-1 rounded {colors.tag} border text-xs font-mono">
                {depName}
              </span>
            {/each}
          </div>
        </div>
      </div>
    </div>
  </div>
{/if}
