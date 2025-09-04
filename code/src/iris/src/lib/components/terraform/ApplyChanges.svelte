<!-- Terraform Apply Changes Component -->
<script lang="ts">
  import ResourceDiff from './ResourceDiff.svelte';
  import Card from '../ui/Card.svelte';
  import LoadingSpinner from '../ui/LoadingSpinner.svelte';
  import { parseTerraformApply, getApplySummary } from '../../utils/terraformApplyParser';
  import type { ParsedPlan } from '../../types/terraform';

  // Props
  export let applyOutput: string;
  export let workManifestId: string = '';
  export let showHeader: boolean = true;

  // State
  let parsedApply: ParsedPlan | null = null;
  let isLoading = true;
  let parseError: string | null = null;

  // Parse apply output on mount or when applyOutput changes
  $: if (applyOutput) {
    parseApply();
  }

  function parseApply(): void {
    isLoading = true;
    parseError = null;
    
    try {
      parsedApply = parseTerraformApply(applyOutput);
      
      if (parsedApply.resources.length === 0) {
        parseError = 'No resource changes found in apply output';
      }
    } catch (error) {
      console.error('Failed to parse apply output:', error);
      parseError = error instanceof Error ? error.message : 'Failed to parse apply output';
    } finally {
      isLoading = false;
    }
  }
</script>

<div class="apply-changes">
  {#if showHeader}
    <div class="header mb-4">
      <h2 class="text-lg sm:text-2xl font-bold text-gray-900 dark:text-white">
        Apply Changes
        {#if workManifestId}
          <span class="text-gray-500 text-sm sm:text-lg ml-2">#{workManifestId}</span>
        {/if}
      </h2>
      {#if parsedApply && !parseError}
        <p class="text-sm sm:text-base text-gray-600 dark:text-gray-400 mt-1">
          {getApplySummary(parsedApply)}
        </p>
      {/if}
    </div>
  {/if}

  {#if isLoading}
    <Card padding="lg">
      <div class="flex flex-col items-center justify-center py-12">
        <LoadingSpinner size="lg" />
        <p class="mt-4 text-gray-600 dark:text-gray-400">Parsing apply output...</p>
      </div>
    </Card>
  {:else if parseError}
    <Card padding="lg">
      <div class="text-center py-8">
        <div class="text-yellow-500 mb-4">
          <svg class="w-12 h-12 mx-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
                  d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
          </svg>
        </div>
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">
          Limited Change Details Available
        </h3>
        <p class="text-gray-600 dark:text-gray-400">{parseError}</p>
        <p class="text-sm text-gray-500 dark:text-gray-500 mt-4">
          You can still view the full apply output in the "All Steps" or "Raw" tab
        </p>
      </div>
    </Card>
  {:else if parsedApply}
    <!-- Simplified header with Changes count -->
    <div class="mb-4">
      <h3 class="text-base sm:text-lg font-semibold text-gray-900 dark:text-white">
        Applied Changes ({parsedApply.changes.total})
      </h3>
    </div>

    <!-- Content Area - Show ResourceDiff directly -->
    <div class="content-area">
      <ResourceDiff 
        resources={parsedApply.resources}
        changes={parsedApply.changes}
      />
    </div>
  {:else}
    <Card padding="lg">
      <div class="text-center py-8">
        <p class="text-gray-600 dark:text-gray-400">No apply data available</p>
      </div>
    </Card>
  {/if}
</div>

<style>
  .apply-changes {
    width: 100%;
  }

  .content-area {
    min-height: 400px;
  }
</style>