<script lang="ts">
  import { onMount } from 'svelte';
  // Auth handled by PageLayout
  import { api } from './api';
  import { selectedInstallation } from './stores';
  import PageLayout from './components/layout/PageLayout.svelte';
  import Card from './components/ui/Card.svelte';
  import LoadingSpinner from './components/ui/LoadingSpinner.svelte';
  import type { Dirspace, Repository } from './types';
  import { navigateToRun, navigateToRuns } from './utils/navigation';

  // Tab state
  let activeTab: 'repository' | 'workflow' | 'drift' = 'repository';

  // Shared data state
  let repositories: Repository[] = [];
  let dirspaces: Dirspace[] = [];
  let isLoadingRepos = false;
  let isLoadingDirspaces = false;
  let error: string | null = null;

  // Shared filtering
  let dateRange = '30'; // days
  let selectedRepo = '';

  // Repository Analytics state
  let repoAnalytics: RepoAnalytics[] = [];
  let overallMetrics = {
    totalRepos: 0,
    activeRepos: 0,
    totalRuns: 0,
    avgSuccessRate: 0,
    totalUsers: 0,
    mostActiveRepo: '',
    leastActiveRepo: ''
  };

  interface RepoAnalytics {
    name: string;
    totalRuns: number;
    successRate: number;
    failureRate: number;
    avgDuration: number;
    lastRun: string;
    topUsers: string[];
    environments: string[];
    planToApplyRatio: number;
    recentTrend: 'up' | 'down' | 'stable';
  }

  // Repository Analytics filtering/sorting
  let sortBy: 'name' | 'runs' | 'success' | 'activity' = 'runs';
  let sortOrder: 'asc' | 'desc' = 'desc';
  let searchQuery = '';

  // Workflow Analytics state
  let workflowSteps: WorkflowStep[] = [];
  let stepAnalytics: StepAnalytics[] = [];
  let performanceMetrics: PerformanceMetrics = {
    totalSteps: 0,
    avgDuration: 0,
    successRate: 0,
    failureRate: 0,
    slowestSteps: [],
    fastestSteps: [],
    errorProneSteps: [],
    mostUsedSteps: []
  };

  interface WorkflowStep {
    created_at: string;
    idx: number;
    ignore_errors: boolean;
    payload: Record<string, unknown>;
    scope: {
      dir?: string;
      workspace?: string;
      type?: string;
    };
    state: string;
    step: string;
    duration?: number;
    success: boolean;
    repository?: string;
    workManifestId?: string;
  }

  interface StepAnalytics {
    stepType: string;
    totalExecutions: number;
    successCount: number;
    failureCount: number;
    successRate: number;
    failureRate: number;
    avgDuration: number;
    minDuration: number;
    maxDuration: number;
    repositories: Set<string>;
    commonErrors: string[];
    performanceTrend: 'improving' | 'degrading' | 'stable';
    lastExecuted: string;
  }

  interface PerformanceMetrics {
    totalSteps: number;
    avgDuration: number;
    successRate: number;
    failureRate: number;
    slowestSteps: string[];
    fastestSteps: string[];
    errorProneSteps: string[];
    mostUsedSteps: string[];
  }

  // Workflow Analytics filtering
  let selectedStepType = '';
  let onlyShowFailures = false;
  let selectedScope = '';
  let filteredSteps: WorkflowStep[] = [];
  let filteredStepAnalytics: StepAnalytics[] = [];
  
  // Enhanced workflow data loading
  let loadingDetailedData = false;
  let loadedDetailedRepos = new Set<string>();
  
  // Expandable details state
  let expandedStepAnalytic: string | null = null;
  let expandedWorkflowStep: string | null = null;
  let expandedDriftItem: string | null = null;

  // Drift Analytics state  
  let driftOperations: Dirspace[] = [];
  let isLoadingDrift = false;
  let driftError: string | null = null;
  let driftMetrics = {
    totalDrifts: 0,
    openDrifts: 0,
    avgDriftResolutionTime: 0,
    mostDriftProneRepo: ''
  };

  // Load data when installation changes
  $: if ($selectedInstallation) {
    loadData();
  }

  // Shared data loading
  async function loadData(): Promise<void> {
    // Reset detailed data tracking when reloading
    loadedDetailedRepos.clear();
    loadedDetailedRepos = loadedDetailedRepos; // Trigger reactivity

    await Promise.all([
      loadRepositories(),
      loadDirspaces(),
      loadDriftOperations()
    ]);

    // Calculate analytics for all tabs
    calculateRepoAnalytics();
    createWorkflowAnalytics();
    calculateDriftMetrics();
  }

  async function loadRepositories(): Promise<void> {
    if (!$selectedInstallation) return;

    isLoadingRepos = true;
    try {
      const response = await api.getInstallationRepos($selectedInstallation.id);
      repositories = response.repositories || [];
    } catch (err) {
      console.error('Error loading repositories:', err);
      error = err instanceof Error ? err.message : 'Failed to load repositories';
    } finally {
      isLoadingRepos = false;
    }
  }

  async function loadDirspaces(): Promise<void> {
    if (!$selectedInstallation) return;

    isLoadingDirspaces = true;
    try {
      const now = new Date();
      const days = parseInt(dateRange);
      const startDate = new Date(now.getTime() - days * 24 * 60 * 60 * 1000);
      const dateFilter = startDate.toISOString().split('T')[0];

      const response = await api.getInstallationDirspaces($selectedInstallation.id, {
        q: `created_at:${dateFilter}..`,
        tz: Intl.DateTimeFormat().resolvedOptions().timeZone,
        limit: 200
      });

      dirspaces = response.dirspaces || [];
    } catch (err) {
      console.error('Error loading dirspaces:', err);
      error = err instanceof Error ? err.message : 'Failed to load run data';
    } finally {
      isLoadingDirspaces = false;
    }
  }

  async function loadDriftOperations(): Promise<void> {
    if (!$selectedInstallation) return;

    isLoadingDrift = true;
    driftError = null;
    
    try {
      
      // Use the dirspaces API with kind:drift filter 
      const response = await api.getInstallationDirspaces($selectedInstallation.id, {
        q: 'kind:drift',
        tz: Intl.DateTimeFormat().resolvedOptions().timeZone,
        limit: 100 // Get more drift operations for better analytics
      });
      
      driftOperations = response.dirspaces || [];
    } catch (err) {
      console.error('❌ Error loading drift operations:', err);
      driftError = err instanceof Error ? err.message : 'Failed to load drift operations';
      driftOperations = [];
    } finally {
      isLoadingDrift = false;
    }
  }

  function calculateDriftMetrics(): void {
    if (driftOperations.length === 0) {
      driftMetrics = {
        totalDrifts: 0,
        openDrifts: 0,
        avgDriftResolutionTime: 0,
        mostDriftProneRepo: ''
      };
      return;
    }

    // Filter to recent drift operations (last 30 days)
    const now = new Date();
    const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
    const recentDrifts = driftOperations.filter(drift => 
      new Date(drift.created_at) >= thirtyDaysAgo
    );

    // Calculate open drifts (running, queued, or no completion)
    const openDrifts = driftOperations.filter(drift => 
      drift.state === 'running' || drift.state === 'queued' || !drift.completed_at
    );

    // Calculate average resolution time for completed drifts
    const completedDrifts = driftOperations.filter(drift => 
      drift.completed_at && (drift.state === 'success' || drift.state === 'failure')
    );
    
    let totalResolutionTime = 0;
    completedDrifts.forEach(drift => {
      const created = new Date(drift.created_at).getTime();
      const completed = new Date(drift.completed_at!).getTime();
      totalResolutionTime += completed - created;
    });
    
    const avgDriftResolutionTime = completedDrifts.length > 0 
      ? totalResolutionTime / completedDrifts.length 
      : 0;

    // Find most drift-prone repository by frequency
    const repoFrequency = new Map<string, number>();
    driftOperations.forEach(drift => {
      repoFrequency.set(drift.repo, (repoFrequency.get(drift.repo) || 0) + 1);
    });
    
    const mostDriftProneRepo = Array.from(repoFrequency.entries())
      .sort((a, b) => b[1] - a[1])[0]?.[0] || '';

    driftMetrics = {
      totalDrifts: recentDrifts.length,
      openDrifts: openDrifts.length,
      avgDriftResolutionTime,
      mostDriftProneRepo
    };
  }

  // Repository Analytics calculations
  function calculateRepoAnalytics(): void {
    const repoMap = new Map<string, {
      runs: Dirspace[];
      totalRuns: number;
      successCount: number;
      failureCount: number;
      users: Set<string>;
      environments: Set<string>;
      planCount: number;
      applyCount: number;
      durations: number[];
    }>();

    // Initialize repo map
    repositories.forEach(repo => {
      repoMap.set(repo.name, {
        runs: [],
        totalRuns: 0,
        successCount: 0,
        failureCount: 0,
        users: new Set(),
        environments: new Set(),
        planCount: 0,
        applyCount: 0,
        durations: []
      });
    });

    // Process dirspaces
    dirspaces.forEach(ds => {
      if (!repoMap.has(ds.repo)) {
        repoMap.set(ds.repo, {
          runs: [],
          totalRuns: 0,
          successCount: 0,
          failureCount: 0,
          users: new Set(),
          environments: new Set(),
          planCount: 0,
          applyCount: 0,
          durations: []
        });
      }

      const repoData = repoMap.get(ds.repo)!;
      repoData.runs.push(ds);
      repoData.totalRuns++;

      if (ds.state === 'success') repoData.successCount++;
      else if (ds.state === 'failure') repoData.failureCount++;

      if (ds.user) repoData.users.add(ds.user);
      if (ds.environment) repoData.environments.add(ds.environment);

      if (ds.run_type === 'plan') repoData.planCount++;
      else if (ds.run_type === 'apply') repoData.applyCount++;

      // Calculate duration if available
      if (ds.created_at && ds.completed_at) {
        const duration = new Date(ds.completed_at).getTime() - new Date(ds.created_at).getTime();
        repoData.durations.push(duration);
      }
    });

    // Calculate analytics
    repoAnalytics = Array.from(repoMap.entries()).map(([name, data]) => {
      const successRate = data.totalRuns > 0 ? (data.successCount / data.totalRuns) * 100 : 0;
      const failureRate = data.totalRuns > 0 ? (data.failureCount / data.totalRuns) * 100 : 0;
      const avgDuration = data.durations.length > 0 ? data.durations.reduce((a, b) => a + b, 0) / data.durations.length : 0;
      const planToApplyRatio = data.applyCount > 0 ? data.planCount / data.applyCount : 0;

      const lastRun = data.runs.length > 0 
        ? data.runs.sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime())[0].created_at
        : '';

      return {
        name,
        totalRuns: data.totalRuns,
        successRate,
        failureRate,
        avgDuration,
        lastRun,
        topUsers: Array.from(data.users).slice(0, 3),
        environments: Array.from(data.environments),
        planToApplyRatio,
        recentTrend: 'stable' as const // Simplified for now
      };
    });

    // Calculate overall metrics
    const totalRuns = dirspaces.length;
    const successfulRuns = dirspaces.filter(ds => ds.state === 'success').length;
    const activeRepos = repoAnalytics.filter(ra => ra.totalRuns > 0).length;
    const allUsers = new Set(dirspaces.filter(ds => ds.user).map(ds => ds.user!));

    overallMetrics = {
      totalRepos: repositories.length,
      activeRepos,
      totalRuns,
      avgSuccessRate: totalRuns > 0 ? (successfulRuns / totalRuns) * 100 : 0,
      totalUsers: allUsers.size,
      mostActiveRepo: repoAnalytics.length > 0 ? repoAnalytics.sort((a, b) => b.totalRuns - a.totalRuns)[0]?.name || '' : '',
      leastActiveRepo: repoAnalytics.length > 0 ? repoAnalytics.sort((a, b) => a.totalRuns - b.totalRuns)[0]?.name || '' : ''
    };
  }

  // Workflow Analytics calculations
  function createWorkflowAnalytics(): void {
    // Create synthetic workflow steps from dirspaces only for repos without detailed data
    const syntheticSteps: WorkflowStep[] = [];
    
    dirspaces.forEach(ds => {
      // Skip repos that have enhanced data loaded
      if (loadedDetailedRepos.has(ds.repo)) return;
      
      // Create synthetic steps based on operation type
      const stepTypes = getTypicalWorkflowSteps(ds.run_type);
      const totalDuration = ds.created_at && ds.completed_at 
        ? new Date(ds.completed_at).getTime() - new Date(ds.created_at).getTime()
        : 60000; // Default 1 minute
      
      const stepDuration = totalDuration / stepTypes.length;
      
      stepTypes.forEach((stepType, index) => {
        const stepStartTime = new Date(new Date(ds.created_at).getTime() + (stepDuration * index));
        
        syntheticSteps.push({
          created_at: stepStartTime.toISOString(),
          idx: index,
          ignore_errors: false,
          payload: {},
          scope: {
            dir: ds.dir,
            workspace: ds.workspace,
            type: 'dirspace'
          },
          state: ds.state,
          step: stepType,
          success: ds.state === 'success',
          repository: ds.repo,
          workManifestId: ds.id,
          duration: stepDuration
        });
      });
    });

    // Keep existing detailed steps and add synthetic ones
    const existingDetailedSteps = workflowSteps.filter(step => 
      loadedDetailedRepos.has(step.repository || '')
    );
    
    workflowSteps = [...existingDetailedSteps, ...syntheticSteps]
      .sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime());

    calculateStepAnalytics();
    calculatePerformanceMetrics();
  }

  function getTypicalWorkflowSteps(runType: string): string[] {
    // Define typical workflow steps based on operation type
    switch (runType) {
      case 'plan':
        return ['checkout', 'init', 'plan'];
      case 'apply':
        return ['checkout', 'init', 'plan', 'apply'];
      case 'drift':
        return ['checkout', 'init', 'plan', 'drift-create-issue'];
      case 'index':
        return ['checkout', 'init'];
      default:
        return ['checkout', 'init', 'plan'];
    }
  }

  async function loadDetailedDataForRepo(repo: string): Promise<void> {
    if (!$selectedInstallation || !repo || loadingDetailedData) return;

    loadingDetailedData = true;

    try {
      // Load detailed workflow data for a specific repo (limited set)
      const repoDirections = dirspaces.filter(ds => ds.repo === repo).slice(0, 10); // Limit to 10 recent ones
      const detailedSteps: WorkflowStep[] = [];

      for (const ds of repoDirections) {
        try {
          const outputsResponse = await api.getWorkManifestOutputs(
            $selectedInstallation.id,
            ds.id,
            { limit: 20, lite: true } // Limit outputs per dirspace, use lite mode
          );

          if (outputsResponse?.outputs) {
            outputsResponse.outputs.forEach((output, idx) => {
              const typedOutput = output as {
                payload?: Record<string, unknown>;
                scope?: { dir?: string; workspace?: string; type?: string; };
                step?: string;
                state?: string;
                created_at?: string;
                success?: boolean;
                ignore_errors?: boolean;
              };

              if (typedOutput.step) {
                detailedSteps.push({
                  created_at: typedOutput.created_at || ds.created_at,
                  idx: idx,
                  ignore_errors: typedOutput.ignore_errors || false,
                  payload: typedOutput.payload || {},
                  scope: typedOutput.scope || {},
                  state: typedOutput.state || 'unknown',
                  step: typedOutput.step,
                  success: typedOutput.success !== false,
                  repository: ds.repo,
                  workManifestId: ds.id
                });
              }
            });
          }
        } catch (err) {
          console.warn(`Failed to load detailed data for ${ds.id}:`, err);
        }
      }

      // Replace synthetic data for this repo with detailed data
      workflowSteps = [
        ...workflowSteps.filter(step => step.repository !== repo),
        ...detailedSteps
      ].sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime());

      // Recalculate analytics
      calculateStepAnalytics();
      calculatePerformanceMetrics();
      
      // Mark this repo as having detailed data
      loadedDetailedRepos.add(repo);
      loadedDetailedRepos = loadedDetailedRepos; // Trigger reactivity

    } catch (err) {
      console.error('Error loading detailed workflow data:', err);
    } finally {
      loadingDetailedData = false;
    }
  }

  function calculateStepAnalytics(): void {
    const stepMap = new Map<string, {
      executions: WorkflowStep[];
      successCount: number;
      failureCount: number;
      durations: number[];
      repositories: Set<string>;
      errors: string[];
    }>();

    workflowSteps.forEach(step => {
      if (!stepMap.has(step.step)) {
        stepMap.set(step.step, {
          executions: [],
          successCount: 0,
          failureCount: 0,
          durations: [],
          repositories: new Set(),
          errors: []
        });
      }

      const stepData = stepMap.get(step.step)!;
      stepData.executions.push(step);
      
      if (step.success) stepData.successCount++;
      else stepData.failureCount++;

      if (step.duration) stepData.durations.push(step.duration);
      if (step.repository) stepData.repositories.add(step.repository);
    });

    stepAnalytics = Array.from(stepMap.entries()).map(([stepType, data]) => {
      const totalExecutions = data.executions.length;
      const successRate = totalExecutions > 0 ? (data.successCount / totalExecutions) * 100 : 0;
      const failureRate = 100 - successRate;
      const avgDuration = data.durations.length > 0 ? data.durations.reduce((a, b) => a + b, 0) / data.durations.length : 0;
      const minDuration = data.durations.length > 0 ? Math.min(...data.durations) : 0;
      const maxDuration = data.durations.length > 0 ? Math.max(...data.durations) : 0;

      const lastExecuted = data.executions.length > 0
        ? data.executions.sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime())[0].created_at
        : '';

      return {
        stepType,
        totalExecutions,
        successCount: data.successCount,
        failureCount: data.failureCount,
        successRate,
        failureRate,
        avgDuration,
        minDuration,
        maxDuration,
        repositories: data.repositories,
        commonErrors: [], // Simplified for now
        performanceTrend: 'stable' as const,
        lastExecuted
      };
    });
  }

  function calculatePerformanceMetrics(): void {
    const totalSteps = workflowSteps.length;
    const successfulSteps = workflowSteps.filter(s => s.success).length;
    const durations = workflowSteps.filter(s => s.duration).map(s => s.duration!);
    const avgDuration = durations.length > 0 ? durations.reduce((a, b) => a + b, 0) / durations.length : 0;

    // Calculate step frequencies and performance
    const stepFrequency = new Map<string, number>();
    const stepDurations = new Map<string, number[]>();
    const stepFailures = new Map<string, number>();

    workflowSteps.forEach(step => {
      stepFrequency.set(step.step, (stepFrequency.get(step.step) || 0) + 1);
      
      if (step.duration) {
        if (!stepDurations.has(step.step)) stepDurations.set(step.step, []);
        stepDurations.get(step.step)!.push(step.duration);
      }

      if (!step.success) {
        stepFailures.set(step.step, (stepFailures.get(step.step) || 0) + 1);
      }
    });

    performanceMetrics = {
      totalSteps,
      avgDuration,
      successRate: totalSteps > 0 ? (successfulSteps / totalSteps) * 100 : 0,
      failureRate: totalSteps > 0 ? ((totalSteps - successfulSteps) / totalSteps) * 100 : 0,
      slowestSteps: Array.from(stepDurations.entries())
        .map(([step, durations]) => ({ step, avgDuration: durations.reduce((a, b) => a + b, 0) / durations.length }))
        .sort((a, b) => b.avgDuration - a.avgDuration)
        .slice(0, 5)
        .map(item => item.step),
      fastestSteps: Array.from(stepDurations.entries())
        .map(([step, durations]) => ({ step, avgDuration: durations.reduce((a, b) => a + b, 0) / durations.length }))
        .sort((a, b) => a.avgDuration - b.avgDuration)
        .slice(0, 5)
        .map(item => item.step),
      errorProneSteps: Array.from(stepFailures.entries())
        .sort((a, b) => b[1] - a[1])
        .slice(0, 5)
        .map(([step]) => step),
      mostUsedSteps: Array.from(stepFrequency.entries())
        .sort((a, b) => b[1] - a[1])
        .slice(0, 5)
        .map(([step]) => step)
    };
  }

  // Filtering for both tabs
  $: uniqueRepos = Array.from(new Set(dirspaces.map(ds => ds.repo))).sort();

  // Repository Analytics filtering
  $: filteredRepoAnalytics = repoAnalytics
    .filter(ra => {
      if (searchQuery && !ra.name.toLowerCase().includes(searchQuery.toLowerCase())) return false;
      if (selectedRepo && ra.name !== selectedRepo) return false;
      return true;
    })
    .sort((a, b) => {
      const aVal = sortBy === 'name' ? a.name : 
                   sortBy === 'runs' ? a.totalRuns :
                   sortBy === 'success' ? a.successRate :
                   new Date(a.lastRun).getTime();
      const bVal = sortBy === 'name' ? b.name :
                   sortBy === 'runs' ? b.totalRuns :
                   sortBy === 'success' ? b.successRate :
                   new Date(b.lastRun).getTime();
      
      if (typeof aVal === 'string' && typeof bVal === 'string') {
        return sortOrder === 'asc' ? aVal.localeCompare(bVal) : bVal.localeCompare(aVal);
      }
      return sortOrder === 'asc' ? Number(aVal) - Number(bVal) : Number(bVal) - Number(aVal);
    });

  // Workflow Analytics filtering
  $: {
    filteredSteps = workflowSteps.filter(step => {
      if (selectedRepo && step.repository !== selectedRepo) return false;
      if (selectedStepType && step.step !== selectedStepType) return false;
      if (onlyShowFailures && step.success) return false;
      if (selectedScope && step.scope.type !== selectedScope) return false;
      return true;
    });
  }

  $: {
    filteredStepAnalytics = stepAnalytics.filter(analytics => {
      if (selectedStepType && analytics.stepType !== selectedStepType) return false;
      if (selectedRepo && !analytics.repositories.has(selectedRepo)) return false;
      return true;
    });
  }

  $: uniqueStepTypes = Array.from(new Set(workflowSteps.map(s => s.step))).sort();

  // Utility functions
  function formatDuration(ms: number): string {
    if (ms < 1000) return `${ms}ms`;
    if (ms < 60000) return `${(ms / 1000).toFixed(1)}s`;
    if (ms < 3600000) return `${(ms / 60000).toFixed(1)}m`;
    return `${(ms / 3600000).toFixed(1)}h`;
  }

  function formatDate(dateString: string): string {
    if (!dateString) return 'Never';
    const date = new Date(dateString);
    return date.toLocaleDateString() + ' ' + date.toLocaleTimeString();
  }

  function getSuccessRateColor(rate: number): string {
    if (rate >= 90) return 'text-green-600 dark:text-green-400';
    if (rate >= 70) return 'text-yellow-600 dark:text-yellow-400';
    return 'text-red-600 dark:text-red-400';
  }

  function getStepCategoryColor(category: string): string {
    switch (category) {
      case 'Core': return 'bg-blue-100 dark:bg-blue-900/30 text-blue-800 dark:text-blue-200 border-blue-200 dark:border-blue-600';
      case 'Setup': return 'bg-green-100 dark:bg-green-900/30 text-green-800 dark:text-green-200 border-green-200 dark:border-green-600';
      case 'Validation': return 'bg-yellow-100 dark:bg-yellow-900/30 text-yellow-800 dark:text-yellow-200 border-yellow-200 dark:border-yellow-600';
      case 'Execution': return 'bg-purple-100 dark:bg-purple-900/30 text-purple-800 dark:text-purple-200 border-purple-200 dark:border-purple-600';
      case 'Cleanup': return 'bg-gray-100 dark:bg-gray-800 text-gray-800 dark:text-gray-200 border-gray-200 dark:border-gray-600';
      default: return 'bg-gray-100 dark:bg-gray-800 text-gray-800 dark:text-gray-200 border-gray-200 dark:border-gray-600';
    }
  }

  function getStepCategory(stepType: string): string {
    if (stepType.includes('plan') || stepType.includes('apply')) return 'Core';
    if (stepType.includes('init') || stepType.includes('checkout') || stepType.includes('setup')) return 'Setup';
    if (stepType.includes('validate') || stepType.includes('fmt') || stepType.includes('lint')) return 'Validation';
    if (stepType.includes('destroy') || stepType.includes('clean')) return 'Cleanup';
    return 'Execution';
  }

  onMount(() => {
    if ($selectedInstallation) {
      loadData();
    }
  });
