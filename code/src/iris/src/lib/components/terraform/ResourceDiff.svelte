<!-- Resource Diff Component - Shows before/after comparison of Terraform resources -->
<script lang="ts">
  import Card from '../ui/Card.svelte';
  import type { ResourceNode, ChangeSet } from '../../types/terraform';

  // Props
  export let resources: ResourceNode[];
  export let changes: ChangeSet;

  // State
  let selectedResource: ResourceNode | null = null;
  let filterType: 'all' | 'create' | 'update' | 'delete' | 'replace' = 'all';
  let searchQuery = '';
  let showOnlyChangedAttributes = true;

  // Filter resources based on type and search
  $: filteredResources = resources.filter(resource => {
    // Filter by change type
    if (filterType !== 'all' && resource.changeType !== filterType) {
      return false;
    }
    
    // Filter by search query
    if (searchQuery) {
      const query = searchQuery.toLowerCase();
      return resource.id.toLowerCase().includes(query) ||
             resource.type.toLowerCase().includes(query) ||
             resource.name.toLowerCase().includes(query);
    }
    
    return true;
  });

  // Group resources by change type for summary
  $: groupedResources = {
    create: filteredResources.filter(r => r.changeType === 'create'),
    update: filteredResources.filter(r => r.changeType === 'update'),
    delete: filteredResources.filter(r => r.changeType === 'delete'),
    replace: filteredResources.filter(r => r.changeType === 'replace')
  };

  function selectResource(resource: ResourceNode): void {
    selectedResource = resource === selectedResource ? null : resource;
  }

  function getChangeIcon(changeType: string): string {
    switch (changeType) {
      case 'create': return '+';
      case 'delete': return '-';
      case 'update': return '~';
      case 'replace': return '±';
      default: return '';
    }
  }

  function getChangeColor(changeType: string): string {
    switch (changeType) {
      case 'create': return 'text-green-600 bg-green-50 dark:text-green-400 dark:bg-green-900/20';
      case 'delete': return 'text-red-600 bg-red-50 dark:text-red-400 dark:bg-red-900/20';
      case 'update': return 'text-yellow-600 bg-yellow-50 dark:text-yellow-400 dark:bg-yellow-900/20';
      case 'replace': return 'text-purple-600 bg-purple-50 dark:text-purple-400 dark:bg-purple-900/20';
      default: return 'text-gray-600 bg-gray-50 dark:text-gray-400 dark:bg-gray-900/20';
    }
  }

  function formatValue(value: unknown): string {
    if (value === null || value === undefined) return 'null';
    if (typeof value === 'string') return value;
    if (typeof value === 'boolean') return value.toString();
    if (typeof value === 'number') return value.toString();
    if (Array.isArray(value)) return `[${value.length} items]`;
    if (typeof value === 'object') return `{${Object.keys(value).length} props}`;
    return String(value);
  }

  function getChangedAttributes(resource: ResourceNode): Array<{key: string, before: unknown, after: unknown}> {
    const changes: Array<{key: string, before: unknown, after: unknown}> = [];
    const allKeys = new Set([
      ...Object.keys(resource.before),
      ...Object.keys(resource.after)
    ]);

    for (const key of allKeys) {
      const beforeVal = resource.before[key];
      const afterVal = resource.after[key];
      
      if (JSON.stringify(beforeVal) !== JSON.stringify(afterVal)) {
        changes.push({ key, before: beforeVal, after: afterVal });
      }
    }

    return changes;
  }

  function exportDiff(): void {
    const diffContent = filteredResources.map(resource => {
      const changes = getChangedAttributes(resource);
      return `
# ${resource.id} (${resource.changeType})
Type: ${resource.type}
Provider: ${resource.provider}

Changes:
${changes.map(c => `  ${c.key}: ${formatValue(c.before)} → ${formatValue(c.after)}`).join('\n')}
`;
    }).join('\n---\n');

    const blob = new Blob([diffContent], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = 'terraform-diff.txt';
    link.click();
    URL.revokeObjectURL(url);
  }
  
  // Format resource data for display, handling escaped strings
  function formatResourceData(data: unknown): string {
    if (!data || typeof data !== 'object') {
      if (typeof data === 'string') {
        // Clean up escaped quotes in strings
        return data.replace(/\\"/g, '"');
      }
      return JSON.stringify(data, null, 2);
    }
    
    // Use a custom replacer to clean up escaped quotes
    return JSON.stringify(data, (key, value) => {
      if (typeof value === 'string') {
        // Clean up any escaped quotes
        return value.replace(/\\"/g, '"');
      }
      return value;
    }, 2);
  }
</script>

<div class="resource-diff">
  <!-- Controls -->
  <Card padding="sm">
    <div class="space-y-4">
      <!-- Search Bar -->
      <div class="relative w-full">
        <input
          type="text"
          placeholder="Search resources..."
          bind:value={searchQuery}
          class="w-full pl-10 pr-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg
                 bg-white dark:bg-gray-800 text-gray-900 dark:text-white
                 focus:ring-2 focus:ring-brand-primary focus:border-transparent"
        />
        <svg class="absolute left-3 top-2.5 w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
        </svg>
      </div>

      <!-- Filter buttons - Horizontal scroll on mobile -->
      <div class="flex items-center gap-2 overflow-x-auto pb-2 -mx-2 px-2">
        <button
          class="flex-shrink-0 px-3 py-1.5 rounded-lg text-xs sm:text-sm font-medium transition-colors whitespace-nowrap
                 {filterType === 'all' ? 'bg-brand-primary text-white' : 'bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300'}"
          on:click={() => filterType = 'all'}
        >
          All ({resources.length})
        </button>
        <button
          class="flex-shrink-0 px-3 py-1.5 rounded-lg text-xs sm:text-sm font-medium transition-colors whitespace-nowrap
                 {filterType === 'create' ? 'bg-green-500 text-white' : 'bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300'}"
          on:click={() => filterType = 'create'}
        >
          Create ({changes.create.length})
        </button>
        <button
          class="flex-shrink-0 px-3 py-1.5 rounded-lg text-xs sm:text-sm font-medium transition-colors whitespace-nowrap
                 {filterType === 'update' ? 'bg-yellow-500 text-white' : 'bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300'}"
          on:click={() => filterType = 'update'}
        >
          Update ({changes.update.length})
        </button>
        <button
          class="flex-shrink-0 px-3 py-1.5 rounded-lg text-xs sm:text-sm font-medium transition-colors whitespace-nowrap
                 {filterType === 'delete' ? 'bg-red-500 text-white' : 'bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300'}"
          on:click={() => filterType = 'delete'}
        >
          Delete ({changes.delete.length})
        </button>
        <button
          class="flex-shrink-0 px-3 py-1.5 rounded-lg text-xs sm:text-sm font-medium transition-colors whitespace-nowrap
                 {filterType === 'replace' ? 'bg-purple-500 text-white' : 'bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300'}"
          on:click={() => filterType = 'replace'}
        >
          Replace ({changes.replace.length})
        </button>
      </div>

      <!-- Actions - Stack on mobile -->
      <div class="flex flex-col sm:flex-row sm:items-center gap-2">
        <label class="flex items-center gap-2 text-xs sm:text-sm text-gray-600 dark:text-gray-400">
          <input
            type="checkbox"
            bind:checked={showOnlyChangedAttributes}
            class="rounded border-gray-300 dark:border-gray-600"
          />
          Only show changes
        </label>
        <button
          class="px-3 py-1.5 rounded-lg text-xs sm:text-sm font-medium bg-gray-100 dark:bg-gray-700 
                 text-gray-700 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600
                 inline-flex items-center justify-center"
          on:click={exportDiff}
        >
          <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
                  d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
          </svg>
          Export
        </button>
      </div>
    </div>
  </Card>

  <!-- Summary Statistics -->
  {#if filteredResources.length > 0}
    <div class="mt-4 grid grid-cols-2 sm:grid-cols-4 gap-2 sm:gap-4">
      <Card padding="sm">
        <div class="text-center">
          <div class="text-2xl font-bold text-green-600 dark:text-green-400">
            +{groupedResources.create.length}
          </div>
          <div class="text-sm text-gray-600 dark:text-gray-400">Created</div>
        </div>
      </Card>
      <Card padding="sm">
        <div class="text-center">
          <div class="text-2xl font-bold text-yellow-600 dark:text-yellow-400">
            ~{groupedResources.update.length}
          </div>
          <div class="text-sm text-gray-600 dark:text-gray-400">Updated</div>
        </div>
      </Card>
      <Card padding="sm">
        <div class="text-center">
          <div class="text-2xl font-bold text-red-600 dark:text-red-400">
            -{groupedResources.delete.length}
          </div>
          <div class="text-sm text-gray-600 dark:text-gray-400">Deleted</div>
        </div>
      </Card>
      <Card padding="sm">
        <div class="text-center">
          <div class="text-2xl font-bold text-purple-600 dark:text-purple-400">
            ±{groupedResources.replace.length}
          </div>
          <div class="text-sm text-gray-600 dark:text-gray-400">Replaced</div>
        </div>
      </Card>
    </div>
  {/if}

  <!-- Resource List -->
  <div class="mt-4 space-y-2">
    {#if filteredResources.length === 0}
      <Card padding="lg">
        <div class="text-center py-8 text-gray-500 dark:text-gray-400">
          {searchQuery ? 'No resources match your search' : 'No resources to display'}
        </div>
      </Card>
    {:else}
      {#each filteredResources as resource (resource.id)}
        <Card 
          padding="none" 
          hover={true}
          class="cursor-pointer {selectedResource?.id === resource.id ? 'ring-2 ring-brand-primary' : ''}"
        >
          <div 
            class="p-4"
            on:click={() => selectResource(resource)}
            on:keydown={(e) => e.key === 'Enter' && selectResource(resource)}
            role="button"
            tabindex="0"
          >
            <!-- Resource Header -->
            <div class="flex items-start justify-between gap-2">
              <div class="flex items-start gap-2 sm:gap-3 min-w-0 flex-1">
                <span class="flex-shrink-0 text-lg sm:text-2xl font-bold {getChangeColor(resource.changeType)} px-1.5 sm:px-2 py-0.5 sm:py-1 rounded">
                  {getChangeIcon(resource.changeType)}
                </span>
                <div class="min-w-0 flex-1">
                  <h3 class="font-semibold text-sm sm:text-base text-gray-900 dark:text-white break-all">
                    {resource.id}
                  </h3>
                  <p class="text-xs sm:text-sm text-gray-600 dark:text-gray-400">
                    Type: {resource.type} | Provider: {resource.provider}
                  </p>
                </div>
              </div>
              <svg 
                class="flex-shrink-0 w-4 h-4 sm:w-5 sm:h-5 text-gray-400 transform transition-transform
                       {selectedResource?.id === resource.id ? 'rotate-180' : ''}"
                fill="none" 
                stroke="currentColor" 
                viewBox="0 0 24 24"
              >
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
              </svg>
            </div>

            <!-- Expanded Details -->
            {#if selectedResource?.id === resource.id}
              <div class="mt-4 pt-4 border-t border-gray-200 dark:border-gray-700">
                {#if resource.changeType === 'create'}
                  <div class="space-y-2">
                    <h4 class="text-sm font-semibold text-gray-700 dark:text-gray-300">New Resource</h4>
                    <div class="bg-green-50 dark:bg-green-900/20 p-3 rounded-lg">
                      <pre class="text-xs text-green-800 dark:text-green-200 overflow-x-auto">
{formatResourceData(resource.after)}
                      </pre>
                    </div>
                  </div>
                {:else if resource.changeType === 'delete'}
                  <div class="space-y-2">
                    <h4 class="text-sm font-semibold text-gray-700 dark:text-gray-300">Removed Resource</h4>
                    <div class="bg-red-50 dark:bg-red-900/20 p-3 rounded-lg">
                      <pre class="text-xs text-red-800 dark:text-red-200 overflow-x-auto">
{formatResourceData(resource.before)}
                      </pre>
                    </div>
                  </div>
                {:else}
                  <!-- Update or Replace - show diff -->
                  <div class="space-y-2">
                    <h4 class="text-sm font-semibold text-gray-700 dark:text-gray-300">
                      Attribute Changes
                    </h4>
                    {#each getChangedAttributes(resource) as change}
                      <div class="border-l-4 border-yellow-400 pl-4 py-2">
                        <div class="text-xs sm:text-sm font-medium text-gray-900 dark:text-white break-all">
                          {change.key}
                        </div>
                        <div class="mt-1 grid grid-cols-1 sm:grid-cols-2 gap-2 sm:gap-4">
                          <div>
                            <span class="text-xs text-gray-500 dark:text-gray-400">Before:</span>
                            <div class="mt-1 p-2 bg-red-50 dark:bg-red-900/20 rounded text-xs overflow-x-auto">
                              <code class="text-red-700 dark:text-red-300 break-all">
                                {formatValue(change.before)}
                              </code>
                            </div>
                          </div>
                          <div>
                            <span class="text-xs text-gray-500 dark:text-gray-400">After:</span>
                            <div class="mt-1 p-2 bg-green-50 dark:bg-green-900/20 rounded text-xs overflow-x-auto">
                              <code class="text-green-700 dark:text-green-300 break-all">
                                {formatValue(change.after)}
                              </code>
                            </div>
                          </div>
                        </div>
                      </div>
                    {/each}
                    
                    {#if !showOnlyChangedAttributes}
                      <h4 class="text-sm font-semibold text-gray-700 dark:text-gray-300 mt-4">
                        Unchanged Attributes
                      </h4>
                      <div class="bg-gray-50 dark:bg-gray-800 p-3 rounded-lg">
                        <pre class="text-xs text-gray-600 dark:text-gray-400 overflow-x-auto">
{formatResourceData(resource.after)}
                        </pre>
                      </div>
                    {/if}
                  </div>
                {/if}
              </div>
            {/if}
          </div>
        </Card>
      {/each}
    {/if}
  </div>
</div>

<style>
  .resource-diff {
    width: 100%;
  }

  input[type="text"] {
    min-width: 250px;
  }

  pre {
    white-space: pre-wrap;
    word-wrap: break-word;
  }

  code {
    font-family: 'Courier New', monospace;
  }
</style>