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
  <div class="border border-yellow-200 bg-yellow-50 rounded-lg p-4">
    <div class="flex items-start space-x-3">
      <div class="text-yellow-600 text-xl">⚠️</div>
      <div class="flex-1">
        <h4 class="font-medium text-yellow-800 mb-2">
          {#if isMedium}
            Large Output Detected
          {:else if isLarge}
            Very Large Output Detected
          {:else if isHuge}
            Extremely Large Output Detected
          {/if}
        </h4>
        <p class="text-sm text-yellow-700 mb-3">
          This {title.toLowerCase()} output is {formatSize(contentSize)}.
          {#if isMedium}
            This is large but should render fine on modern browsers.
          {:else if isLarge}
            This is quite large and may take a moment to render.
          {:else if isHuge}
            <strong>This is extremely large - we recommend viewing in GitHub instead.</strong>
          {/if}
        </p>
        
        <div class="flex flex-wrap gap-2">
          {#if !isHuge}
            <button
              class="px-3 py-1 bg-yellow-600 text-white text-sm rounded hover:bg-yellow-700 transition-colors"
              on:click={handleShowContent}
            >
              📄 Show Preview ({formatSize(Math.min(contentSize, 1000000))})
            </button>
          {/if}
          
          <button
            class="px-3 py-1 bg-green-600 text-white text-sm rounded hover:bg-green-700 transition-colors"
            on:click={handleDownload}
          >
            💾 Download Output
          </button>
          
          {#if githubUrl}
            <button
              class="px-3 py-1 bg-blue-600 text-white text-sm rounded hover:bg-blue-700 transition-colors"
              on:click={openGitHubLog}
            >
              🔗 View in GitHub
            </button>
          {/if}
          
          {#if !isHuge}
            <button
              class="px-3 py-1 border border-yellow-300 text-yellow-700 text-sm rounded hover:bg-yellow-100 transition-colors"
              on:click={handleShowFullContent}
            >
              ⚡ Load Full Output (Risk: May freeze browser)
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
    <div class="flex items-center justify-between text-xs text-gray-600 bg-gray-50 px-3 py-2 rounded">
      <span>
        {#if isMedium || isLarge || isHuge}
          Size: {formatSize(contentSize)}
        {:else}
          Output:
        {/if}
      </span>
      <div class="flex items-center space-x-2">
        <button
          class="text-blue-600 hover:text-blue-800 px-2 py-1 border border-blue-200 rounded hover:bg-blue-50 transition-colors"
          on:click={handleExpand}
        >
          🔍 Expand
        </button>
        <button
          class="text-green-600 hover:text-green-800 px-2 py-1 border border-green-200 rounded hover:bg-green-50 transition-colors"
          on:click={handleDownload}
        >
          💾 Download
        </button>
        {#if githubUrl && (isMedium || isLarge || isHuge)}
          <button
            class="text-blue-600 hover:text-blue-800 underline"
            on:click={openGitHubLog}
          >
            View in GitHub
          </button>
        {/if}
      </div>
    </div>
    
    <pre class="text-xs bg-gray-900 text-gray-100 p-3 rounded overflow-x-auto whitespace-pre-wrap font-mono" style="max-height: {showFullContent ? 'none' : '24rem'}">
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