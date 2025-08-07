<script lang="ts">
  // Auth handled by PageLayout
  import { api } from './api';
  import { selectedInstallation, installations, installationsLoading, currentVCSProvider } from './stores';
  
  export let params: { installationId?: string } = {};
  import { analytics } from './analytics';
  import PageLayout from './components/layout/PageLayout.svelte';
  import Card from './components/ui/Card.svelte';
  import ClickableCard from './components/ui/ClickableCard.svelte';
  import { navigateToRun, navigateToRuns, navigateToWorkspaces } from './utils/navigation';
  import LoadingSpinner from './components/ui/LoadingSpinner.svelte';
  import type { Dirspace } from './types';
  import { VCS_PROVIDERS } from './vcs/providers';
  
  // Get current VCS provider terminology
  $: currentProvider = $currentVCSProvider || 'github';
  $: terminology = VCS_PROVIDERS[currentProvider]?.terminology || VCS_PROVIDERS.github.terminology;
  
  let isLoadingStats = false;
  let statsError: string | null = null;
  
  // Statistics data
  let stats = {
    failed24h: 0,
    successful24h: 0,
    running: 0,
    total7d: 0,
    workspaces24h: 0,
    prodSuccessRate: 0,
    plans: 0,
    applies: 0,
    conversionRate: 0,
    avgDuration: 0,
    topUsers: [] as Array<{ name: string; count: number }>,
    environments: [] as Array<{ name: string; successRate: number; total: number }>,
  };

  // Recent activity data
  let recentActivity: Dirspace[] = [];
  let isLoadingActivity = false;
  let activityError: string | null = null;

  // Auto-select installation if provided in URL
  $: if (params.installationId && $installations && $installations.length > 0) {
    const targetInstallation = $installations.find(inst => inst.id === params.installationId);
    if (targetInstallation && (!$selectedInstallation || $selectedInstallation.id !== targetInstallation.id)) {
      selectedInstallation.set(targetInstallation);
    }
  }

  // Load stats when installation changes
  let lastInstallationId: string | null = null;
  $: if ($selectedInstallation && $selectedInstallation.id !== lastInstallationId) {
    lastInstallationId = $selectedInstallation.id;
    loadDashboardStats();
    loadRecentActivity();
    
    // Track dashboard view
    analytics.trackPageView('dashboard', {
      installation_id: $selectedInstallation.id,
      installation_name: $selectedInstallation.name
    });
  }

  async function loadDashboardStats(): Promise<void> {
    if (!$selectedInstallation) return;
    
    isLoadingStats = true;
    statsError = null;
    
    try {
      const now = new Date();
      const yesterday = new Date(now.getTime() - 24 * 60 * 60 * 1000);
      const lastWeek = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
      
      const dateFilter24h = yesterday.toISOString().split('T')[0];
      const dateFilterWeek = lastWeek.toISOString().split('T')[0];
      
      // Load parallel data for dashboard stats
      const [recent24h, recentWeek, currentRunning] = await Promise.all([
        // Last 24 hours data
        api.getInstallationDirspaces($selectedInstallation.id, {
          q: `created_at:${dateFilter24h}..`,
          limit: 500
        }),
        // Last week data for workspace analysis
        api.getInstallationDirspaces($selectedInstallation.id, {
          q: `created_at:${dateFilterWeek}..`,
          limit: 1000
        }),
        // Currently running operations
        api.getInstallationDirspaces($selectedInstallation.id, {
          q: 'state:running',
          limit: 100
        }),
      ]);

      // Calculate 24h stats
      const dirspaces24h = recent24h?.dirspaces || [];
      stats.failed24h = dirspaces24h.filter(d => d.state === 'failure').length;
      stats.successful24h = dirspaces24h.filter(d => d.state === 'success').length;
      
      // Count unique workspaces (dir:workspace combinations) in last 24h
      const uniqueWorkspaces = new Set(dirspaces24h.map(d => `${d.dir}:${d.workspace}`));
      stats.workspaces24h = uniqueWorkspaces.size;
      
      // Count running operations
      stats.running = currentRunning?.dirspaces?.length || 0;
      
      // Count total operations in last 7 days
      const weekData = recentWeek?.dirspaces || [];
      stats.total7d = weekData.length;
      
      // Calculate plan vs apply ratios
      stats.plans = weekData.filter(d => d.run_type === 'plan').length;
      stats.applies = weekData.filter(d => d.run_type === 'apply').length;
      stats.conversionRate = stats.plans > 0 ? (stats.applies / stats.plans) * 100 : 0;
      
      // Calculate environment success rates
      const envStats: Record<string, { success: number; total: number }> = {};
      weekData.forEach(d => {
        const env = d.environment || 'default';
        if (!envStats[env]) {
          envStats[env] = { success: 0, total: 0 };
        }
        envStats[env].total += 1;
        if (d.state === 'success') {
          envStats[env].success += 1;
        }
      });
      
      stats.environments = Object.entries(envStats)
        .map(([name, data]) => ({
          name,
          successRate: data.total > 0 ? (data.success / data.total) * 100 : 0,
          total: data.total
        }))
        .sort((a, b) => b.total - a.total)
        .slice(0, 3);
      
      // Production success rate (special case)
      const prodEnv = envStats['production'] || envStats['prod'];
      stats.prodSuccessRate = prodEnv ? (prodEnv.success / prodEnv.total) * 100 : 0;
      
      // Calculate top users
      const userCounts: Record<string, number> = {};
      weekData.forEach(d => {
        if (d.user) {
          userCounts[d.user] = (userCounts[d.user] || 0) + 1;
        }
      });
      
      stats.topUsers = Object.entries(userCounts)
        .sort(([,a], [,b]) => b - a)
        .slice(0, 3)
        .map(([name, count]) => ({ name, count }));
      
      // Calculate average run duration
      const completedOps = weekData.filter(d => d.completed_at && d.created_at);
      if (completedOps.length > 0) {
        const totalDuration = completedOps.reduce((sum, d) => {
          const start = new Date(d.created_at).getTime();
          const end = new Date(d.completed_at!).getTime();
          return sum + (end - start);
        }, 0);
        stats.avgDuration = Math.round(totalDuration / completedOps.length / 1000 / 60); // minutes
      } else {
        stats.avgDuration = 0;
      }

    } catch (err) {
      console.error('Error loading dashboard stats:', err);
      statsError = err instanceof Error ? err.message : 'Failed to load dashboard statistics';
    } finally {
      isLoadingStats = false;
    }
  }

  async function loadRecentActivity(): Promise<void> {
    if (!$selectedInstallation) return;
    
    isLoadingActivity = true;
    activityError = null;
    
    try {
      const params = { 
        tz: Intl.DateTimeFormat().resolvedOptions().timeZone,
        limit: 10, // Just show last 10 operations
        d: 'desc' // Most recent first
      };
      
      const response = await api.getInstallationDirspaces($selectedInstallation.id, params);
      
      if (response && 'dirspaces' in response) {
        recentActivity = response.dirspaces as Dirspace[];
      } else {
        recentActivity = [];
      }
      
    } catch (err) {
      console.error('Error loading recent activity:', err);
      activityError = err instanceof Error ? err.message : 'Failed to load recent activity';
      recentActivity = [];
    } finally {
      isLoadingActivity = false;
    }
  }

  function formatRelativeTime(dateString: string): string {
    const date = new Date(dateString);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffMins = Math.floor(diffMs / (1000 * 60));
    const diffHours = Math.floor(diffMs / (1000 * 60 * 60));
    const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));
    
    if (diffMins < 1) {
      return 'Just now';
    } else if (diffMins < 60) {
      return `${diffMins}m ago`;
    } else if (diffHours < 24) {
      return `${diffHours}h ago`;
    } else {
      return `${diffDays}d ago`;
    }
  }

  function getStateColor(state: string): string {
    switch (state) {
      case 'success': return 'bg-green-100 dark:bg-green-900/30 text-green-800 dark:text-green-400 border-green-200 dark:border-green-700';
      case 'failure': return 'bg-red-100 dark:bg-red-900/30 text-red-800 dark:text-red-400 border-red-200 dark:border-red-700';
      case 'running': return 'bg-blue-100 dark:bg-blue-900/30 text-blue-800 dark:text-blue-400 border-blue-200 dark:border-blue-700';
      case 'queued': return 'bg-yellow-100 dark:bg-yellow-900/30 text-yellow-800 dark:text-yellow-400 border-yellow-200 dark:border-yellow-700';
      case 'aborted': return 'bg-gray-100 dark:bg-gray-700 text-gray-800 dark:text-gray-300 border-gray-200 dark:border-gray-600';
      default: return 'bg-gray-100 dark:bg-gray-700 text-gray-800 dark:text-gray-300 border-gray-200 dark:border-gray-600';
    }
  }

  function getStateIcon(state: string): string {
    switch (state) {
      case 'success': return '✅';
      case 'failure': return '❌';
      case 'running': return '🔄';
      case 'queued': return '⏳';
      case 'aborted': return '⏹️';
      default: return '❓';
    }
  }

  function getTypeIcon(type: string): string {
    switch (type) {
      case 'plan': return '📋';
      case 'apply': return '🚀';
      case 'index': return '📑';
      default: return '📄';
    }
  }

  function getTypeColor(type: string): string {
    switch (type) {
      case 'plan': return 'bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-400 border-blue-200 dark:border-blue-700';
      case 'apply': return 'bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-400 border-green-200 dark:border-green-700';
      case 'index': return 'bg-purple-100 dark:bg-purple-900/30 text-purple-700 dark:text-purple-400 border-purple-200 dark:border-purple-700';
      default: return 'bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 border-gray-200 dark:border-gray-600';
    }
  }

  function navigateToDetail(operationId: string): void {
    navigateToRun(operationId);
  }

