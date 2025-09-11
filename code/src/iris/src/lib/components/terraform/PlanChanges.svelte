<!-- Terraform Plan Changes Component - JSON Only -->
<script lang="ts">
  import ResourceDiff from './ResourceDiff.svelte';
  import Card from '../ui/Card.svelte';
  import LoadingSpinner from '../ui/LoadingSpinner.svelte';
  import type { ParsedPlan, TerraformJsonPlan } from '../../types/terraform';

  // Props
  export let planJson: string | undefined = undefined;
  export let workManifestId: string = '';
  export let showHeader: boolean = true;

  // State
  let parsedPlan: ParsedPlan | null = null;
  let isLoading = true;
  let parseError: string | null = null;

  // Parse plan on mount or when planJson changes
  $: if (planJson) {
    parsePlan();
  } else {
    // No JSON data available
    isLoading = false;
    parseError = 'No JSON plan data available';
    parsedPlan = null;
  }

  function parsePlan(): void {
    isLoading = true;
    parseError = null;
    
    try {
      if (!planJson) {
        parseError = 'No JSON plan data provided';
        return;
      }

      // First check if it looks like JSON (starts with { or [)
      const trimmed = planJson.trim();
      if (!trimmed.startsWith('{') && !trimmed.startsWith('[')) {
        parseError = 'Plan output is in text format. JSON format is required for visualization.';
        parsedPlan = null;
        return;
      }

      const jsonPlan: TerraformJsonPlan = JSON.parse(planJson);
      
      // Validate it has the expected structure
      if (!jsonPlan.resource_changes) {
        parseError = 'No resource changes found in this plan';
        parsedPlan = null;
        return;
      }
      
      parsedPlan = parseJsonPlan(jsonPlan);
      
      if (!parsedPlan || parsedPlan.resources.length === 0) {
        parseError = 'No resources found in plan';
      }
    } catch (error) {
      console.error('Failed to parse JSON plan:', error);
      // Provide more helpful error message
      if (error instanceof SyntaxError) {
        parseError = 'Plan output is not valid JSON. Ensure Terraform is configured to output JSON format.';
      } else {
        parseError = error instanceof Error ? error.message : 'Failed to parse JSON plan';
      }
      parsedPlan = null;
    } finally {
      isLoading = false;
    }
  }

  // Parse JSON format Terraform plan
  function parseJsonPlan(plan: TerraformJsonPlan): ParsedPlan {
    const resources: ResourceNode[] = [];

    // Process resource changes
    if (plan.resource_changes) {
      for (const change of plan.resource_changes) {
        const resource = convertResourceChange(change);
        if (resource) {
          resources.push(resource);
        }
      }
    }

    // Calculate change set
    const changes = calculateChangeSet(resources);

    return {
      resources,
      changes,
      outputs: plan.output_changes,
      plannedValues: plan.planned_values,
      priorState: plan.prior_state,
      configuration: plan.configuration
    };
  }

  // Convert a Terraform resource change to our ResourceNode format
  function convertResourceChange(change: any): ResourceNode | null {
    const changeType = mapActionsToChangeType(change.change.actions);
    
    if (changeType === 'no-change') {
      return null; // Skip unchanged resources
    }

    return {
      id: change.address,
      type: change.type,
      name: change.name,
      provider: change.provider_name || 'unknown',
      changeType,
      before: (change.change.before || {}) as Record<string, unknown>,
      after: (change.change.after || {}) as Record<string, unknown>,
      module: change.module_address
    };
  }

  // Map Terraform actions to our change type
  type ChangeType = 'create' | 'update' | 'delete' | 'replace' | 'no-change';
  
  function mapActionsToChangeType(actions: string[]): ChangeType {
    if (actions.includes('create')) return 'create';
    if (actions.includes('delete') && actions.includes('create')) return 'replace';
    if (actions.includes('delete')) return 'delete';
    if (actions.includes('update')) return 'update';
    if (actions.includes('read')) return 'update';
    return 'no-change';
  }

  interface ResourceNode {
    id: string;
    type: string;
    name: string;
    provider: string;
    changeType: ChangeType;
    before: Record<string, unknown>;
    after: Record<string, unknown>;
    module?: string;
    attributes?: Record<string, unknown>;
  }

  interface ChangeSet {
    create: ResourceNode[];
    update: ResourceNode[];
    delete: ResourceNode[];
    replace: ResourceNode[];
    unchanged: ResourceNode[];
    total: number;
  }

  // Calculate change set from resources
  function calculateChangeSet(resources: ResourceNode[]): ChangeSet {
    const changes: ChangeSet = {
      create: [],
      update: [],
      delete: [],
      replace: [],
      unchanged: [],
      total: resources.length
    };

    for (const resource of resources) {
      switch (resource.changeType) {
        case 'create':
          changes.create.push(resource);
          break;
        case 'update':
          changes.update.push(resource);
          break;
        case 'delete':
          changes.delete.push(resource);
          break;
        case 'replace':
          changes.replace.push(resource);
          break;
        case 'no-change':
          changes.unchanged.push(resource);
          break;
      }
    }

    return changes;
  }

  // Extract a summary of the plan for display
  function getPlanSummary(plan: ParsedPlan): string {
    const { changes } = plan;
    const parts: string[] = [];
    
    if (changes.create.length > 0) {
      parts.push(`${changes.create.length} to add`);
    }
    if (changes.update.length > 0) {
      parts.push(`${changes.update.length} to change`);
    }
    if (changes.delete.length > 0) {
      parts.push(`${changes.delete.length} to destroy`);
    }
    if (changes.replace.length > 0) {
      parts.push(`${changes.replace.length} to replace`);
    }
    
    if (parts.length === 0) {
      return 'No changes';
    }
    
    return parts.join(', ');
  }
</script>

<div class="plan-changes">
  {#if showHeader}
    <div class="header mb-4">
      <h2 class="text-lg sm:text-2xl font-bold text-gray-900 dark:text-white">
        Plan Changes
        {#if workManifestId}
          <span class="text-gray-500 text-sm sm:text-lg ml-2">#{workManifestId}</span>
        {/if}
      </h2>
      {#if parsedPlan && !parseError}
        <p class="text-sm sm:text-base text-gray-600 dark:text-gray-400 mt-1">
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
        <div class="text-yellow-500 mb-4">
          <svg class="w-12 h-12 mx-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
                  d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
          </svg>
        </div>
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">
          Plan Visualization Not Available
        </h3>
        <p class="text-gray-600 dark:text-gray-400">{parseError}</p>
        <p class="text-sm text-gray-500 dark:text-gray-500 mt-4">
          Plan visualization requires Terraform to output plans in JSON format.
          The current plan is in text format.
        </p>
        <p class="text-sm text-gray-500 dark:text-gray-500 mt-2">
          To enable visualization, ensure your Terraform workflow is configured to generate JSON-formatted plans.
        </p>
      </div>
    </Card>
  {:else if parsedPlan}
    <!-- Simplified header with Changes count -->
    <div class="mb-4">
      <h3 class="text-base sm:text-lg font-semibold text-gray-900 dark:text-white">
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