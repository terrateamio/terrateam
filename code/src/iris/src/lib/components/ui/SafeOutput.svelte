<script lang="ts">
  import { createEventDispatcher } from 'svelte';
  // The `common` bundle registers the ~35 most used languages (diff, yaml, json,
  // bash, markdown, ...) so an arbitrary `format: {lang: x}` from a workflow can
  // be resolved without importing every grammar by hand.
  import hljs from 'highlight.js/lib/common';
  import 'highlight.js/styles/github-dark.css';
  import { marked } from 'marked';
  import DOMPurify from 'dompurify';
  import { sentryService } from '../../sentry';
  import { TEXT_FORMAT, type OutputFormat } from '../../utils/outputFormat';

  export let content: string = '';
  export let title: string = '';
  export const maxPreviewSize: number = 5000000; // 5MB
  export let githubUrl: string = '';
  export let format: OutputFormat = TEXT_FORMAT; // How to render the content
  export let highlight: boolean = false; // Whether to apply syntax highlighting

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

  // Generate preview
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

  // Render the content to HTML when the format calls for it. An empty string
  // means "render as plain text", which is also the fallback when rendering
  // fails or the requested language is not one highlight.js knows about.
  function renderHtml(text: string, fmt: OutputFormat, syntaxHighlight: boolean): string {
    if (!text) {
      return '';
    }

    try {
      if (fmt.kind === 'markdown') {
        return DOMPurify.sanitize(marked.parse(text, { async: false }));
      }

      if (fmt.kind === 'code' && syntaxHighlight && hljs.getLanguage(fmt.lang)) {
        return hljs.highlight(text, { language: fmt.lang }).value;
      }
    } catch (error) {
      console.error('Error rendering output:', error);

      // Capture to Sentry with context
      sentryService.captureError(error as Error, {
        feature: 'output-rendering',
        component: 'SafeOutput',
        contentSize: text.length,
        stepName: stepName || 'unknown',
        format: fmt.kind
      });
    }

    return '';
  }

  // Only render what is on screen: the full content is rendered lazily, once the
  // user has asked for it.
  $: renderedPreview = renderHtml(previewContent, format, highlight);
  $: renderedContent = showFullContent ? renderHtml(content, format, highlight) : '';
  $: displayHtml = showFullContent ? renderedContent : renderedPreview;
  $: displayText = showFullContent ? content : previewContent;

  // `plan-hljs` carries the addition/deletion/change colors; everything else
  // uses the generic token palette. Both are defined in app.css and theme-aware.
  $: hljsClass = format.kind === 'code' && format.lang === 'diff' ? 'plan-hljs' : 'config-hljs';

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
  
  // The expanded view shows the full content, rendered as this block renders it.
  function handleExpand() {
    const html = displayText === content ? displayHtml : renderHtml(content, format, highlight);
    dispatch('expand', { content, title, html, markdown: format.kind === 'markdown', htmlClass: hljsClass });
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
  <div class="border border-[var(--sg-warning)] bg-[var(--sg-warning-bg)] rounded-lg p-4">
    <div class="flex items-start gap-3">
      <svg class="w-5 h-5 text-[var(--sg-warning)] flex-shrink-0 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
      </svg>
      <div class="flex-1">
        <h4 class="font-medium text-[var(--sg-warning)] mb-2 text-sm sm:text-base">
          {#if isMedium}
            Large Output Detected
          {:else if isLarge}
            Very Large Output Detected
          {:else if isHuge}
            Extremely Large Output Detected
          {/if}
        </h4>
        <p class="text-xs sm:text-sm text-[var(--sg-warning)] mb-3">
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
              class="px-3 py-1.5 bg-[var(--sg-warning)] text-white text-xs sm:text-sm rounded hover:bg-[var(--sg-warning)] hover:opacity-90 transition-colors inline-flex items-center justify-center"
              on:click={handleShowContent}
            >
              <svg class="w-4 h-4 mr-1.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
              Show Preview ({formatSize(Math.min(contentSize, 1000000))})
            </button>
          {/if}
          
          <button
            class="px-3 py-1.5 bg-[var(--sg-success)] text-white text-xs sm:text-sm rounded hover:bg-[var(--sg-success)] hover:opacity-90 transition-colors inline-flex items-center justify-center"
            on:click={handleDownload}
          >
            <svg class="w-4 h-4 mr-1.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
            </svg>
            Download Output
          </button>
          
          {#if githubUrl}
            <button
              class="px-3 py-1.5 bg-[var(--sg-accent-button)] text-white text-xs sm:text-sm rounded hover:bg-[var(--sg-accent-button-hover)] transition-colors inline-flex items-center justify-center"
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
              class="px-3 py-1.5 border border-[var(--sg-warning)] text-[var(--sg-warning)] text-xs sm:text-sm rounded hover:bg-[var(--sg-warning-bg)] transition-colors inline-flex items-center justify-center"
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
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2 text-xs text-[var(--sg-text-dim)] bg-[var(--sg-bg-0)] px-3 py-2 rounded">
      <span class="font-medium">
        {#if isMedium || isLarge || isHuge}
          Size: {formatSize(contentSize)}
        {/if}
      </span>
      <div class="flex items-center gap-2 flex-wrap">
        <button
          class="text-[var(--sg-accent)] hover:text-[var(--sg-accent-hover)] px-3 py-1 border border-[var(--sg-accent)] rounded hover:bg-[var(--sg-accent-bg)] transition-colors inline-flex items-center justify-center"
          on:click={handleExpand}
        >
          <svg class="w-4 h-4 mr-1 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
          <span>Expand</span>
        </button>
        <button
          class="text-[var(--sg-success)] hover:text-[var(--sg-success)] px-3 py-1 border border-[var(--sg-success)] rounded hover:bg-[var(--sg-success-bg)] transition-colors inline-flex items-center justify-center"
          on:click={handleDownload}
        >
          <svg class="w-4 h-4 mr-1 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
          </svg>
          <span>Download</span>
        </button>
        {#if githubUrl && (isMedium || isLarge || isHuge)}
          <button
            class="text-[var(--sg-accent)] hover:text-[var(--sg-accent-hover)] underline"
            on:click={openGitHubLog}
          >
            View in GitHub
          </button>
        {/if}
      </div>
    </div>
    
    {#if format.kind === 'markdown' && displayHtml}
      <!-- Markdown output, sanitized -->
      <div class="output-markdown text-sm bg-[var(--sg-bg-code)] text-[var(--sg-text-code)] p-3 rounded overflow-x-auto {showFullContent ? '' : 'max-h-96'}">
        {@html displayHtml}
      </div>
    {:else if displayHtml}
      <!-- Syntax-highlighted output -->
      <pre class="{hljsClass} text-xs bg-[var(--sg-bg-code)] p-3 rounded overflow-x-auto whitespace-pre-wrap font-mono {showFullContent ? '' : 'max-h-96'}"><code>{@html displayHtml}</code></pre>
    {:else}
      <!-- Plain text output (no format, or rendering failed) -->
      <pre class="text-xs bg-[var(--sg-bg-code)] text-[var(--sg-text-code)] p-3 rounded overflow-x-auto whitespace-pre-wrap font-mono {showFullContent ? '' : 'max-h-96'}">{displayText}</pre>
    {/if}
    
    {#if !showFullContent && (isMedium || isLarge)}
      <div class="text-center">
        <button
          class="px-4 py-2 bg-[var(--sg-bg-2)] text-[var(--sg-text)] text-sm rounded hover:bg-[var(--sg-bg-2)] hover:opacity-90 transition-colors"
          on:click={handleShowFullContent}
        >
          ⚡ Load Full Output ({formatSize(contentSize)})
        </button>
      </div>
    {/if}
  </div>
{/if}