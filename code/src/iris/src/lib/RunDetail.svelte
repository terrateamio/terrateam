<script lang="ts">
  import { onMount, tick } from 'svelte';
  import type { WorkManifest } from './types';
  import type { OutputItem, ResourceSummary } from './types/stepOutput';
  // Auth handled by PageLayout
  import { api } from './api';
  import { selectedInstallation, installations, currentVCSProvider, serverConfig } from './stores';
  import { analytics } from './analytics';
  import PageLayout from './components/layout/PageLayout.svelte';
  import LoadingSpinner from './components/ui/LoadingSpinner.svelte';
  import ErrorMessage from './components/ui/ErrorMessage.svelte';
  import Card from './components/ui/Card.svelte';
  import StepOutput from './components/ui/StepOutput.svelte';
  import DirspaceHeader from './components/ui/DirspaceHeader.svelte';
  import RunSummaryTable from './components/ui/RunSummaryTable.svelte';
  import { dirspaceAnchor, runSummary } from './utils/runSummary';
  import { getWebBaseUrl } from './server-config';

  export let params: { id: string; installationId?: string } = { id: '' };

  let run: WorkManifest | null = null;
  let isLoading: boolean = false;
  let error: string | null = null;

  // Plan highlighting preference
  let enablePlanHighlighting = false;

  // Load preference from localStorage on mount
  onMount(() => {
    const saved = localStorage.getItem('enablePlanHighlighting');
    enablePlanHighlighting = saved === 'true';
  });

  // Save preference when toggled
  function toggleHighlighting() {
    localStorage.setItem('enablePlanHighlighting', String(enablePlanHighlighting));
  }

  // Force re-render of outputs when preference changes
  $: if (enablePlanHighlighting !== undefined) {
    // Force Svelte to re-evaluate by reassigning the arrays
    outputs = [...outputs];
    allOutputs = [...allOutputs];
  }

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
  type OutputTab = 'summary' | 'all' | 'raw' | 'cost' | 'failed';
  let activeOutputTab: OutputTab | null = null;
  // Until a tab is picked, a run of several dirspaces opens on Summary and a
  // run of one on All Steps.
  $: shownTab = activeOutputTab ?? ((run?.dirspaces?.length ?? 0) > 1 ? 'summary' : 'all');
  const web_base_url = getWebBaseUrl($currentVCSProvider, $serverConfig);

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

      // Fetch all pages of step metadata (with full payload) to check visible_on for filtering
      let allStepOutputs: unknown[] = [];

      // First page via normal API method
      const firstResponse = await api.getWorkManifestOutputs(
        $selectedInstallation.id,
        runId,
        { q: 'not step:tf/cost-estimation', limit: 100, lite: false }
      );
      allStepOutputs = firstResponse.outputs || [];

      // Follow pagination for remaining pages using full Link header URLs
      let linkHeaders = api.getLastLinkHeaders();
      while (linkHeaders?.next) {
        const nextUrl = linkHeaders.next.replace('//api/', '/api/');
        const pageResponse = await api.getFromUrl<{ steps: unknown[] }>(nextUrl);
        allStepOutputs = allStepOutputs.concat(pageResponse.steps || []);
        linkHeaders = api.getLastLinkHeaders();
      }

      const allStepsResponse = { outputs: allStepOutputs };

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
          const out = output as OutputItem;
          return {
            ...out,
            payload: {
              text: 'Click to view output content',
              _isLiteMode: true,
              _originalStep: out.step,
              // Keep essential payload properties for filtering
              visible_on: out.payload?.visible_on,
              ignore_errors: out.payload?.ignore_errors,
              // A single boolean per plan step: it is what tells a no-op run
              // from an applying one in the header status without loading any
              // output content.
              has_changes: out.payload?.has_changes,
              // The plan step's resource counts, kept for the collapsed
              // dirspace header line.
              resource_summary: out.payload?.resource_summary,
              // Small enough to keep: it is what tells two `run` steps apart in
              // the header, and dropping it would hide the command until the
              // output is loaded on demand.
              cmd: out.payload?.cmd
            }
          };
        })
      };

      // Store ALL outputs (including hidden ones) for Raw Steps tab
      const allLiteOutputsResponse = {
        outputs: (allStepsResponse.outputs || []).map((output: unknown) => {
          const out = output as OutputItem;
          return {
            ...out,
            payload: {
              text: 'Click to view output content',
              _isLiteMode: true,
              _originalStep: out.step,
              // Keep essential payload properties for filtering
              visible_on: out.payload?.visible_on,
              ignore_errors: out.payload?.ignore_errors,
              has_changes: out.payload?.has_changes,
              resource_summary: out.payload?.resource_summary,
              // Small enough to keep: it is what tells two `run` steps apart in
              // the header, and dropping it would hide the command until the
              // output is loaded on demand.
              cmd: out.payload?.cmd
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
      // Fetch all pages for this step name to find the exact output by idx
      let allFullOutputs: unknown[] = [];
      const firstFullResponse = await api.getWorkManifestOutputs(
        $selectedInstallation.id,
        run.id,
        { q: `step:${output.payload._originalStep}`, limit: 100, lite: false }
      );
      allFullOutputs = firstFullResponse.outputs || [];

      // Follow pagination
      let fullLinkHeaders = api.getLastLinkHeaders();
      while (fullLinkHeaders?.next) {
        const nextUrl = fullLinkHeaders.next.replace('//api/', '/api/');
        const pageResponse = await api.getFromUrl<{ steps: unknown[] }>(nextUrl);
        allFullOutputs = allFullOutputs.concat(pageResponse.steps || []);
        fullLinkHeaders = api.getLastLinkHeaders();
      }

      if (allFullOutputs.length > 0) {
        // Find the specific output that matches the one we clicked on
        interface OutputMatch {
          idx?: number;
          step?: string;
          scope?: {
            dir?: string;
            workspace?: string;
          };
        }

        const matchingOutput = allFullOutputs.find((o: unknown) => {
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
        
        // If there's no content at all, show a message. A plan step may carry
        // only the diff, which is still worth rendering.
        if (!updatedPayload.text && !updatedPayload.plan) {
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
        return 'text-[var(--sg-success)] bg-[var(--sg-success-bg)]';
      case 'completed':
        return 'text-[var(--sg-accent)] bg-[var(--sg-accent-bg)]'; // Neutral blue for completed (could have failures)
      case 'running':
      case 'queued':
        return 'text-[var(--sg-accent)] bg-[var(--sg-accent-bg)]';
      case 'failure':
      case 'aborted':
        return 'text-[var(--sg-error)] bg-[var(--sg-error-bg)]';
      default:
        return 'text-[var(--sg-text-dim)] bg-[var(--sg-bg-2)]';
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
        color: 'text-[var(--sg-warning)] bg-[var(--sg-warning-bg)]'
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

  // A completed run whose plan steps all reported no changes applied nothing: the status says
  // that instead of "Completed".  Runs without plan outputs (applies, older runs) keep the
  // generic label.  Only a plan step's `has_changes` counts, thus an apply step that carries the
  // field cannot make an applied run read "No Changes".
  function runHadNoChanges(items: OutputItem[]): boolean {
    let sawPlanOutput = false;
    for (const item of items) {
      if (!(item?.step?.endsWith('/plan') ?? false)) continue;
      const hasChanges = item?.payload?.has_changes;
      if (typeof hasChanges !== 'boolean') continue;
      sawPlanOutput = true;
      if (hasChanges) return false;
    }
    return sawPlanOutput;
  }

  $: noChanges = run !== null && run.state === 'completed' && runHadNoChanges(allOutputs);

  // Smarter status display that considers dirspace failures
  function getSmartStatusDisplay(run: WorkManifest, noChanges: boolean): { icon: string, color: string, label: string } {
    const state = run.state;
    
    // For completed runs, check if any dirspaces failed
    if (state === 'completed') {
      const hasFailures = run.dirspaces?.some(ds => ds.success === false);
      
      if (hasFailures) {
        return {
          icon: '⚠️',
          color: 'text-[var(--sg-warning)] bg-[var(--sg-warning-bg)]',
          label: 'Completed with Failures'
        };
      } else if (noChanges) {
        return {
          icon: '✅',
          color: 'text-[var(--sg-accent)] bg-[var(--sg-accent-bg)]',
          label: 'No Changes'
        };
      } else {
        return {
          icon: '🏁',
          color: 'text-[var(--sg-accent)] bg-[var(--sg-accent-bg)]',
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

  $: summary = run ? runSummary(run.dirspaces ?? [], allOutputs) : null;

  $: live = run !== null && (run.state === 'queued' || run.state === 'running');

  async function openDirspaceSteps(row: { dir: string; workspace: string }): Promise<void> {
    expandedDirspaces = new Set(expandedDirspaces).add(getDirspaceKey(row.dir, row.workspace));
    activeOutputTab = 'all';
    await tick();
    document.getElementById(dirspaceAnchor(row.dir, row.workspace))?.scrollIntoView({ block: 'start' });
  }

  // Collapsed-header resource counts, read from the dirspace's plan step in
  // the unfiltered `allOutputs` list (the same source `runHadNoChanges`
  // reads): `shouldShowStep` filters a successful plan step out of `outputs`.
  // The counts come from the payload field, never from parsing plan text.
  function resourceSummaryForDirspace(dirspace: { dir: string; workspace: string }): ResourceSummary | null {
    const plan = allOutputs.find(
      (output) =>
        output?.scope?.dir === dirspace.dir &&
        output?.scope?.workspace === dirspace.workspace &&
        (output.step?.endsWith('/plan') ?? false)
    );
    return plan?.payload?.resource_summary ?? null;
  }

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
        // Non-Terraform engines use the same suffixes: custom/plan, pulumi/apply, ...
        if (step.endsWith('/init')) return '🔧';
        if (step.endsWith('/plan')) return '📋';
        if (step.endsWith('/apply')) return '🚀';
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
      default: {
        // Non-Terraform engines use the same suffixes: custom/plan -> "Custom Plan"
        const [engine, operation] = step.split('/');
        if (operation && ['init', 'plan', 'apply', 'unsafe-apply'].includes(operation)) {
          return `${capitalize(engine)} ${capitalize(operation)}`;
        }
        return step.replace(/\//g, ' / ');
      }
    }
  }

  function capitalize(s: string): string {
    return s.charAt(0).toUpperCase() + s.slice(1);
  }

  // The runner reports every run step as step "run", so several in one workflow
  // are indistinguishable by label alone. The command is what tells them apart,
  // and the pull request comment already shows it.
  function getStepCmd(output: OutputItem): string {
    const cmd = output?.payload?.cmd;
    return Array.isArray(cmd) ? cmd.join(' ') : '';
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
        class="text-[var(--sg-accent)] hover:text-[var(--sg-accent-hover)] font-medium"
      >
        ← Back to Runs
      </a>
    </div>
  {:else if run}
    <!-- Back Navigation -->
    <div class="mb-6">
      <a 
        href={getBackUrl()} 
        class="inline-flex items-center text-[var(--sg-accent)] hover:text-[var(--sg-accent-hover)] font-medium"
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
          <h2 class="text-xl sm:text-2xl font-bold text-[var(--sg-accent)] mb-2 break-words">
            {run.repo}
          </h2>
          <div class="flex flex-col sm:flex-row sm:items-center sm:space-x-4 space-y-1 sm:space-y-0 text-sm text-[var(--sg-text-dim)]">
            <span>Dirspaces: <span class="font-medium">{run.dirspaces.length}</span></span>
            {#if run.environment}
              <span>{$currentVCSProvider === 'gitlab' ? 'GitLab' : 'GitHub'} Environment: <span class="font-medium">{run.environment}</span></span>
            {/if}
          </div>
        </div>
        <div class="flex flex-col items-start lg:items-end space-y-2">
          {#if run}
            {@const smartStatus = getSmartStatusDisplay(run, noChanges)}
            <div class="flex flex-wrap items-center gap-2">
              <span class="text-sm font-medium whitespace-nowrap">Status:</span>
              <span class={`px-3 py-1 text-xs sm:text-sm font-medium rounded-full whitespace-nowrap ${smartStatus.color}`}>
                {smartStatus.icon} {smartStatus.label}
              </span>
            </div>
          {/if}
          <div class="text-sm text-[var(--sg-text-dim)]">
            {getRunTypeLabel(run.run_type)}
          </div>
          {#if run.run_id}
            <a 
              href={getGitHubActionsUrl(run.owner, run.repo, run.run_id)}
              target="_blank"
              rel="noopener noreferrer"
              class="inline-flex items-center text-sm text-[var(--sg-accent)] hover:text-[var(--sg-accent-hover)] hover:underline whitespace-nowrap"
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
        <div class="border-t border-[var(--sg-border)] pt-6 mb-6">
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-lg font-semibold text-[var(--sg-accent)]">Pull Request Details</h3>
            <button
              on:click={() => {
                // Store the current run ID so PR detail page can navigate back
                if (typeof window !== 'undefined' && params.id) {
                  sessionStorage.setItem('lastRunId', params.id);
                }
                const prUrl = $selectedInstallation
                  ? `#/i/${$selectedInstallation.id}/runs/pr/${prInfo.pullNumber}`
                  : `#/runs/pr/${prInfo.pullNumber}`;
                window.location.hash = prUrl;
              }}
              class="inline-flex items-center px-3 py-1.5 text-sm font-medium text-[var(--sg-accent)] bg-[var(--sg-accent-bg)] border border-[var(--sg-accent)] rounded-md hover:bg-[var(--sg-accent-bg)] transition-colors"
            >
              <svg class="w-4 h-4 mr-1.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 17V7m0 10a2 2 0 01-2 2H5a2 2 0 01-2-2V7a2 2 0 012-2h2a2 2 0 012 2m0 10a2 2 0 002 2h2a2 2 0 002-2M9 7a2 2 0 012-2h2a2 2 0 012 2m0 10V7m0 10a2 2 0 002 2h2a2 2 0 002-2V7a2 2 0 00-2-2h-2a2 2 0 00-2 2" />
              </svg>
              View Stacks & All Runs
            </button>
          </div>
          <div class="flex flex-col md:grid md:grid-cols-2 gap-4 md:gap-6">
            <div>
              <div class="flex items-center space-x-2 mb-3">
                <svg class="w-5 h-5 text-[var(--sg-success)] flex-shrink-0" fill="currentColor" viewBox="0 0 16 16">
                  <path d="M8 0a8 8 0 1 1 0 16A8 8 0 0 1 8 0zM4.5 7.5a.5.5 0 0 0 0 1h5.793l-2.147 2.146a.5.5 0 0 0 .708.708l3-3a.5.5 0 0 0 0-.708l-3-3a.5.5 0 1 0-.708.708L10.293 7.5H4.5z"/>
                </svg>
                <a
                  href={getPullRequestUrl(run.owner, run.repo, prInfo.pullNumber || 0)}
                  target="_blank"
                  rel="noopener noreferrer"
                  class="font-medium text-[var(--sg-accent)] hover:text-[var(--sg-accent-hover)] hover:underline flex items-center space-x-1"
                >
                  <span>PR #{prInfo.pullNumber}</span>
                  <svg class="w-3 h-3 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
                  </svg>
                </a>
              </div>
              {#if prInfo.pullTitle}
                <p class="text-[var(--sg-text-muted)] text-sm break-words">
                  {prInfo.pullTitle}
                </p>
              {/if}
            </div>
            <div class="mt-2 md:mt-0">
              <div class="space-y-2 text-sm">
                <div class="flex flex-col sm:flex-row sm:justify-between gap-1">
                  <span class="text-[var(--sg-text-dim)]">Branch:</span>
                  <span class="font-medium font-mono text-xs sm:text-sm text-[var(--sg-accent)] break-all">{run.branch}</span>
                </div>
                <div class="flex flex-col sm:flex-row sm:justify-between gap-1">
                  <span class="text-[var(--sg-text-dim)]">Target:</span>
                  <span class="font-medium font-mono text-xs sm:text-sm text-[var(--sg-success)] break-all">{run.base_branch}</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      {:else}
        <!-- Non-PR Run (drift, index, etc.) -->
        <div class="border-t border-[var(--sg-border)] pt-6 mb-6">
          <h3 class="text-lg font-semibold text-[var(--sg-accent)] mb-4">Run Information</h3>
          <div class="grid md:grid-cols-2 gap-4 md:gap-6">
            <div>
              <div class="flex items-center space-x-2 mb-3">
                <svg class="w-5 h-5 text-[var(--sg-accent)]" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
                <span class="font-medium text-[var(--sg-text)]">
                  {typeof run.kind === 'string' ? run.kind.charAt(0).toUpperCase() + run.kind.slice(1) : 'Manual'} Run
                </span>
              </div>
            </div>
            <div>
              <div class="space-y-2 text-sm">
                <div class="flex justify-between">
                  <span class="text-[var(--sg-text-dim)]">Branch:</span>
                  <span class="font-medium font-mono text-[var(--sg-accent)]">{run.branch}</span>
                </div>
                <div class="flex justify-between">
                  <span class="text-[var(--sg-text-dim)]">Base:</span>
                  <span class="font-medium font-mono text-[var(--sg-success)]">{run.base_branch}</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      {/if}

      <!-- Timing Information -->
      <div class="border-t border-[var(--sg-border)] pt-6">
        <h3 class="text-lg font-semibold text-[var(--sg-accent)] mb-4">Execution Timeline</h3>
        <div class="grid md:grid-cols-3 gap-4 md:gap-6">
          <div>
            <div class="text-sm text-[var(--sg-text-dim)] mb-1">Started</div>
            <div class="font-medium text-[var(--sg-text)]">{formatDate(run.created_at)}</div>
          </div>
          {#if run.completed_at}
            <div>
              <div class="text-sm text-[var(--sg-text-dim)] mb-1">Completed</div>
              <div class="font-medium text-[var(--sg-text)]">{formatDate(run.completed_at)}</div>
            </div>
            <div>
              <div class="text-sm text-[var(--sg-text-dim)] mb-1">Duration</div>
              <div class="font-medium">
                {Math.round((new Date(run.completed_at).getTime() - new Date(run.created_at).getTime()) / 1000 / 60)} minutes
              </div>
            </div>
          {:else}
            <div>
              <div class="text-sm text-[var(--sg-text-dim)] mb-1">Status</div>
              <div class="font-medium text-[var(--sg-accent)]">In Progress</div>
            </div>
            <div>
              <div class="text-sm text-[var(--sg-text-dim)] mb-1">Running Time</div>
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
          <h3 class="text-lg font-semibold text-[var(--sg-accent)] mb-4">Triggered By</h3>
          <div class="flex items-center space-x-2">
            <div class="w-8 h-8 bg-[var(--sg-accent-button)] rounded-full flex items-center justify-center">
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
        <h3 class="text-lg font-semibold text-[var(--sg-accent)]">Execution Outputs</h3>

        <!-- Output Filter Tabs -->
        <div class="flex flex-wrap gap-1 bg-[var(--sg-bg-2)] rounded-lg p-1">
          <button
            on:click={() => activeOutputTab = 'summary'}
            class="px-2 sm:px-3 py-1 text-xs sm:text-sm font-medium rounded-md transition-colors whitespace-nowrap {shownTab === 'summary' ? 'bg-[var(--sg-bg-1)] text-[var(--sg-accent)] shadow-sm' : 'text-[var(--sg-text-dim)] hover:text-[var(--sg-text)]'}"
          >
            Summary
          </button>
          <button 
            on:click={() => activeOutputTab = 'all'}
            class="px-2 sm:px-3 py-1 text-xs sm:text-sm font-medium rounded-md transition-colors whitespace-nowrap {shownTab === 'all' ? 'bg-[var(--sg-bg-1)] text-[var(--sg-accent)] shadow-sm' : 'text-[var(--sg-text-dim)] hover:text-[var(--sg-text)]'}"
          >
            <span class="hidden sm:inline">All Steps</span>
            <span class="sm:hidden">All</span>
          </button>
          <button 
            on:click={() => activeOutputTab = 'raw'}
            class="px-2 sm:px-3 py-1 text-xs sm:text-sm font-medium rounded-md transition-colors whitespace-nowrap {shownTab === 'raw' ? 'bg-[var(--sg-bg-1)] text-[var(--sg-accent)] shadow-sm' : 'text-[var(--sg-text-dim)] hover:text-[var(--sg-text)]'}"
          >
            <span class="hidden sm:inline">🔧 Raw Steps</span>
            <span class="sm:hidden">🔧 Raw</span>
          </button>
          <button 
            on:click={() => activeOutputTab = 'cost'}
            class="px-2 sm:px-3 py-1 text-xs sm:text-sm font-medium rounded-md transition-colors whitespace-nowrap {shownTab === 'cost' ? 'bg-[var(--sg-bg-1)] text-[var(--sg-accent)] shadow-sm' : 'text-[var(--sg-text-dim)] hover:text-[var(--sg-text)]'}"
          >
            💰 Cost <span class="hidden sm:inline">({costEstimation.length})</span>
            <span class="sm:hidden text-[10px]">({costEstimation.length})</span>
          </button>
          <button
            on:click={() => activeOutputTab = 'failed'}
            class="px-2 sm:px-3 py-1 text-xs sm:text-sm font-medium rounded-md transition-colors whitespace-nowrap {shownTab === 'failed' ? 'bg-[var(--sg-bg-1)] text-[var(--sg-accent)] shadow-sm' : 'text-[var(--sg-text-dim)] hover:text-[var(--sg-text)]'}"
          >
            ❌ Failed
          </button>
        </div>
      </div>

      <!-- Plan Highlighting Toggle -->
      <div class="mb-4 items-center gap-2 text-sm {shownTab === 'summary' ? 'hidden' : 'flex'}">
        <input
          type="checkbox"
          id="enable-highlighting"
          bind:checked={enablePlanHighlighting}
          on:change={toggleHighlighting}
          class="h-4 w-4 text-[var(--sg-accent)] border-[var(--sg-border)] rounded focus:ring-[var(--sg-accent)] cursor-pointer"
        />
        <label for="enable-highlighting" class="cursor-pointer select-none text-[var(--sg-text-muted)]">
          Enable syntax highlighting
          <span class="text-xs text-[var(--sg-text-dim)] ml-1">(Beta)</span>
        </label>
      </div>

      {#if isLoadingOutputs}
        <div class="flex justify-center items-center py-8">
          <LoadingSpinner size="md" />
          <span class="ml-3 text-[var(--sg-text-dim)]">Loading outputs...</span>
        </div>
      {:else if outputsError}
        <ErrorMessage type="error" message={outputsError} />
      {:else}
        
        <!-- Summary Tab -->
        {#if shownTab === 'summary'}
          {#if summary}
            <RunSummaryTable
              {summary}
              isApply={run.run_type === 'apply'}
              {live}
              onOpen={openDirspaceSteps}
            />
          {/if}

        <!-- Cost Estimation Tab -->
        {:else if shownTab === 'cost'}
          {#if costEstimation.length === 0}
            <div class="text-center py-8 text-[var(--sg-text-dim)]">
              <div class="text-4xl mb-2">💰</div>
              <p class="text-[var(--sg-text-dim)]">No cost estimation data available</p>
            </div>
          {:else}
            <div class="space-y-6">
              {#each costEstimation as output}
                {@const typedOutput = output}
                {@const costData = typedOutput?.payload}

                {#if costData?.summary}
                  <!-- Cost Summary Card -->
                  <div class="bg-[var(--sg-success-bg)] border border-[var(--sg-success)] rounded-lg p-6">
                    <div class="mb-6">
                      <div class="flex items-center space-x-3">
                        <div class="w-10 h-10 bg-[var(--sg-success-bg)] rounded-full flex items-center justify-center">
                          <span class="text-xl">💰</span>
                        </div>
                        <div>
                          <h4 class="text-lg font-semibold text-[var(--sg-success)]">Cost Impact Summary</h4>
                          <p class="text-sm text-[var(--sg-success)]">Monthly infrastructure costs in {costData?.currency || 'USD'}</p>
                        </div>
                      </div>
                    </div>
                    
                    <!-- Cost Summary Metrics -->
                    <div class="grid md:grid-cols-3 gap-4 md:gap-6">
                      <div class="bg-[var(--sg-bg-1)] rounded-lg p-4 text-center border border-[var(--sg-border)]">
                        <div class="text-2xl font-bold text-[var(--sg-accent)]">
                          ${(costData.summary.total_monthly_cost || 0).toFixed(2)}
                        </div>
                        <div class="text-sm text-[var(--sg-text-dim)] mt-1">Total Monthly Cost</div>
                      </div>
                      
                      <div class="bg-[var(--sg-bg-1)] rounded-lg p-4 text-center border border-[var(--sg-border)]">
                        <div class="text-2xl font-bold {(costData.summary?.diff_monthly_cost || 0) > 0 ? 'text-[var(--sg-error)]' : (costData.summary?.diff_monthly_cost || 0) < 0 ? 'text-[var(--sg-success)]' : 'text-[var(--sg-text-dim)]'}">
                          {(costData.summary?.diff_monthly_cost || 0) > 0 ? '+' : ''}${(costData.summary?.diff_monthly_cost || 0).toFixed(2)}
                        </div>
                        <div class="text-sm text-[var(--sg-text-dim)] mt-1">Monthly Change</div>
                      </div>
                      
                      <div class="bg-[var(--sg-bg-1)] rounded-lg p-4 text-center border border-[var(--sg-border)]">
                        <div class="text-2xl font-bold text-[var(--sg-text-muted)]">
                          ${(costData.summary.prev_monthly_cost || 0).toFixed(2)}
                        </div>
                        <div class="text-sm text-[var(--sg-text-dim)] mt-1">Previous Monthly Cost</div>
                      </div>
                    </div>
                  </div>
                  
                  <!-- Per-Dirspace Cost Breakdown -->
                  {#if costData?.dirspaces && costData.dirspaces.length > 0}
                    {@const zeroCostDirspaces = costData.dirspaces.filter(d => d.total_monthly_cost === 0 && d.diff_monthly_cost === 0)}
                    <div class="bg-[var(--sg-bg-1)] border border-[var(--sg-border)] rounded-lg overflow-hidden">
                      <div class="bg-[var(--sg-bg-0)] px-6 py-4 border-b border-[var(--sg-border)]">
                        <h4 class="text-lg font-semibold text-[var(--sg-text)]">Cost Breakdown by Directory</h4>
                        <p class="text-sm text-[var(--sg-text-dim)] mt-1">Per-workspace cost analysis</p>
                      </div>
                      
                      <div class="divide-y divide-[var(--sg-border)]">
                        {#each costData.dirspaces as dirspace}
                          {#if dirspace.total_monthly_cost > 0 || dirspace.diff_monthly_cost !== 0}
                            <div class="px-4 sm:px-6 py-4 hover:bg-[var(--sg-bg-2)]">
                              <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
                                <div class="flex-1 min-w-0">
                                  <div class="flex items-center gap-3">
                                    <div class="w-3 h-3 rounded-full flex-shrink-0 {dirspace.diff_monthly_cost > 0 ? 'bg-[var(--sg-error)]' : dirspace.diff_monthly_cost < 0 ? 'bg-[var(--sg-success)]' : 'bg-[var(--sg-bg-2)]'}"></div>
                                    <div class="min-w-0 flex-1">
                                      <div class="font-medium text-[var(--sg-text)] truncate">{dirspace.dir}</div>
                                      <div class="text-sm text-[var(--sg-text-dim)]">Workspace: {dirspace.workspace}</div>
                                    </div>
                                  </div>
                                </div>
                                
                                <div class="flex items-center gap-3 sm:gap-4 text-xs sm:text-sm flex-shrink-0">
                                  <div class="text-center min-w-[60px]">
                                    <div class="font-semibold text-[var(--sg-text)]">${dirspace.total_monthly_cost.toFixed(2)}</div>
                                    <div class="text-xs text-[var(--sg-text-dim)]">Total</div>
                                  </div>
                                  
                                  {#if dirspace.diff_monthly_cost !== 0}
                                    <div class="text-center min-w-[60px]">
                                      <div class="font-semibold {dirspace.diff_monthly_cost > 0 ? 'text-[var(--sg-error)]' : 'text-[var(--sg-success)]'}">
                                        {dirspace.diff_monthly_cost > 0 ? '+' : ''}${dirspace.diff_monthly_cost.toFixed(2)}
                                      </div>
                                      <div class="text-xs text-[var(--sg-text-dim)]">Change</div>
                                    </div>
                                  {/if}
                                  
                                  <div class="text-center min-w-[60px]">
                                    <div class="font-semibold text-[var(--sg-text-muted)]">${dirspace.prev_monthly_cost.toFixed(2)}</div>
                                    <div class="text-xs text-[var(--sg-text-dim)]">Previous</div>
                                  </div>
                                </div>
                              </div>
                            </div>
                          {/if}
                        {/each}
                      </div>
                      
                      <!-- Show zero-cost dirspaces in a collapsed section -->
                      {#if zeroCostDirspaces.length > 0}
                        <details class="border-t border-[var(--sg-border)]">
                          <summary class="px-6 py-3 bg-[var(--sg-bg-0)] text-sm text-[var(--sg-text-dim)] cursor-pointer hover:bg-[var(--sg-bg-2)]">
                            Show {zeroCostDirspaces.length} directories with no cost impact
                          </summary>
                          <div class="divide-y divide-[var(--sg-border)]">
                            {#each zeroCostDirspaces as dirspace}
                              <div class="px-6 py-3 text-sm bg-[var(--sg-bg-1)]">
                                <div class="flex items-center justify-between">
                                  <div class="flex items-center space-x-3">
                                    <div class="w-2 h-2 rounded-full bg-[var(--sg-bg-2)]"></div>
                                    <span class="text-[var(--sg-text-muted)]">{dirspace.dir}</span>
                                    <span class="text-[var(--sg-text-dim)]">({dirspace.workspace})</span>
                                  </div>
                                  <span class="text-[var(--sg-text-dim)]">$0.00</span>
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
                  <div class="bg-[var(--sg-warning-bg)] border border-[var(--sg-warning)] rounded-lg p-4">
                    <div class="flex items-center space-x-2 mb-2">
                      <span class="text-lg">💰</span>
                      <span class="font-medium text-[var(--sg-warning)]">Cost Estimation</span>
                    </div>
                    
                    {#if typedOutput?.payload?.text}
                      <div class="mt-3">
                        <div class="flex items-center justify-between mb-1">
                          <div class="text-xs text-[var(--sg-warning)]">Cost Analysis:</div>
                          <button 
                            class="text-xs text-[var(--sg-accent)] hover:text-[var(--sg-accent-hover)] px-2 py-1 border border-[var(--sg-accent)] rounded hover:bg-[var(--sg-accent-bg)] transition-colors"
                            on:click={() => openOutputModal(typedOutput.payload?.text || '', 'Cost Estimation Analysis')}
                          >
                            🔍 Expand
                          </button>
                        </div>
                        <pre class="text-sm bg-[var(--sg-bg-1)] p-3 rounded border border-[var(--sg-border)] overflow-x-auto text-[var(--sg-text)] max-h-60 whitespace-pre-wrap font-mono">{typedOutput.payload?.text || ''}</pre>
                      </div>
                    {:else}
                      <pre class="text-sm bg-[var(--sg-bg-1)] p-3 rounded border border-[var(--sg-border)] overflow-x-auto text-[var(--sg-text)]">{JSON.stringify(output, null, 2)}</pre>
                    {/if}
                  </div>
                {/if}
              {/each}
            </div>
          {/if}
        
        <!-- All Steps Tab -->
        {:else if shownTab === 'all'}
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
              
              <div id={dirspaceAnchor(dirspace.dir, dirspace.workspace)} class="border border-[var(--sg-border)] rounded-lg scroll-mt-4">
                <DirspaceHeader
                  dir={dirspace.dir}
                  workspace={dirspace.workspace}
                  success={dirspace.success}
                  stepCount={dirspaceOutputs.length}
                  suffix=""
                  resourceSummary={resourceSummaryForDirspace(dirspace)}
                  expanded={isExpanded}
                  onToggle={() => toggleDirspaceExpansion(dirspaceKey)}
                />
                
                {#if isExpanded}
                  <div class="border-t border-[var(--sg-border)] bg-[var(--sg-bg-0)]">
                    {#if dirspaceOutputs.length === 0}
                      <div class="p-4 text-center text-[var(--sg-text-dim)]">
                        No step outputs available for this dirspace
                      </div>
                    {:else}
                      <div class="p-4 space-y-3">
                        {#each dirspaceOutputs as output (output.idx)}
                          {@const typedOutput = output}
                          {@const displayState = getDisplayState(typedOutput)}
                          <div class="bg-[var(--sg-bg-1)] border border-[var(--sg-border)] rounded p-3">
                            <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2 mb-2">
                              <div class="flex flex-wrap items-center gap-x-2 gap-y-1 min-w-0">
                                <span class="flex-shrink-0">{getStepIcon(typedOutput?.step || 'unknown')}</span>
                                <span class="font-medium text-[var(--sg-text)]">{getStepLabel(typedOutput?.step || 'Unknown Step')}</span>
                                {#if getStepCmd(typedOutput)}
                                  <code class="text-xs text-[var(--sg-text-dim)] font-mono bg-[var(--sg-bg-2)] px-1.5 py-0.5 rounded max-w-full truncate" title={getStepCmd(typedOutput)}>{getStepCmd(typedOutput)}</code>
                                {/if}
                                {#if typedOutput?.state}
                                  <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium {displayState.color}">
                                    {displayState.state}
                                  </span>
                                {/if}
                                <span class="text-xs text-[var(--sg-text-dim)]">idx: {typedOutput?.idx}</span>
                              </div>
                            </div>
                            <StepOutput
                              output={typedOutput}
                              stepLabel={getStepLabel(typedOutput?.step || 'Unknown Step')}
                              highlight={enablePlanHighlighting}
                              githubUrl={run?.owner && run?.repo && run?.run_id ? getGitHubActionsUrl(run.owner, run.repo, run.run_id) : ''}
                              orgName={run?.owner || ''}
                              repoName={run?.repo || ''}
                              prNumber={typeof run?.kind === 'object' && run.kind?.pull_number ? run.kind.pull_number : ''}
                              runType={run?.run_type || ''}
                              on:expand={(e) => openOutputModal(e.detail.content, e.detail.title)}
                              on:loadFull={(e) => loadFullOutput(e.detail)}
                            />
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
        {:else if shownTab === 'raw'}
          <!-- Dirspace-organized outputs (unfiltered) -->
          <div class="space-y-4">
            {#each run.dirspaces as dirspace}
              {@const dirspaceKey = getDirspaceKey(dirspace.dir, dirspace.workspace)}
              {@const isExpanded = expandedDirspaces.has(dirspaceKey)}
              {@const dirspaceOutputs = allOutputs.filter((output) => {
                const matchesDirspace = output?.scope?.dir === dirspace.dir && output?.scope?.workspace === dirspace.workspace;
                return matchesDirspace; // No visibility filtering for raw steps
              })}
              
              <div class="border border-[var(--sg-border-light)] rounded-lg">
                <DirspaceHeader
                  dir={dirspace.dir}
                  workspace={dirspace.workspace}
                  success={dirspace.success}
                  stepCount={dirspaceOutputs.length}
                  suffix=" (unfiltered)"
                  resourceSummary={resourceSummaryForDirspace(dirspace)}
                  expanded={isExpanded}
                  onToggle={() => toggleDirspaceExpansion(dirspaceKey)}
                />
                
                {#if isExpanded}
                  <div class="border-t border-[var(--sg-border)] bg-[var(--sg-bg-0)]">
                    {#if dirspaceOutputs.length === 0}
                      <div class="p-4 text-center text-[var(--sg-text-dim)]">
                        No step outputs available for this dirspace
                      </div>
                    {:else}
                      <div class="p-4 space-y-3">
                        {#each dirspaceOutputs as output (output.idx)}
                          {@const typedOutput = output}
                          {@const displayState = getDisplayState(typedOutput)}
                          <div class="bg-[var(--sg-bg-1)] border border-[var(--sg-border)] rounded p-3">
                            <div class="flex flex-wrap items-center gap-x-2 gap-y-1 mb-2 min-w-0">
                              <span class="flex-shrink-0">{getStepIcon(typedOutput?.step || 'unknown')}</span>
                              <span class="font-medium text-[var(--sg-text)]">{getStepLabel(typedOutput?.step || 'Unknown Step')}</span>
                                {#if getStepCmd(typedOutput)}
                                  <code class="text-xs text-[var(--sg-text-dim)] font-mono bg-[var(--sg-bg-2)] px-1.5 py-0.5 rounded max-w-full truncate" title={getStepCmd(typedOutput)}>{getStepCmd(typedOutput)}</code>
                                {/if}
                              {#if typedOutput?.state}
                                <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium {displayState.color}">
                                  {displayState.state}
                                </span>
                              {/if}
                              <span class="text-xs text-[var(--sg-text-dim)]">idx: {typedOutput?.idx}</span>
                              {#if typedOutput?.payload?.visible_on}
                                <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-[var(--sg-accent-bg)] text-[var(--sg-accent)]">
                                  visible_on: {typedOutput.payload.visible_on}
                                </span>
                              {/if}
                            </div>
                            
                            <StepOutput
                              output={typedOutput}
                              stepLabel={getStepLabel(typedOutput?.step || 'Unknown Step')}
                              highlight={enablePlanHighlighting}
                              githubUrl={run?.owner && run?.repo && run?.run_id ? getGitHubActionsUrl(run.owner, run.repo, run.run_id) : ''}
                              orgName={run?.owner || ''}
                              repoName={run?.repo || ''}
                              prNumber={typeof run?.kind === 'object' && run.kind?.pull_number ? run.kind.pull_number : ''}
                              runType={run?.run_type || ''}
                              debugVisibility={true}
                              on:expand={(e) => openOutputModal(e.detail.content, e.detail.title)}
                              on:loadFull={(e) => loadFullOutput(e.detail)}
                            />
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
        {:else if shownTab === 'failed'}
          {#if failedOutputs.length === 0}
            <div class="text-center py-8 text-[var(--sg-text-dim)]">
              <div class="text-4xl mb-2">✅</div>
              <p>No failed steps found</p>
            </div>
          {:else}
            <div class="space-y-4">
              {#each Object.entries(failedByDirspace) as [dirspaceKey, dirspaceData]}
                {@const isExpanded = expandedDirspaces.has(dirspaceKey)}
                
                <div class="border border-[var(--sg-error)] rounded-lg bg-[var(--sg-error-bg)]">
                  <button 
                    on:click={() => toggleDirspaceExpansion(dirspaceKey)}
                    class="w-full flex items-center justify-between p-4 text-left hover:bg-[var(--sg-error-bg)] focus:outline-none focus:ring-2 focus:ring-[var(--sg-error)] focus:ring-inset"
                  >
                    <div class="flex items-center space-x-3 flex-1 min-w-0">
                      <div class="flex-shrink-0">
                        <div class="w-3 h-3 rounded-full bg-[var(--sg-error)]"></div>
                      </div>
                      <div class="flex-1 min-w-0">
                        <div class="font-medium text-[var(--sg-error)]">{dirspaceData.dir}</div>
                        <div class="text-sm text-[var(--sg-error)]">Workspace: {dirspaceData.workspace}</div>
                      </div>
                    </div>
                    <div class="flex items-center space-x-2 flex-shrink-0">
                      <span class="text-sm text-[var(--sg-error)]">{dirspaceData.outputs.length} failed step{dirspaceData.outputs.length !== 1 ? 's' : ''}</span>
                      <svg class="w-5 h-5 text-[var(--sg-error)] transform transition-transform {isExpanded ? 'rotate-180' : ''}" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                      </svg>
                    </div>
                  </button>
                  
                  {#if isExpanded}
                    <div class="border-t border-[var(--sg-error)] bg-[var(--sg-error-bg)]">
                      <div class="p-4 space-y-3">
                        {#each dirspaceData.outputs as output ((output.step || 'unknown') + (output.payload?._loadTimestamp || ''))}
                          {@const typedOutput = output}
                          {@const displayState = getDisplayState(typedOutput)}
                          <div class="bg-[var(--sg-bg-1)] border border-[var(--sg-error)] rounded p-3">
                            <div class="flex flex-wrap items-center gap-x-2 gap-y-1 mb-2 min-w-0">
                              <span class="flex-shrink-0">❌</span>
                              <span class="font-medium text-[var(--sg-error)]">{getStepLabel(typedOutput?.step || 'Unknown Step')}</span>
                                {#if getStepCmd(typedOutput)}
                                  <code class="text-xs text-[var(--sg-text-dim)] font-mono bg-[var(--sg-bg-2)] px-1.5 py-0.5 rounded max-w-full truncate" title={getStepCmd(typedOutput)}>{getStepCmd(typedOutput)}</code>
                                {/if}
                              {#if typedOutput?.state}
                                <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium {displayState.color}">
                                  {displayState.state}
                                </span>
                              {/if}
                              <span class="text-xs text-[var(--sg-text-dim)]">idx: {typedOutput?.idx}</span>
                            </div>
                            <StepOutput
                              output={typedOutput}
                              stepLabel={getStepLabel(typedOutput?.step || 'Unknown Step')}
                              highlight={enablePlanHighlighting}
                              githubUrl={run?.owner && run?.repo && run?.run_id ? getGitHubActionsUrl(run.owner, run.repo, run.run_id) : ''}
                              orgName={run?.owner || ''}
                              repoName={run?.repo || ''}
                              prNumber={typeof run?.kind === 'object' && run.kind?.pull_number ? run.kind.pull_number : ''}
                              runType={run?.run_type || ''}
                              variant="error"
                              on:expand={(e) => openOutputModal(e.detail.content, e.detail.title)}
                              on:loadFull={(e) => loadFullOutput(e.detail)}
                            />
                          </div>
                        {/each}
                      </div>
                    </div>
                  {/if}
                </div>
              {/each}
            </div>
          {/if}
        {/if}
        
      {/if}
    </Card>
    {/if}

    <!-- Technical Details -->
    <Card padding="lg">
      <h3 class="text-lg font-semibold text-[var(--sg-accent)] mb-4">Run Metadata</h3>
      <div class="grid md:grid-cols-2 gap-6">
        <div>
          <h4 class="font-medium text-[var(--sg-text)] mb-3">Identifiers</h4>
          <div class="space-y-2 text-sm">
            <div class="flex flex-col sm:flex-row sm:justify-between gap-1">
              <span class="text-[var(--sg-text-dim)] whitespace-nowrap">Work Manifest ID:</span>
              <span class="font-mono text-[10px] sm:text-xs bg-[var(--sg-bg-2)] text-[var(--sg-text)] px-2 py-1 rounded break-all">{run.id}</span>
            </div>
            {#if run.run_id}
              <div class="flex flex-col sm:flex-row sm:justify-between gap-1">
                <span class="text-[var(--sg-text-dim)] whitespace-nowrap">GitHub Actions ID:</span>
                <span class="font-mono text-[10px] sm:text-xs bg-[var(--sg-bg-2)] text-[var(--sg-text)] px-2 py-1 rounded break-all">{run.run_id}</span>
              </div>
            {/if}
          </div>
        </div>
        <div class="mt-4 md:mt-0">
          <h4 class="font-medium text-[var(--sg-text)] mb-3">Git References</h4>
          <div class="space-y-2 text-sm">
            <div class="flex flex-col sm:flex-row sm:justify-between gap-1">
              <span class="text-[var(--sg-text-dim)] whitespace-nowrap">Branch Ref:</span>
              <span class="font-mono text-[10px] sm:text-xs bg-[var(--sg-bg-2)] text-[var(--sg-text)] px-2 py-1 rounded">{run.branch_ref.substring(0, 8)}</span>
            </div>
            <div class="flex flex-col sm:flex-row sm:justify-between gap-1">
              <span class="text-[var(--sg-text-dim)] whitespace-nowrap">Base Ref:</span>
              <span class="font-mono text-[10px] sm:text-xs bg-[var(--sg-bg-2)] text-[var(--sg-text)] px-2 py-1 rounded">{run.base_ref.substring(0, 8)}</span>
            </div>
          </div>
        </div>
      </div>
    </Card>
  {:else if !isLoading && !run}
    <div class="text-center py-12">
      <p class="text-[var(--sg-text-dim)]">Run not found.</p>
      <div class="mt-4">
        <a 
          href={getBackUrl()} 
          class="text-[var(--sg-accent)] hover:text-[var(--sg-accent)] font-medium"
        >
          ← Back to Runs
        </a>
      </div>
    </div>
  {/if}

  <!-- Full-Screen Output Modal -->
  {#if showOutputModal}
    <div class="fixed inset-0 z-50 overflow-y-auto bg-black bg-opacity-75 flex items-center justify-center p-2 sm:p-4">
      <div class="bg-[var(--sg-bg-1)] rounded-lg shadow-xl w-full h-full max-w-7xl max-h-full flex flex-col">
        <!-- Modal Header -->
        <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between p-3 sm:p-4 border-b border-[var(--sg-border)] gap-2">
          <div class="flex flex-col sm:flex-row sm:items-center gap-1 sm:gap-3">
            <h3 class="text-base sm:text-lg font-semibold text-[var(--sg-text)]">Output View</h3>
            <span class="text-xs sm:text-sm text-[var(--sg-text-dim)] break-all">{modalOutputTitle}</span>
          </div>
          <div class="flex items-center gap-2">
            <button
              class="px-2 sm:px-3 py-1 text-xs sm:text-sm text-[var(--sg-text-dim)] hover:text-[var(--sg-text)] border border-[var(--sg-border)] rounded hover:bg-[var(--sg-bg-2)] transition-colors"
              on:click={() => navigator.clipboard.writeText(modalOutputContent)}
              title="Copy to clipboard"
            >
              📋 Copy
            </button>
            <button
              class="p-1.5 sm:p-2 text-[var(--sg-text-dim)] hover:text-[var(--sg-text-dim)] hover:text-[var(--sg-text)] rounded-full hover:bg-[var(--sg-bg-2)] transition-colors"
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
          <pre class="h-full w-full bg-[var(--sg-bg-0)] text-[var(--sg-text)] p-3 sm:p-4 overflow-auto text-xs sm:text-sm font-mono whitespace-pre-wrap break-words">{modalOutputContent}</pre>
        </div>

        <!-- Modal Footer -->
        <div class="p-3 sm:p-4 border-t border-[var(--sg-border)] bg-[var(--sg-bg-0)]">
          <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-1 text-xs sm:text-sm text-[var(--sg-text-dim)]">
            <div>
              {modalOutputContent.split('\n').length} lines • {modalOutputContent.length} characters
            </div>
            <div class="hidden sm:block">
              Press <kbd class="px-2 py-1 bg-[var(--sg-bg-2)] rounded text-xs">Esc</kbd> to close
            </div>
          </div>
        </div>
      </div>
    </div>
  {/if}
</PageLayout>
