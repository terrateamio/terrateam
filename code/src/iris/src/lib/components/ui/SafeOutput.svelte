<script lang="ts">
  import { createEventDispatcher } from 'svelte';
  
  export let content: string = '';
  export let title: string = '';
  export const maxPreviewSize: number = 5000000; // 5MB
  export let githubUrl: string = '';
  
  // Optional props for enhanced filename generation
  export let orgName: string = '';
  export let repoName: string = '';
  export let prNumber: string | number = '';
  export let runType: string = ''; // 'plan', 'apply', etc.
  export let stepName: string = ''; // 'tf/plan', 'tf/apply', etc.
  
  const dispatch = createEventDispatcher();
  
  // Size thresholds (in characters) - Updated for modern browser capabilities
  const SMALL_SIZE = 1000000;   // 1MB - show inline, typical for most Terraform plans
  const MEDIUM_SIZE = 5000000;  // 5MB - show with warning, still very manageable
  const LARGE_SIZE = 20000000;  // 20MB - require explicit load, genuinely large
  
  $: contentSize = content.length;
  $: isSmall = contentSize <= SMALL_SIZE;
  $: isMedium = contentSize > SMALL_SIZE && contentSize <= MEDIUM_SIZE;
  $: isLarge = contentSize > MEDIUM_SIZE && contentSize <= LARGE_SIZE;
  $: isHuge = contentSize > LARGE_SIZE;
  
  // Auto-show small content
  $: {
    if (isSmall) {
      showContent = true;
    }
  }
  
  
  let showContent = false; // Will be set to true for small content below
  let showFullContent = false;
  let previewContent = '';
  
  // Generate preview (first 5000 lines or 1MB, whichever is smaller)
  $: {
    if (content) {
      const lines = content.split('\n');
      if (lines.length > 5000) {
        previewContent = lines.slice(0, 5000).join('\n') + '\n\n... (truncated, showing first 5000 lines)';
      } else if (contentSize > 1000000) {
        previewContent = content.substring(0, 1000000) + '\n\n... (truncated)';
      } else {
        previewContent = content;
      }
    }
  }
  
  function handleShowContent() {
    showContent = true;
  }
  
  function handleShowFullContent() {
    showFullContent = true;
  }
  
  function formatSize(bytes: number): string {
    if (bytes < 1024) return `${bytes} characters`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)}KB`;
    return `${(bytes / (1024 * 1024)).toFixed(1)}MB`;
  }
  
  function openGitHubLog() {
    if (githubUrl) {
      window.open(githubUrl, '_blank');
    }
  }
  
  function handleExpand() {
    dispatch('expand', { content, title });
  }
  
  function handleDownload() {
    const blob = new Blob([content], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    
    // Generate descriptive filename with org, repo, PR, step info
    const filename = generateFilename();
    
    link.href = url;
    link.download = filename;
    link.click();
    
    // Clean up
    URL.revokeObjectURL(url);
  }
  
  function generateFilename(): string {
    const parts: string[] = [];
    
    // Add org and repo if available
    if (orgName && repoName) {
      parts.push(`${orgName}_${repoName}`);
    } else if (repoName) {
      parts.push(repoName);
    }
    
    // Add PR number if available
    if (prNumber) {
      parts.push(`PR${prNumber}`);
    }
    
    // Add run type if available
    if (runType) {
      parts.push(runType);
    }
    
    // Add step name (cleaned up)
    if (stepName) {
      const cleanStep = stepName.replace(/[\/]/g, '_');
      parts.push(cleanStep);
    }
    
    // Add timestamp for uniqueness
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
    parts.push(timestamp);
    
    // Combine parts and clean up
    const baseName = parts.length > 0 
      ? parts.join('_').replace(/[^a-zA-Z0-9\-_]/g, '_')
      : 'terraform_output';
    
    return `${baseName}.txt`;
  }
</script>

{#if !showContent}
  <!-- Size warning with options -->
  <div class="border border-yellow-200 dark:border-yellow-700 bg-yellow-50 dark:bg-yellow-900/20 rounded-lg p-4">
    <div class="flex items-start gap-3">
      <svg class="w-5 h-5 text-yellow-600 dark:text-yellow-400 flex-shrink-0 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
      </svg>
      <div class="flex-1">
        <h4 class="font-medium text-yellow-800 dark:text-yellow-200 mb-2 text-sm sm:text-base">
          {#if isMedium}
            Large Output Detected
          {:else if isLarge}
            Very Large Output Detected
          {:else if isHuge}
            Extremely Large Output Detected
          {/if}
        </h4>
        <p class="text-xs sm:text-sm text-yellow-700 dark:text-yellow-300 mb-3">
          This {title.toLowerCase()} output is {formatSize(contentSize)}.
          {#if isMedium}
            This is large but should render fine on modern browsers.
          {:else if isLarge}
            This is quite large and may take a moment to render.
          {:else if isHuge}
            <strong>This is extremely large - we recommend viewing in GitHub instead.</strong>
          {/if}
        </p>
        
        <div class="flex flex-col sm:flex-row gap-2">
          {#if !isHuge}
            <button
              class="px-3 py-1.5 bg-yellow-600 dark:bg-yellow-700 text-white text-xs sm:text-sm rounded hover:bg-yellow-700 dark:hover:bg-yellow-800 transition-colors inline-flex items-center justify-center"
              on:click={handleShowContent}
            >
              <svg class="w-4 h-4 mr-1.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
              Show Preview ({formatSize(Math.min(contentSize, 1000000))})
            </button>
          {/if}
          
          <button
            class="px-3 py-1.5 bg-green-600 dark:bg-green-700 text-white text-xs sm:text-sm rounded hover:bg-green-700 dark:hover:bg-green-800 transition-colors inline-flex items-center justify-center"
            on:click={handleDownload}
          >
            <svg class="w-4 h-4 mr-1.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
            </svg>
            Download Output
          </button>
          
          {#if githubUrl}
            <button
              class="px-3 py-1.5 bg-blue-600 dark:bg-blue-700 text-white text-xs sm:text-sm rounded hover:bg-blue-700 dark:hover:bg-blue-800 transition-colors inline-flex items-center justify-center"
              on:click={openGitHubLog}
            >
              <svg class="w-4 h-4 mr-1.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
              </svg>
              View in GitHub
            </button>
          {/if}
          
          {#if !isHuge}
            <button
              class="px-3 py-1.5 border border-yellow-300 dark:border-yellow-600 text-yellow-700 dark:text-yellow-300 text-xs sm:text-sm rounded hover:bg-yellow-100 dark:hover:bg-yellow-900/30 transition-colors inline-flex items-center justify-center"
              on:click={handleShowFullContent}
            >
              <svg class="w-4 h-4 mr-1.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
              </svg>
              Load Full Output (Risk: May freeze browser)
            </button>
          {/if}
        </div>
      </div>
    </div>
  </div>
{:else}
  <!-- Content display -->
  <div class="space-y-3">
    <!-- Header with expand button and size info -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2 text-xs text-gray-600 dark:text-gray-400 bg-gray-50 dark:bg-gray-800 px-3 py-2 rounded">
      <span class="font-medium">
        {#if isMedium || isLarge || isHuge}
          Size: {formatSize(contentSize)}
        {:else}
          Output:
        {/if}
      </span>
      <div class="flex items-center gap-2 flex-wrap">
        <button
          class="text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 px-3 py-1 border border-blue-200 dark:border-blue-600 rounded hover:bg-blue-50 dark:hover:bg-blue-900/30 transition-colors inline-flex items-center justify-center"
          on:click={handleExpand}
        >
          <svg class="w-4 h-4 mr-1 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
          <span>Expand</span>
        </button>
        <button
          class="text-green-600 dark:text-green-400 hover:text-green-800 dark:hover:text-green-300 px-3 py-1 border border-green-200 dark:border-green-600 rounded hover:bg-green-50 dark:hover:bg-green-900/30 transition-colors inline-flex items-center justify-center"
          on:click={handleDownload}
        >
          <svg class="w-4 h-4 mr-1 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
          </svg>
          <span>Download</span>
        </button>
        {#if githubUrl && (isMedium || isLarge || isHuge)}
          <button
            class="text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 underline"
            on:click={openGitHubLog}
          >
            View in GitHub
          </button>
        {/if}
      </div>
    </div>
    
    <pre class="text-xs bg-gray-900 dark:bg-gray-950 text-gray-100 dark:text-gray-200 p-3 rounded overflow-x-auto whitespace-pre-wrap font-mono {showFullContent ? '' : 'max-h-96'}">
      {showFullContent ? content : previewContent}
    </pre>
    
    {#if !showFullContent && (isMedium || isLarge)}
      <div class="text-center">
        <button
          class="px-4 py-2 bg-gray-600 text-white text-sm rounded hover:bg-gray-700 transition-colors"
          on:click={handleShowFullContent}
        >
          ⚡ Load Full Output ({formatSize(contentSize)})
        </button>
      </div>
    {/if}
  </div>
{/if}