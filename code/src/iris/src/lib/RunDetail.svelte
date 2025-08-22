<script lang="ts">
  import type { WorkManifest } from './types';
  // Auth handled by PageLayout
  import { api } from './api';
  import { selectedInstallation, installations, currentVCSProvider, serverConfig } from './stores';
  import { analytics } from './analytics';
  import PageLayout from './components/layout/PageLayout.svelte';
  import LoadingSpinner from './components/ui/LoadingSpinner.svelte';
  import ErrorMessage from './components/ui/ErrorMessage.svelte';
  import Card from './components/ui/Card.svelte';
  import SafeOutput from './components/ui/SafeOutput.svelte';
  import { getWebBaseUrl } from './server-config';
  import PlanChanges from './components/terraform/PlanChanges.svelte';
  import ApplyChanges from './components/terraform/ApplyChanges.svelte';
  
  export let params: { id: string; installationId?: string } = { id: '' };
  
  let run: WorkManifest | null = null;
  let isLoading: boolean = false;
  let error: string | null = null;
  
  // Set initial loading state if we have a run ID
  $: if (params.id && !run && !error) {
    isLoading = true;
  }

  // Outputs state
  let outputs: OutputItem[] = [];
  let allOutputs: OutputItem[] = []; // All outputs including hidden ones for Raw Steps tab
  let costEstimation: OutputItem[] = [];
  let isLoadingOutputs: boolean = false;
  let outputsError: string | null = null;
  let expandedDirspaces: Set<string> = new Set();
  let activeOutputTab: 'all' | 'raw' | 'cost' | 'failed' | 'changes' = 'all';
  const web_base_url = getWebBaseUrl($currentVCSProvider, $serverConfig);
  
  // Visualization state
  let visualizationPlanOutput: string = '';
  let visualizationWorkManifestId: string = '';
  let isFetchingVisualizationData: boolean = false;
  
  interface OutputItem {
    payload?: {
      text?: string;
      plan?: string;
      plan_text?: string;
      has_changes?: boolean;
      ignore_errors?: boolean;
      visible_on?: string;
      summary?: {
        total_monthly_cost?: number;
        diff_monthly_cost?: number;
        prev_monthly_cost?: number;
      };
      currency?: string;
      dirspaces?: Array<{
        dir: string;
        workspace: string;
        total_monthly_cost: number;
        diff_monthly_cost: number;
        prev_monthly_cost: number;
      }>;
      // Lite mode properties
      _isLiteMode?: boolean;
      _originalStep?: string;
      _wasLoadedOnDemand?: boolean;
      _loadTimestamp?: number;
      _loadError?: boolean;
    };
    scope?: {
      dir?: string;
      workspace?: string;
      type?: string;
    };
    step?: string;
    state?: string;
    ignore_errors?: boolean;
    idx?: number;
  }
  
  // Auth check is handled by PageLayout
  
  // Auto-select installation if provided in URL
  $: if (params.installationId && $installations && $installations.length > 0) {
    const targetInstallation = $installations.find(inst => inst.id === params.installationId);
    if (targetInstallation && (!$selectedInstallation || $selectedInstallation.id !== targetInstallation.id)) {
      selectedInstallation.set(targetInstallation);
    }
  }
  
  // Load run data when params change
  $: if (params.id && $selectedInstallation) {
    loadRunData(params.id);
    
    // Track run detail view
    analytics.trackRunAction('view_details', params.id, {
      installation_id: $selectedInstallation.id
    });
  }
  
  async function loadRunData(runId: string): Promise<void> {
    if (!$selectedInstallation) return;
    
    error = null;
    isLoading = true;
    
    try {
      run = await api.getInstallationWorkManifest($selectedInstallation.id, runId);
      
      // Load outputs after run data is loaded
      loadOutputsData(runId);
    } catch (err) {
      console.error('Error loading run details:', err);
      error = err instanceof Error ? err.message : 'Failed to load run details';
      run = null;
    } finally {
      isLoading = false;
    }
  }

  async function loadOutputsData(runId: string): Promise<void> {
    if (!$selectedInstallation) return;
    
    outputsError = null;
    isLoadingOutputs = true;
    
    try {
      // Load full step data for filtering (All Steps tab needs visible_on metadata)
      
      // First, load all step metadata (with full payload) to check visible_on for filtering
      const allStepsResponse = await api.getWorkManifestOutputs(
        $selectedInstallation.id, 
        runId,
        { q: 'not step:tf/cost-estimation', limit: 100, lite: false }
      );
      
      interface StepOutput {
        step?: string;
        state?: string;
        payload?: {
          visible_on?: string;
          ignore_errors?: boolean;
          text?: string;
          _isLiteMode?: boolean;
          _originalStep?: string;
        };
        [key: string]: unknown;
      }

      // Filter out steps that shouldn't be visible based on visible_on property
      const visibleSteps = (allStepsResponse.outputs || []).filter((output: unknown) => {
        const step = output as OutputItem;
        
        // Apply visibility filtering
        const shouldShow = shouldShowStep(step);

        return shouldShow;
      });

      // Convert to lite mode format (remove payload to prevent memory issues)
      const liteOutputsResponse = {
        outputs: visibleSteps.map((output: unknown) => {
          const out = output as StepOutput;
          return {
            ...out,
            payload: {
              text: 'Click to view output content',
              _isLiteMode: true,
              _originalStep: out.step,
              // Keep essential payload properties for filtering
              visible_on: out.payload?.visible_on,
              ignore_errors: out.payload?.ignore_errors
            }
          };
        })
      };
      
      // Store ALL outputs (including hidden ones) for Raw Steps tab
      const allLiteOutputsResponse = {
        outputs: (allStepsResponse.outputs || []).map((output: unknown) => {
          const out = output as StepOutput;
          return {
            ...out,
            payload: {
              text: 'Click to view output content',
              _isLiteMode: true,
              _originalStep: out.step,
              // Keep essential payload properties for filtering
              visible_on: out.payload?.visible_on,
              ignore_errors: out.payload?.ignore_errors
            }
          };
        })
      };
      
      const costResponse = await api.getWorkManifestOutputs(
        $selectedInstallation.id, 
        runId,
        { q: 'step:tf/cost-estimation', limit: 100, lite: false }
      );
      
      // The outputs are already in the correct lite mode format from the filtering above
      outputs = liteOutputsResponse.outputs || [];
      allOutputs = allLiteOutputsResponse.outputs || []; // Store all outputs for Raw Steps tab
      
      // Cost estimation always gets full data
      costEstimation = (costResponse.outputs || []).map(output => output as OutputItem);

    } catch (err) {
      console.error('Error loading outputs:', err);
      outputsError = err instanceof Error ? err.message : 'Failed to load outputs';
      outputs = [];
      allOutputs = [];
      costEstimation = [];
    } finally {
      isLoadingOutputs = false;
    }
  }
  
  // Function to load full output content on demand
  async function loadFullOutput(output: OutputItem): Promise<void> {
    if (!$selectedInstallation || !run || !output.payload?._originalStep) return;
    
    try {
      const fullResponse = await api.getWorkManifestOutputs(
        $selectedInstallation.id,
        run.id,
        { q: `step:${output.payload._originalStep}`, lite: false }
      );
      
      if (fullResponse.outputs && fullResponse.outputs.length > 0) {
        // Find the specific output that matches the one we clicked on
        interface OutputMatch {
          idx?: number;
          step?: string;
          scope?: {
            dir?: string;
            workspace?: string;
          };
        }
        
        const matchingOutput = fullResponse.outputs.find((o: unknown) => {
          const out = o as OutputMatch;
          return out.idx === output.idx && 
            out.step === output.step &&
            out.scope?.dir === output.scope?.dir &&
            out.scope?.workspace === output.scope?.workspace;
        });
        
        if (!matchingOutput) {
          console.error('Could not find matching output for the selected step');
          return;
        }
        
        const fullOutput = matchingOutput as OutputItem;
        
        // Update the output in both the outputs and allOutputs arrays
        // Use the same matching logic to find the exact output
        const outputIndex = outputs.findIndex(o => 
          o.idx === output.idx && 
          o.step === output.step &&
          o.scope?.dir === output.scope?.dir &&
          o.scope?.workspace === output.scope?.workspace
        );
        const allOutputIndex = allOutputs.findIndex(o => 
          o.idx === output.idx && 
          o.step === output.step &&
          o.scope?.dir === output.scope?.dir &&
          o.scope?.workspace === output.scope?.workspace
        );
        
        const updatedPayload = {
          ...fullOutput.payload,
          _wasLoadedOnDemand: true,
          _loadTimestamp: Date.now()
        };
        
        // If there's no text content, show a message
        if (!updatedPayload.text) {
          updatedPayload.text = 'This step completed without producing any output.';
        }
        
        const updatedOutput = {
          ...fullOutput,
          payload: updatedPayload
        };
        
        // Update in outputs array (for All Steps tab)
        if (outputIndex !== -1) {
          outputs[outputIndex] = updatedOutput;
          outputs = [...outputs]; // Force Svelte reactivity
        }
        
        // Update in allOutputs array (for Raw Steps tab)
        if (allOutputIndex !== -1) {
          allOutputs[allOutputIndex] = updatedOutput;
          allOutputs = [...allOutputs]; // Force Svelte reactivity
        }
      }
    } catch (error) {
      console.error('Failed to load full output:', error);
      // Show error in both outputs arrays - use exact matching
      const index = outputs.findIndex(o => 
        o.idx === output.idx && 
        o.step === output.step &&
        o.scope?.dir === output.scope?.dir &&
        o.scope?.workspace === output.scope?.workspace
      );
      const allIndex = allOutputs.findIndex(o => 
        o.idx === output.idx && 
        o.step === output.step &&
        o.scope?.dir === output.scope?.dir &&
        o.scope?.workspace === output.scope?.workspace
      );
      
      const errorPayload = {
        text: `❌ Failed to load full output: ${error instanceof Error ? error.message : 'Unknown error'}`,
        _loadError: true
      };
      
      if (index !== -1) {
        outputs[index] = {
          ...outputs[index],
          payload: errorPayload
        };
        outputs = [...outputs]; // Trigger reactivity
      }
      
      if (allIndex !== -1) {
        allOutputs[allIndex] = {
          ...allOutputs[allIndex],
          payload: errorPayload
        };
        allOutputs = [...allOutputs]; // Trigger reactivity
      }
    }
  }
  
  // Helper functions for display
  function formatDate(dateString: string): string {
    return new Date(dateString).toLocaleString();
  }
  
  function getStateColor(state: string): string {
    switch (state) {
      case 'success':
        return 'text-green-600 bg-green-100';
      case 'completed':
        return 'text-blue-600 bg-blue-100'; // Neutral blue for completed (could have failures)
      case 'running':
      case 'queued':
        return 'text-blue-600 bg-blue-100';
      case 'failure':
      case 'aborted':
        return 'text-red-600 bg-red-100';
      default:
        return 'text-gray-600 dark:text-gray-400 bg-gray-100';
    }
  }

  // Get display state and color accounting for ignore_errors
  function getDisplayState(output: OutputItem): { state: string, color: string } {
    const originalState = output?.state || 'unknown';
    const ignoreErrors = output?.payload?.ignore_errors;
    
    // If the step failed but errors are ignored, show as "ignored" instead of "failure"
    if ((originalState === 'failure' || originalState === 'error') && ignoreErrors === true) {
      return {
        state: 'ignored',
        color: 'text-yellow-600 bg-yellow-100'
      };
    }
    
    // Otherwise use the original state
    return {
      state: originalState,
      color: getStateColor(originalState)
    };
  }

  // Terraform summary extraction removed for memory safety
  // Even parsing already-loaded text can cause performance issues with massive outputs
  
  function getStateIcon(state: string): string {
    switch (state) {
      case 'success':
        return '✅';
      case 'completed':
        return '🏁'; // Finished flag - neutral completion indicator
      case 'running':
        return '🔄';
      case 'queued':
        return '⏳';
      case 'failure':
      case 'aborted':
        return '❌';
      default:
        return '❓';
    }
  }

  // Smarter status display that considers dirspace failures
  function getSmartStatusDisplay(run: WorkManifest): { icon: string, color: string, label: string } {
    const state = run.state;
    
    // For completed runs, check if any dirspaces failed
    if (state === 'completed') {
      const hasFailures = run.dirspaces?.some(ds => ds.success === false);
      
      if (hasFailures) {
        return {
          icon: '⚠️',
          color: 'text-orange-600 bg-orange-100',
          label: 'Completed with Failures'
        };
      } else {
        return {
          icon: '🏁',
          color: 'text-blue-600 bg-blue-100',
          label: 'Completed'
        };
      }
    }
    
    // For other states, use the original logic
    return {
      icon: getStateIcon(state),
      color: getStateColor(state),
      label: state
    };
  }
  
  function getPullRequestInfo(kind: WorkManifest['kind']): { pullNumber: number | null, pullTitle: string | null } {
    if (typeof kind === 'object' && kind !== null && 'pull_number' in kind) {
      return {
        pullNumber: kind.pull_number,
        pullTitle: kind.pull_request_title || null
      };
    }
    return { pullNumber: null, pullTitle: null };
  }
  
  function getPullRequestUrl(owner: string, repo: string, pullNumber: number): string {
    // Construct GitHub PR URL using owner and repo
    return `${web_base_url}/${owner}/${repo}/pull/${pullNumber}`;
  }
  
  function getGitHubActionsUrl(owner: string, repo: string, runId: string): string {
    // Construct GitHub Actions run URL using owner, repo, and run_id
    return `${web_base_url}/${owner}/${repo}/actions/runs/${runId}`;
  }
  
  // Removed unused function - can be added back if needed for job-specific URLs
  
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

  // Output helper functions
  function toggleDirspaceExpansion(dirspaceKey: string): void {
    const newExpanded = new Set(expandedDirspaces);
    if (newExpanded.has(dirspaceKey)) {
      newExpanded.delete(dirspaceKey);
    } else {
      newExpanded.add(dirspaceKey);
    }
    expandedDirspaces = newExpanded;
  }

  function getDirspaceKey(dir: string, workspace: string): string {
    return `${dir}:${workspace}`;
  }

  // Terraform summaries removed for memory safety

  function getStepIcon(step: string): string {
    switch (step) {
      case 'tf/init':
        return '🔧';
      case 'tf/plan':
        return '📋';
      case 'tf/apply':
        return '🚀';
      case 'tf/cost-estimation':
        return '💰';
      case 'auth/update-terrateam-github-token':
        return '🔑';
      case 'auth/oidc':
        return '🔐';
      case 'env':
        return '🌍';
      case 'run':
        return '⚡';
      default:
        return '📄';
    }
  }

  function getStepLabel(step: string): string {
    switch (step) {
      case 'tf/init':
        return 'Terraform Init';
      case 'tf/plan':
        return 'Terraform Plan';
      case 'tf/apply':
        return 'Terraform Apply';
      case 'tf/cost-estimation':
        return 'Cost Estimation';
      case 'auth/update-terrateam-github-token':
        return 'Update GitHub Token';
      case 'auth/oidc':
        return 'OIDC Authentication';
      case 'env':
        return 'Environment Setup';
      case 'run':
        return 'Command Execution';
      default:
        return step.replace(/\//g, ' / ');
    }
  }

  // Check if a step should be considered as a real failure (accounting for ignore_errors)
  function isActualFailure(output: OutputItem): boolean {
    const state = output?.state;
    const ignoreErrors = output?.payload?.ignore_errors;
    
    // If the step failed but ignore_errors is true, don't treat it as a failure
    if ((state === 'failure' || state === 'error') && ignoreErrors === true) {
      return false;
    }
    
    // Otherwise, check if it actually failed
    return state === 'failure' || state === 'error';
  }

  // Check if a step should be visible based on the visible_on key
  function shouldShowStep(output: OutputItem): boolean {
    // Check for visible_on in the payload
    const visibleOn = output?.payload?.visible_on;
    
    // If there's no visible_on key, default is "failure" (only show if failed)
    if (!visibleOn) {
      return isActualFailure(output);
    }
    
    // Handle different visible_on values:
    // "always" - always show the step
    // "failure" - only show if there's a real failure (accounting for ignore_errors)
    // "success" - only show if successful
    if (typeof visibleOn === 'string') {
      switch (visibleOn) {
        case 'always':
          return true;
        case 'failure':
          // Only show if the step actually failed (accounting for ignore_errors)
          return isActualFailure(output);
        case 'success':
          // Only show if the step succeeded or if errors are ignored
          const ignoreErrors = output?.payload?.ignore_errors;
          return output.state === 'success' || (ignoreErrors === true && (output.state === 'failure' || output.state === 'error'));
        case 'error':
          // Only show if the step actually failed (accounting for ignore_errors)
          return isActualFailure(output);
        default:
          // Default to showing for unknown values
          return true;
      }
    }
    
    // Default to showing if we can't determine visibility
    return true;
  }

  // Modal state for full-screen output view
  let showOutputModal = false;
  let modalOutputContent = '';
  let modalOutputTitle = '';

  function openOutputModal(content: string, title: string) {
    modalOutputContent = content;
    modalOutputTitle = title;
    showOutputModal = true;
    // Prevent body scroll when modal is open
    document.body.classList.add('modal-open');
  }

  function closeOutputModal() {
    showOutputModal = false;
    modalOutputContent = '';
    modalOutputTitle = '';
    // Restore body scroll
    document.body.classList.remove('modal-open');
  }

  // Function to open plan changes view
  async function openPlanChanges(output: OutputItem) {
    // Check if this is lite mode and we need to fetch the full output
    if (output?.payload?._isLiteMode) {
      isFetchingVisualizationData = true;
      try {
        // Fetch the full output content
        const fullOutput = await fetchFullOutput(output);
        if (fullOutput) {
          visualizationPlanOutput = fullOutput;
          visualizationWorkManifestId = run?.id || '';
          activeOutputTab = 'changes';
        } else {
          console.error('Failed to fetch full output');
        }
      } catch (error) {
        console.error('Error fetching full output:', error);
      } finally {
        isFetchingVisualizationData = false;
      }
    } else {
      // Use the existing content
      visualizationPlanOutput = output.payload?.plan_text || output.payload?.text || '';
      visualizationWorkManifestId = run?.id || '';
      activeOutputTab = 'changes';
    }
  }
  
  // Helper function to fetch full output content
  async function fetchFullOutput(output: OutputItem): Promise<string | null> {
    if (!run?.id || !$selectedInstallation?.id) return null;
    
    try {
      // Get the full outputs (not lite mode)
      const response = await api.getWorkManifestOutputs(
        $selectedInstallation.id,
        run.id,
        {
          lite: false  // Force full content
        }
      );
      
      // Find the matching output by step and scope
      const fullOutput = response.outputs.find((o: unknown) => {
        const out = o as OutputItem;
        return out.step === output.step && 
          out.scope?.dir === output.scope?.dir &&
          out.scope?.workspace === output.scope?.workspace;
      }) as OutputItem | undefined;
      
      if (fullOutput?.payload?.text) {
        return fullOutput.payload.text;
      } else if (fullOutput?.payload?.plan_text) {
        return fullOutput.payload.plan_text;
      }
      
      return null;
    } catch (error) {
      console.error('Error fetching full outputs:', error);
      return null;
    }
  }

  // Check if output contains a Terraform plan
  function isPlanOutput(output: OutputItem): boolean {
    return !!(output?.step === 'tf/plan' || 
              output?.payload?.plan_text || 
              (output?.payload?.text && output.payload.text.includes('Terraform will perform')));
  }
  
  // Check if output contains a Terraform apply
  function isApplyOutput(output: OutputItem): boolean {
    return !!(output?.step === 'tf/apply' || 
              (output?.payload?.text && 
               (output.payload.text.includes('Creating...') || 
                output.payload.text.includes('Modifying...') || 
                output.payload.text.includes('Destroying...') ||
                output.payload.text.includes('Apply complete!'))));
  }
  
  // Function to open apply changes view
  async function openApplyChanges(output: OutputItem) {
    // Check if this is lite mode and we need to fetch the full output
    if (output?.payload?._isLiteMode) {
      isFetchingVisualizationData = true;
      try {
        // Fetch the full output content
        const fullOutput = await fetchFullOutput(output);
        if (fullOutput) {
          visualizationPlanOutput = fullOutput; // Reusing the same variable for simplicity
          visualizationWorkManifestId = run?.id || '';
          activeOutputTab = 'changes';
        } else {
          console.error('Failed to fetch full output');
        }
      } catch (error) {
        console.error('Error fetching full output:', error);
      } finally {
        isFetchingVisualizationData = false;
      }
    } else {
      // Use the existing full output
      const outputText = output?.payload?.text || '';
      if (outputText) {
        visualizationPlanOutput = outputText;
        visualizationWorkManifestId = run?.id || '';
        activeOutputTab = 'changes';
      }
    }
  }

  // Close modal on Escape key
  function handleKeydown(event: KeyboardEvent) {
    if (event.key === 'Escape' && showOutputModal) {
      closeOutputModal();
    }
  }

  // Get back URL based on stored search context
  function getBackUrl(): string {
    if (!$selectedInstallation) {
      return '#/runs';
    }
    
    const installationPath = `#/i/${$selectedInstallation.id}/runs`;
    
    if (typeof window !== 'undefined') {
      // Check if there's a stored search context from when we navigated here
      const storedSearch = sessionStorage.getItem('lastRunSearch');
      if (storedSearch) {
        return `${installationPath}?${storedSearch}`;
      }
      
      // Fallback: Check if we came from a search page with query params
      const referrer = document.referrer;
      if (referrer.includes('/runs?')) {
        // Extract the query parameters from the referrer
        const referrerUrl = new URL(referrer);
        const hash = referrerUrl.hash;
        const queryIndex = hash.indexOf('?');
        if (queryIndex !== -1) {
          const queryString = hash.substring(queryIndex);
          return `${installationPath}${queryString}`;
        }
      }
    }
    
    // Default to runs overview with installation scope
    return installationPath;
  }

  // Computed variables for filtering
  $: failedOutputs = outputs.filter((output: OutputItem) => {
    const isFailed = isActualFailure(output);
    const shouldShow = shouldShowStep(output);
    return isFailed && shouldShow;
  }) as OutputItem[];
  
  // Group failed outputs by dirspace
  interface DirspaceGroup {
    dir: string;
    workspace: string;
    outputs: OutputItem[];
  }
  
  $: failedByDirspace = failedOutputs.reduce<Record<string, DirspaceGroup>>((acc, output) => {
    const key = getDirspaceKey(output?.scope?.dir || 'unknown', output?.scope?.workspace || 'unknown');
    if (!acc[key]) {
      acc[key] = {
        dir: output?.scope?.dir || 'unknown',
        workspace: output?.scope?.workspace || 'unknown',
        outputs: []
      };
    }
    acc[key].outputs.push(output);
    return acc;
  }, {});
</script>

<svelte:window on:keydown={handleKeydown} />

<PageLayout 
  activeItem="runs" 
  title="Run Details"
  subtitle={run ? `${run.repo} - ${run.dirspaces.length} dirspace${run.dirspaces.length !== 1 ? 's' : ''}` : 'Loading...'}
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
        ← Back to Runs
      </a>
    </div>
  {:else if run}
    <!-- Back Navigation -->
    <div class="mb-6">
      <a 
        href={getBackUrl()} 
        class="inline-flex items-center text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 font-medium"
      >
        <svg class="w-4 h-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
        </svg>
        Back to Runs
      </a>
    </div>

    <!-- Run Overview -->
    <Card padding="lg" class="mb-6">
      <div class="flex flex-col lg:flex-row lg:items-start lg:justify-between gap-4 mb-6">
        <div class="flex-1">
          <h2 class="text-xl sm:text-2xl font-bold text-blue-600 dark:text-blue-400 mb-2 break-words">
            {run.repo}
          </h2>
          <div class="flex flex-col sm:flex-row sm:items-center sm:space-x-4 space-y-1 sm:space-y-0 text-sm text-gray-600 dark:text-gray-400">
            <span>Dirspaces: <span class="font-medium">{run.dirspaces.length}</span></span>
            <span>Environment: <span class="font-medium">{run.environment || 'default'}</span></span>
          </div>
        </div>
        <div class="flex flex-col items-start lg:items-end space-y-2">
          {#if run}
            {@const smartStatus = getSmartStatusDisplay(run)}
            <div class="flex flex-wrap items-center gap-2">
              <span class="text-sm font-medium whitespace-nowrap">Status:</span>
              <span class={`px-3 py-1 text-xs sm:text-sm font-medium rounded-full whitespace-nowrap ${smartStatus.color}`}>
                {smartStatus.icon} {smartStatus.label}
              </span>
            </div>
          {/if}
          <div class="text-sm text-gray-600 dark:text-gray-400">
            {getRunTypeLabel(run.run_type)}
          </div>
          {#if run.run_id}
            <a 
              href={getGitHubActionsUrl(run.owner, run.repo, run.run_id)}
              target="_blank"
              rel="noopener noreferrer"
              class="inline-flex items-center text-sm text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 hover:underline whitespace-nowrap"
            >
              <svg class="w-4 h-4 mr-1 flex-shrink-0" fill="currentColor" viewBox="0 0 24 24">
                <path d="M12 0C5.37 0 0 5.37 0 12c0 5.31 3.435 9.795 8.205 11.385.6.105.825-.255.825-.57 0-.285-.015-1.23-.015-2.235-3.015.555-3.795-.735-4.035-1.41-.135-.345-.72-1.41-1.23-1.695-.42-.225-1.02-.78-.015-.795.945-.015 1.62.87 1.845 1.23 1.08 1.815 2.805 1.305 3.495.99.105-.78.42-1.305.765-1.605-2.67-.3-5.46-1.335-5.46-5.925 0-1.305.465-2.385 1.23-3.225-.12-.3-.54-1.53.12-3.18 0 0 1.005-.315 3.3 1.23.96-.27 1.98-.405 3-.405s2.04.135 3 .405c2.295-1.56 3.3-1.23 3.3-1.23.66 1.65.24 2.88.12 3.18.765.84 1.23 1.905 1.23 3.225 0 4.605-2.805 5.625-5.475 5.925.435.375.81 1.095.81 2.22 0 1.605-.015 2.895-.015 3.3 0 .315.225.69.825.57A12.02 12.02 0 0024 12c0-6.63-5.37-12-12-12z"/>
              </svg>
              <span class="hidden sm:inline">View GitHub Actions Log</span>
              <span class="sm:hidden">View Log</span>
              <svg class="w-3 h-3 ml-1 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
              </svg>
            </a>
          {/if}
        </div>
      </div>

      <!-- Pull Request Information -->
      {#if getPullRequestInfo(run.kind).pullNumber}
        {@const prInfo = getPullRequestInfo(run.kind)}
        <div class="border-t border-gray-200 dark:border-gray-700 pt-6 mb-6">
          <h3 class="text-lg font-semibold text-blue-600 dark:text-blue-400 mb-4">Pull Request Details</h3>
          <div class="flex flex-col md:grid md:grid-cols-2 gap-4 md:gap-6">
            <div>
              <div class="flex items-center space-x-2 mb-3">
                <svg class="w-5 h-5 text-green-600 flex-shrink-0" fill="currentColor" viewBox="0 0 16 16">
                  <path d="M8 0a8 8 0 1 1 0 16A8 8 0 0 1 8 0zM4.5 7.5a.5.5 0 0 0 0 1h5.793l-2.147 2.146a.5.5 0 0 0 .708.708l3-3a.5.5 0 0 0 0-.708l-3-3a.5.5 0 1 0-.708.708L10.293 7.5H4.5z"/>
                </svg>
                <a 
                  href={getPullRequestUrl(run.owner, run.repo, prInfo.pullNumber || 0)}
                  target="_blank"
                  rel="noopener noreferrer"
                  class="font-medium text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 hover:underline flex items-center space-x-1"
                >
                  <span>PR #{prInfo.pullNumber}</span>
                  <svg class="w-3 h-3 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
                  </svg>
                </a>
              </div>
              {#if prInfo.pullTitle}
                <p class="text-gray-700 dark:text-gray-300 text-sm break-words">
                  {prInfo.pullTitle}
                </p>
              {/if}
            </div>
            <div class="mt-2 md:mt-0">
              <div class="space-y-2 text-sm">
                <div class="flex flex-col sm:flex-row sm:justify-between gap-1">
                  <span class="text-gray-600 dark:text-gray-400">Branch:</span>
                  <span class="font-medium font-mono text-xs sm:text-sm text-blue-600 dark:text-blue-400 break-all">{run.branch}</span>
                </div>
                <div class="flex flex-col sm:flex-row sm:justify-between gap-1">
                  <span class="text-gray-600 dark:text-gray-400">Target:</span>
                  <span class="font-medium font-mono text-xs sm:text-sm text-green-600 dark:text-green-400 break-all">{run.base_branch}</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      {:else}
        <!-- Non-PR Run (drift, index, etc.) -->
        <div class="border-t border-gray-200 dark:border-gray-700 pt-6 mb-6">
          <h3 class="text-lg font-semibold text-blue-600 dark:text-blue-400 mb-4">Run Information</h3>
          <div class="grid md:grid-cols-2 gap-4 md:gap-6">
            <div>
              <div class="flex items-center space-x-2 mb-3">
                <svg class="w-5 h-5 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
                <span class="font-medium text-gray-900 dark:text-gray-100">
                  {typeof run.kind === 'string' ? run.kind.charAt(0).toUpperCase() + run.kind.slice(1) : 'Manual'} Run
                </span>
              </div>
            </div>
            <div>
              <div class="space-y-2 text-sm">
                <div class="flex justify-between">
                  <span class="text-gray-600 dark:text-gray-400">Branch:</span>
                  <span class="font-medium font-mono text-blue-600">{run.branch}</span>
                </div>
                <div class="flex justify-between">
                  <span class="text-gray-600 dark:text-gray-400">Base:</span>
                  <span class="font-medium font-mono text-green-600">{run.base_branch}</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      {/if}

      <!-- Timing Information -->
      <div class="border-t border-gray-200 dark:border-gray-700 pt-6">
        <h3 class="text-lg font-semibold text-blue-600 dark:text-blue-400 mb-4">Execution Timeline</h3>
        <div class="grid md:grid-cols-3 gap-4 md:gap-6">
          <div>
            <div class="text-sm text-gray-600 dark:text-gray-400 mb-1">Started</div>
            <div class="font-medium text-gray-900 dark:text-gray-100 dark:text-gray-100">{formatDate(run.created_at)}</div>
          </div>
          {#if run.completed_at}
            <div>
              <div class="text-sm text-gray-600 dark:text-gray-400 mb-1">Completed</div>
              <div class="font-medium text-gray-900 dark:text-gray-100 dark:text-gray-100">{formatDate(run.completed_at)}</div>
            </div>
            <div>
              <div class="text-sm text-gray-600 dark:text-gray-400 mb-1">Duration</div>
              <div class="font-medium">
                {Math.round((new Date(run.completed_at).getTime() - new Date(run.created_at).getTime()) / 1000 / 60)} minutes
              </div>
            </div>
          {:else}
            <div>
              <div class="text-sm text-gray-600 dark:text-gray-400 mb-1">Status</div>
              <div class="font-medium text-blue-600">In Progress</div>
            </div>
            <div>
              <div class="text-sm text-gray-600 dark:text-gray-400 mb-1">Running Time</div>
              <div class="font-medium">
                {Math.round((new Date().getTime() - new Date(run.created_at).getTime()) / 1000 / 60)} minutes
              </div>
            </div>
          {/if}
        </div>
      </div>

      <!-- User Information -->
      {#if run.user}
        <div class="border-t pt-6">
          <h3 class="text-lg font-semibold text-blue-600 dark:text-blue-400 mb-4">Triggered By</h3>
          <div class="flex items-center space-x-2">
            <div class="w-8 h-8 bg-blue-600 rounded-full flex items-center justify-center">
              <span class="text-white text-sm font-medium">
                {run.user.charAt(0).toUpperCase()}
              </span>
            </div>
            <span class="font-medium">{run.user}</span>
          </div>
        </div>
      {/if}
    </Card>

    <!-- Run Outputs -->{#if run}
    <Card padding="lg" class="mb-6">
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-6">
        <h3 class="text-lg font-semibold text-blue-600 dark:text-blue-400">Execution Outputs</h3>
        
        <!-- Output Filter Tabs -->
        <div class="flex flex-wrap gap-1 bg-gray-100 dark:bg-gray-800 rounded-lg p-1">
          <button 
            on:click={() => activeOutputTab = 'all'}
            class="px-2 sm:px-3 py-1 text-xs sm:text-sm font-medium rounded-md transition-colors whitespace-nowrap {activeOutputTab === 'all' ? 'bg-white dark:bg-gray-700 text-blue-600 dark:text-blue-400 shadow-sm' : 'text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-100'}"
          >
            <span class="hidden sm:inline">All Steps</span>
            <span class="sm:hidden">All</span>
          </button>
          <button 
            on:click={() => activeOutputTab = 'raw'}
            class="px-2 sm:px-3 py-1 text-xs sm:text-sm font-medium rounded-md transition-colors whitespace-nowrap {activeOutputTab === 'raw' ? 'bg-white dark:bg-gray-700 text-blue-600 dark:text-blue-400 shadow-sm' : 'text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-100'}"
          >
            <span class="hidden sm:inline">🔧 Raw Steps</span>
            <span class="sm:hidden">🔧 Raw</span>
          </button>
          <button 
            on:click={() => activeOutputTab = 'cost'}
            class="px-2 sm:px-3 py-1 text-xs sm:text-sm font-medium rounded-md transition-colors whitespace-nowrap {activeOutputTab === 'cost' ? 'bg-white dark:bg-gray-700 text-blue-600 dark:text-blue-400 shadow-sm' : 'text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-100'}"
          >
            💰 Cost <span class="hidden sm:inline">({costEstimation.length})</span>
            <span class="sm:hidden text-[10px]">({costEstimation.length})</span>
          </button>
          <button 
            on:click={() => activeOutputTab = 'failed'}
            class="px-2 sm:px-3 py-1 text-xs sm:text-sm font-medium rounded-md transition-colors whitespace-nowrap {activeOutputTab === 'failed' ? 'bg-white dark:bg-gray-700 text-blue-600 dark:text-blue-400 shadow-sm' : 'text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-100'}"
          >
            ❌ Failed
          </button>
          {#if run?.run_type === 'plan' || run?.run_type === 'apply'}
            <button 
              on:click={() => activeOutputTab = 'changes'}
              class="px-3 py-1 text-sm font-medium rounded-md transition-colors {activeOutputTab === 'changes' ? 'bg-white dark:bg-gray-700 text-blue-600 dark:text-blue-400 shadow-sm' : 'text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-100'}"
            >
              📊 Changes
            </button>
          {/if}
        </div>
      </div>

      {#if isLoadingOutputs}
        <div class="flex justify-center items-center py-8">
          <LoadingSpinner size="md" />
          <span class="ml-3 text-gray-600 dark:text-gray-400">Loading outputs...</span>
        </div>
      {:else if outputsError}
        <ErrorMessage type="error" message={outputsError} />
      {:else}
        
        <!-- Cost Estimation Tab -->
        {#if activeOutputTab === 'cost'}
          {#if costEstimation.length === 0}
            <div class="text-center py-8 text-gray-500 dark:text-gray-400">
              <div class="text-4xl mb-2">💰</div>
              <p class="text-gray-500 dark:text-gray-400">No cost estimation data available</p>
            </div>
          {:else}
            <div class="space-y-6">
              {#each costEstimation as output}
                {@const typedOutput = output}
                {@const costData = typedOutput?.payload}

                {#if costData?.summary}
                  <!-- Cost Summary Card -->
                  <div class="bg-gradient-to-r from-green-50 to-blue-50 dark:from-green-900/20 dark:to-blue-900/20 border border-green-200 dark:border-green-800 rounded-lg p-6">
                    <div class="mb-6">
                      <div class="flex items-center space-x-3">
                        <div class="w-10 h-10 bg-green-100 dark:bg-green-900/30 rounded-full flex items-center justify-center">
                          <span class="text-xl">💰</span>
                        </div>
                        <div>
                          <h4 class="text-lg font-semibold text-green-800 dark:text-green-400">Cost Impact Summary</h4>
                          <p class="text-sm text-green-600 dark:text-green-400">Monthly infrastructure costs in {costData?.currency || 'USD'}</p>
                        </div>
                      </div>
                    </div>
                    
                    <!-- Cost Summary Metrics -->
                    <div class="grid md:grid-cols-3 gap-4 md:gap-6">
                      <div class="bg-white dark:bg-gray-800 rounded-lg p-4 text-center border border-gray-200 dark:border-gray-700">
                        <div class="text-2xl font-bold text-blue-600 dark:text-blue-400">
                          ${(costData.summary.total_monthly_cost || 0).toFixed(2)}
                        </div>
                        <div class="text-sm text-gray-600 dark:text-gray-400 mt-1">Total Monthly Cost</div>
                      </div>
                      
                      <div class="bg-white dark:bg-gray-800 rounded-lg p-4 text-center border border-gray-200 dark:border-gray-700">
                        <div class="text-2xl font-bold {(costData.summary?.diff_monthly_cost || 0) > 0 ? 'text-red-600' : (costData.summary?.diff_monthly_cost || 0) < 0 ? 'text-green-600' : 'text-gray-600 dark:text-gray-400'}">
                          {(costData.summary?.diff_monthly_cost || 0) > 0 ? '+' : ''}${(costData.summary?.diff_monthly_cost || 0).toFixed(2)}
                        </div>
                        <div class="text-sm text-gray-600 dark:text-gray-400 mt-1">Monthly Change</div>
                      </div>
                      
                      <div class="bg-white dark:bg-gray-800 rounded-lg p-4 text-center border border-gray-200 dark:border-gray-700">
                        <div class="text-2xl font-bold text-gray-700 dark:text-gray-300">
                          ${(costData.summary.prev_monthly_cost || 0).toFixed(2)}
                        </div>
                        <div class="text-sm text-gray-600 dark:text-gray-400 mt-1">Previous Monthly Cost</div>
                      </div>
                    </div>
                  </div>
                  
                  <!-- Per-Dirspace Cost Breakdown -->
                  {#if costData?.dirspaces && costData.dirspaces.length > 0}
                    {@const zeroCostDirspaces = costData.dirspaces.filter(d => d.total_monthly_cost === 0 && d.diff_monthly_cost === 0)}
                    <div class="bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg overflow-hidden">
                      <div class="bg-gray-50 dark:bg-gray-700 px-6 py-4 border-b border-gray-200 dark:border-gray-600">
                        <h4 class="text-lg font-semibold text-gray-800 dark:text-gray-200">Cost Breakdown by Directory</h4>
                        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Per-workspace cost analysis</p>
                      </div>
                      
                      <div class="divide-y divide-gray-200 dark:divide-gray-600">
                        {#each costData.dirspaces as dirspace}
                          {#if dirspace.total_monthly_cost > 0 || dirspace.diff_monthly_cost !== 0}
                            <div class="px-4 sm:px-6 py-4 hover:bg-gray-50 dark:hover:bg-gray-700">
                              <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
                                <div class="flex-1 min-w-0">
                                  <div class="flex items-center gap-3">
                                    <div class="w-3 h-3 rounded-full flex-shrink-0 {dirspace.diff_monthly_cost > 0 ? 'bg-red-400' : dirspace.diff_monthly_cost < 0 ? 'bg-green-400' : 'bg-gray-400'}"></div>
                                    <div class="min-w-0 flex-1">
                                      <div class="font-medium text-gray-900 dark:text-gray-100 truncate">{dirspace.dir}</div>
                                      <div class="text-sm text-gray-500 dark:text-gray-400">Workspace: {dirspace.workspace}</div>
                                    </div>
                                  </div>
                                </div>
                                
                                <div class="flex items-center gap-3 sm:gap-4 text-xs sm:text-sm flex-shrink-0">
                                  <div class="text-center min-w-[60px]">
                                    <div class="font-semibold text-gray-900 dark:text-gray-100">${dirspace.total_monthly_cost.toFixed(2)}</div>
                                    <div class="text-xs text-gray-500">Total</div>
                                  </div>
                                  
                                  {#if dirspace.diff_monthly_cost !== 0}
                                    <div class="text-center min-w-[60px]">
                                      <div class="font-semibold {dirspace.diff_monthly_cost > 0 ? 'text-red-600 dark:text-red-400' : 'text-green-600 dark:text-green-400'}">
                                        {dirspace.diff_monthly_cost > 0 ? '+' : ''}${dirspace.diff_monthly_cost.toFixed(2)}
                                      </div>
                                      <div class="text-xs text-gray-500">Change</div>
                                    </div>
                                  {/if}
                                  
                                  <div class="text-center min-w-[60px]">
                                    <div class="font-semibold text-gray-700 dark:text-gray-300">${dirspace.prev_monthly_cost.toFixed(2)}</div>
                                    <div class="text-xs text-gray-500">Previous</div>
                                  </div>
                                </div>
                              </div>
                            </div>
                          {/if}
                        {/each}
                      </div>
                      
                      <!-- Show zero-cost dirspaces in a collapsed section -->
                      {#if zeroCostDirspaces.length > 0}
                        <details class="border-t border-gray-200 dark:border-gray-600">
                          <summary class="px-6 py-3 bg-gray-50 dark:bg-gray-700 text-sm text-gray-600 dark:text-gray-400 cursor-pointer hover:bg-gray-100 dark:hover:bg-gray-600">
                            Show {zeroCostDirspaces.length} directories with no cost impact
                          </summary>
                          <div class="divide-y divide-gray-100 dark:divide-gray-600">
                            {#each zeroCostDirspaces as dirspace}
                              <div class="px-6 py-3 text-sm bg-white dark:bg-gray-800">
                                <div class="flex items-center justify-between">
                                  <div class="flex items-center space-x-3">
                                    <div class="w-2 h-2 rounded-full bg-gray-300 dark:bg-gray-600"></div>
                                    <span class="text-gray-700 dark:text-gray-300">{dirspace.dir}</span>
                                    <span class="text-gray-500 dark:text-gray-400">({dirspace.workspace})</span>
                                  </div>
                                  <span class="text-gray-500 dark:text-gray-400">$0.00</span>
                                </div>
                              </div>
                            {/each}
                          </div>
                        </details>
                      {/if}
                    </div>
                  {/if}
                {:else}
                  <!-- Fallback for unstructured cost data -->
                  <div class="bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg p-4">
                    <div class="flex items-center space-x-2 mb-2">
                      <span class="text-lg">💰</span>
                      <span class="font-medium text-yellow-800 dark:text-yellow-400">Cost Estimation</span>
                    </div>
                    
                    {#if typedOutput?.payload?.text}
                      <div class="mt-3">
                        <div class="flex items-center justify-between mb-1">
                          <div class="text-xs text-yellow-700 dark:text-yellow-400">Cost Analysis:</div>
                          <button 
                            class="text-xs text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 px-2 py-1 border border-blue-200 dark:border-blue-600 rounded hover:bg-blue-50 dark:hover:bg-blue-900/30 transition-colors"
                            on:click={() => openOutputModal(typedOutput.payload?.text || '', 'Cost Estimation Analysis')}
                          >
                            🔍 Expand
                          </button>
                        </div>
                        <pre class="text-sm bg-white dark:bg-gray-800 p-3 rounded border border-gray-200 dark:border-gray-600 overflow-x-auto text-gray-800 dark:text-gray-200 max-h-60 whitespace-pre-wrap font-mono">{typedOutput.payload?.text || ''}</pre>
                      </div>
                    {:else}
                      <pre class="text-sm bg-white dark:bg-gray-800 p-3 rounded border border-gray-200 dark:border-gray-600 overflow-x-auto text-gray-800 dark:text-gray-200">{JSON.stringify(output, null, 2)}</pre>
                    {/if}
                  </div>
                {/if}
              {/each}
            </div>
          {/if}
        
        <!-- All Steps Tab -->
        {:else if activeOutputTab === 'all'}
          <!-- Dirspace-organized outputs -->
          <div class="space-y-4">
            {#each run.dirspaces as dirspace}
              {@const dirspaceKey = getDirspaceKey(dirspace.dir, dirspace.workspace)}
              {@const isExpanded = expandedDirspaces.has(dirspaceKey)}
              {@const dirspaceOutputs = outputs.filter((output) => {
                const matchesDirspace = output?.scope?.dir === dirspace.dir && output?.scope?.workspace === dirspace.workspace;
                const shouldShow = shouldShowStep(output);
                return matchesDirspace && shouldShow;
              })}
              
              <div class="border border-gray-200 dark:border-gray-700 rounded-lg">
                <button 
                  on:click={() => toggleDirspaceExpansion(dirspaceKey)}
                  class="w-full flex items-center justify-between p-4 text-left hover:bg-gray-50 dark:hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-inset"
                >
                  <div class="flex items-center space-x-3 flex-1 min-w-0">
                    <div class="flex-shrink-0">
                      {#if dirspace.success === true}
                        <div class="w-3 h-3 rounded-full bg-green-500"></div>
                      {:else if dirspace.success === false}
                        <div class="w-3 h-3 rounded-full bg-red-500"></div>
                      {:else}
                        <div class="w-3 h-3 rounded-full bg-gray-400"></div>
                      {/if}
                    </div>
                    <div class="flex-1 min-w-0">
                      <div class="font-medium text-gray-900 dark:text-gray-100 truncate">{dirspace.dir}</div>
                      <div class="text-sm text-gray-600 dark:text-gray-400 truncate">Workspace: {dirspace.workspace}</div>
                      
                      <!-- Terraform summaries removed for memory safety -->
                    </div>
                  </div>
                  <div class="flex items-center space-x-2 flex-shrink-0">
                    <span class="text-xs sm:text-sm text-gray-500 dark:text-gray-400">
                      <span class="hidden sm:inline">{dirspaceOutputs.length} step{dirspaceOutputs.length !== 1 ? 's' : ''}</span>
                      <span class="sm:hidden">{dirspaceOutputs.length} {dirspaceOutputs.length === 1 ? 'step' : 'steps'}</span>
                    </span>
                    <svg class="w-5 h-5 text-gray-400 dark:text-gray-500 transform transition-transform {isExpanded ? 'rotate-180' : ''}" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                    </svg>
                  </div>
                </button>
                
                {#if isExpanded}
                  <div class="border-t border-gray-200 dark:border-gray-600 bg-gray-50 dark:bg-gray-700">
                    {#if dirspaceOutputs.length === 0}
                      <div class="p-4 text-center text-gray-500 dark:text-gray-400">
                        No step outputs available for this dirspace
                      </div>
                    {:else}
                      <div class="p-4 space-y-3">
                        {#each dirspaceOutputs as output ((output.step || 'unknown') + (output.payload?._loadTimestamp || ''))}
                          {@const typedOutput = output}
                          {@const displayState = getDisplayState(typedOutput)}
                          <div class="bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-600 rounded p-3">
                            <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2 mb-2">
                              <div class="flex flex-wrap items-center gap-x-2 gap-y-1">
                                <span class="flex-shrink-0">{getStepIcon(typedOutput?.step || 'unknown')}</span>
                                <span class="font-medium text-gray-900 dark:text-gray-100">{getStepLabel(typedOutput?.step || 'Unknown Step')}</span>
                                {#if typedOutput?.state}
                                  <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium {displayState.color}">
                                    {displayState.state}
                                  </span>
                                {/if}
                                <span class="text-xs text-gray-500">idx: {typedOutput?.idx}</span>
                              </div>
                              {#if isPlanOutput(typedOutput)}
                                <button
                                  type="button"
                                  on:click={() => openPlanChanges(typedOutput)}
                                  class="flex-shrink-0 inline-flex items-center px-2 py-1 text-xs font-medium rounded-md text-blue-700 dark:text-blue-400 bg-blue-50 dark:bg-blue-900/30 hover:bg-blue-100 dark:hover:bg-blue-900/50 transition-colors"
                                  title="View plan changes"
                                >
                                  <svg class="w-3 h-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
                                          d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                                  </svg>
                                  View Changes
                                </button>
                              {:else if isApplyOutput(typedOutput)}
                                <button
                                  type="button"
                                  on:click={() => openApplyChanges(typedOutput)}
                                  class="flex-shrink-0 inline-flex items-center px-2 py-1 text-xs font-medium rounded-md text-green-700 dark:text-green-400 bg-green-50 dark:bg-green-900/30 hover:bg-green-100 dark:hover:bg-green-900/50 transition-colors"
                                  title="View apply changes"
                                >
                                  <svg class="w-3 h-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
                                          d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                                  </svg>
                                  View Changes
                                </button>
                              {/if}
                            </div>
                            {#if typedOutput?.payload?.text}
                              <!-- Output not loaded - click to view -->
                              {#if typedOutput.payload._isLiteMode}
                                <div class="mt-3">
                                  <div class="text-xs text-gray-600 dark:text-gray-400 mb-2">Output:</div>
                                  <div class="bg-gray-50 dark:bg-gray-700 border border-gray-200 dark:border-gray-600 rounded-lg p-4">
                                    <div class="flex flex-col gap-3">
                                      <div class="flex items-center text-sm text-gray-600 dark:text-gray-400">
                                        <svg class="w-5 h-5 text-gray-500 dark:text-gray-400 mr-2 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                                        </svg>
                                        <span>Output content not loaded</span>
                                      </div>
                                      <button
                                        type="button"
                                        on:click={() => loadFullOutput(typedOutput)}
                                        class="inline-flex items-center justify-center px-4 py-2 border border-blue-300 dark:border-blue-600 text-sm font-medium rounded-md text-blue-700 dark:text-blue-400 bg-blue-50 dark:bg-blue-900/30 hover:bg-blue-100 dark:hover:bg-blue-900/50 transition-colors"
                                      >
                                        <svg class="w-4 h-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                                        </svg>
                                        View Output
                                      </button>
                                    </div>
                                  </div>
                                </div>
                              {:else}
                                <!-- Display actual step output content with safe loading -->
                                <div class="mt-3">
                                  <div class="text-xs text-gray-600 dark:text-gray-400 mb-2">
                                    Output: {#if typedOutput.payload._wasLoadedOnDemand}
                                      <span class="text-green-600 dark:text-green-400 font-medium">(loaded on demand)</span>
                                    {/if}
                                  </div>
                                  <SafeOutput 
                                    content={typedOutput.payload.text}
                                    title={`${getStepLabel(typedOutput?.step || 'Unknown Step')} - ${typedOutput?.scope?.dir || 'unknown'}:${typedOutput?.scope?.workspace || 'unknown'}`}
                                    githubUrl={run?.owner && run?.repo && run?.run_id ? getGitHubActionsUrl(run.owner, run.repo, run.run_id) : ''}
                                    orgName={run?.owner || ''}
                                    repoName={run?.repo || ''}
                                    prNumber={typeof run?.kind === 'object' && run.kind?.pull_number ? run.kind.pull_number : ''}
                                    runType={run?.run_type || ''}
                                    stepName={typedOutput?.step || ''}
                                    on:expand={(e) => openOutputModal(e.detail.content, e.detail.title)}
                                  />
                                </div>
                              {/if}
                            {:else if typedOutput?.step === 'auth/update-terrateam-github-token' || typedOutput?.step === 'auth/oidc'}
                              <!-- Hide debug for auth steps - no meaningful output to show -->
                              <div class="mt-3 text-xs text-gray-500 dark:text-gray-400 italic">
                                Authentication step completed
                              </div>
                            {:else}
                              <!-- Fallback to JSON for other steps if no payload.text found -->
                              <div class="mt-3 text-xs text-gray-600 dark:text-gray-400">
                                No output content available for this step type
                              </div>
                            {/if}
                          </div>
                        {/each}
                      </div>
                    {/if}
                  </div>
                {/if}
              </div>
            {/each}
          </div>
        
        <!-- Raw Steps Tab (All steps without visibility filtering) -->
        {:else if activeOutputTab === 'raw'}
          <!-- Dirspace-organized outputs (unfiltered) -->
          <div class="space-y-4">
            {#each run.dirspaces as dirspace}
              {@const dirspaceKey = getDirspaceKey(dirspace.dir, dirspace.workspace)}
              {@const isExpanded = expandedDirspaces.has(dirspaceKey)}
              {@const dirspaceOutputs = allOutputs.filter((output) => {
                const matchesDirspace = output?.scope?.dir === dirspace.dir && output?.scope?.workspace === dirspace.workspace;
                return matchesDirspace; // No visibility filtering for raw steps
              })}
              
              <div class="border border-gray-200 rounded-lg">
                <button 
                  on:click={() => toggleDirspaceExpansion(dirspaceKey)}
                  class="w-full flex items-center justify-between p-4 text-left hover:bg-gray-50 dark:hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-inset"
                >
                  <div class="flex items-center space-x-3 flex-1 min-w-0">
                    <div class="flex-shrink-0">
                      {#if dirspace.success === true}
                        <div class="w-3 h-3 rounded-full bg-green-500"></div>
                      {:else if dirspace.success === false}
                        <div class="w-3 h-3 rounded-full bg-red-500"></div>
                      {:else}
                        <div class="w-3 h-3 rounded-full bg-gray-400"></div>
                      {/if}
                    </div>
                    <div class="flex-1 min-w-0">
                      <div class="font-medium text-gray-900 dark:text-gray-100 truncate">{dirspace.dir}</div>
                      <div class="text-sm text-gray-600 dark:text-gray-400 truncate">Workspace: {dirspace.workspace}</div>
                      
                      <!-- Terraform summaries removed for memory safety -->
                    </div>
                  </div>
                  <div class="flex items-center space-x-2 flex-shrink-0">
                    <span class="text-xs sm:text-sm text-gray-500 dark:text-gray-400">
                      <span class="hidden sm:inline">{dirspaceOutputs.length} step{dirspaceOutputs.length !== 1 ? 's' : ''} (unfiltered)</span>
                      <span class="sm:hidden">{dirspaceOutputs.length} {dirspaceOutputs.length === 1 ? 'step' : 'steps'}</span>
                    </span>
                    <svg class="w-5 h-5 text-gray-400 dark:text-gray-500 transform transition-transform {isExpanded ? 'rotate-180' : ''}" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                    </svg>
                  </div>
                </button>
                
                {#if isExpanded}
                  <div class="border-t border-gray-200 dark:border-gray-600 bg-gray-50 dark:bg-gray-700">
                    {#if dirspaceOutputs.length === 0}
                      <div class="p-4 text-center text-gray-500 dark:text-gray-400">
                        No step outputs available for this dirspace
                      </div>
                    {:else}
                      <div class="p-4 space-y-3">
                        {#each dirspaceOutputs as output ((output.step || 'unknown') + (output.payload?._loadTimestamp || ''))}
                          {@const typedOutput = output}
                          {@const displayState = getDisplayState(typedOutput)}
                          <div class="bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-600 rounded p-3">
                            <div class="flex flex-wrap items-center gap-x-2 gap-y-1 mb-2">
                              <span class="flex-shrink-0">{getStepIcon(typedOutput?.step || 'unknown')}</span>
                              <span class="font-medium text-gray-900 dark:text-gray-100">{getStepLabel(typedOutput?.step || 'Unknown Step')}</span>
                              {#if typedOutput?.state}
                                <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium {displayState.color}">
                                  {displayState.state}
                                </span>
                              {/if}
                              <span class="text-xs text-gray-500">idx: {typedOutput?.idx}</span>
                              {#if typedOutput?.payload?.visible_on}
                                <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300">
                                  visible_on: {typedOutput.payload.visible_on}
                                </span>
                              {/if}
                            </div>
                            
                            {#if typedOutput?.payload?.text}
                              <!-- Output not loaded - click to view -->
                              {#if typedOutput.payload._isLiteMode}
                                <div class="mt-3">
                                  <div class="text-xs text-gray-600 dark:text-gray-400 mb-2">Output:</div>
                                  <div class="bg-gray-50 dark:bg-gray-700 border border-gray-200 dark:border-gray-600 rounded-lg p-4">
                                    <div class="flex flex-col gap-3">
                                      <div class="flex items-center text-sm text-gray-600 dark:text-gray-400">
                                        <svg class="w-5 h-5 text-gray-500 dark:text-gray-400 mr-2 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                                        </svg>
                                        <span>Output content not loaded</span>
                                      </div>
                                      <button
                                        type="button"
                                        on:click={() => loadFullOutput(typedOutput)}
                                        class="inline-flex items-center justify-center px-4 py-2 border border-blue-300 dark:border-blue-600 text-sm font-medium rounded-md text-blue-700 dark:text-blue-400 bg-blue-50 dark:bg-blue-900/30 hover:bg-blue-100 dark:hover:bg-blue-900/50 transition-colors"
                                      >
                                        <svg class="w-4 h-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                                        </svg>
                                        View Output
                                      </button>
                                    </div>
                                  </div>
                                </div>
                              {:else}
                                <!-- Display actual step output content with safe loading -->
                                <div class="mt-3">
                                  <div class="text-xs text-gray-600 dark:text-gray-400 mb-2">
                                    Output: {#if typedOutput.payload._wasLoadedOnDemand}
                                      <span class="text-green-600 dark:text-green-400 font-medium">(loaded on demand)</span>
                                    {/if}
                                  </div>
                                  <SafeOutput 
                                    content={typedOutput.payload.text}
                                    title={`${getStepLabel(typedOutput?.step || 'Unknown Step')} - ${typedOutput?.scope?.dir || 'unknown'}:${typedOutput?.scope?.workspace || 'unknown'}`}
                                    githubUrl={run?.owner && run?.repo && run?.run_id ? getGitHubActionsUrl(run.owner, run.repo, run.run_id) : ''}
                                    orgName={run?.owner || ''}
                                    repoName={run?.repo || ''}
                                    prNumber={typeof run?.kind === 'object' && run.kind?.pull_number ? run.kind.pull_number : ''}
                                    runType={run?.run_type || ''}
                                    stepName={typedOutput?.step || ''}
                                    on:expand={(e) => openOutputModal(e.detail.content, e.detail.title)}
                                  />
                                </div>
                              {/if}
                            {:else if typedOutput?.step === 'auth/update-terrateam-github-token' || typedOutput?.step === 'auth/oidc'}
                              <!-- Hide debug for auth steps - no meaningful output to show -->
                              <div class="mt-3 text-xs text-gray-500 dark:text-gray-400 italic">
                                Authentication step completed - {typedOutput?.payload?.visible_on ? `visible_on: ${typedOutput.payload.visible_on}` : 'no visibility setting'}
                              </div>
                            {:else}
                              <!-- Fallback to JSON for other steps if no payload.text found -->
                              <div class="mt-3 text-xs text-gray-600 dark:text-gray-400">
                                No output content available for this step type
                              </div>
                            {/if}
                          </div>
                        {/each}
                      </div>
                    {/if}
                  </div>
                {/if}
              </div>
            {/each}
          </div>
        
        <!-- Failed Steps Tab -->
        {:else if activeOutputTab === 'failed'}
          {#if failedOutputs.length === 0}
            <div class="text-center py-8 text-gray-500">
              <div class="text-4xl mb-2">✅</div>
              <p>No failed steps found</p>
            </div>
          {:else}
            <div class="space-y-4">
              {#each Object.entries(failedByDirspace) as [dirspaceKey, dirspaceData]}
                {@const isExpanded = expandedDirspaces.has(dirspaceKey)}
                
                <div class="border border-red-200 dark:border-red-800 rounded-lg bg-red-50/50 dark:bg-red-900/10">
                  <button 
                    on:click={() => toggleDirspaceExpansion(dirspaceKey)}
                    class="w-full flex items-center justify-between p-4 text-left hover:bg-red-50 dark:hover:bg-red-900/20 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-inset"
                  >
                    <div class="flex items-center space-x-3 flex-1 min-w-0">
                      <div class="flex-shrink-0">
                        <div class="w-3 h-3 rounded-full bg-red-500"></div>
                      </div>
                      <div class="flex-1 min-w-0">
                        <div class="font-medium text-red-900 dark:text-red-100">{dirspaceData.dir}</div>
                        <div class="text-sm text-red-700 dark:text-red-300">Workspace: {dirspaceData.workspace}</div>
                      </div>
                    </div>
                    <div class="flex items-center space-x-2 flex-shrink-0">
                      <span class="text-sm text-red-600 dark:text-red-400">{dirspaceData.outputs.length} failed step{dirspaceData.outputs.length !== 1 ? 's' : ''}</span>
                      <svg class="w-5 h-5 text-red-400 dark:text-red-500 transform transition-transform {isExpanded ? 'rotate-180' : ''}" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                      </svg>
                    </div>
                  </button>
                  
                  {#if isExpanded}
                    <div class="border-t border-red-200 dark:border-red-700 bg-red-50 dark:bg-red-900/20">
                      <div class="p-4 space-y-3">
                        {#each dirspaceData.outputs as output ((output.step || 'unknown') + (output.payload?._loadTimestamp || ''))}
                          {@const typedOutput = output}
                          {@const displayState = getDisplayState(typedOutput)}
                          <div class="bg-white dark:bg-gray-800 border border-red-200 dark:border-red-600 rounded p-3">
                            <div class="flex flex-wrap items-center gap-x-2 gap-y-1 mb-2">
                              <span class="flex-shrink-0">❌</span>
                              <span class="font-medium text-red-900 dark:text-red-100">{getStepLabel(typedOutput?.step || 'Unknown Step')}</span>
                              {#if typedOutput?.state}
                                <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium {displayState.color}">
                                  {displayState.state}
                                </span>
                              {/if}
                              <span class="text-xs text-gray-500">idx: {typedOutput?.idx}</span>
                            </div>
                            {#if typedOutput?.payload?.text}
                              <!-- Output not loaded - click to view -->
                              {#if typedOutput.payload._isLiteMode}
                                <div class="mt-3">
                                  <div class="text-xs text-red-700 dark:text-red-400 mb-2">Error Output:</div>
                                  <div class="bg-red-50 dark:bg-red-900/30 border border-red-200 dark:border-red-600 rounded-lg p-4">
                                    <div class="flex flex-col gap-3">
                                      <div class="flex items-center text-sm text-red-600 dark:text-red-400">
                                        <svg class="w-5 h-5 text-red-500 dark:text-red-400 mr-2 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                                        </svg>
                                        <span>Error output not loaded</span>
                                      </div>
                                      <button
                                        type="button"
                                        on:click={() => loadFullOutput(typedOutput)}
                                        class="inline-flex items-center justify-center px-4 py-2 border border-red-300 dark:border-red-600 text-sm font-medium rounded-md text-red-700 dark:text-red-400 bg-red-50 dark:bg-red-900/30 hover:bg-red-100 dark:hover:bg-red-900/50 transition-colors"
                                      >
                                        <svg class="w-4 h-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                                        </svg>
                                        View Error Output
                                      </button>
                                    </div>
                                  </div>
                                </div>
                              {:else}
                                <!-- Display actual step output content with safe loading -->
                                <div class="mt-3">
                                  <div class="text-xs text-red-700 dark:text-red-400 mb-2">Error Output:
                                    {#if typedOutput.payload._wasLoadedOnDemand}
                                      <span class="ml-2 text-green-600 font-medium">(loaded on demand)</span>
                                    {/if}
                                  </div>
                                  <SafeOutput 
                                    content={typedOutput.payload.text}
                                    title={`Failed: ${getStepLabel(typedOutput?.step || 'Unknown Step')} - ${typedOutput?.scope?.dir || 'unknown'}:${typedOutput?.scope?.workspace || 'unknown'}`}
                                    githubUrl={run?.owner && run?.repo && run?.run_id ? getGitHubActionsUrl(run.owner, run.repo, run.run_id) : ''}
                                    orgName={run?.owner || ''}
                                    repoName={run?.repo || ''}
                                    prNumber={typeof run?.kind === 'object' && run.kind?.pull_number ? run.kind.pull_number : ''}
                                    runType={run?.run_type || ''}
                                    stepName={typedOutput?.step || ''}
                                    on:expand={(e) => openOutputModal(e.detail.content, e.detail.title)}
                                  />
                                </div>
                              {/if}
                            {:else if typedOutput?.step === 'auth/update-terrateam-github-token' || typedOutput?.step === 'auth/oidc'}
                              <!-- Hide debug for auth steps - no meaningful output to show -->
                              <div class="mt-3 text-xs text-gray-500 dark:text-gray-400 italic">
                                Authentication step failed
                              </div>
                            {:else}
                              <!-- Fallback to JSON for other steps if no payload.text found -->
                              <div class="mt-3 text-xs text-gray-600 dark:text-gray-400">
                                No output content available for this step type
                              </div>
                            {/if}
                          </div>
                        {/each}
                      </div>
                    </div>
                  {/if}
                </div>
              {/each}
            </div>
          {/if}
        
        <!-- Changes Tab -->
        {:else if activeOutputTab === 'changes'}
          {#if isFetchingVisualizationData}
            <!-- Loading state while fetching full output -->
            <div class="flex flex-col items-center justify-center py-12">
              <LoadingSpinner size="lg" />
              <p class="mt-4 text-gray-600 dark:text-gray-400">
                Loading {run?.run_type === 'apply' ? 'apply' : 'plan'} changes...
              </p>
            </div>
          {:else if !visualizationPlanOutput}
            <!-- First, show list of plans or applies that can view changes -->
            <div class="space-y-4">
              {#if run?.run_type === 'plan'}
                <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">
                  Select a Terraform plan output to view changes:
                </p>
                {#each outputs.filter(o => isPlanOutput(o)) as planOutput}
                  <Card 
                    padding="md" 
                    hover={true}
                    class="cursor-pointer"
                  >
                    <button
                      class="w-full text-left"
                      on:click={() => openPlanChanges(planOutput)}
                    >
                      <div class="flex items-center justify-between">
                        <div>
                          <h4 class="font-medium text-gray-900 dark:text-white">
                            {planOutput.scope?.dir || 'unknown'} / {planOutput.scope?.workspace || 'default'}
                          </h4>
                          <p class="text-sm text-gray-600 dark:text-gray-400">
                            {getStepLabel(planOutput.step || 'tf/plan')}
                          </p>
                        </div>
                        <svg class="w-5 h-5 text-brand-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
                                d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                        </svg>
                      </div>
                    </button>
                  </Card>
                {:else}
                  <div class="text-center py-8 text-gray-500 dark:text-gray-400">
                    <div class="text-4xl mb-2">📊</div>
                    <p>No Terraform plan outputs found</p>
                    <p class="text-sm mt-2">Run a plan first to see changes</p>
                  </div>
                {/each}
              {:else if run?.run_type === 'apply'}
                <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">
                  Select a Terraform apply output to view changes:
                </p>
                {#each outputs.filter(o => isApplyOutput(o)) as applyOutput}
                  <Card 
                    padding="md" 
                    hover={true}
                    class="cursor-pointer"
                  >
                    <button
                      class="w-full text-left"
                      on:click={() => openApplyChanges(applyOutput)}
                    >
                      <div class="flex items-center justify-between">
                        <div>
                          <h4 class="font-medium text-gray-900 dark:text-white">
                            {applyOutput.scope?.dir || 'unknown'} / {applyOutput.scope?.workspace || 'default'}
                          </h4>
                          <p class="text-sm text-gray-600 dark:text-gray-400">
                            {getStepLabel(applyOutput.step || 'tf/apply')}
                          </p>
                        </div>
                        <svg class="w-5 h-5 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
                                d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                        </svg>
                      </div>
                    </button>
                  </Card>
                {:else}
                  <div class="text-center py-8 text-gray-500 dark:text-gray-400">
                    <div class="text-4xl mb-2">🚀</div>
                    <p>No Terraform apply outputs found</p>
                    <p class="text-sm mt-2">Run an apply to see changes</p>
                  </div>
                {/each}
              {/if}
            </div>
          {:else}
            <!-- Show the visualization -->
            <div class="mb-4">
              <button
                class="text-sm text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300"
                on:click={() => {
                  visualizationPlanOutput = '';
                  activeOutputTab = 'all';
                }}
              >
                ← Back to {run?.run_type === 'apply' ? 'apply' : 'plan'} selection
              </button>
            </div>
            {#if run?.run_type === 'apply'}
              <ApplyChanges 
                applyOutput={visualizationPlanOutput}
                workManifestId={visualizationWorkManifestId}
                showHeader={false}
              />
            {:else}
              <PlanChanges 
                planOutput={visualizationPlanOutput}
                workManifestId={visualizationWorkManifestId}
                showHeader={false}
              />
            {/if}
          {/if}
        {/if}
        
      {/if}
    </Card>
    {/if}

    <!-- Technical Details -->
    <Card padding="lg">
      <h3 class="text-lg font-semibold text-blue-600 dark:text-blue-400 mb-4">Run Metadata</h3>
      <div class="grid md:grid-cols-2 gap-6">
        <div>
          <h4 class="font-medium text-gray-900 dark:text-gray-100 mb-3">Identifiers</h4>
          <div class="space-y-2 text-sm">
            <div class="flex flex-col sm:flex-row sm:justify-between gap-1">
              <span class="text-gray-600 dark:text-gray-400 whitespace-nowrap">Work Manifest ID:</span>
              <span class="font-mono text-[10px] sm:text-xs bg-gray-100 dark:bg-gray-700 text-gray-900 dark:text-gray-100 px-2 py-1 rounded break-all">{run.id}</span>
            </div>
            {#if run.run_id}
              <div class="flex flex-col sm:flex-row sm:justify-between gap-1">
                <span class="text-gray-600 dark:text-gray-400 whitespace-nowrap">GitHub Actions ID:</span>
                <span class="font-mono text-[10px] sm:text-xs bg-gray-100 dark:bg-gray-700 text-gray-900 dark:text-gray-100 px-2 py-1 rounded break-all">{run.run_id}</span>
              </div>
            {/if}
          </div>
        </div>
        <div class="mt-4 md:mt-0">
          <h4 class="font-medium text-gray-900 dark:text-gray-100 mb-3">Git References</h4>
          <div class="space-y-2 text-sm">
            <div class="flex flex-col sm:flex-row sm:justify-between gap-1">
              <span class="text-gray-600 dark:text-gray-400 whitespace-nowrap">Branch Ref:</span>
              <span class="font-mono text-[10px] sm:text-xs bg-gray-100 dark:bg-gray-700 text-gray-900 dark:text-gray-100 px-2 py-1 rounded">{run.branch_ref.substring(0, 8)}</span>
            </div>
            <div class="flex flex-col sm:flex-row sm:justify-between gap-1">
              <span class="text-gray-600 dark:text-gray-400 whitespace-nowrap">Base Ref:</span>
              <span class="font-mono text-[10px] sm:text-xs bg-gray-100 dark:bg-gray-700 text-gray-900 dark:text-gray-100 px-2 py-1 rounded">{run.base_ref.substring(0, 8)}</span>
            </div>
          </div>
        </div>
      </div>
    </Card>
  {:else if !isLoading && !run}
    <div class="text-center py-12">
      <p class="text-gray-600 dark:text-gray-400">Run not found.</p>
      <div class="mt-4">
        <a 
          href={getBackUrl()} 
          class="text-blue-600 hover:text-blue-800 font-medium"
        >
          ← Back to Runs
        </a>
      </div>
    </div>
  {/if}

  <!-- Full-Screen Output Modal -->
  {#if showOutputModal}
    <div class="fixed inset-0 z-50 overflow-y-auto bg-black bg-opacity-75 flex items-center justify-center p-2 sm:p-4">
      <div class="bg-white dark:bg-gray-800 rounded-lg shadow-xl w-full h-full max-w-7xl max-h-full flex flex-col">
        <!-- Modal Header -->
        <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between p-3 sm:p-4 border-b border-gray-200 dark:border-gray-700 gap-2">
          <div class="flex flex-col sm:flex-row sm:items-center gap-1 sm:gap-3">
            <h3 class="text-base sm:text-lg font-semibold text-gray-900 dark:text-gray-100">Output View</h3>
            <span class="text-xs sm:text-sm text-gray-600 dark:text-gray-400 break-all">{modalOutputTitle}</span>
          </div>
          <div class="flex items-center gap-2">
            <button
              class="px-2 sm:px-3 py-1 text-xs sm:text-sm text-gray-600 dark:text-gray-400 hover:text-gray-800 dark:hover:text-gray-200 border border-gray-300 dark:border-gray-600 rounded hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
              on:click={() => navigator.clipboard.writeText(modalOutputContent)}
              title="Copy to clipboard"
            >
              📋 Copy
            </button>
            <button
              class="p-1.5 sm:p-2 text-gray-400 hover:text-gray-600 dark:text-gray-400 dark:hover:text-gray-200 rounded-full hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
              on:click={closeOutputModal}
              title="Close (Esc)"
            >
              <svg class="w-5 h-5 sm:w-6 sm:h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>
        </div>

        <!-- Modal Content -->
        <div class="flex-1 overflow-hidden">
          <pre class="h-full w-full bg-gray-900 dark:bg-gray-950 text-gray-100 p-3 sm:p-4 overflow-auto text-xs sm:text-sm font-mono whitespace-pre-wrap break-words">{modalOutputContent}</pre>
        </div>

        <!-- Modal Footer -->
        <div class="p-3 sm:p-4 border-t border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800">
          <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-1 text-xs sm:text-sm text-gray-600 dark:text-gray-400">
            <div>
              {modalOutputContent.split('\n').length} lines • {modalOutputContent.length} characters
            </div>
            <div class="hidden sm:block">
              Press <kbd class="px-2 py-1 bg-gray-200 dark:bg-gray-700 rounded text-xs">Esc</kbd> to close
            </div>
          </div>
        </div>
      </div>
    </div>
  {/if}
</PageLayout>