</script>

<PageLayout activeItem="dashboard" title="Dashboard" subtitle="Overview of your Terraform infrastructure">
  <!-- Welcome Section -->
  <div class="mb-8">
    <Card padding="lg" class="bg-gradient-to-r from-blue-50 to-blue-100 dark:from-blue-900/20 dark:to-blue-800/20 border-blue-200 dark:border-blue-700">
      <div class="flex flex-col md:flex-row md:items-start md:justify-between">
        <div class="flex-1">
          <h2 class="text-xl md:text-2xl font-bold text-gray-900 dark:text-gray-100 mb-2">Welcome to Terrateam</h2>
          <p class="text-sm md:text-base text-gray-700 dark:text-gray-300 mb-4">
            New to Terrateam? Check out our getting started guide to learn the basics and set up your first workspace.
          </p>
          <ClickableCard 
            padding="sm"
            hover={true}
            on:click={() => window.location.hash = '#/getting-started'}
            aria-label="Open getting started guide"
            class="inline-block bg-white dark:bg-blue-800/30 border-blue-300 dark:border-blue-600 hover:border-blue-400 dark:hover:border-blue-500"
          >
            <div class="flex items-center space-x-2 text-blue-700 dark:text-blue-300">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.746 0 3.332.477 4.5 1.253v13C19.832 18.477 18.246 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
              </svg>
              <span class="font-medium">Getting Started Guide</span>
            </div>
          </ClickableCard>
        </div>
        <img src="/assets/images/logo-symbol.svg" alt="Infrastructure Orchestration" class="hidden md:block w-56 h-56 opacity-30" />
      </div>
    </Card>
  </div>

  {#if $installationsLoading}
    <div class="flex justify-center items-center py-12 mb-8">
      <LoadingSpinner size="lg" />
      <span class="ml-3 text-gray-600 dark:text-gray-400">Loading {terminology.organizations.toLowerCase()}...</span>
    </div>
  {:else if !$selectedInstallation}
    <!-- Demo Mode Message -->
    <Card padding="lg" class="mb-8 border-blue-200 bg-blue-50 dark:bg-blue-900/20 dark:border-blue-800">
      <div class="text-center">
        <div class="flex justify-center mb-4">
          <svg class="w-12 h-12 text-blue-500 dark:text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        </div>
        <h3 class="text-xl font-semibold text-blue-800 dark:text-blue-200 mb-2">Demo Mode</h3>
        <p class="text-blue-700 dark:text-blue-300 mb-4">
          You're viewing the dashboard in demo mode. Once you connect a {VCS_PROVIDERS[currentProvider].displayName} {terminology.organization.toLowerCase()}, you'll see real run statistics and activity here.
        </p>
        <div class="space-y-3">
          <div class="text-sm text-blue-600 dark:text-blue-400 bg-white dark:bg-blue-800/30 rounded-lg p-3 border border-blue-200 dark:border-blue-700">
            <strong>What you'll see here:</strong> Run success rates, recent activity, running operations, and workspace statistics
          </div>
        </div>
      </div>
    </Card>
  {:else if isLoadingStats}
    <div class="flex justify-center items-center py-12 mb-8">
      <LoadingSpinner size="lg" />
      <span class="ml-3 text-gray-600 dark:text-gray-400">Loading dashboard statistics...</span>
    </div>
  {:else if statsError}
    <Card padding="lg" class="mb-8 border-amber-200 dark:border-amber-700 bg-amber-50 dark:bg-amber-900/20">
      <div class="flex items-center space-x-2 text-amber-800 dark:text-amber-400">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
        </svg>
        <span>Unable to load some dashboard statistics: {statsError}</span>
      </div>
    </Card>
  {:else}
    <!-- Core Statistics Overview -->
    <div class="grid grid-cols-2 md:grid-cols-4 gap-2 md:gap-4 mb-8">
      <ClickableCard 
        padding="md" 
        hover={true}
        on:click={() => navigateToRuns('state:failure')}
        aria-label="View failed runs from last 24 hours"
        class="text-center"
      >
        <div class="text-2xl md:text-3xl font-bold text-red-600 dark:text-red-400">{stats.failed24h}</div>
        <div class="text-xs md:text-sm text-gray-600 dark:text-gray-400 mt-1">Failed Runs</div>
        <div class="text-xs text-gray-500 dark:text-gray-400">Last 24 hours</div>
      </ClickableCard>
      
      <ClickableCard 
        padding="md" 
        hover={true}
        on:click={() => navigateToRuns('state:success')}
        aria-label="View successful runs from last 24 hours"
        class="text-center"
      >
        <div class="text-2xl md:text-3xl font-bold text-green-600 dark:text-green-400">{stats.successful24h}</div>
        <div class="text-xs md:text-sm text-gray-600 dark:text-gray-400 mt-1">Successful Runs</div>
        <div class="text-xs text-gray-500 dark:text-gray-400">Last 24 hours</div>
      </ClickableCard>
      
      <ClickableCard 
        padding="md" 
        hover={true}
        on:click={() => navigateToRuns('state:running')}
        aria-label="View currently running operations"
        class="text-center"
      >
        <div class="text-2xl md:text-3xl font-bold text-orange-600 dark:text-orange-400">{stats.running}</div>
        <div class="text-xs md:text-sm text-gray-600 dark:text-gray-400 mt-1">Running Operations</div>
        <div class="text-xs text-gray-500 dark:text-gray-400">Currently active</div>
      </ClickableCard>
      
      <ClickableCard 
        padding="md" 
        hover={true}
        on:click={() => {
          const weekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
          navigateToRuns(`created_at:${weekAgo}..`);
        }}
        aria-label="View all runs from last 7 days"
        class="text-center"
      >
        <div class="text-2xl md:text-3xl font-bold text-blue-600 dark:text-blue-400">{stats.total7d}</div>
        <div class="text-xs md:text-sm text-gray-600 dark:text-gray-400 mt-1">Total Operations</div>
        <div class="text-xs text-gray-500 dark:text-gray-400">Last 7 days</div>
      </ClickableCard>
    </div>

    <!-- Enhanced Insights -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
      
      <ClickableCard 
        padding="md" 
        hover={true}
        on:click={() => {
          const weekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
          navigateToRuns(`created_at:${weekAgo}.. and type:plan`);
        }}
        aria-label="View plan operations from last 7 days"
        class="text-center"
      >
        <div class="text-2xl md:text-3xl font-bold text-indigo-600 dark:text-indigo-400">{stats.conversionRate.toFixed(1)}%</div>
        <div class="text-xs md:text-sm text-gray-600 dark:text-gray-400 mt-1">Plan → Apply Rate</div>
        <div class="text-xs text-gray-500 dark:text-gray-400">{stats.plans} plans, {stats.applies} applies</div>
      </ClickableCard>
      
      <ClickableCard 
        padding="md" 
        hover={true}
        on:click={() => {
          const weekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
          navigateToRuns(`created_at:${weekAgo}.. and state:success`);
        }}
        aria-label="View completed runs"
        class="text-center"
      >
        <div class="text-2xl md:text-3xl font-bold text-teal-600 dark:text-teal-400">{stats.avgDuration}</div>
        <div class="text-xs md:text-sm text-gray-600 dark:text-gray-400 mt-1">Avg Duration</div>
        <div class="text-xs text-gray-500 dark:text-gray-400">Minutes</div>
      </ClickableCard>
      
      <ClickableCard 
        padding="md" 
        hover={true}
        on:click={() => {
          const yesterday = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString().split('T')[0];
          navigateToWorkspaces({ since: yesterday });
        }}
        aria-label="View active workspaces from last 24 hours"
        class="text-center"
      >
        <div class="text-2xl md:text-3xl font-bold text-purple-600 dark:text-purple-400">{stats.workspaces24h}</div>
        <div class="text-xs md:text-sm text-gray-600 dark:text-gray-400 mt-1">Active Workspaces</div>
        <div class="text-xs text-gray-500 dark:text-gray-400">Last 24 hours</div>
      </ClickableCard>
      
    </div>

    <!-- Team Activity -->
    {#if stats.topUsers.length > 0}
      <div class="mb-8">
        <Card padding="lg">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-4">Most Active Contributors</h3>
          <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">Click to view runs by user from the last 7 days</p>
          <div class="space-y-3">
            {#each stats.topUsers as user, index}
              <ClickableCard
                padding="sm"
                hover={true}
                on:click={() => {
                  const weekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
                  navigateToRuns(`created_at:${weekAgo}.. and user:${encodeURIComponent(user.name)}`);
                }}
                aria-label="View runs by {user.name} from last 7 days"
                class="bg-gray-50 dark:bg-gray-700 hover:bg-blue-50 dark:hover:bg-blue-900/30 transition-colors"
              >
                <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2">
                  <div class="flex items-center space-x-3">
                    <div class="text-lg font-bold text-blue-600 dark:text-blue-400">#{index + 1}</div>
                    <div class="font-medium text-gray-900 dark:text-gray-100">{user.name}</div>
                  </div>
                  <div class="flex items-center gap-2 self-start sm:self-center">
                    <div class="text-sm font-bold text-blue-600 dark:text-blue-400 whitespace-nowrap">{user.count} operations</div>
                    <svg class="w-4 h-4 text-gray-400 dark:text-gray-500 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
                    </svg>
                  </div>
                </div>
              </ClickableCard>
            {/each}
          </div>
        </Card>
      </div>
    {/if}

    <!-- Recent Activity Timeline -->
    <div class="mb-8">
      <Card padding="lg">
        <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 mb-4">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100">Recent Activity</h3>
          <div class="flex items-center gap-2 flex-shrink-0">
            {#if isLoadingActivity}
              <LoadingSpinner size="sm" centered={false} />
            {:else}
              <button
                on:click={() => loadRecentActivity()}
                class="inline-flex items-center px-3 py-1 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm text-xs font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-700 hover:bg-gray-50 dark:hover:bg-gray-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 whitespace-nowrap"
              >
                <svg class="w-3 h-3 mr-1 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                </svg>
                Refresh
              </button>
            {/if}
            <ClickableCard
              padding="sm"
              hover={true}
              on:click={() => navigateToRuns()}
              aria-label="View all runs"
              class="inline-block bg-blue-50 dark:bg-blue-900/30 border-blue-200 dark:border-blue-700 hover:bg-blue-100 dark:hover:bg-blue-900/50"
            >
              <div class="flex items-center space-x-1 text-blue-700 dark:text-blue-300">
                <span class="text-xs font-medium whitespace-nowrap">View All</span>
                <svg class="w-3 h-3 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
                </svg>
              </div>
            </ClickableCard>
          </div>
        </div>
        
        {#if activityError}
          <div class="flex items-center space-x-2 text-amber-800 dark:text-amber-400 bg-amber-50 dark:bg-amber-900/20 p-3 rounded-md border border-amber-200 dark:border-amber-700">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
            </svg>
            <span class="text-sm">Unable to load recent activity: {activityError}</span>
          </div>
        {:else if isLoadingActivity && recentActivity.length === 0}
          <div class="flex justify-center items-center py-8">
            <LoadingSpinner size="md" />
            <span class="ml-3 text-gray-600 dark:text-gray-400">Loading recent activity...</span>
          </div>
        {:else if recentActivity.length === 0}
          <div class="text-center py-8 text-gray-500 dark:text-gray-400">
            <svg class="w-12 h-12 mx-auto mb-4 text-gray-300 dark:text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <p class="text-sm">No recent activity to display</p>
          </div>
        {:else}
          <div class="space-y-3">
            {#each recentActivity as activity}
              <ClickableCard
                padding="sm"
                hover={true}
                on:click={() => navigateToDetail(activity.id)}
                aria-label="View details for {activity.run_type || 'unknown'} operation in {activity.repo}"
                class="bg-gray-50 dark:bg-gray-700 hover:bg-blue-50 dark:hover:bg-blue-900/30 transition-colors border-l-4 {
                  activity.state === 'success' ? 'border-green-400' :
                  activity.state === 'failure' ? 'border-red-400' :
                  activity.state === 'running' ? 'border-blue-400' :
                  activity.state === 'queued' ? 'border-yellow-400' :
                  'border-gray-400'
                }"
              >
                <div class="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-3">
                  <div class="flex-1 min-w-0 overflow-hidden">
                    <div class="flex items-center gap-2 mb-1 flex-wrap">
                      <!-- Type Badge -->
                      {#if activity.run_type}
                        <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium border {getTypeColor(activity.run_type)} whitespace-nowrap">
                          {getTypeIcon(activity.run_type)} {activity.run_type.toUpperCase()}
                        </span>
                      {/if}
                      
                      <!-- State Badge -->
                      <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium border {getStateColor(activity.state)} whitespace-nowrap">
                        {getStateIcon(activity.state)} {activity.state ? activity.state.toUpperCase() : 'UNKNOWN'}
                      </span>
                    </div>
                    
                    <div class="flex flex-wrap items-center gap-2 text-sm">
                      <span class="font-medium text-gray-900 dark:text-gray-100">{activity.repo}</span>
                      {#if activity.dir}
                        <span class="text-gray-400 dark:text-gray-500">•</span>
                        <span class="text-gray-600 dark:text-gray-400 font-mono text-xs bg-gray-100 dark:bg-gray-600 px-1 rounded break-all">{activity.dir}</span>
                      {/if}
                    </div>
                    
                    <div class="flex flex-wrap items-center gap-2 text-xs text-gray-500 dark:text-gray-400 mt-1">
                      <span class="whitespace-nowrap">{formatRelativeTime(activity.created_at)}</span>
                      {#if activity.user}
                        <span class="text-gray-400 dark:text-gray-500">•</span>
                        <span class="whitespace-nowrap">by {activity.user}</span>
                      {/if}
                      {#if activity.branch}
                        <span class="text-gray-400 dark:text-gray-500">•</span>
                        <span class="break-all">{activity.branch}</span>
                      {/if}
                    </div>
                  </div>
                  
                  <div class="flex-shrink-0 self-start">
                    <svg class="w-4 h-4 text-gray-400 dark:text-gray-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
                    </svg>
                  </div>
                </div>
              </ClickableCard>
            {/each}
          </div>
        {/if}
      </Card>
    </div>
  {/if}
</PageLayout>
