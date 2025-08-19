<!-- Terraform Plan Changes Component -->
<script lang="ts">
  // import { onMount } from 'svelte'; // Reserved for future use
  import ResourceDiff from './ResourceDiff.svelte';
  import Card from '../ui/Card.svelte';
  import LoadingSpinner from '../ui/LoadingSpinner.svelte';
  import { parseTerraformPlan, getPlanSummary } from '../../utils/terraformPlanParser';
  import type { ParsedPlan } from '../../types/terraform';

  // Props
  export let planOutput: string;
  export let workManifestId: string = '';
  export let showHeader: boolean = true;

  // State
  let parsedPlan: ParsedPlan | null = null;
  let isLoading = true;
  let parseError: string | null = null;

  // Parse plan on mount or when planOutput changes
  $: if (planOutput) {
    parsePlan();
  }

  function parsePlan(): void {
    isLoading = true;
    parseError = null;
    
    try {
      parsedPlan = parseTerraformPlan(planOutput);
      
      if (parsedPlan.resources.length === 0) {
        parseError = 'No resources found in plan output';
      }
    } catch (error) {
      console.error('Failed to parse plan:', error);
      parseError = error instanceof Error ? error.message : 'Failed to parse plan output';
    } finally {
      isLoading = false;
    }
  }
</script>

<div class="plan-changes">
  {#if showHeader}
    <div class="header mb-4">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">
        Plan Changes
        {#if workManifestId}
          <span class="text-gray-500 text-lg ml-2">#{workManifestId}</span>
        {/if}
      </h2>
      {#if parsedPlan && !parseError}
        <p class="text-gray-600 dark:text-gray-400 mt-1">
          {getPlanSummary(parsedPlan)}
        </p>
      {/if}
    </div>
  {/if}

  {#if isLoading}
    <Card padding="lg">
      <div class="flex flex-col items-center justify-center py-12">
        <LoadingSpinner size="lg" />
        <p class="mt-4 text-gray-600 dark:text-gray-400">Parsing Terraform plan...</p>
      </div>
    </Card>
  {:else if parseError}
    <Card padding="lg">
      <div class="text-center py-8">
        <div class="text-red-500 mb-4">
          <svg class="w-12 h-12 mx-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
                  d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
          </svg>
        </div>
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">
          Unable to Parse Plan
        </h3>
        <p class="text-gray-600 dark:text-gray-400">{parseError}</p>
        <p class="text-sm text-gray-500 dark:text-gray-500 mt-4">
          Make sure the plan output is in valid Terraform JSON or text format
        </p>
      </div>
    </Card>
  {:else if parsedPlan}
    <!-- Simplified header with Changes count -->
    <div class="mb-4">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white">
        Changes ({parsedPlan.changes.total})
      </h3>
    </div>

    <!-- Content Area - Show ResourceDiff directly -->
    <div class="content-area">
      <ResourceDiff 
        resources={parsedPlan.resources}
        changes={parsedPlan.changes}
      />
    </div>
  {:else}
    <Card padding="lg">
      <div class="text-center py-8">
        <p class="text-gray-600 dark:text-gray-400">No plan data available</p>
      </div>
    </Card>
  {/if}
</div>

<style>
  .plan-changes {
    width: 100%;
  }

  .content-area {
    min-height: 400px;
  }
</style>