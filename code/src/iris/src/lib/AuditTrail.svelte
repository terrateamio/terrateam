<script lang="ts">
  import { onMount } from 'svelte';
  import PageLayout from './components/layout/PageLayout.svelte';
  import { LoadingSpinner, ErrorMessage, Card } from './components';
  import { api } from './api';
  import type { WorkManifest } from './types';
  import { validateWorkManifests } from './types';
  import { selectedInstallation } from './stores';

  // State variables
  let loading = true;
  let error: string | null = null;
  let workManifests: WorkManifest[] = [];
  let allWorkManifests: WorkManifest[] = []; // Store all data for filtering
  let selectedDateRange = '7d'; // Default to last 7 days
  let selectedUser = 'all';
  let selectedOperation = 'all';
  let selectedStatus = 'all';
  let selectedRepository = 'all';
  let users: Set<string> = new Set();
  let repositories: Set<string> = new Set();
  let statuses: Set<string> = new Set();

  // Pagination state
  let hasMoreResults: boolean = false;
  let isLoadingMore: boolean = false;
  let nextPageUrl: string | null = null; // URL for next page from Link header

  // Get timezone for API calls
  const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone;

  // Date range options
  const dateRangeOptions = [
    { value: '1d', label: 'Last 24 hours' },
    { value: '7d', label: 'Last 7 days' },
    { value: '30d', label: 'Last 30 days' },
    { value: '90d', label: 'Last 90 days' },
    { value: 'all', label: 'All time' }
  ];

  // Operation type options
  const operationOptions = [
    { value: 'all', label: 'All Operations' },
    { value: 'plan', label: 'Plans' },
    { value: 'apply', label: 'Applies' },
    { value: 'drift', label: 'Drift Checks' },
    { value: 'index', label: 'Index Operations' }
  ];

  // Get date range filter
  function getDateRangeQuery(): string {
    if (selectedDateRange === 'all') return '';
    
    const now = new Date();
    const past = new Date();
    
    switch (selectedDateRange) {
      case '1d':
        past.setDate(now.getDate() - 1);
        break;
      case '7d':
        past.setDate(now.getDate() - 7);
        break;
      case '30d':
        past.setDate(now.getDate() - 30);
        break;
      case '90d':
        past.setDate(now.getDate() - 90);
        break;
    }
    
    return `created_at:${past.toISOString().split('T')[0]}..`;
  }

  // Build search query for API
  function buildSearchQuery(): string {
    const queries: string[] = [];
    
    // Always add date range for API efficiency
    const dateQuery = getDateRangeQuery();
    if (dateQuery) queries.push(dateQuery);
    
    return queries.length > 0 ? queries.join(' and ') : '';
  }

  // Apply client-side filters
  function applyFilters(): void {
    let filtered = [...allWorkManifests];
    
    // Filter by user
    if (selectedUser !== 'all') {
      filtered = filtered.filter(m => m.user === selectedUser);
    }
    
    // Filter by operation type
    if (selectedOperation !== 'all') {
      if (selectedOperation === 'drift') {
        filtered = filtered.filter(m => m.kind === 'drift');
      } else if (selectedOperation === 'index') {
        filtered = filtered.filter(m => m.kind === 'index');
      } else {
        filtered = filtered.filter(m => m.run_type === selectedOperation);
      }
    }
    
    // Filter by status
    if (selectedStatus !== 'all') {
      filtered = filtered.filter(m => m.state === selectedStatus);
    }
    
    // Filter by repository
    if (selectedRepository !== 'all') {
      filtered = filtered.filter(m => m.repo === selectedRepository);
    }
    
    workManifests = filtered;
  }

  // Load audit trail data
  async function loadAuditTrail(loadMore: boolean = false) {
    if (!$selectedInstallation) return;
    
    if (loadMore) {
      isLoadingMore = true;
    } else {
      loading = true;
      // Reset for new search
      hasMoreResults = false;
      nextPageUrl = null;
    }
    
    try {
      error = null;
      
      let response;
      let rawLinkHeader: string | null = null;
      
      if (loadMore && nextPageUrl) {
        // Use the next page URL directly from the Link header
        const fetchResponse = await fetch(nextPageUrl, {
          method: 'GET',
          headers: {
            'Content-Type': 'application/json',
          },
          credentials: 'include',
        });
        
        if (!fetchResponse.ok) {
          throw new Error(`Failed to fetch: ${fetchResponse.status} ${fetchResponse.statusText}`);
        }
        
        const rawResponse = await fetchResponse.json();
        
        // Store Link header for later use
        rawLinkHeader = fetchResponse.headers.get('Link') || fetchResponse.headers.get('link');
        
        // Parse Link headers from the raw response
        let linkHeaders;
        if (rawLinkHeader) {
          // Use a simple regex to extract next link
          const nextMatch = rawLinkHeader.match(/<([^>]+)>;\s*rel="next"/);
          if (nextMatch) {
            linkHeaders = { next: nextMatch[1] };
          }
        }
        
        // Format response to match our expected structure
        response = {
          work_manifests: validateWorkManifests(rawResponse.work_manifests || []),
          hasMore: linkHeaders?.next !== undefined
        };
      } else {
        const query = buildSearchQuery();
        const params: {
          tz: string;
          limit: number;
          d: string;
          lite: boolean;
          q?: string;
        } = {
          tz: timezone,
          limit: 50,
          d: 'desc',
          lite: true
        };
        
        // Only add query if it exists
        if (query) {
          params.q = query;
        }
        
        response = await api.getWorkManifestsWithQuery(
          $selectedInstallation.id,
          params
        );
      }
      
      // Store pagination info
      hasMoreResults = response.hasMore;
      
      // Update next page URL
      if (loadMore && rawLinkHeader) {
        // When loading more via direct URL, get the next URL from parsed headers
        const nextMatch = rawLinkHeader.match(/<([^>]+)>;\s*rel="next"/);
        if (nextMatch) {
          nextPageUrl = nextMatch[1].replace('//api/', '/api/');
        } else {
          nextPageUrl = null;
        }
      } else {
        // For initial load, get it from the API response
        const linkHeaders = api.getLastLinkHeaders();
        if (linkHeaders?.next) {
          nextPageUrl = linkHeaders.next.replace('//api/', '/api/');
        } else {
          nextPageUrl = null;
        }
      }
      
      const actualResults = response.work_manifests;
      
      if (loadMore) {
        // Append new results
        allWorkManifests = [...allWorkManifests, ...actualResults];
        
        // Update unique value sets
        actualResults.forEach(wm => {
          if (wm.user) users.add(wm.user);
          repositories.add(wm.repo);
          statuses.add(wm.state);
        });
      } else {
        allWorkManifests = actualResults;
        
        // Extract unique values for filters
        users = new Set(
          allWorkManifests
            .filter(wm => wm.user)
            .map(wm => wm.user!)
        );
        
        repositories = new Set(
          allWorkManifests.map(wm => wm.repo)
        );
        
        statuses = new Set(
          allWorkManifests.map(wm => wm.state)
        );
      }
      
      // Apply filters to show data
      applyFilters();
      
    } catch (err) {
      console.error('Failed to load audit trail:', err);
      error = err instanceof Error ? err.message : 'Failed to load audit trail';
      if (!loadMore) {
        allWorkManifests = [];
        hasMoreResults = false;
      }
    } finally {
      if (loadMore) {
        isLoadingMore = false;
      } else {
        loading = false;
      }
    }
  }

  // Get operation type display
  function getOperationType(manifest: WorkManifest): string {
    if (manifest.kind === 'drift') return 'Drift Check';
    if (manifest.kind === 'index') return 'Index';
    return manifest.run_type.charAt(0).toUpperCase() + manifest.run_type.slice(1);
  }

  // Get operation icon
  function getOperationIcon(manifest: WorkManifest): string {
    if (manifest.kind === 'drift') return 'auto-fix';
    if (manifest.kind === 'index') return 'file-code';
    if (manifest.run_type === 'plan') return 'file-edit';
    if (manifest.run_type === 'apply') return 'rocket-launch';
    return 'cog';
  }

  // Check if kind is pull request
  function isPullRequestKind(kind: WorkManifest['kind']): kind is { pull_number: number; pull_request_title?: string } {
    return typeof kind === 'object' && 'pull_number' in kind;
  }

  // Get state color
  function getStateColor(state: string): string {
    switch (state) {
      case 'success': return 'text-green-600 dark:text-green-400';
      case 'failure': return 'text-red-600 dark:text-red-400';
      case 'running': return 'text-blue-600 dark:text-blue-400';
      case 'queued': return 'text-gray-600 dark:text-gray-400';
      case 'aborted': return 'text-orange-600 dark:text-orange-400';
      default: return 'text-gray-600 dark:text-gray-400';
    }
  }

  // Get state icon
  function getStateIcon(state: string): string {
    switch (state) {
      case 'success': return 'check-circle';
      case 'failure': return 'close-circle';
      case 'running': return 'loading';
      case 'queued': return 'clock-outline';
      case 'aborted': return 'cancel';
      default: return 'help-circle';
    }
  }

  // Handle filter changes
  function handleFilterChange() {
    applyFilters();
  }
  
  // Handle date range change (requires API call)
  function handleDateRangeChange() {
    loadAuditTrail();
  }

  // Load more functionality
  async function loadMoreAuditTrail(): Promise<void> {
    await loadAuditTrail(true);
  }


  // Format data for export
  function formatDataForExport(): { csv: string; json: string } {
    // Prepare data rows
    const rows = workManifests.map(manifest => ({
      timestamp: manifest.created_at,
      date: new Date(manifest.created_at).toLocaleDateString('en-US'),
      time: new Date(manifest.created_at).toLocaleTimeString('en-US', { hour12: false }),
      user: manifest.user || 'system',
      operation: getOperationType(manifest),
      repository: manifest.repo,
      directory: manifest.dirspaces.length > 0 ? manifest.dirspaces[0].dir : '',
      workspace: manifest.dirspaces.length > 0 ? manifest.dirspaces[0].workspace : '',
      branch: manifest.branch || '',
      pr_number: isPullRequestKind(manifest.kind) ? manifest.kind.pull_number.toString() : '',
      status: manifest.state,
      run_type: manifest.run_type,
      kind: typeof manifest.kind === 'string' ? manifest.kind : 'pr'
    }));

    // CSV format
    const csvHeaders = ['Date', 'Time', 'User', 'Operation', 'Repository', 'Directory', 'Workspace', 'Branch', 'PR Number', 'Status'];
    const csvRows = rows.map(row => [
      row.date,
      row.time,
      row.user,
      row.operation,
      row.repository,
      row.directory,
      row.workspace,
      row.branch,
      row.pr_number,
      row.status
    ]);
    
    const csv = [
      csvHeaders.join(','),
      ...csvRows.map(row => row.map(cell => `"${cell}"`).join(','))
    ].join('\n');

    // JSON format
    const json = JSON.stringify(rows, null, 2);

    return { csv, json };
  }

  // Download data
  function downloadData(format: 'csv' | 'json') {
    const { csv, json } = formatDataForExport();
    const data = format === 'csv' ? csv : json;
    const mimeType = format === 'csv' ? 'text/csv' : 'application/json';
    const filename = `audit-trail-${new Date().toISOString().split('T')[0]}.${format}`;

    // Create blob and download
    const blob = new Blob([data], { type: mimeType });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  }

  onMount(() => {
    loadAuditTrail();
  });

  // Reload when installation changes
  $: if ($selectedInstallation) {
    loadAuditTrail();
  }
