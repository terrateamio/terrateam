<script lang="ts">
  import type { Dirspace } from './types';
  // Auth handled by PageLayout
  import { api } from './api';
  import { selectedInstallation, currentVCSProvider, serverConfig } from './stores';
  import PageLayout from './components/layout/PageLayout.svelte';
  import LoadingSpinner from './components/ui/LoadingSpinner.svelte';
  import { navigateToRun, navigateToRuns } from './utils/navigation';
  import ErrorMessage from './components/ui/ErrorMessage.svelte';
  import Card from './components/ui/Card.svelte';
  import ClickableCard from './components/ui/ClickableCard.svelte';
  import { getWebBaseUrl } from './server-config';
  
  export let params: { repo: string; dir: string; workspace: string } = { 
    repo: '', 
    dir: '', 
    workspace: '' 
  };
  
  let workspace: Dirspace | null = null;
  let allWorkspaceRuns: Dirspace[] = [];
  interface OutputItem {
    idx?: number;
    step?: string;
    state?: string;
    scope?: {
      dir?: string;
      workspace?: string;
      type?: string;
    };
    payload?: {
      text?: string;
      plan?: string;
      plan_text?: string;
      has_changes?: boolean;
      summary?: unknown;
      [key: string]: unknown;
    } | string | unknown;
  }
  
  let outputs: OutputItem[] = [];
  let costEstimation: OutputItem[] = [];
  let isLoading: boolean = false;
  let error: string | null = null;
  const web_base_url = getWebBaseUrl($currentVCSProvider, $serverConfig);
  
  // Plan analysis data
  let resourceChanges = {
    add: 0,
    change: 0,
    destroy: 0,
    hasChanges: false
  };
  
  // Set initial loading state if we have workspace params
  $: if (params.repo && params.dir && params.workspace && !workspace && !error) {
    isLoading = true;
  }

  // Load workspace data when params change
  $: if (params.repo && params.dir && params.workspace && $selectedInstallation) {
    loadWorkspaceData();
  }
  
  async function loadWorkspaceData(): Promise<void> {
    if (!$selectedInstallation) return;
    
    error = null;
    isLoading = true;
    
    try {
      // Load all dirspaces for this specific workspace (dir + workspace combination)
      const response = await api.getInstallationDirspaces($selectedInstallation.id, {
        q: `repo:${params.repo} and dir:${params.dir} and workspace:${params.workspace}`,
        limit: 100,
      });
      
      if (response && response.dirspaces && response.dirspaces.length > 0) {
        allWorkspaceRuns = response.dirspaces;
        
        // Sort by created_at descending and take the most recent as the primary workspace
        allWorkspaceRuns.sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime());
        workspace = allWorkspaceRuns[0];

        // Load outputs for the most recent run
        if (workspace) {
          loadWorkspaceOutputs(workspace.id);
        }
        
        // Also try to load cost data from the most recent plan run (if different)
        const mostRecentPlan = allWorkspaceRuns.find(run => run.run_type === 'plan');
        if (mostRecentPlan && mostRecentPlan.id !== workspace.id) {
          loadCostDataFromPlan(mostRecentPlan.id);
        }
      } else {
        workspace = null;
        allWorkspaceRuns = [];
      }
    } catch (err) {
      console.error('Error loading workspace data:', err);
      error = err instanceof Error ? err.message : 'Failed to load workspace data';
      workspace = null;
      allWorkspaceRuns = [];
    } finally {
      isLoading = false;
    }
  }
  
  async function loadWorkspaceOutputs(workspaceId: string): Promise<void> {
    if (!$selectedInstallation) return;

    try {
      
      // Load ALL outputs first to see what we have
      const allOutputsResponse = await api.getWorkManifestOutputs(
        $selectedInstallation.id, 
        workspaceId,
        { limit: 100, lite: true } // No filter to see everything
      );

      // Use the outputs from the response and properly type them
      const responseOutputs = (allOutputsResponse.outputs || []).map(output => output as OutputItem);
      
      if (responseOutputs && responseOutputs.length > 0) {
        // Log each step to see what we have
        responseOutputs.forEach(() => {
        });
        
        // Check for cost estimation specifically
        const costSteps = responseOutputs.filter(o => 
          o?.step === 'tf/cost-estimation' || 
          o?.step?.includes('cost') ||
          (o?.payload && (
            typeof o.payload === 'string' && o.payload.includes('cost') ||
            (typeof o.payload === 'object' && (
              'cost_estimation' in o.payload ||
              'monthlyCost' in o.payload ||
              'total_monthly_cost' in o.payload
            ))
          ))
        );
        costSteps.forEach(() => {
        });
      }
      
      // Separate cost and non-cost outputs from the all outputs response
      if (responseOutputs) {
        outputs = responseOutputs.filter(output => output?.step !== 'tf/cost-estimation') || [];
        costEstimation = responseOutputs.filter(output => output?.step === 'tf/cost-estimation') || [];
        
        if (costEstimation.length > 0) {
          costEstimation.forEach((cost) => {
            if (cost?.payload) {
            }
          });
        }
      } else {
        outputs = [];
        costEstimation = [];
      }
      
      // Analyze plan outputs for resource changes
      analyzePlanOutputs();

    } catch (err) {
      console.error('❌ Error loading workspace outputs:', err);
      // Don't clear outputs if we got some data, only clear if no data was loaded
      if (!outputs.length && !costEstimation.length) {
        outputs = [];
        costEstimation = [];
      }
    }
  }
  
  async function loadCostDataFromPlan(planWorkspaceId: string): Promise<void> {
    if (!$selectedInstallation || costEstimation.length > 0) return; // Don't override existing cost data
    
    try {
      
      // First, see all outputs from the plan run
      const allPlanOutputs = await api.getWorkManifestOutputs(
        $selectedInstallation.id, 
        planWorkspaceId,
        { limit: 100, lite: true }
      );

      const planResponseOutputs = (allPlanOutputs.outputs || []).map(output => output as OutputItem);
      if (planResponseOutputs) {
        planResponseOutputs.forEach(() => {
        });
      }
      
      // Try to get cost estimation from plan
      const costResponse = await api.getWorkManifestOutputs(
        $selectedInstallation.id, 
        planWorkspaceId,
        { q: 'step:tf/cost-estimation', lite: true }
      );

      const costResponseOutputs = (costResponse.outputs || []).map(output => output as OutputItem);
      if (costResponseOutputs && costResponseOutputs.length > 0) {
        costEstimation = costResponseOutputs;
      } else {
      }
    } catch (err) {
    }
  }
  
  function analyzePlanOutputs(): void {
    // Reset counts
    resourceChanges = { add: 0, change: 0, destroy: 0, hasChanges: false };
    
    // Find plan outputs and analyze them
    const planOutputs = outputs.filter(output => 
      output?.step === 'tf/plan' && output?.payload
    );
    
    if (planOutputs.length === 0) {
      // No plan outputs found, leave as "no changes"
      return;
    }
    
    planOutputs.forEach(output => {
      // First try to use structured plan data if available
      if (output?.payload && typeof output.payload === 'object' && 'plan' in output.payload && output.payload.plan) {
        try {
          const planData = typeof output.payload.plan === 'string' 
            ? JSON.parse(output.payload.plan) 
            : output.payload.plan;
            
          // Check if structured plan has resource changes
          if (planData && planData.resource_changes) {
            planData.resource_changes.forEach((change: { action: string; change?: { actions?: string[] } }) => {
              const actions = change.change?.actions || [];
              if (actions.includes('create')) resourceChanges.add++;
              if (actions.includes('update')) resourceChanges.change++;
              if (actions.includes('delete')) resourceChanges.destroy++;
            });
            resourceChanges.hasChanges = resourceChanges.add + resourceChanges.change + resourceChanges.destroy > 0;
            return;
          }
        } catch (e) {
        }
      }
      
      // Fallback to text parsing - look for the plan summary first
      const planText = (output?.payload && typeof output.payload === 'object' && 'text' in output.payload && typeof output.payload.text === 'string') ? output.payload.text : '';
      if (planText) {
        // First try to parse the "Plan: X to add, Y to change, Z to destroy" summary
        const planSummaryMatch = planText.match(/Plan:\s+(\d+)\s+to\s+add,\s+(\d+)\s+to\s+change,\s+(\d+)\s+to\s+destroy/i);
        
        if (planSummaryMatch) {
          // Use the summary numbers - this is the most accurate
          resourceChanges.add += parseInt(planSummaryMatch[1], 10);
          resourceChanges.change += parseInt(planSummaryMatch[2], 10);
          resourceChanges.destroy += parseInt(planSummaryMatch[3], 10);
          resourceChanges.hasChanges = resourceChanges.add + resourceChanges.change + resourceChanges.destroy > 0;
        } else {
          // Fallback: Check for "no changes" text
          const hasNoChangesText = planText.includes('No changes.') || 
                                   planText.includes('no changes are needed') ||
                                   planText.includes('Infrastructure is up-to-date');
          
          if (hasNoChangesText) {
            // Explicitly no changes
            resourceChanges.hasChanges = false;
          } else {
            // If we can't find a summary and it's not explicitly "no changes", 
            // fall back to counting resource blocks (not individual + lines)
            const resourceBlocks = planText.match(/^[\s]*#\s+[^#\n]+will\s+be\s+(created|destroyed|updated)/gmi) || [];
            const addBlocks = planText.match(/^[\s]*#\s+[^#\n]+will\s+be\s+created/gmi) || [];
            const changeBlocks = planText.match(/^[\s]*#\s+[^#\n]+will\s+be\s+updated/gmi) || [];
            const destroyBlocks = planText.match(/^[\s]*#\s+[^#\n]+will\s+be\s+destroyed/gmi) || [];
            
            resourceChanges.add += addBlocks.length;
            resourceChanges.change += changeBlocks.length; 
            resourceChanges.destroy += destroyBlocks.length;
            resourceChanges.hasChanges = resourceBlocks.length > 0;
          }
        }
      }
    });
  }
  
  function formatDate(dateString: string): string {
    return new Date(dateString).toLocaleString();
  }
  
  function getRelativeTime(dateString: string): string {
    const now = new Date();
    const date = new Date(dateString);
    const diffInHours = Math.floor((now.getTime() - date.getTime()) / (1000 * 60 * 60));
    
    if (diffInHours < 1) return 'Just now';
    if (diffInHours < 24) return `${diffInHours} hours ago`;
    const diffInDays = Math.floor(diffInHours / 24);
    if (diffInDays < 7) return `${diffInDays} days ago`;
    const diffInWeeks = Math.floor(diffInDays / 7);
    return `${diffInWeeks} weeks ago`;
  }
  
  function getStateColor(state: string): string {
    switch (state) {
      case 'success':
        return 'bg-green-100 dark:bg-green-900/30 text-green-800 dark:text-green-400';
      case 'failure':
        return 'bg-red-100 dark:bg-red-900/30 text-red-800 dark:text-red-400';
      case 'running':
        return 'bg-blue-100 dark:bg-blue-900/30 text-blue-800 dark:text-blue-400';
      case 'queued':
        return 'bg-yellow-100 dark:bg-yellow-900/30 text-yellow-800 dark:text-yellow-400';
      case 'aborted':
        return 'bg-gray-100 dark:bg-gray-700 text-gray-800 dark:text-gray-300';
      default:
        return 'bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-400';
    }
  }
  
  function getStateIcon(state: string): string {
    switch (state) {
      case 'success':
        return '✅';
      case 'failure':
        return '❌';
      case 'running':
        return '🔄';
      case 'queued':
        return '⏳';
      case 'aborted':
        return '⚠️';
      default:
        return '❓';
    }
  }
  
  function getRunTypeLabel(runType: string): string {
    switch (runType) {
      case 'plan':
        return '📋 Plan';
      case 'apply':
        return '🚀 Apply';
      case 'index':
        return '📑 Index';
      case 'build-config':
        return '🔧 Build Config';
      case 'build-tree':
        return '🌳 Build Tree';
      default:
        return runType;
    }
  }
  
  function getBackUrl(): string {
    if ($selectedInstallation) {
      return `#/i/${$selectedInstallation.id}/workspaces`;
    }
    return '#/workspaces';
  }
  
  // Group runs by type for history view
  $: runHistory = allWorkspaceRuns.slice(0, 10); // Show last 10 runs
  $: lastApplyRun = allWorkspaceRuns.find(run => run.run_type === 'apply');
  $: lastPlanRun = allWorkspaceRuns.find(run => run.run_type === 'plan');
  
  // Tab state - removed 'outputs' tab
  let activeTab: 'history' = 'history';
</script>

<PageLayout 
  activeItem="workspaces" 
  title="Workspace Details"
  subtitle={workspace ? `${workspace.repo} / ${workspace.dir} / ${workspace.workspace}` : 'Loading...'}
>
  {#if isLoading}
    <div class="flex justify-center items-center py-12">
      <LoadingSpinner size="lg" />
    </div>
  {:else if error}
    <ErrorMessage type="error" message={error} />
    <div class="mt-4">
      <a 
        href={getBackUrl()} 
        class="text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 font-medium"
      >
        ← Back to Workspaces
      </a>
    </div>
  {:else if !isLoading && !workspace}
    <div class="text-center py-12">
      <p class="text-gray-600 dark:text-gray-400">Workspace not found.</p>
      <div class="mt-4">
        <a 
          href={getBackUrl()} 
          class="text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 font-medium"
        >
          ← Back to Workspaces
        </a>
      </div>
    </div>
  {:else if workspace}
    <!-- Back Navigation -->
    <div class="mb-6">
      <a 
        href={getBackUrl()} 
        class="inline-flex items-center text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 font-medium"
      >
        <svg class="w-4 h-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
        </svg>
        Back to Workspaces
      </a>
    </div>

    <!-- Workspace Overview -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-4 md:gap-6 mb-6 md:mb-8">
      <!-- Main Info -->
      <Card padding="md" class="lg:col-span-2">
        <div class="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-4 mb-4 md:mb-6">
          <div class="min-w-0 flex-1">
            <h2 class="text-xl md:text-2xl font-bold text-brand-primary mb-2 truncate">
              📁 {workspace.dir}
            </h2>
            <div class="flex flex-wrap items-center gap-2">
              <span class="text-sm md:text-lg px-2 md:px-3 py-0.5 md:py-1 bg-blue-100 dark:bg-blue-900/30 text-blue-800 dark:text-blue-400 rounded-full font-mono">
                {workspace.workspace}
              </span>
              <span class={`px-2 md:px-3 py-0.5 md:py-1 rounded-full font-medium text-sm ${getStateColor(workspace.state)}`}>
                {getStateIcon(workspace.state)} {workspace.state}
              </span>
            </div>
          </div>
          <div class="text-left sm:text-right">
            <div class="text-xs md:text-sm text-gray-600 dark:text-gray-400">Last Run</div>
            <div class="font-medium text-sm md:text-base">{getRunTypeLabel(workspace.run_type)}</div>
            <div class="text-xs md:text-sm text-gray-500 dark:text-gray-400">{getRelativeTime(workspace.created_at)}</div>
          </div>
        </div>
        
        <!-- Repository & Environment Info -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4 md:gap-6 text-xs md:text-sm">
          <div>
            <h4 class="font-medium text-gray-900 dark:text-gray-100 mb-2">Repository</h4>
            <div class="space-y-1">
              <div class="truncate"><span class="text-gray-600 dark:text-gray-400">Owner:</span> <span class="font-mono">{workspace.owner}</span></div>
              <div class="truncate"><span class="text-gray-600 dark:text-gray-400">Repo:</span> <span class="font-mono">{workspace.repo}</span></div>
              <div class="truncate"><span class="text-gray-600 dark:text-gray-400">{$currentVCSProvider === 'gitlab' ? 'GitLab' : 'GitHub'} Environment:</span> <span class="font-mono">{workspace.environment || 'default'}</span></div>
            </div>
          </div>
          <div>
            <h4 class="font-medium text-gray-900 dark:text-gray-100 mb-2">Last Run Context</h4>
            <div class="space-y-1">
              <div class="truncate"><span class="text-gray-600 dark:text-gray-400">Branch:</span> <span class="font-mono text-xs">{workspace.branch}</span></div>
              <div class="truncate"><span class="text-gray-600 dark:text-gray-400">Base Branch:</span> <span class="font-mono text-xs">{workspace.base_branch}</span></div>
              <div class="truncate"><span class="text-gray-600 dark:text-gray-400">Commit:</span> <span class="font-mono text-xs">{workspace.branch_ref.substring(0, 8)}</span></div>
            </div>
          </div>
        </div>
      </Card>
      
      <!-- Quick Stats -->
      <div class="space-y-3 md:space-y-4">
        <!-- Resource Changes (only show if we have plan data) -->
        {#if outputs.some(output => output?.step === 'tf/plan')}
          <Card padding="md">
            <h4 class="font-medium text-gray-900 dark:text-gray-100 mb-3">📊 Resource Changes</h4>
            {#if resourceChanges.hasChanges}
              <div class="space-y-2">
                <div class="flex justify-between">
                  <span class="text-green-600 dark:text-green-400">+ Add</span>
                  <span class="font-medium">{resourceChanges.add}</span>
                </div>
                <div class="flex justify-between">
                  <span class="text-yellow-600 dark:text-yellow-400">~ Change</span>
                  <span class="font-medium">{resourceChanges.change}</span>
                </div>
                <div class="flex justify-between">
                  <span class="text-red-600 dark:text-red-400">- Destroy</span>
                  <span class="font-medium">{resourceChanges.destroy}</span>
                </div>
              </div>
            {:else}
              <div class="text-center py-4 text-gray-500 dark:text-gray-400">
                <div class="text-2xl mb-1">✨</div>
                <div class="text-sm">No changes</div>
              </div>
            {/if}
          </Card>
        {/if}
        
        <!-- Cost Summary (if available) -->
        {#if costEstimation.length > 0 && costEstimation.some(c => c?.payload)}
          {@const costData = (() => {
            try {
              const rawData = costEstimation[0]?.payload;
              
              let parsedData;
              if (typeof rawData === 'string') {
                parsedData = JSON.parse(rawData);
              } else if (rawData && typeof rawData === 'object' && 'summary' in rawData && rawData.summary) {
                // @ts-ignore - Complex dynamic API response parsing
                const typedRawData = rawData;
                const summary = typedRawData.summary;
                parsedData = {
                  // @ts-ignore - Dynamic property access for API response
                  total_monthly_cost: summary?.total_monthly_cost,
                  // @ts-ignore - Dynamic property access for API response
                  prev_monthly_cost: summary?.prev_monthly_cost,
                  // @ts-ignore - Dynamic property access for API response
                  diff_monthly_cost: summary?.diff_monthly_cost,
                  // @ts-ignore - Dynamic property access for API response
                  currency: typedRawData.currency,
                  // @ts-ignore - Dynamic property access for API response
                  dirspaces: typedRawData.dirspaces
                };
              } else if (rawData && typeof rawData === 'object' && 'cost_estimation' in rawData) {
                parsedData = rawData['cost_estimation'];
              } else if (rawData && typeof rawData === 'object' && 'text' in rawData) {
                const textValue = rawData['text'];
                if (typeof textValue === 'string') {
                  parsedData = JSON.parse(textValue);
                }
              } else {
                parsedData = rawData;
              }
              
              // Filter to only show costs for the current workspace
              if (parsedData && parsedData.dirspaces && workspace) {
                const ws = workspace; // Create non-null reference
                // @ts-ignore - Dynamic property access from API response
                const currentWorkspaceCosts = parsedData.dirspaces.filter(ds => 
                  (ds.dir === ws.dir || ds.path === ws.dir) && 
                  ds.workspace === ws.workspace
                );
                
                if (currentWorkspaceCosts.length > 0) {
                  const workspaceCost = currentWorkspaceCosts[0];
                  return {
                    total_monthly_cost: workspaceCost.total_monthly_cost,
                    prev_monthly_cost: workspaceCost.prev_monthly_cost,
                    diff_monthly_cost: workspaceCost.diff_monthly_cost,
                    currency: parsedData.currency,
                    dirspaces: currentWorkspaceCosts
                  };
                }
              }
              
              return parsedData;
            } catch (e) {
              console.error('💰 Error parsing cost data:', e);
              return null;
            }
          })()}
          
          {#if costData?.total_monthly_cost !== undefined}
            <Card padding="md">
              <h4 class="font-medium text-gray-900 dark:text-gray-100 mb-3">💰 Last Plan Cost</h4>
              <div class="text-center">
                <div class="text-2xl font-bold text-green-600 dark:text-green-400">
                  ${costData.total_monthly_cost.toFixed(2)}
                </div>
                <div class="text-sm text-gray-600 dark:text-gray-400 mt-1">
                  {costData.currency || 'USD'} from last plan
                </div>
                {#if costData.diff_monthly_cost !== 0}
                  <div class="mt-2 text-sm">
                    <span class={costData.diff_monthly_cost > 0 ? 'text-red-600 dark:text-red-400' : 'text-green-600 dark:text-green-400'}>
                      {costData.diff_monthly_cost > 0 ? '+' : ''}{costData.diff_monthly_cost.toFixed(2)} change
                    </span>
                  </div>
                {/if}
              </div>
            </Card>
          {/if}
        {/if}
        
        <!-- Last Operations -->
        <Card padding="md">
          <h4 class="font-medium text-gray-900 dark:text-gray-100 mb-3">⏰ Recent Operations</h4>
          <div class="space-y-3 text-xs md:text-sm">
            {#if lastApplyRun}
              <div>
                <div class="flex justify-between items-center">
                  <span class="text-gray-600 dark:text-gray-400">Last Apply</span>
                  <span class={`px-2 py-1 rounded text-xs ${getStateColor(lastApplyRun.state)}`}>
                    {getStateIcon(lastApplyRun.state)}
                  </span>
                </div>
                <div class="text-xs text-gray-500 dark:text-gray-400">{getRelativeTime(lastApplyRun.created_at)}</div>
              </div>
            {/if}
            {#if lastPlanRun}
              <div>
                <div class="flex justify-between items-center">
                  <span class="text-gray-600 dark:text-gray-400">Last Plan</span>
                  <span class={`px-2 py-1 rounded text-xs ${getStateColor(lastPlanRun.state)}`}>
                    {getStateIcon(lastPlanRun.state)}
                  </span>
                </div>
                <div class="text-xs text-gray-500 dark:text-gray-400">{getRelativeTime(lastPlanRun.created_at)}</div>
              </div>
            {/if}
          </div>
        </Card>
      </div>
    </div>

    <!-- Actions -->
    <div class="grid grid-cols-1 sm:grid-cols-3 gap-3 md:gap-4 mb-6 md:mb-8">
      <ClickableCard 
        padding="md" 
        hover={true}
        on:click={() => workspace && navigateToRun(workspace.id)}
        aria-label="View latest run details"
      >
        <div class="text-center">
          <div class="text-xl md:text-2xl mb-1 md:mb-2">📋</div>
          <div class="font-medium text-sm md:text-base">Latest Run</div>
          <div class="text-xs md:text-sm text-gray-600 dark:text-gray-400">View most recent run details</div>
        </div>
      </ClickableCard>
      
      <ClickableCard 
        padding="md" 
        hover={true}
        on:click={() => workspace && navigateToRuns(`repo:${encodeURIComponent(workspace.repo)} and dir:${encodeURIComponent(workspace.dir)} and workspace:${encodeURIComponent(workspace.workspace)}`)}
        aria-label="View all runs for this workspace"
      >
        <div class="text-center">
          <div class="text-xl md:text-2xl mb-1 md:mb-2">📋</div>
          <div class="font-medium text-sm md:text-base">All Runs</div>
          <div class="text-xs md:text-sm text-gray-600 dark:text-gray-400">History of all runs</div>
        </div>
      </ClickableCard>
      
      <ClickableCard 
        padding="md" 
        hover={true}
        on:click={() => workspace && window.open(`${web_base_url}/${workspace.owner}/${workspace.repo}/tree/${workspace.branch}/${workspace.dir}`, '_blank')}
        aria-label="View workspace directory on GitHub"
      >
        <div class="text-center">
          <div class="text-xl md:text-2xl mb-1 md:mb-2">🔗</div>
          <div class="font-medium text-sm md:text-base">View on GitHub</div>
          <div class="text-xs md:text-sm text-gray-600 dark:text-gray-400">Open directory in repo</div>
        </div>
      </ClickableCard>
    </div>

    <!-- Tabbed Content -->
    <Card padding="none" class="mb-6">
      <!-- Tab Navigation - Single tab now, so just show as header -->
      <div class="border-b border-gray-200 dark:border-gray-600 px-4 md:px-6 py-3">
        <h3 class="font-medium text-base md:text-lg text-gray-900 dark:text-gray-100">
          📈 Recent Run History
        </h3>
      </div>
      
      <!-- Tab Content -->
      <div class="p-4 md:p-6">
        {#if activeTab === 'history'}
          <!-- Run History -->
          {#if runHistory.length === 0}
            <div class="text-center py-8 text-gray-500 dark:text-gray-400">
              <div class="text-4xl mb-2">📝</div>
              <p>No run history found</p>
            </div>
          {:else}
            <div class="space-y-3">
              {#each runHistory as run}
                <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between p-3 md:p-4 bg-gray-50 dark:bg-gray-700 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-600 transition-colors gap-3">
                  <div class="flex flex-wrap items-center gap-2">
                    <span class={`px-1.5 md:px-2 py-0.5 md:py-1 rounded text-xs font-medium ${getStateColor(run.state)}`}>
                      {getStateIcon(run.state)} {run.state}
                    </span>
                    <span class="font-medium text-sm md:text-base">{getRunTypeLabel(run.run_type)}</span>
                    {#if run.user}
                      <span class="text-xs md:text-sm text-gray-600 dark:text-gray-400">by {run.user}</span>
                    {/if}
                  </div>
                  <div class="flex items-center justify-between sm:justify-end gap-3 sm:gap-4">
                    <span class="text-xs md:text-sm text-gray-500 dark:text-gray-400">{formatDate(run.created_at)}</span>
                    <button
                      on:click={() => navigateToRun(run.id)}
                      class="text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 text-xs md:text-sm font-medium whitespace-nowrap"
                    >
                      View Details →
                    </button>
                  </div>
                </div>
              {/each}
            </div>
          {/if}
        
        {/if}
      </div>
    </Card>
  {/if}
</PageLayout>
