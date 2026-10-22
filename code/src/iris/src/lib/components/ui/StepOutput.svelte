<script lang="ts">
  import { createEventDispatcher } from 'svelte';
  import SafeOutput from './SafeOutput.svelte';
  import type { OutputItem } from '../../types/stepOutput';
  import { DIFF_FORMAT, parseOutputFormat } from '../../utils/outputFormat';

  export let output: OutputItem;
  export let stepLabel: string = '';
  export let highlight: boolean = false; // Pass through to SafeOutput
  export let variant: 'normal' | 'error' = 'normal';
  export let debugVisibility: boolean = false; // Raw Steps tab: show the visible_on setting

  // Run context, used for the download filename and the "View in GitHub" link
  export let githubUrl: string = '';
  export let orgName: string = '';
  export let repoName: string = '';
  export let prNumber: string | number = '';
  export let runType: string = '';

  const dispatch = createEventDispatcher<{
    expand: { content: string; title: string };
    loadFull: OutputItem;
  }>();

  const isError = variant === 'error';

  $: payload = output?.payload;
  $: text = payload?.text || '';

  // A plan step carries the human-readable diff from the engine's diff command
  // in `plan`, separate from the plan command's stdout in `text`. Match on the
  // step suffix so every engine is covered: tf/plan, custom/plan, pulumi/plan,
  // cdktf/plan, fly/plan, ...
  $: diff = output?.step?.endsWith('/plan') && typeof payload?.plan === 'string' ? payload.plan : '';

  $: textFormat = parseOutputFormat(payload?.format);
  $: scopeLabel = `${output?.scope?.dir || 'unknown'}:${output?.scope?.workspace || 'unknown'}`;
  $: titlePrefix = isError ? 'Failed: ' : '';

</script>

{#if text || diff}
  {#if payload?._isLiteMode}
    <!-- Output not loaded - click to view -->
    <div class="mt-3">
      <div class="text-xs {isError ? 'text-[var(--sg-error)]' : 'text-[var(--sg-text-dim)]'} mb-2">
        {isError ? 'Error Output:' : 'Output:'}
      </div>
      <div class="bg-[var(--sg-bg-0)] border border-[var(--sg-border)] rounded-lg p-4 {isError ? 'bg-[var(--sg-error-bg)] border-[var(--sg-error)]' : ''}">
        <div class="flex flex-col gap-3">
          <div class="flex items-center text-sm {isError ? 'text-[var(--sg-error)]' : 'text-[var(--sg-text-dim)]'}">
            <svg class="w-5 h-5 mr-2 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
            </svg>
            <span>{isError ? 'Error output not loaded' : 'Output content not loaded'}</span>
          </div>
          <button
            type="button"
            on:click={() => dispatch('loadFull', output)}
            class="inline-flex items-center justify-center px-4 py-2 border text-sm font-medium rounded-md transition-colors {isError
              ? 'border-[var(--sg-error)] text-[var(--sg-error)] bg-[var(--sg-error-bg)] hover:bg-[var(--sg-error-bg)]'
              : 'border-[var(--sg-accent)] text-[var(--sg-accent)] bg-[var(--sg-accent-bg)] hover:bg-[var(--sg-accent-bg)]'}"
          >
            <svg class="w-4 h-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
            </svg>
            {isError ? 'View Error Output' : 'View Output'}
          </button>
        </div>
      </div>
    </div>
  {:else}
    <!-- Display actual step output content with safe loading -->
    <div class="mt-3 space-y-3">
      {#if diff}
        <div>
          <div class="text-xs text-[var(--sg-text-dim)] mb-2">
            <span class="font-medium text-[var(--sg-text)]">Planned changes</span>
            Read from the saved plan file.
          </div>
          <SafeOutput
            content={diff}
            format={DIFF_FORMAT}
            {highlight}
            title={`${titlePrefix}${stepLabel} diff - ${scopeLabel}`}
            {githubUrl}
            {orgName}
            {repoName}
            {prNumber}
            {runType}
            stepName={output?.step || ''}
            on:expand
          />
        </div>
      {/if}

      {#if text}
        <div>
          <div class="text-xs {isError ? 'text-[var(--sg-error)]' : 'text-[var(--sg-text-dim)]'} mb-2">
            {#if diff}
              <span class="font-medium text-[var(--sg-text)]">Plan command output</span>
              Full log of the plan command. Data source reads, refresh, warnings, then the same plan.
            {:else}
              {isError ? 'Error Output:' : 'Output:'}
            {/if}
          </div>
          <SafeOutput
            content={text}
            format={textFormat}
            {highlight}
            title={`${titlePrefix}${stepLabel} - ${scopeLabel}`}
            {githubUrl}
            {orgName}
            {repoName}
            {prNumber}
            {runType}
            stepName={output?.step || ''}
            on:expand
          />
        </div>
      {/if}
    </div>
  {/if}
{:else if output?.step === 'auth/update-terrateam-github-token' || output?.step === 'auth/oidc'}
  <!-- Hide debug for auth steps - no meaningful output to show -->
  <div class="mt-3 text-xs text-[var(--sg-text-dim)] italic">
    {isError ? 'Authentication step failed' : 'Authentication step completed'}{#if debugVisibility}
      {payload?.visible_on ? ` - visible_on: ${payload.visible_on}` : ' - no visibility setting'}
    {/if}
  </div>
{:else}
  <!-- Fallback for other steps if no payload content was found -->
  <div class="mt-3 text-xs text-[var(--sg-text-dim)]">
    No output content available for this step type
  </div>
{/if}