</script>

<PageLayout
  activeItem="audit-trail"
  title="Audit Trail"
  subtitle="View operational history and user activity"
>
  <!-- Filters -->
  <div class="mb-6 space-y-4">
    <!-- First row of filters -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
      <!-- Date Range Filter -->
      <div>
        <label for="date-range" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
          Date Range
        </label>
        <select
          id="date-range"
          bind:value={selectedDateRange}
          on:change={handleDateRangeChange}
          class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 focus:outline-none focus:ring-2 focus:ring-brand-primary"
        >
          {#each dateRangeOptions as option}
            <option value={option.value}>{option.label}</option>
          {/each}
        </select>
      </div>

      <!-- User Filter -->
      <div>
        <label for="user" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
          User
        </label>
        <select
          id="user"
          bind:value={selectedUser}
          on:change={handleFilterChange}
          class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 focus:outline-none focus:ring-2 focus:ring-brand-primary"
        >
          <option value="all">All Users</option>
          {#each Array.from(users).sort() as user}
            <option value={user}>{user}</option>
          {/each}
        </select>
      </div>

      <!-- Operation Type Filter -->
      <div>
        <label for="operation" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
          Operation Type
        </label>
        <select
          id="operation"
          bind:value={selectedOperation}
          on:change={handleFilterChange}
          class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 focus:outline-none focus:ring-2 focus:ring-brand-primary"
        >
          {#each operationOptions as option}
            <option value={option.value}>{option.label}</option>
          {/each}
        </select>
      </div>
    </div>

    <!-- Second row of filters -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
      <!-- Repository Filter -->
      <div>
        <label for="repository" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
          Repository
        </label>
        <select
          id="repository"
          bind:value={selectedRepository}
          on:change={handleFilterChange}
          class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 focus:outline-none focus:ring-2 focus:ring-brand-primary"
        >
          <option value="all">All Repositories</option>
          {#each Array.from(repositories).sort() as repo}
            <option value={repo}>{repo}</option>
          {/each}
        </select>
      </div>

      <!-- Status Filter -->
      <div>
        <label for="status" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
          Status
        </label>
        <select
          id="status"
          bind:value={selectedStatus}
          on:change={handleFilterChange}
          class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 focus:outline-none focus:ring-2 focus:ring-brand-primary"
        >
          <option value="all">All Statuses</option>
          {#each Array.from(statuses).sort() as status}
            <option value={status}>
              <span class="capitalize">{status}</span>
            </option>
          {/each}
        </select>
      </div>

      <!-- Clear Filters Button -->
      <div class="flex items-end">
        <button
          on:click={() => {
            selectedUser = 'all';
            selectedOperation = 'all';
            selectedStatus = 'all';
            selectedRepository = 'all';
            applyFilters();
          }}
          class="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 shadow-sm text-sm font-medium rounded-md text-gray-700 dark:text-gray-200 bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-brand-primary"
        >
          <iconify-icon icon="mdi:filter-remove" width="16" height="16" class="mr-1.5 inline-block"></iconify-icon>
          Clear Filters
        </button>
      </div>
    </div>
  </div>

  <!-- Results section with download button -->
  <div class="flex items-center justify-between mb-4">
    <h2 class="text-lg font-medium text-gray-900 dark:text-gray-100">
      {#if loading}
        Loading audit entries...
      {:else if error}
        Error loading audit entries
      {:else}
        {#if hasMoreResults}
          <span>
            Showing {workManifests.length} audit {workManifests.length === 1 ? 'entry' : 'entries'}
            {#if workManifests.length !== allWorkManifests.length}
              (filtered from {allWorkManifests.length} loaded)
            {/if}
            <span class="text-gray-500 dark:text-gray-400 font-normal ml-2">
              • Load more below
            </span>
          </span>
        {:else}
          {workManifests.length} audit {workManifests.length === 1 ? 'entry' : 'entries'}
          {#if workManifests.length !== allWorkManifests.length}
            (filtered from {allWorkManifests.length} total)
          {/if}
        {/if}
      {/if}
    </h2>
    
    {#if !loading && !error && workManifests.length > 0}
      <div class="flex gap-2">
        <button
          on:click={() => downloadData('csv')}
          class="inline-flex items-center px-3 py-1.5 border border-gray-300 dark:border-gray-600 shadow-sm text-sm font-medium rounded-md text-gray-700 dark:text-gray-200 bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-brand-primary"
        >
          <iconify-icon icon="mdi:download" width="16" height="16" class="mr-1.5"></iconify-icon>
          CSV
        </button>
        <button
          on:click={() => downloadData('json')}
          class="inline-flex items-center px-3 py-1.5 border border-gray-300 dark:border-gray-600 shadow-sm text-sm font-medium rounded-md text-gray-700 dark:text-gray-200 bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-brand-primary"
        >
          <iconify-icon icon="mdi:download" width="16" height="16" class="mr-1.5"></iconify-icon>
          JSON
        </button>
      </div>
    {/if}
  </div>

  <!-- Results -->
  {#if loading}
    <div class="flex justify-center py-12">
      <LoadingSpinner size="lg" />
    </div>
  {:else if error}
    <ErrorMessage type="error" message={error} />
  {:else if workManifests.length === 0}
    <Card padding="lg">
      <div class="text-center">
        <iconify-icon icon="mdi:file-clock" width="48" height="48" class="text-gray-400 dark:text-gray-600 mb-2"></iconify-icon>
        <h3 class="text-lg font-medium text-gray-900 dark:text-gray-100 mb-1">No audit entries found</h3>
        <p class="text-sm text-gray-500 dark:text-gray-400">Try adjusting your filters or search criteria</p>
      </div>
    </Card>
  {:else}
    <!-- Log-style view -->
    <div class="bg-gray-50 dark:bg-gray-900 rounded-lg border border-gray-200 dark:border-gray-700 overflow-hidden">
      <div class="overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
          <thead class="bg-gray-100 dark:bg-gray-800">
            <tr>
              <th scope="col" class="px-3 py-2 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                Time
              </th>
              <th scope="col" class="px-3 py-2 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                User
              </th>
              <th scope="col" class="px-3 py-2 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                Operation
              </th>
              <th scope="col" class="px-3 py-2 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                Target
              </th>
              <th scope="col" class="px-3 py-2 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                Status
              </th>
              <th scope="col" class="px-3 py-2 text-center text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                Details
              </th>
            </tr>
          </thead>
          <tbody class="bg-white dark:bg-gray-900 divide-y divide-gray-200 dark:divide-gray-700">
            {#each workManifests as manifest}
              <tr class="hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors">
                <!-- Time -->
                <td class="px-3 py-2 whitespace-nowrap text-sm font-mono text-gray-600 dark:text-gray-400">
                  {new Date(manifest.created_at).toLocaleTimeString('en-US', { 
                    hour12: false, 
                    hour: '2-digit', 
                    minute: '2-digit', 
                    second: '2-digit' 
                  })}
                  <span class="text-xs text-gray-500 dark:text-gray-500 ml-1">
                    {new Date(manifest.created_at).toLocaleDateString('en-US', { 
                      month: 'short', 
                      day: 'numeric' 
                    })}
                  </span>
                </td>
                
                <!-- User -->
                <td class="px-3 py-2 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100">
                  {manifest.user || 'system'}
                </td>
                
                <!-- Operation -->
                <td class="px-3 py-2 whitespace-nowrap text-sm">
                  <div class="flex items-center gap-1">
                    <iconify-icon 
                      icon="mdi:{getOperationIcon(manifest)}" 
                      width="16" 
                      height="16" 
                      class="text-gray-500 dark:text-gray-400"
                    ></iconify-icon>
                    <span class="text-gray-900 dark:text-gray-100 font-medium">
                      {getOperationType(manifest).toLowerCase()}
                    </span>
                  </div>
                </td>
                
                <!-- Target -->
                <td class="px-3 py-2 text-sm text-gray-600 dark:text-gray-400">
                  <div class="flex items-center gap-1 truncate max-w-md">
                    <span class="font-mono text-xs">{manifest.repo}</span>
                    {#if manifest.dirspaces.length > 0 && manifest.dirspaces[0].dir !== '.'}
                      <span class="text-gray-400">:</span>
                      <span class="font-mono text-xs">{manifest.dirspaces[0].dir}</span>
                    {/if}
                    {#if manifest.dirspaces.length > 0 && manifest.dirspaces[0].workspace !== 'default'}
                      <span class="text-gray-400">@</span>
                      <span class="font-mono text-xs">{manifest.dirspaces[0].workspace}</span>
                    {/if}
                    {#if isPullRequestKind(manifest.kind)}
                      <span class="text-gray-400 ml-1">(PR #{manifest.kind.pull_number})</span>
                    {/if}
                  </div>
                </td>
                
                <!-- Status -->
                <td class="px-3 py-2 whitespace-nowrap text-sm">
                  <div class="flex items-center gap-1">
                    <iconify-icon 
                      icon="mdi:{getStateIcon(manifest.state)}" 
                      width="16" 
                      height="16"
                      class="{getStateColor(manifest.state)} {manifest.state === 'running' ? 'animate-spin' : ''}"
                    ></iconify-icon>
                    <span class="{getStateColor(manifest.state)} font-medium">
                      {manifest.state}
                    </span>
                  </div>
                </td>
                
                <!-- Details Link -->
                <td class="px-3 py-2 whitespace-nowrap text-center">
                  {#if manifest.id}
                    <a 
                      href="#/i/{$selectedInstallation?.id}/runs/{manifest.id}"
                      class="text-brand-primary hover:text-blue-700 dark:hover:text-blue-400 underline text-sm"
                      title="View run details"
                    >
                      View
                    </a>
                  {:else}
                    <span class="text-gray-400 text-xs">No ID</span>
                  {/if}
                </td>
              </tr>
            {/each}
          </tbody>
        </table>
      </div>
    </div>
    
    <!-- Load More Button -->
    {#if hasMoreResults}
      <div class="mt-6 text-center">
        <p class="text-sm text-gray-500 dark:text-gray-400 mb-3">
          More entries available
        </p>
        <button
          on:click={loadMoreAuditTrail}
          disabled={isLoadingMore}
          class="inline-flex items-center px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {#if isLoadingMore}
            <svg class="animate-spin -ml-1 mr-2 h-4 w-4 text-gray-600 dark:text-gray-400" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
              <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
            Loading more...
          {:else}
            Load More
          {/if}
        </button>
      </div>
    {/if}
  {/if}
</PageLayout>