</script>

<PageLayout activeItem="analytics" title="Analytics" subtitle="Repository health and workflow performance insights based on the most recent 100 operations">
  
  <!-- Tab Navigation -->
  <div class="mb-6">
    <div class="border-b border-gray-200 dark:border-gray-700">
      <nav class="-mb-px flex space-x-8">
        <button
          on:click={() => activeTab = 'repository'}
          class="py-2 px-1 border-b-2 font-medium text-sm transition-colors duration-200 {activeTab === 'repository' 
            ? 'border-blue-500 text-blue-600 dark:text-blue-400' 
            : 'border-transparent text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300 hover:border-gray-300 dark:hover:border-gray-600'}"
        >
          🏢 Repository Health
        </button>
        <button
          on:click={() => activeTab = 'workflow'}
          class="py-2 px-1 border-b-2 font-medium text-sm transition-colors duration-200 {activeTab === 'workflow' 
            ? 'border-blue-500 text-blue-600 dark:text-blue-400' 
            : 'border-transparent text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300 hover:border-gray-300 dark:hover:border-gray-600'}"
        >
          ⚙️ Workflow Performance
        </button>
        <button
          on:click={() => activeTab = 'drift'}
          class="py-2 px-1 border-b-2 font-medium text-sm transition-colors duration-200 {activeTab === 'drift' 
            ? 'border-blue-500 text-blue-600 dark:text-blue-400' 
            : 'border-transparent text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300 hover:border-gray-300 dark:hover:border-gray-600'}"
        >
          🔍 Drift Detection
        </button>
      </nav>
    </div>
  </div>

  <!-- Shared Controls -->
  <div class="mb-6">
    <Card padding="md">
      <div class="flex flex-wrap items-center gap-4">
        <!-- Date Range -->
        <div class="flex items-center space-x-2">
          <label for="date-range" class="text-sm font-medium text-gray-700 dark:text-gray-300">Time Range:</label>
          <select id="date-range" bind:value={dateRange} on:change={loadData}
                  class="border-gray-300 dark:border-gray-600 rounded-md shadow-sm text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 focus:border-blue-500 focus:ring-blue-500">
            <option value="7">Last 7 days</option>
            <option value="30">Last 30 days</option>
            <option value="90">Last 90 days</option>
          </select>
        </div>

        <!-- Repository Filter -->
        <div class="flex items-center space-x-2">
          <label for="repo-filter" class="text-sm font-medium text-gray-700 dark:text-gray-300">Repository:</label>
          <select id="repo-filter" bind:value={selectedRepo}
                  class="border-gray-300 dark:border-gray-600 rounded-md shadow-sm text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 focus:border-blue-500 focus:ring-blue-500">
            <option value="">All Repositories</option>
            {#each uniqueRepos as repo}
              <option value={repo}>{repo}</option>
            {/each}
          </select>
        </div>

        <!-- Enhanced Analysis (Workflow tab only) -->
        {#if activeTab === 'workflow'}
          {#if selectedRepo}
            <div class="flex items-center space-x-2 border-l border-gray-300 dark:border-gray-600 pl-4">
              <span class="text-sm text-gray-600 dark:text-gray-400">Step Details:</span>
              <button 
                on:click={() => loadDetailedDataForRepo(selectedRepo)}
                disabled={loadingDetailedData || loadedDetailedRepos.has(selectedRepo)}
                class="px-3 py-1 rounded-md text-sm font-medium border transition-all {
                  loadedDetailedRepos.has(selectedRepo) 
                    ? 'bg-green-50 dark:bg-green-900/30 border-green-200 dark:border-green-600 text-green-700 dark:text-green-300 cursor-default' 
                    : loadingDetailedData 
                      ? 'bg-gray-50 dark:bg-gray-800 border-gray-200 dark:border-gray-600 text-gray-400 dark:text-gray-500 cursor-not-allowed'
                      : 'bg-blue-50 dark:bg-blue-900/30 border-blue-200 dark:border-blue-600 text-blue-700 dark:text-blue-300 hover:bg-blue-100 dark:hover:bg-blue-900/50'
                }"
                title={loadedDetailedRepos.has(selectedRepo) 
                  ? 'Detailed step execution data loaded' 
                  : 'Load detailed step-by-step execution data for more accurate analysis'}
              >
                {#if loadingDetailedData}
                  ⏳ Loading...
                {:else if loadedDetailedRepos.has(selectedRepo)}
                  ✅ Enhanced
                {:else}
                  🔍 Load Details
                {/if}
              </button>
            </div>
          {:else}
            <div class="flex items-center space-x-2 border-l border-gray-300 dark:border-gray-600 pl-4">
              <span class="text-xs text-gray-500 dark:text-gray-400">💡 Select a repository to load detailed step analysis</span>
            </div>
          {/if}
        {/if}
      </div>
      
      <!-- Success message -->
      {#if activeTab === 'workflow' && selectedRepo && loadedDetailedRepos.has(selectedRepo)}
        <div class="mt-3 text-xs text-green-700 dark:text-green-300 bg-green-50 dark:bg-green-900/30 px-2 py-1 rounded border border-green-200 dark:border-green-600">
          ✅ Now showing detailed step execution data for {selectedRepo}
        </div>
      {/if}
    </Card>
  </div>

  <!-- Loading State -->
  {#if isLoadingRepos || isLoadingDirspaces}
    <div class="flex justify-center items-center py-12">
      <LoadingSpinner size="lg" />
      <span class="ml-3 text-gray-600 dark:text-gray-400">Loading analytics data...</span>
    </div>
  
  <!-- Error State -->
  {:else if error}
    <div class="text-center py-12">
      <div class="text-red-600 dark:text-red-400 mb-4">
        <svg class="w-12 h-12 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        <p class="text-lg font-medium">Error Loading Data</p>
        <p class="text-sm mt-1">{error}</p>
      </div>
      <button on:click={loadData} class="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700">
        Retry
      </button>
    </div>

  <!-- Repository Health Tab -->
  {:else if activeTab === 'repository'}
    <!-- Overall Metrics -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
      <Card padding="lg" class="text-center">
        <div class="text-3xl font-bold text-blue-600 dark:text-blue-400">{overallMetrics.totalRepos}</div>
        <div class="text-sm text-blue-700 dark:text-blue-300 mt-1">Total Repositories</div>
        <div class="text-xs text-gray-500 dark:text-gray-400 mt-1">{overallMetrics.activeRepos} active</div>
      </Card>
      
      <Card padding="lg" class="text-center">
        <div class="text-3xl font-bold text-green-600 dark:text-green-400">{overallMetrics.totalRuns}</div>
        <div class="text-sm text-green-700 dark:text-green-300 mt-1">Total Runs</div>
        <div class="text-xs text-gray-500 dark:text-gray-400 mt-1">Last {dateRange} days (max 100)</div>
      </Card>
      
      <Card padding="lg" class="text-center">
        <div class="text-3xl font-bold {getSuccessRateColor(overallMetrics.avgSuccessRate)}">
          {overallMetrics.avgSuccessRate.toFixed(1)}%
        </div>
        <div class="text-sm text-gray-700 dark:text-gray-300 mt-1">Avg Success Rate</div>
        <div class="text-xs text-gray-500 dark:text-gray-400 mt-1">Across all repos</div>
      </Card>
      
      <Card padding="lg" class="text-center">
        <div class="text-3xl font-bold text-purple-600 dark:text-purple-400">{overallMetrics.totalUsers}</div>
        <div class="text-sm text-purple-700 dark:text-purple-300 mt-1">Active Users</div>
        <div class="text-xs text-gray-500 dark:text-gray-400 mt-1">Contributing to runs</div>
      </Card>
    </div>

    <!-- Repository Analytics Table -->
    <Card padding="lg">
      <div class="flex items-center justify-between mb-6">
        <div>
          <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100">Repository Performance</h3>
          <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">Based on the most recent 100 runs from the selected time range</p>
        </div>
        
        <!-- Repository Tab Controls -->
        <div class="flex items-center space-x-4">
          <!-- Search -->
          <div class="flex items-center space-x-2">
            <label for="search-repos" class="text-sm font-medium text-gray-700">Search:</label>
            <input id="search-repos" type="text" bind:value={searchQuery} placeholder="Filter repositories..."
                   class="border-gray-300 rounded-md shadow-sm text-sm focus:border-blue-500 focus:ring-blue-500" />
          </div>

          <!-- Sort -->
          <div class="flex items-center space-x-2">
            <label for="sort-by" class="text-sm font-medium text-gray-700">Sort by:</label>
            <select id="sort-by" bind:value={sortBy}
                    class="border-gray-300 rounded-md shadow-sm text-sm focus:border-blue-500 focus:ring-blue-500">
              <option value="runs">Runs</option>
              <option value="success">Success Rate</option>
              <option value="activity">Last Activity</option>
              <option value="name">Name</option>
            </select>
            <button on:click={() => sortOrder = sortOrder === 'asc' ? 'desc' : 'asc'}
                    class="p-1 text-gray-400 hover:text-gray-600">
              {#if sortOrder === 'asc'}
                ↑
              {:else}
                ↓
              {/if}
            </button>
          </div>
        </div>
      </div>

      {#if filteredRepoAnalytics.length === 0}
        <div class="text-center py-8 text-gray-500">
          <p class="text-sm">No repositories found</p>
          {#if searchQuery || selectedRepo}
            <p class="text-xs mt-1">Try adjusting your search or filters</p>
          {/if}
        </div>
      {:else}
        <div class="overflow-x-auto">
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Repository</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Runs</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Success Rate</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Avg Duration</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Last Activity</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Environments</th>
              </tr>
            </thead>
            <tbody class="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
              {#each filteredRepoAnalytics as repo}
                <tr class="hover:bg-gray-50 dark:hover:bg-gray-700">
                  <td class="px-6 py-4 whitespace-nowrap">
                    <div class="font-medium text-gray-900 dark:text-gray-100">{repo.name}</div>
                    {#if repo.topUsers.length > 0}
                      <div class="text-xs text-gray-500 dark:text-gray-400">Top users: {repo.topUsers.join(', ')}</div>
                    {/if}
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100">
                    {repo.totalRuns}
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <span class="text-sm font-medium {getSuccessRateColor(repo.successRate)}">
                      {repo.successRate.toFixed(1)}%
                    </span>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100">
                    {formatDuration(repo.avgDuration)}
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400">
                    {formatDate(repo.lastRun)}
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <div class="flex flex-wrap gap-1">
                      {#each repo.environments.slice(0, 3) as env}
                        <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-blue-100 dark:bg-blue-900/30 text-blue-800 dark:text-blue-200">
                          {env}
                        </span>
                      {/each}
                      {#if repo.environments.length > 3}
                        <span class="text-xs text-gray-400 dark:text-gray-500">+{repo.environments.length - 3} more</span>
                      {/if}
                    </div>
                  </td>
                </tr>
              {/each}
            </tbody>
          </table>
        </div>
      {/if}
    </Card>

  <!-- Workflow Performance Tab -->
  {:else if activeTab === 'workflow'}
    <!-- Performance Overview -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
      <Card padding="lg" class="text-center">
        <div class="text-3xl font-bold text-blue-600 dark:text-blue-400">{performanceMetrics.totalSteps}</div>
        <div class="text-sm text-blue-700 dark:text-blue-300 mt-1">Total Steps</div>
        <div class="text-xs text-gray-500 dark:text-gray-400 mt-1">Executed</div>
      </Card>
      
      <Card padding="lg" class="text-center">
        <div class="text-3xl font-bold {getSuccessRateColor(performanceMetrics.successRate)}">
          {performanceMetrics.successRate.toFixed(1)}%
        </div>
        <div class="text-sm text-gray-700 dark:text-gray-300 mt-1">Success Rate</div>
        <div class="text-xs text-gray-500 dark:text-gray-400 mt-1">Overall performance</div>
      </Card>
      
      <Card padding="lg" class="text-center">
        <div class="text-3xl font-bold text-purple-600 dark:text-purple-400">{formatDuration(performanceMetrics.avgDuration)}</div>
        <div class="text-sm text-purple-700 dark:text-purple-300 mt-1">Avg Duration</div>
        <div class="text-xs text-gray-500 dark:text-gray-400 mt-1">Per step</div>
      </Card>
      
      <Card padding="lg" class="text-center">
        <div class="text-3xl font-bold text-yellow-600 dark:text-yellow-400">
          {selectedStepType || selectedRepo ? filteredStepAnalytics.length : stepAnalytics.length}
        </div>
        <div class="text-sm text-yellow-700 dark:text-yellow-300 mt-1">
          {selectedStepType || selectedRepo ? 'Filtered' : ''} Step Types
        </div>
        <div class="text-xs text-gray-500 dark:text-gray-400 mt-1">In workflow</div>
      </Card>
    </div>

    <!-- Workflow Tab Controls -->
    <div class="mb-6">
      <Card padding="md">
        <div class="flex flex-wrap items-center gap-4">
          <!-- Step Type Filter -->
          <div class="flex items-center space-x-2">
            <label for="step-filter" class="text-sm font-medium text-gray-700 dark:text-gray-300">Step Type:</label>
            <select id="step-filter" bind:value={selectedStepType}
                    class="border-gray-300 dark:border-gray-600 rounded-md shadow-sm text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 focus:border-blue-500 focus:ring-blue-500">
              <option value="">All Steps</option>
              {#each uniqueStepTypes as stepType}
                <option value={stepType}>{stepType}</option>
              {/each}
            </select>
          </div>

          <!-- Failures Only -->
          <div class="flex items-center space-x-2">
            <input id="failures-only" type="checkbox" bind:checked={onlyShowFailures}
                   class="rounded border-gray-300 dark:border-gray-600 text-blue-600 dark:bg-gray-800 focus:ring-blue-500" />
            <label for="failures-only" class="text-sm font-medium text-gray-700 dark:text-gray-300">Show failures only</label>
          </div>
        </div>
      </Card>
    </div>

    <!-- Step Analytics -->
    <Card padding="lg">
      <div class="flex items-center justify-between mb-6">
        <div>
          <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100">Step-by-Step Analysis</h3>
          <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">Based on the most recent 100 runs from the selected time range</p>
        </div>
        {#if selectedStepType || selectedRepo}
          <div class="text-xs text-gray-600 dark:text-gray-400">
            {#if selectedRepo && !selectedStepType}
              Showing {filteredStepAnalytics.length} step types used by {selectedRepo}
            {:else if selectedStepType && !selectedRepo}
              Filtered to {selectedStepType} steps only
            {:else if selectedStepType && selectedRepo}
              Showing {selectedStepType} steps for {selectedRepo}
            {:else}
              Filtered: {filteredStepAnalytics.length} / {stepAnalytics.length} step types
            {/if}
          </div>
        {/if}
      </div>
      
      {#if filteredStepAnalytics.length === 0}
        <div class="text-center py-8 text-gray-500">
          <p class="text-sm">No workflow steps found for the selected criteria</p>
          {#if selectedStepType || selectedRepo}
            <p class="text-xs mt-1">Try adjusting your filters or selecting "All Steps" and "All Repositories"</p>
          {/if}
        </div>
      {:else}
        <div class="relative">
          <!-- Loading overlay for detailed data -->
          {#if loadingDetailedData}
            <div class="absolute inset-0 bg-white dark:bg-gray-800 bg-opacity-75 dark:bg-opacity-75 flex items-center justify-center z-10 rounded-md">
              <div class="text-center">
                <LoadingSpinner size="md" />
                <p class="text-sm text-gray-600 dark:text-gray-400 mt-2">Loading detailed workflow data...</p>
              </div>
            </div>
          {/if}
          
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {#each filteredStepAnalytics as analytics}
            <Card padding="md" class="bg-gray-50 dark:bg-gray-700">
              
              <!-- Step Header -->
              <div class="flex items-center justify-between mb-3">
                <div class="flex items-center gap-2">
                  <button
                    on:click={() => selectedStepType = getStepCategory(analytics.stepType)}
                    class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium border transition-colors hover:bg-opacity-80 {getStepCategoryColor(getStepCategory(analytics.stepType))}"
                    title="Filter to {getStepCategory(analytics.stepType)} steps"
                  >
                    {getStepCategory(analytics.stepType)}
                  </button>
                  <button 
                    on:click={() => selectedStepType = analytics.stepType}
                    class="font-medium text-gray-900 dark:text-gray-100 hover:text-blue-600 dark:hover:text-blue-400 transition-colors"
                    title="Filter to {analytics.stepType} steps only"
                  >
                    {analytics.stepType}
                  </button>
                </div>
                
                <!-- Expand/Collapse Button -->
                <button
                  on:click={() => expandedStepAnalytic = expandedStepAnalytic === analytics.stepType ? null : analytics.stepType}
                  class="text-gray-400 dark:text-gray-500 hover:text-gray-600 dark:hover:text-gray-300 transition-colors"
                  title={expandedStepAnalytic === analytics.stepType ? 'Collapse details' : 'Show detailed analysis'}
                >
                  {#if expandedStepAnalytic === analytics.stepType}
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 15l7-7 7 7" />
                    </svg>
                  {:else}
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                    </svg>
                  {/if}
                </button>
              </div>

              <!-- Metrics -->
              <div class="space-y-2">
                <div class="flex justify-between text-sm">
                  <span class="text-gray-600 dark:text-gray-400">Executions:</span>
                  <span class="font-medium">{analytics.totalExecutions}</span>
                </div>
                
                <div class="flex justify-between text-sm">
                  <span class="text-gray-600 dark:text-gray-400">Success Rate:</span>
                  <button 
                    on:click={() => {
                      selectedStepType = analytics.stepType;
                      onlyShowFailures = analytics.failureCount > 0;
                    }}
                    class="font-medium transition-colors hover:underline {getSuccessRateColor(analytics.successRate)}"
                    title={analytics.failureCount > 0 ? `View ${analytics.failureCount} failed ${analytics.stepType} executions` : 'No failures to show'}
                    disabled={analytics.failureCount === 0}
                  >
                    {analytics.successRate.toFixed(1)}%
                  </button>
                </div>
                
                <div class="flex justify-between text-sm">
                  <span class="text-gray-600 dark:text-gray-400">Avg Duration:</span>
                  <span class="font-medium">{formatDuration(analytics.avgDuration)}</span>
                </div>
                
                <div class="flex justify-between text-sm">
                  <span class="text-gray-600 dark:text-gray-400">Repositories:</span>
                  <span class="font-medium">{analytics.repositories.size}</span>
                </div>
                
                <div class="flex justify-between text-sm">
                  <span class="text-gray-600 dark:text-gray-400">Last Executed:</span>
                  <span class="text-xs text-gray-500 dark:text-gray-400">{formatDate(analytics.lastExecuted)}</span>
                </div>
              </div>

              <!-- Expandable Details Section -->
              {#if expandedStepAnalytic === analytics.stepType}
                <div class="mt-4 pt-4 border-t border-gray-200 dark:border-gray-600 space-y-3">
                  
                  <!-- Performance Details -->
                  <div class="bg-white dark:bg-gray-800 rounded-md p-3">
                    <h5 class="text-xs font-medium text-gray-700 dark:text-gray-300 mb-2">Performance Details</h5>
                    <div class="grid grid-cols-2 gap-2 text-xs">
                      <div class="flex justify-between">
                        <span class="text-gray-600 dark:text-gray-400">Min Duration:</span>
                        <span class="font-mono">{formatDuration(analytics.minDuration)}</span>
                      </div>
                      <div class="flex justify-between">
                        <span class="text-gray-600 dark:text-gray-400">Max Duration:</span>
                        <span class="font-mono">{formatDuration(analytics.maxDuration)}</span>
                      </div>
                      <div class="flex justify-between">
                        <span class="text-gray-600 dark:text-gray-400">Success Count:</span>
                        <span class="text-green-600 dark:text-green-400 font-medium">{analytics.successCount}</span>
                      </div>
                      <div class="flex justify-between">
                        <span class="text-gray-600 dark:text-gray-400">Failure Count:</span>
                        <span class="text-red-600 dark:text-red-400 font-medium">{analytics.failureCount}</span>
                      </div>
                    </div>
                  </div>

                  <!-- Repository Usage -->
                  <div class="bg-white dark:bg-gray-800 rounded-md p-3">
                    <h5 class="text-xs font-medium text-gray-700 dark:text-gray-300 mb-2">Repository Usage</h5>
                    <div class="flex flex-wrap gap-1">
                      {#each Array.from(analytics.repositories).slice(0, 5) as repo}
                        <button
                          on:click={() => selectedRepo = repo}
                          class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-blue-100 dark:bg-blue-900/30 text-blue-800 dark:text-blue-200 hover:bg-blue-200 dark:hover:bg-blue-900/50 transition-colors"
                          title="Filter to {repo} repository"
                        >
                          {repo}
                        </button>
                      {/each}
                      {#if analytics.repositories.size > 5}
                        <span class="text-xs text-gray-500 dark:text-gray-400 px-2 py-1">+{analytics.repositories.size - 5} more</span>
                      {/if}
                    </div>
                  </div>

                  <!-- Recent Executions -->
                  <div class="bg-white dark:bg-gray-800 rounded-md p-3">
                    <div class="flex items-center justify-between mb-2">
                      <h5 class="text-xs font-medium text-gray-700 dark:text-gray-300">Recent Executions</h5>
                      <button
                        on:click={() => selectedStepType = analytics.stepType}
                        class="text-xs text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 transition-colors"
                        title="View all {analytics.stepType} executions"
                      >
                        View All →
                      </button>
                    </div>
                    <div class="space-y-1">
                      {#each filteredSteps.filter(s => s.step === analytics.stepType).slice(0, 3) as execution}
                        <div class="flex items-center justify-between py-1">
                          <div class="flex items-center gap-2">
                            <span class="w-2 h-2 rounded-full {execution.success ? 'bg-green-400' : 'bg-red-400'}"></span>
                            <button
                              on:click={() => selectedRepo = execution.repository || ''}
                              class="text-xs font-medium text-gray-900 dark:text-gray-100 hover:text-blue-600 dark:hover:text-blue-400 transition-colors"
                              title="Filter to {execution.repository}"
                            >
                              {execution.repository}
                            </button>
                          </div>
                          <div class="flex items-center gap-2">
                            {#if execution.workManifestId}
                              <button
                                on:click={() => execution.workManifestId && navigateToRun(execution.workManifestId)}
                                class="text-xs text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 transition-colors"
                                title="View run details"
                              >
                                Details →
                              </button>
                            {/if}
                            <span class="text-xs text-gray-500 dark:text-gray-400">{formatDuration(execution.duration || 0)}</span>
                          </div>
                        </div>
                      {/each}
                    </div>
                  </div>
                </div>
              {/if}
            </Card>
          {/each}
          </div>
        </div>
      {/if}
    </Card>

    <!-- Recent Workflow Steps -->
    <div class="mt-8">
      <Card padding="lg">
        <div class="flex items-center justify-between mb-4">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100">Recent Workflow Steps</h3>
          {#if selectedStepType || selectedRepo || onlyShowFailures}
            <div class="text-xs text-gray-600 dark:text-gray-400">
              Filtered: {filteredSteps.length} / {workflowSteps.length} steps
            </div>
          {/if}
        </div>
        
        {#if filteredSteps.length === 0}
          <div class="text-center py-8 text-gray-500 dark:text-gray-400">
            <p class="text-sm">No workflow steps found</p>
            {#if selectedStepType || selectedRepo || onlyShowFailures}
              <p class="text-xs mt-1">Try adjusting your filters</p>
            {/if}
          </div>
        {:else}
          <div class="space-y-3 max-h-96 overflow-y-auto">
            {#each filteredSteps.slice(0, 50) as step}
              <div class="bg-gray-50 dark:bg-gray-700 rounded-md">
                <div class="flex items-center justify-between p-3">
                  <div class="flex-1 min-w-0">
                    <div class="flex items-center gap-2 mb-1">
                      <button
                        on:click={() => selectedStepType = step.step}
                        class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium border transition-colors hover:bg-opacity-80 {getStepCategoryColor(getStepCategory(step.step))}"
                        title="Filter to {step.step} steps"
                      >
                        {step.step}
                      </button>
                      <button 
                        on:click={() => selectedRepo = step.repository || ''}
                        class="text-sm font-medium text-gray-900 dark:text-gray-100 hover:text-blue-600 dark:hover:text-blue-400 transition-colors"
                        title="Filter to {step.repository} repository"
                      >
                        {step.repository}
                      </button>
                      <button
                        on:click={() => {
                          if (!step.success) {
                            selectedStepType = step.step;
                            onlyShowFailures = true;
                          }
                        }}
                        class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium transition-colors {
                          step.success 
                            ? 'bg-green-100 dark:bg-green-900/30 text-green-800 dark:text-green-300 cursor-default' 
                            : 'bg-red-100 dark:bg-red-900/30 text-red-800 dark:text-red-300 hover:bg-red-200 dark:hover:bg-red-900/50 cursor-pointer'
                        }"
                        title={step.success ? 'Successful execution' : `Filter to failed ${step.step} steps`}
                        disabled={step.success}
                      >
                        {step.success ? 'Success' : 'Failed'}
                      </button>
                    </div>
                    <div class="text-xs text-gray-500 dark:text-gray-400">
                      {formatDate(step.created_at)}
                      {#if step.duration}
                        • {formatDuration(step.duration)}
                      {/if}
                      {#if step.scope.dir}
                        • {step.scope.dir}
                      {/if}
                      {#if step.scope.workspace}
                        • {step.scope.workspace}
                      {/if}
                    </div>
                  </div>
                  
                  <!-- Expand/Collapse Button for Workflow Steps -->
                  <button
                    on:click={() => expandedWorkflowStep = expandedWorkflowStep === `${step.workManifestId}-${step.step}-${step.idx}` ? null : `${step.workManifestId}-${step.step}-${step.idx}`}
                    class="text-gray-400 dark:text-gray-500 hover:text-gray-600 dark:hover:text-gray-300 transition-colors ml-2"
                    title={expandedWorkflowStep === `${step.workManifestId}-${step.step}-${step.idx}` ? 'Collapse details' : 'Show step details'}
                  >
                    {#if expandedWorkflowStep === `${step.workManifestId}-${step.step}-${step.idx}`}
                      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 15l7-7 7 7" />
                      </svg>
                    {:else}
                      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                      </svg>
                    {/if}
                  </button>
                </div>

                <!-- Expandable Step Details -->
                {#if expandedWorkflowStep === `${step.workManifestId}-${step.step}-${step.idx}`}
                  <div class="px-3 pb-3 border-t border-gray-200 dark:border-gray-600 bg-white dark:bg-gray-800 rounded-b-md">
                    <div class="pt-3 space-y-3">
                      
                      <!-- Step Execution Details -->
                      <div class="bg-gray-50 dark:bg-gray-700 rounded-md p-3">
                        <h6 class="text-xs font-medium text-gray-700 dark:text-gray-300 mb-2">Execution Details</h6>
                        <div class="grid grid-cols-2 gap-2 text-xs">
                          <div class="flex justify-between">
                            <span class="text-gray-600 dark:text-gray-400">Step Index:</span>
                            <span class="font-mono">#{step.idx}</span>
                          </div>
                          <div class="flex justify-between">
                            <span class="text-gray-600 dark:text-gray-400">State:</span>
                            <span class="font-medium {step.success ? 'text-green-600 dark:text-green-400' : 'text-red-600 dark:text-red-400'}">{step.state}</span>
                          </div>
                          <div class="flex justify-between">
                            <span class="text-gray-600 dark:text-gray-400">Ignore Errors:</span>
                            <span class="font-medium {step.ignore_errors ? 'text-yellow-600 dark:text-yellow-400' : 'text-gray-600 dark:text-gray-400'}">{step.ignore_errors ? 'Yes' : 'No'}</span>
                          </div>
                          {#if step.duration}
                            <div class="flex justify-between">
                              <span class="text-gray-600 dark:text-gray-400">Duration:</span>
                              <span class="font-mono">{formatDuration(step.duration)}</span>
                            </div>
                          {/if}
                        </div>
                      </div>

                      <!-- Scope Information -->
                      {#if step.scope && (step.scope.dir || step.scope.workspace || step.scope.type)}
                        <div class="bg-gray-50 dark:bg-gray-700 rounded-md p-3">
                          <h6 class="text-xs font-medium text-gray-700 dark:text-gray-300 mb-2">Scope Information</h6>
                          <div class="space-y-1 text-xs">
                            {#if step.scope.dir}
                              <div class="flex justify-between">
                                <span class="text-gray-600 dark:text-gray-400">Directory:</span>
                                <span class="font-mono text-gray-900 dark:text-gray-100">{step.scope.dir}</span>
                              </div>
                            {/if}
                            {#if step.scope.workspace}
                              <div class="flex justify-between">
                                <span class="text-gray-600 dark:text-gray-400">Workspace:</span>
                                <span class="font-mono text-gray-900 dark:text-gray-100">{step.scope.workspace}</span>
                              </div>
                            {/if}
                            {#if step.scope.type}
                              <div class="flex justify-between">
                                <span class="text-gray-600 dark:text-gray-400">Type:</span>
                                <span class="font-mono text-gray-900 dark:text-gray-100">{step.scope.type}</span>
                              </div>
                            {/if}
                          </div>
                        </div>
                      {/if}

                      <!-- Actions -->
                      <div class="flex items-center justify-between pt-2">
                        <div class="flex gap-2">
                          <button
                            on:click={() => {
                              selectedStepType = step.step;
                              selectedRepo = step.repository || '';
                            }}
                            class="text-xs text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 transition-colors"
                            title="Filter to this step type and repository"
                          >
                            🔍 Filter Similar
                          </button>
                          {#if !step.success}
                            <button
                              on:click={() => {
                                selectedStepType = step.step;
                                onlyShowFailures = true;
                              }}
                              class="text-xs text-red-600 dark:text-red-400 hover:text-red-800 dark:hover:text-red-300 transition-colors"
                              title="Show all failed {step.step} steps"
                            >
                              ❌ View Failures
                            </button>
                          {/if}
                        </div>
                        {#if step.workManifestId}
                          <button
                            on:click={() => step.workManifestId && navigateToRun(step.workManifestId)}
                            class="text-xs font-medium text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 transition-colors"
                            title="View full run details"
                          >
                            📋 View Run →
                          </button>
                        {/if}
                      </div>
                    </div>
                  </div>
                {/if}
              </div>
            {/each}
            {#if filteredSteps.length > 50}
              <div class="text-center py-2 text-xs text-gray-500">
                Showing first 50 of {filteredSteps.length} steps
              </div>
            {/if}
          </div>
        {/if}
      </Card>
    </div>

  <!-- Drift Detection Tab -->
  {:else if activeTab === 'drift'}
    <!-- Drift Overview Metrics -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
      <Card padding="lg" class="text-center">
        <div class="text-3xl font-bold text-blue-600">{driftMetrics.totalDrifts}</div>
        <div class="text-sm text-blue-700 mt-1">Drift Detections</div>
        <div class="text-xs text-gray-500 mt-1">Last 30 days</div>
      </Card>
      
      <Card padding="lg" class="text-center">
        <div class="text-3xl font-bold {driftMetrics.openDrifts > 0 ? 'text-red-600' : 'text-green-600'}">
          {driftMetrics.openDrifts}
        </div>
        <div class="text-sm text-gray-700 mt-1">Open Drifts</div>
        <div class="text-xs text-gray-500 mt-1">Requiring attention</div>
      </Card>
      
      <Card padding="lg" class="text-center">
        <div class="text-3xl font-bold text-purple-600">
          {formatDuration(driftMetrics.avgDriftResolutionTime)}
        </div>
        <div class="text-sm text-purple-700 mt-1">Avg Resolution</div>
        <div class="text-xs text-gray-500 mt-1">Time to complete</div>
      </Card>
      
      <Card padding="lg" class="text-center">
        <div class="text-lg font-bold text-yellow-600">
          {driftMetrics.mostDriftProneRepo || 'None'}
        </div>
        <div class="text-sm text-yellow-700 mt-1">Most Drift-Prone</div>
        <div class="text-xs text-gray-500 mt-1">Repository</div>
      </Card>
    </div>

    <!-- Drift Data Loading State or Error -->
    {#if isLoadingDrift}
      <div class="flex justify-center items-center py-12">
        <LoadingSpinner size="lg" />
        <span class="ml-3 text-gray-600">Loading drift detection data...</span>
      </div>
    {:else if driftError}
      <Card padding="lg" class="border-red-200 bg-red-50">
        <div class="text-center">
          <div class="text-red-800 mb-4">
            <svg class="w-12 h-12 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
            </svg>
            <p class="text-lg font-medium">Failed to Load Drift Data</p>
            <p class="text-sm mt-1">{driftError}</p>
          </div>
          <button 
            on:click={loadDriftOperations} 
            class="mt-4 px-4 py-2 bg-red-600 text-white rounded-md hover:bg-red-700"
          >
            Retry Loading
          </button>
        </div>
      </Card>
    {:else if driftOperations.length === 0}
      <Card padding="lg" class="border-gray-200 bg-gray-50">
        <div class="text-center py-8">
          <div class="text-gray-600 mb-4">
            <svg class="w-12 h-12 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <p class="text-lg font-medium">No Infrastructure Drift Detected</p>
            <p class="text-sm mt-1">Either no drift has been detected, or drift detection is not enabled</p>
          </div>
          <div class="text-gray-600 text-sm">
            <p>Infrastructure drift monitoring helps detect unauthorized changes to your Terraform-managed infrastructure.</p>
            <p class="mt-2">Consider enabling drift detection in your repositories to monitor infrastructure compliance.</p>
          </div>
        </div>
      </Card>
    {:else}
      
      <!-- Drift Detection Timeline -->
      <Card padding="lg" class="mb-8">
        <div class="flex items-center justify-between mb-6">
          <div>
            <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100">Recent Drift Detections</h3>
            <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">Based on the most recent 100 drift operations</p>
          </div>
          <div class="text-xs text-gray-600 dark:text-gray-400">
            Showing {Math.min(20, driftOperations.length)} of {driftOperations.length} drift operations
          </div>
        </div>
        
        <div class="space-y-4 max-h-96 overflow-y-auto">
          {#each driftOperations.slice(0, 20) as drift}
            <div class="bg-gray-50 dark:bg-gray-700 rounded-md">
              <div class="flex items-center justify-between p-4">
                <div class="flex-1 min-w-0">
                  <div class="flex items-center gap-3 mb-2">
                    <span class="w-3 h-3 rounded-full {
                      drift.state === 'success' ? 'bg-green-400' :
                      drift.state === 'failure' ? 'bg-red-400' :
                      drift.state === 'running' ? 'bg-blue-400' :
                      drift.state === 'queued' ? 'bg-yellow-400' :
                      'bg-gray-400'
                    }"></span>
                    <span class="font-medium text-gray-900 dark:text-gray-100">{drift.repo}</span>
                    <span class="text-sm text-gray-700 dark:text-gray-300">/{drift.dir}</span>
                    {#if drift.workspace && drift.workspace !== 'default'}
                      <span class="text-sm text-gray-700 dark:text-gray-300">:{drift.workspace}</span>
                    {/if}
                    <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium {
                      drift.state === 'success' ? 'bg-green-100 dark:bg-green-900/30 text-green-800 dark:text-green-200' :
                      drift.state === 'failure' ? 'bg-red-100 dark:bg-red-900/30 text-red-800 dark:text-red-200' :
                      drift.state === 'running' ? 'bg-blue-100 dark:bg-blue-900/30 text-blue-800 dark:text-blue-200' :
                      drift.state === 'queued' ? 'bg-yellow-100 dark:bg-yellow-900/30 text-yellow-800 dark:text-yellow-200' :
                      'bg-gray-100 dark:bg-gray-800 text-gray-800 dark:text-gray-200'
                    }">
                      {drift.state}
                    </span>
                    {#if drift.environment}
                      <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-purple-100 dark:bg-purple-900/30 text-purple-800 dark:text-purple-200">
                        {drift.environment}
                      </span>
                    {/if}
                  </div>
                  <div class="text-sm text-gray-600 dark:text-gray-400">
                    <span>Owner: {drift.owner || 'Unknown'}</span>
                    <span class="mx-2">•</span>
                    <span>Created: {formatDate(drift.created_at)}</span>
                    {#if drift.completed_at}
                      <span class="mx-2">•</span>
                      <span>Completed: {formatDate(drift.completed_at)}</span>
                    {/if}
                    <span class="mx-2">•</span>
                    <span>Branch: {drift.branch || 'unknown'}</span>
                  </div>
                </div>
                
                <!-- Expand/Collapse Button for Drift Items -->
                <button
                  on:click={() => expandedDriftItem = expandedDriftItem === drift.id ? null : drift.id}
                  class="text-gray-400 dark:text-gray-500 hover:text-gray-600 dark:hover:text-gray-400 transition-colors ml-4"
                  title={expandedDriftItem === drift.id ? 'Collapse details' : 'Show drift details'}
                >
                  {#if expandedDriftItem === drift.id}
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 15l7-7 7 7" />
                    </svg>
                  {:else}
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                    </svg>
                  {/if}
                </button>
              </div>

              <!-- Expandable Drift Details -->
              {#if expandedDriftItem === drift.id}
                <div class="px-4 pb-4 border-t border-gray-200 dark:border-gray-600 bg-white dark:bg-gray-800 rounded-b-md">
                  <div class="pt-4 space-y-3">
                    
                    <!-- Drift Analysis Details -->
                    <div class="bg-gray-50 dark:bg-gray-700 rounded-md p-3">
                      <h6 class="text-xs font-medium text-gray-700 dark:text-gray-300 mb-2">Drift Detection Details</h6>
                      <div class="grid grid-cols-2 gap-2 text-xs">
                        <div class="flex justify-between">
                          <span class="text-gray-600 dark:text-gray-400">Detection ID:</span>
                          <span class="font-mono">{drift.id}</span>
                        </div>
                        <div class="flex justify-between">
                          <span class="text-gray-600 dark:text-gray-400">State:</span>
                          <span class="font-medium {
                            drift.state === 'success' ? 'text-green-600 dark:text-green-400' :
                            drift.state === 'failure' ? 'text-red-600 dark:text-red-400' :
                            drift.state === 'running' ? 'text-blue-600 dark:text-blue-400' :
                            'text-yellow-600 dark:text-yellow-400'
                          }">{drift.state}</span>
                        </div>
                        <div class="flex justify-between">
                          <span class="text-gray-600 dark:text-gray-400">Run Type:</span>
                          <span class="font-medium text-gray-900 dark:text-gray-100">{drift.run_type || 'drift'}</span>
                        </div>
                        <div class="flex justify-between">
                          <span class="text-gray-600 dark:text-gray-400">Run ID:</span>
                          <span class="font-mono text-gray-900 dark:text-gray-100">{drift.run_id || 'N/A'}</span>
                        </div>
                      </div>
                    </div>

                    <!-- Infrastructure Context -->
                    <div class="bg-gray-50 dark:bg-gray-700 rounded-md p-3">
                      <h6 class="text-xs font-medium text-gray-700 dark:text-gray-300 mb-2">Infrastructure Context</h6>
                      <div class="space-y-1 text-xs">
                        <div class="flex justify-between">
                          <span class="text-gray-600 dark:text-gray-400">Repository:</span>
                          <span class="font-mono text-gray-900 dark:text-gray-100">{drift.repo}</span>
                        </div>
                        <div class="flex justify-between">
                          <span class="text-gray-600 dark:text-gray-400">Directory:</span>
                          <span class="font-mono text-gray-900 dark:text-gray-100">{drift.dir}</span>
                        </div>
                        <div class="flex justify-between">
                          <span class="text-gray-600 dark:text-gray-400">Workspace:</span>
                          <span class="font-mono text-gray-900 dark:text-gray-100">{drift.workspace || 'default'}</span>
                        </div>
                        {#if drift.environment}
                          <div class="flex justify-between">
                            <span class="text-gray-600 dark:text-gray-400">Environment:</span>
                            <span class="font-mono text-gray-900 dark:text-gray-100">{drift.environment}</span>
                          </div>
                        {/if}
                        <div class="flex justify-between">
                          <span class="text-gray-600 dark:text-gray-400">Branch:</span>
                          <span class="font-mono text-gray-900 dark:text-gray-100">{drift.branch || 'unknown'}</span>
                        </div>
                      </div>
                    </div>

                    <!-- Timing Information -->
                    <div class="bg-gray-50 dark:bg-gray-700 rounded-md p-3">
                      <h6 class="text-xs font-medium text-gray-700 dark:text-gray-300 mb-2">Timing Information</h6>
                      <div class="space-y-1 text-xs">
                        <div class="flex justify-between">
                          <span class="text-gray-600 dark:text-gray-400">Started:</span>
                          <span class="font-mono text-gray-900 dark:text-gray-100">{formatDate(drift.created_at)}</span>
                        </div>
                        {#if drift.completed_at}
                          <div class="flex justify-between">
                            <span class="text-gray-600 dark:text-gray-400">Completed:</span>
                            <span class="font-mono text-gray-900 dark:text-gray-100">{formatDate(drift.completed_at)}</span>
                          </div>
                          <div class="flex justify-between">
                            <span class="text-gray-600 dark:text-gray-400">Duration:</span>
                            <span class="font-mono text-gray-900 dark:text-gray-100">
                              {formatDuration(new Date(drift.completed_at).getTime() - new Date(drift.created_at).getTime())}
                            </span>
                          </div>
                        {:else}
                          <div class="flex justify-between">
                            <span class="text-gray-600 dark:text-gray-400">Status:</span>
                            <span class="font-medium text-blue-600 dark:text-blue-400">In Progress</span>
                          </div>
                        {/if}
                      </div>
                    </div>

                    <!-- Actions -->
                    <div class="flex items-center justify-between pt-2">
                      <div class="flex gap-2">
                        <button
                          on:click={() => {
                            selectedRepo = drift.repo;
                            activeTab = 'repository';
                          }}
                          class="text-xs text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 transition-colors"
                          title="View repository analytics for {drift.repo}"
                        >
                          📊 Repository Analytics
                        </button>
                        <button
                          on:click={() => {
                            selectedRepo = drift.repo;
                            activeTab = 'workflow';
                          }}
                          class="text-xs text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 transition-colors"
                          title="View workflow analytics for {drift.repo}"
                        >
                          ⚙️ Workflow Analytics
                        </button>
                        {#if drift.state === 'failure'}
                          <span class="text-xs text-red-600 dark:text-red-400">
                            ❌ Investigation Required
                          </span>
                        {/if}
                      </div>
                      <div class="flex gap-2">
                        <button
                          on:click={() => {
                            navigateToRuns(`repo:${encodeURIComponent(drift.repo)} and kind:drift`);
                          }}
                          class="text-xs font-medium text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 transition-colors"
                          title="View all drift runs for this repository"
                        >
                          🔍 View All Drifts →
                        </button>
                        <button
                          on:click={() => {
                            navigateToRun(drift.id);
                          }}
                          class="text-xs font-medium text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 transition-colors"
                          title="View this drift detection details"
                        >
                          📋 Drift Details →
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              {/if}
            </div>
          {/each}
        </div>
      </Card>
    {/if}
  {/if}
</PageLayout>
