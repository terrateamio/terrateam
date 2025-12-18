import type {
  Dirspace,
  Stacks,
  StackOuter,
  StackInner,
  StackState,
  StackWithRuns,
  PRWithStacks,
  StackSummary,
  RepositoryWithPRs,
  RepositoryWithStacks,
  StackWithPRs,
  DashboardMetrics,
  TimelineEvent
} from '../types';
import { api } from '../api';
import type { VCSProvider } from '../vcs/types';

/**
 * Metadata about a PR extracted from dirspaces
 */
interface PRMetadata {
  prNumber: number;
  repo: string;
  repoId?: string;
  title?: string;
}

/**
 * Result of loading recent stacks data
 */
export interface StacksDataResult {
  stacksWithRuns: StackWithRuns[];
  dirspaces: Dirspace[];
  prs: Map<number, PRMetadata>;
  errors: Array<{ prNumber: number; error: string }>;
}

/**
 * Loads recent stacks data by fetching dirspaces and their associated PR stacks
 *
 * Strategy:
 * 1. Fetch recent dirspaces (last N days)
 * 2. Extract unique PRs from dirspaces
 * 3. Fetch stacks for each PR in parallel
 * 4. Match runs to stacks by dir:workspace
 *
 * @param installationId - Installation ID
 * @param daysBack - Number of days to look back (default: 7)
 * @param limit - Maximum dirspaces to fetch (default: 100)
 * @param provider - VCS provider (optional)
 * @returns StacksDataResult with stacks, runs, and metadata
 */
export async function loadRecentStacksData(
  installationId: string,
  daysBack: number = 7,
  limit: number = 100,
  provider?: VCSProvider
): Promise<StacksDataResult> {
  // Calculate date range
  const now = new Date();
  const startDate = new Date(now.getTime() - daysBack * 24 * 60 * 60 * 1000);
  const startDateStr = startDate.toISOString().split('T')[0]; // YYYY-MM-DD

  // Step 1: Fetch recent dirspaces
  const query = `created_at:${startDateStr}..`;
  const params = {
    tz: Intl.DateTimeFormat().resolvedOptions().timeZone,
    q: query,
    limit: limit,
  };

  const response = await api.getInstallationDirspaces(installationId, params, provider);
  const dirspaces = (response && 'dirspaces' in response ? response.dirspaces : []) as Dirspace[];

  console.log(`[Stacks] Found ${dirspaces.length} dirspaces from last ${daysBack} days`);

  // Step 2: Extract unique PRs with metadata
  const prsMap = extractPRsFromDirspaces(dirspaces);

  console.log(`[Stacks] Extracted ${prsMap.size} unique PRs:`, Array.from(prsMap.keys()));

  // Step 3: Fetch repo IDs for PRs (needed for stacks API)
  await enrichPRsWithRepoIds(prsMap, dirspaces, installationId, provider);

  console.log(`[Stacks] PRs with repo IDs:`, Array.from(prsMap.values()).filter(pr => pr.repoId).length);

  // Step 4: Fetch stacks for each PR in parallel
  const { stacksMap, errors } = await fetchStacksForPRs(prsMap, installationId, provider);

  console.log(`[Stacks] Loaded stacks for ${stacksMap.size} PRs, ${errors.length} errors`);

  // Step 5: Match runs to stacks and flatten hierarchy
  const stacksWithRuns = matchRunsToStacks(stacksMap, dirspaces, prsMap);

  return {
    stacksWithRuns,
    dirspaces,
    prs: prsMap,
    errors,
  };
}

/**
 * Extracts unique PRs from dirspaces
 */
function extractPRsFromDirspaces(dirspaces: Dirspace[]): Map<number, PRMetadata> {
  const prsMap = new Map<number, PRMetadata>();

  for (const dirspace of dirspaces) {
    // Check if this dirspace is associated with a PR
    if (dirspace.kind && typeof dirspace.kind === 'object' && 'pull_number' in dirspace.kind) {
      const prNumber = dirspace.kind.pull_number;
      const prTitle = 'pull_request_title' in dirspace.kind ? dirspace.kind.pull_request_title : undefined;

      if (!prsMap.has(prNumber)) {
        prsMap.set(prNumber, {
          prNumber,
          repo: dirspace.repo,
          title: prTitle,
        });
      }
    }
  }

  return prsMap;
}

/**
 * Enriches PR metadata with repo IDs by fetching work manifests
 * The stacks API requires repo_id (VCS provider's internal ID), not repo name
 */
async function enrichPRsWithRepoIds(
  prsMap: Map<number, PRMetadata>,
  dirspaces: Dirspace[],
  installationId: string,
  provider?: VCSProvider
): Promise<void> {
  // Group dirspaces by PR to find dirspace IDs (which are used to fetch work manifests)
  const prToDirspaceId = new Map<number, string>();

  for (const dirspace of dirspaces) {
    if (dirspace.kind && typeof dirspace.kind === 'object' && 'pull_number' in dirspace.kind) {
      const prNumber = dirspace.kind.pull_number;
      // Use dirspace.id (not run_id) - this is what RunsPRDetail uses
      if (dirspace.id && !prToDirspaceId.has(prNumber)) {
        prToDirspaceId.set(prNumber, dirspace.id);
      }
    }
  }

  // Fetch work manifests to get repo IDs
  const repoIdPromises = Array.from(prsMap.keys()).map(async (prNumber) => {
    const dirspaceId = prToDirspaceId.get(prNumber);
    if (!dirspaceId) {
      console.warn(`No dirspace ID found for PR #${prNumber}`);
      return;
    }

    try {
      const workManifest = await api.getWorkManifest(installationId, dirspaceId, provider);
      if (workManifest && workManifest.repo_id) {
        const prMetadata = prsMap.get(prNumber);
        if (prMetadata) {
          prMetadata.repoId = workManifest.repo_id;
        }
      }
    } catch (error) {
      console.warn(`Failed to fetch repo ID for PR #${prNumber} (dirspace ${dirspaceId}):`, error);
    }
  });

  await Promise.all(repoIdPromises);
}

/**
 * Fetches stacks for multiple PRs in parallel
 *
 * @param prs - Map of PR metadata
 * @param installationId - Installation ID
 * @param provider - VCS provider
 * @returns Map of PR number to Stacks, and array of errors
 */
export async function fetchStacksForPRs(
  prs: Map<number, PRMetadata>,
  installationId: string,
  provider?: VCSProvider
): Promise<{ stacksMap: Map<number, Stacks>; errors: Array<{ prNumber: number; error: string }> }> {
  const stacksMap = new Map<number, Stacks>();
  const errors: Array<{ prNumber: number; error: string }> = [];

  // Create parallel fetch promises
  const fetchPromises = Array.from(prs.entries()).map(async ([prNumber, prMetadata]) => {
    // Skip if we don't have repo ID
    if (!prMetadata.repoId) {
      errors.push({
        prNumber,
        error: 'Missing repository ID',
      });
      return;
    }

    try {
      const stacks = await api.getPullRequestStacks(
        installationId,
        prMetadata.repoId,
        prNumber.toString(),
        provider
      );

      if (stacks) {
        stacksMap.set(prNumber, stacks);
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      errors.push({
        prNumber,
        error: errorMessage,
      });
      console.warn(`Failed to fetch stacks for PR #${prNumber}:`, error);
    }
  });

  // Wait for all fetches to complete (both successful and failed)
  await Promise.all(fetchPromises);

  return { stacksMap, errors };
}

/**
 * Matches dirspaces (runs) to stack nodes by dir:workspace combination
 * Flattens the stack hierarchy to create StackWithRuns objects
 *
 * @param stacksMap - Map of PR number to Stacks
 * @param dirspaces - All dirspaces
 * @param prsMap - PR metadata
 * @returns Array of StackWithRuns
 */
export function matchRunsToStacks(
  stacksMap: Map<number, Stacks>,
  dirspaces: Dirspace[],
  prsMap: Map<number, PRMetadata>
): StackWithRuns[] {
  const stacksWithRuns: StackWithRuns[] = [];

  // Iterate through each PR's stacks
  for (const [prNumber, stacks] of stacksMap.entries()) {
    const prMetadata = prsMap.get(prNumber);
    if (!prMetadata) continue;

    // Flatten the stack hierarchy to get all StackInner (leaf) nodes
    const flatStacks = flattenStackHierarchy(stacks, prMetadata);

    // For each stack, find matching dirspaces
    for (const flatStack of flatStacks) {
      const matchingRuns = findMatchingRuns(flatStack, dirspaces, prNumber);

      // Compute aggregated metrics
      const metrics = computeStackMetrics(matchingRuns);

      stacksWithRuns.push({
        stackOuter: flatStack.stackOuter,
        stackInner: flatStack.stackInner,
        prNumber,
        prTitle: prMetadata.title,
        repo: prMetadata.repo,
        repoId: prMetadata.repoId || '',
        recentRuns: matchingRuns,
        state: flatStack.stackInner.state,
        lastActivity: metrics.lastActivity,
        lastUser: metrics.lastUser,
        runningCount: metrics.runningCount,
        failureCount: metrics.failureCount,
        successCount: metrics.successCount,
      });
    }
  }

  return stacksWithRuns;
}

/**
 * Flattens stack hierarchy to get all leaf stacks (StackInner)
 */
interface FlatStack {
  stackOuter: StackOuter;
  stackInner: StackInner;
  repo: string;
  repoId?: string;
}

function flattenStackHierarchy(stacks: Stacks, prMetadata: PRMetadata): FlatStack[] {
  const flatStacks: FlatStack[] = [];

  if (!stacks.stacks) return flatStacks;

  for (const stackOuter of stacks.stacks) {
    // StackOuter contains StackInner children
    if (stackOuter.stacks) {
      for (const stackInner of stackOuter.stacks) {
        flatStacks.push({
          stackOuter,
          stackInner,
          repo: prMetadata.repo,
          repoId: prMetadata.repoId,
        });
      }
    }
  }

  return flatStacks;
}

/**
 * Finds dirspaces that match a stack's dir:workspace combinations
 */
function findMatchingRuns(
  flatStack: FlatStack,
  dirspaces: Dirspace[],
  prNumber: number
): Dirspace[] {
  const matchingRuns: Dirspace[] = [];

  // Get all dir:workspace combinations for this stack
  const dirspaceKeys = new Set<string>();
  if (flatStack.stackInner.dirspaces) {
    for (const ds of flatStack.stackInner.dirspaces) {
      const key = `${ds.dirspace.dir}:${ds.dirspace.workspace}`;
      dirspaceKeys.add(key);
    }
  }

  // Find matching dirspaces
  for (const dirspace of dirspaces) {
    // Must be from the same PR
    const isPRMatch =
      dirspace.kind &&
      typeof dirspace.kind === 'object' &&
      'pull_number' in dirspace.kind &&
      dirspace.kind.pull_number === prNumber;

    if (!isPRMatch) continue;

    // Check if dir:workspace matches
    const dirspaceKey = `${dirspace.dir}:${dirspace.workspace}`;
    if (dirspaceKeys.has(dirspaceKey)) {
      matchingRuns.push(dirspace);
    }
  }

  // Sort by created_at descending (most recent first)
  matchingRuns.sort((a, b) => {
    const dateA = new Date(a.created_at).getTime();
    const dateB = new Date(b.created_at).getTime();
    return dateB - dateA;
  });

  return matchingRuns;
}

/**
 * Computes aggregated metrics for a stack based on its runs
 */
interface StackMetrics {
  lastActivity: string;
  lastUser?: string;
  runningCount: number;
  failureCount: number;
  successCount: number;
}

function computeStackMetrics(runs: Dirspace[]): StackMetrics {
  const metrics: StackMetrics = {
    lastActivity: '',
    lastUser: undefined,
    runningCount: 0,
    failureCount: 0,
    successCount: 0,
  };

  if (runs.length === 0) return metrics;

  // Last activity is the most recent run
  metrics.lastActivity = runs[0].created_at;
  metrics.lastUser = runs[0].user;

  // Count by state
  for (const run of runs) {
    if (run.state === 'running' || run.state === 'queued') {
      metrics.runningCount++;
    } else if (run.state === 'failure') {
      metrics.failureCount++;
    } else if (run.state === 'success') {
      metrics.successCount++;
    }
  }

  return metrics;
}

/**
 * Filters stacks based on search criteria
 */
export interface StackFilters {
  search?: string;
  repo?: string;
  state?: StackState | '';
}

export function filterStacks(
  stacks: StackWithRuns[],
  filters: StackFilters
): StackWithRuns[] {
  let filtered = stacks;

  // Filter by repository
  if (filters.repo) {
    filtered = filtered.filter((s) => s.repo === filters.repo);
  }

  // Filter by state
  if (filters.state) {
    filtered = filtered.filter((s) => s.state === filters.state);
  }

  // Filter by search query (matches stack name, dir, workspace)
  if (filters.search) {
    const query = filters.search.toLowerCase().trim();
    filtered = filtered.filter((s) => {
      const stackName = s.stackInner.name.toLowerCase();
      const outerName = s.stackOuter.name.toLowerCase();

      // Search in stack names
      if (stackName.includes(query) || outerName.includes(query)) {
        return true;
      }

      // Search in dirspaces
      if (s.stackInner.dirspaces) {
        for (const ds of s.stackInner.dirspaces) {
          const dir = ds.dirspace.dir.toLowerCase();
          const workspace = ds.dirspace.workspace.toLowerCase();
          if (dir.includes(query) || workspace.includes(query)) {
            return true;
          }
        }
      }

      return false;
    });
  }

  return filtered;
}

/**
 * Sorts stacks based on criteria
 */
export type StackSortBy = 'state' | 'activity' | 'repo' | 'name';

export function sortStacks(
  stacks: StackWithRuns[],
  sortBy: StackSortBy
): StackWithRuns[] {
  const sorted = [...stacks];

  switch (sortBy) {
    case 'state':
      // Sort by state severity (failures first)
      sorted.sort((a, b) => {
        const severityA = getStateSeverity(a.state);
        const severityB = getStateSeverity(b.state);
        return severityB - severityA;
      });
      break;

    case 'activity':
      // Sort by last activity (most recent first)
      sorted.sort((a, b) => {
        const dateA = new Date(a.lastActivity).getTime();
        const dateB = new Date(b.lastActivity).getTime();
        return dateB - dateA;
      });
      break;

    case 'repo':
      // Sort by repository name
      sorted.sort((a, b) => a.repo.localeCompare(b.repo));
      break;

    case 'name':
      // Sort by stack name
      sorted.sort((a, b) => a.stackInner.name.localeCompare(b.stackInner.name));
      break;
  }

  return sorted;
}

/**
 * Gets severity score for a stack state
 */
function getStateSeverity(state: StackState): number {
  const severityMap: Record<StackState, number> = {
    apply_failed: 7,
    plan_failed: 6,
    apply_pending: 5,
    plan_pending: 4,
    apply_ready: 3,
    apply_success: 2,
    no_changes: 1,
  };
  return severityMap[state] || 0;
}

/**
 * Groups stacks by PR for PR-centric view
 *
 * @param stacksWithRuns - Array of stacks with runs
 * @returns Array of PRs with their associated stacks
 */
export function groupStacksByPR(stacksWithRuns: StackWithRuns[]): PRWithStacks[] {
  const prMap = new Map<number, StackWithRuns[]>();

  // Group stacks by PR number
  for (const stack of stacksWithRuns) {
    if (!prMap.has(stack.prNumber)) {
      prMap.set(stack.prNumber, []);
    }
    prMap.get(stack.prNumber)!.push(stack);
  }

  // Transform to PRWithStacks
  const result: PRWithStacks[] = [];

  for (const [prNumber, stacks] of prMap.entries()) {
    // Use first stack for PR metadata
    const firstStack = stacks[0];

    // Calculate aggregate state (worst state wins)
    const aggregateState = calculateAggregateState(stacks.map(s => s.state));

    // Count stacks by actual stack states
    const stackStateCounts = {
      apply_success: stacks.filter(s => s.state === 'apply_success').length,
      apply_failed: stacks.filter(s => s.state === 'apply_failed').length,
      apply_pending: stacks.filter(s => s.state === 'apply_pending').length,
      apply_ready: stacks.filter(s => s.state === 'apply_ready').length,
      plan_pending: stacks.filter(s => s.state === 'plan_pending').length,
      plan_failed: stacks.filter(s => s.state === 'plan_failed').length,
      no_changes: stacks.filter(s => s.state === 'no_changes').length,
    };

    // Aggregate metrics
    const totalRunningCount = stacks.reduce((sum, s) => sum + s.runningCount, 0);
    const totalFailureCount = stacks.reduce((sum, s) => sum + s.failureCount, 0);
    const totalSuccessCount = stacks.reduce((sum, s) => sum + s.successCount, 0);

    // Find most recent activity
    const lastActivity = stacks.reduce((latest, s) => {
      return new Date(s.lastActivity) > new Date(latest) ? s.lastActivity : latest;
    }, stacks[0].lastActivity);

    const lastStack = stacks.find(s => s.lastActivity === lastActivity);

    // Create stack summaries
    const stackSummaries: StackSummary[] = stacks.map(s => ({
      stackOuter: s.stackOuter,
      stackInner: s.stackInner,
      state: s.state,
      recentRunsCount: s.recentRuns.length,
    }));

    result.push({
      prNumber,
      prTitle: firstStack.prTitle,
      repo: firstStack.repo,
      repoId: firstStack.repoId,
      aggregateState,
      stacks: stackSummaries,
      lastActivity,
      lastUser: lastStack?.lastUser,
      totalRunningCount,
      totalFailureCount,
      totalSuccessCount,
      stackStateCounts,
    });
  }

  return result;
}

/**
 * Calculates aggregate state from multiple stack states
 * Priority: failed > pending > ready > success > no_changes
 */
function calculateAggregateState(states: StackState[]): 'failed' | 'pending' | 'ready' | 'success' | 'no_changes' {
  if (states.some(s => s === 'apply_failed' || s === 'plan_failed')) {
    return 'failed';
  }
  if (states.some(s => s === 'apply_pending' || s === 'plan_pending')) {
    return 'pending';
  }
  if (states.some(s => s === 'apply_ready')) {
    return 'ready';
  }
  if (states.some(s => s === 'apply_success')) {
    return 'success';
  }
  return 'no_changes';
}

/**
 * Groups PRs by repository for repository-centric view
 *
 * @param prsWithStacks - Array of PRs with their stacks
 * @returns Array of repositories with their associated PRs
 */
export function groupStacksByRepository(prsWithStacks: PRWithStacks[]): RepositoryWithPRs[] {
  const repoMap = new Map<string, PRWithStacks[]>();

  // Group PRs by repository name
  for (const pr of prsWithStacks) {
    if (!repoMap.has(pr.repo)) {
      repoMap.set(pr.repo, []);
    }
    repoMap.get(pr.repo)!.push(pr);
  }

  // Transform to RepositoryWithPRs
  const result: RepositoryWithPRs[] = [];

  for (const [repo, prs] of repoMap.entries()) {
    // Use first PR for repo metadata
    const firstPR = prs[0];

    // Calculate aggregate state across all PRs (worst state wins)
    const allPRStates = prs.map(pr => pr.aggregateState);
    const aggregateState = calculateAggregateStateFromPRStates(allPRStates);

    // Sum stack counts across all PRs
    const stackStateCounts = {
      apply_success: prs.reduce((sum, pr) => sum + pr.stackStateCounts.apply_success, 0),
      apply_failed: prs.reduce((sum, pr) => sum + pr.stackStateCounts.apply_failed, 0),
      apply_pending: prs.reduce((sum, pr) => sum + pr.stackStateCounts.apply_pending, 0),
      apply_ready: prs.reduce((sum, pr) => sum + pr.stackStateCounts.apply_ready, 0),
      plan_pending: prs.reduce((sum, pr) => sum + pr.stackStateCounts.plan_pending, 0),
      plan_failed: prs.reduce((sum, pr) => sum + pr.stackStateCounts.plan_failed, 0),
      no_changes: prs.reduce((sum, pr) => sum + pr.stackStateCounts.no_changes, 0),
    };

    // Count total stacks across all PRs
    const totalStacks = prs.reduce((sum, pr) => sum + pr.stacks.length, 0);

    // Find most recent activity across all PRs
    const lastActivity = prs.reduce((latest, pr) => {
      return new Date(pr.lastActivity) > new Date(latest) ? pr.lastActivity : latest;
    }, prs[0].lastActivity);

    const lastPR = prs.find(pr => pr.lastActivity === lastActivity);

    result.push({
      repo,
      repoId: firstPR.repoId,
      prs,
      totalPRs: prs.length,
      totalStacks,
      aggregateState,
      stackStateCounts,
      lastActivity,
      lastUser: lastPR?.lastUser,
    });
  }

  // Sort by repository name
  result.sort((a, b) => a.repo.localeCompare(b.repo));

  return result;
}

/**
 * Calculates aggregate state from multiple PR aggregate states
 * Priority: failed > pending > ready > success > no_changes
 */
function calculateAggregateStateFromPRStates(
  states: Array<'failed' | 'pending' | 'ready' | 'success' | 'no_changes'>
): 'failed' | 'pending' | 'ready' | 'success' | 'no_changes' {
  if (states.some(s => s === 'failed')) {
    return 'failed';
  }
  if (states.some(s => s === 'pending')) {
    return 'pending';
  }
  if (states.some(s => s === 'ready')) {
    return 'ready';
  }
  if (states.some(s => s === 'success')) {
    return 'success';
  }
  return 'no_changes';
}

/**
 * Groups stacks by repository, then by unique stack name within each repository
 * Creates a hierarchical view: Repository -> Stacks -> PRs
 *
 * @param stacksWithRuns - Array of stacks with runs
 * @returns Array of repositories with their unique stacks
 */
export function groupStacksByRepositoryAndStack(stacksWithRuns: StackWithRuns[]): RepositoryWithStacks[] {
  // Group stacks by repository
  const repoMap = new Map<string, StackWithRuns[]>();

  for (const stack of stacksWithRuns) {
    if (!repoMap.has(stack.repo)) {
      repoMap.set(stack.repo, []);
    }
    repoMap.get(stack.repo)!.push(stack);
  }

  // Transform to RepositoryWithStacks
  const result: RepositoryWithStacks[] = [];

  for (const [repo, repoStacks] of repoMap.entries()) {
    // Group stacks by unique stack name within this repository
    const stackMap = new Map<string, StackWithRuns[]>();

    for (const stack of repoStacks) {
      const stackName = `${stack.stackOuter.name}/${stack.stackInner.name}`;
      if (!stackMap.has(stackName)) {
        stackMap.set(stackName, []);
      }
      stackMap.get(stackName)!.push(stack);
    }

    // Create stack summaries with their PRs
    const stacks = Array.from(stackMap.entries()).map(([stackName, stackInstances]) => {
      const firstStack = stackInstances[0];

      // Collect unique PRs for this stack
      const prMap = new Map<number, StackWithRuns>();
      for (const stack of stackInstances) {
        if (!prMap.has(stack.prNumber)) {
          prMap.set(stack.prNumber, stack);
        }
      }

      // Create PR summaries
      const prs = Array.from(prMap.values()).map(stack => ({
        prNumber: stack.prNumber,
        prTitle: stack.prTitle,
        state: mapStackStateToPRState(stack.state),
        lastActivity: stack.lastActivity,
        runCount: stack.recentRuns.length,
      }));

      // Collect unique dirspaces for this stack
      const dirspaceSet = new Set<string>();
      const dirspaces: Array<{ dir: string; workspace: string }> = [];

      for (const stack of stackInstances) {
        if (stack.stackInner.dirspaces) {
          for (const ds of stack.stackInner.dirspaces) {
            const key = `${ds.dirspace.dir}:${ds.dirspace.workspace}`;
            if (!dirspaceSet.has(key)) {
              dirspaceSet.add(key);
              dirspaces.push({
                dir: ds.dirspace.dir,
                workspace: ds.dirspace.workspace,
              });
            }
          }
        }
      }

      // Find most recent activity for this stack
      const lastActivity = stackInstances.reduce((latest, s) => {
        return new Date(s.lastActivity) > new Date(latest) ? s.lastActivity : latest;
      }, stackInstances[0].lastActivity);

      // Calculate aggregate state for this stack
      const allStackStates = stackInstances.map(s => s.state);
      const state = calculateAggregateStateFromStackStates(allStackStates);

      return {
        stackName,
        stackOuter: firstStack.stackOuter,
        stackInner: firstStack.stackInner,
        dirspaces,
        prs,
        state,
        lastActivity,
      };
    });

    // Sort stacks by name
    stacks.sort((a, b) => a.stackName.localeCompare(b.stackName));

    // Use first stack for repo metadata
    const firstStack = repoStacks[0];

    // Calculate aggregate state across all stacks (worst state wins)
    const allStackStates = stacks.map(s => s.state);
    const aggregateState = allStackStates.length > 0
      ? mapStackStateToPRState(calculateAggregateStateFromStackStates(allStackStates))
      : 'no_changes';

    // Count stack states
    const stackStateCounts = {
      apply_success: stacks.filter(s => s.state === 'apply_success').length,
      apply_failed: stacks.filter(s => s.state === 'apply_failed').length,
      apply_pending: stacks.filter(s => s.state === 'apply_pending').length,
      apply_ready: stacks.filter(s => s.state === 'apply_ready').length,
      plan_pending: stacks.filter(s => s.state === 'plan_pending').length,
      plan_failed: stacks.filter(s => s.state === 'plan_failed').length,
      no_changes: stacks.filter(s => s.state === 'no_changes').length,
    };

    // Count unique PRs across all stacks
    const uniquePRs = new Set<number>();
    for (const stack of stacks) {
      for (const pr of stack.prs) {
        uniquePRs.add(pr.prNumber);
      }
    }

    // Find most recent activity across all stacks
    const lastActivity = stacks.reduce((latest, s) => {
      return new Date(s.lastActivity) > new Date(latest) ? s.lastActivity : latest;
    }, stacks[0].lastActivity);

    const lastStack = stacks.find(s => s.lastActivity === lastActivity);

    result.push({
      repo,
      repoId: firstStack.repoId,
      stacks,
      totalStacks: stacks.length,
      totalPRs: uniquePRs.size,
      aggregateState,
      stackStateCounts,
      lastActivity,
      lastUser: lastStack?.prs.find(pr => pr.lastActivity === lastActivity)?.prTitle ? undefined : undefined, // We don't have user info in stack summaries
    });
  }

  // Sort by repository name
  result.sort((a, b) => a.repo.localeCompare(b.repo));

  return result;
}

/**
 * Groups stacks by unique stack name for stack-centric view
 *
 * @param stacksWithRuns - Array of stacks with runs
 * @returns Array of unique stacks with their associated PRs
 */
export function groupStacksByStackName(stacksWithRuns: StackWithRuns[]): StackWithPRs[] {
  // Use a map to group by stack name (outer/inner combination)
  const stackMap = new Map<string, StackWithRuns[]>();

  // Group stacks by name
  for (const stack of stacksWithRuns) {
    const stackName = `${stack.stackOuter.name}/${stack.stackInner.name}`;
    if (!stackMap.has(stackName)) {
      stackMap.set(stackName, []);
    }
    stackMap.get(stackName)!.push(stack);
  }

  // Transform to StackWithPRs
  const result: StackWithPRs[] = [];

  for (const [stackName, stacks] of stackMap.entries()) {
    // Use first stack for stack metadata
    const firstStack = stacks[0];

    // Collect all unique PRs that touch this stack
    const prMap = new Map<number, StackWithRuns>();
    for (const stack of stacks) {
      if (!prMap.has(stack.prNumber)) {
        prMap.set(stack.prNumber, stack);
      }
    }

    // Create PR summaries
    const prs = Array.from(prMap.values()).map(stack => {
      // Determine PR-level aggregate state from this stack's state
      const prState = mapStackStateToPRState(stack.state);

      return {
        prNumber: stack.prNumber,
        prTitle: stack.prTitle,
        repo: stack.repo,
        repoId: stack.repoId,
        state: prState,
        lastActivity: stack.lastActivity,
        runCount: stack.recentRuns.length,
      };
    });

    // Calculate aggregate state across all stacks (worst state wins)
    const allStackStates = stacks.map(s => s.state);
    const aggregateState = calculateAggregateStateFromStackStates(allStackStates);

    // Collect all unique dirspaces for this stack
    const dirspaceSet = new Set<string>();
    const dirspaces: Array<{ dir: string; workspace: string }> = [];

    for (const stack of stacks) {
      if (stack.stackInner.dirspaces) {
        for (const ds of stack.stackInner.dirspaces) {
          const key = `${ds.dirspace.dir}:${ds.dirspace.workspace}`;
          if (!dirspaceSet.has(key)) {
            dirspaceSet.add(key);
            dirspaces.push({
              dir: ds.dirspace.dir,
              workspace: ds.dirspace.workspace,
            });
          }
        }
      }
    }

    // Find most recent activity across all PRs
    const lastActivity = stacks.reduce((latest, s) => {
      return new Date(s.lastActivity) > new Date(latest) ? s.lastActivity : latest;
    }, stacks[0].lastActivity);

    const lastStack = stacks.find(s => s.lastActivity === lastActivity);

    result.push({
      stackName,
      stackOuter: firstStack.stackOuter,
      stackInner: firstStack.stackInner,
      dirspaces,
      prs,
      totalPRs: prMap.size,
      aggregateState,
      lastActivity,
      lastUser: lastStack?.lastUser,
    });
  }

  // Sort by stack name
  result.sort((a, b) => a.stackName.localeCompare(b.stackName));

  return result;
}

/**
 * Maps a StackState to a PR-level aggregate state
 */
function mapStackStateToPRState(
  state: StackState
): 'failed' | 'pending' | 'ready' | 'success' | 'no_changes' {
  if (state === 'apply_failed' || state === 'plan_failed') {
    return 'failed';
  }
  if (state === 'apply_pending' || state === 'plan_pending') {
    return 'pending';
  }
  if (state === 'apply_ready') {
    return 'ready';
  }
  if (state === 'apply_success') {
    return 'success';
  }
  return 'no_changes';
}

/**
 * Calculates aggregate state from multiple stack states (for stack-centric view)
 * Returns the StackState type (not PR aggregate state)
 * Priority: apply_failed > plan_failed > apply_pending > plan_pending > apply_ready > apply_success > no_changes
 */
function calculateAggregateStateFromStackStates(states: StackState[]): StackState {
  if (states.some(s => s === 'apply_failed')) {
    return 'apply_failed';
  }
  if (states.some(s => s === 'plan_failed')) {
    return 'plan_failed';
  }
  if (states.some(s => s === 'apply_pending')) {
    return 'apply_pending';
  }
  if (states.some(s => s === 'plan_pending')) {
    return 'plan_pending';
  }
  if (states.some(s => s === 'apply_ready')) {
    return 'apply_ready';
  }
  if (states.some(s => s === 'apply_success')) {
    return 'apply_success';
  }
  return 'no_changes';
}

/**
 * Computes dashboard metrics and KPIs from stacks data
 *
 * @param stacksWithRuns - Array of stacks with runs
 * @param prsWithStacks - Array of PRs with stacks
 * @param dirspaces - All dirspaces (runs)
 * @param timeRange - Time range in days
 * @returns Dashboard metrics
 */
export function computeDashboardMetrics(
  stacksWithRuns: StackWithRuns[],
  prsWithStacks: PRWithStacks[],
  dirspaces: Dirspace[],
  timeRange: number
): DashboardMetrics {
  // Overall counts
  const totalPRs = prsWithStacks.length;
  const totalStacks = stacksWithRuns.length;
  const totalRuns = dirspaces.length;
  const uniqueRepos = new Set(prsWithStacks.map(pr => pr.repo)).size;

  // PR state distribution
  const prStateCounts = {
    failed: prsWithStacks.filter(pr => pr.aggregateState === 'failed').length,
    pending: prsWithStacks.filter(pr => pr.aggregateState === 'pending').length,
    ready: prsWithStacks.filter(pr => pr.aggregateState === 'ready').length,
    success: prsWithStacks.filter(pr => pr.aggregateState === 'success').length,
    no_changes: prsWithStacks.filter(pr => pr.aggregateState === 'no_changes').length,
  };

  // Stack state distribution
  const stackStateCounts = {
    apply_success: stacksWithRuns.filter(s => s.state === 'apply_success').length,
    apply_failed: stacksWithRuns.filter(s => s.state === 'apply_failed').length,
    apply_pending: stacksWithRuns.filter(s => s.state === 'apply_pending').length,
    apply_ready: stacksWithRuns.filter(s => s.state === 'apply_ready').length,
    plan_pending: stacksWithRuns.filter(s => s.state === 'plan_pending').length,
    plan_failed: stacksWithRuns.filter(s => s.state === 'plan_failed').length,
    no_changes: stacksWithRuns.filter(s => s.state === 'no_changes').length,
  };

  // Calculate failure rate (failed runs / total runs)
  const failedRuns = dirspaces.filter(d => d.state === 'failure').length;
  const failureRate = totalRuns > 0 ? (failedRuns / totalRuns) * 100 : 0;

  // Top failing stacks (by failure count across all runs)
  const stackFailureMap = new Map<string, { count: number; prCount: number }>();
  for (const stack of stacksWithRuns) {
    const stackName = `${stack.stackOuter.name}/${stack.stackInner.name}`;
    const existing = stackFailureMap.get(stackName) || { count: 0, prCount: 0 };
    existing.count += stack.failureCount;
    existing.prCount++;
    stackFailureMap.set(stackName, existing);
  }

  const topFailingStacks = Array.from(stackFailureMap.entries())
    .map(([stackName, data]) => ({
      stackName,
      failureCount: data.count,
      prCount: data.prCount,
    }))
    .filter(item => item.failureCount > 0) // Only show stacks with actual failures
    .sort((a, b) => b.failureCount - a.failureCount)
    .slice(0, 5);

  // Top failing repos (by failure count across all PRs)
  const repoFailureMap = new Map<string, { count: number; prCount: number }>();
  for (const pr of prsWithStacks) {
    const existing = repoFailureMap.get(pr.repo) || { count: 0, prCount: 0 };
    existing.count += pr.totalFailureCount;
    existing.prCount++;
    repoFailureMap.set(pr.repo, existing);
  }

  const topFailingRepos = Array.from(repoFailureMap.entries())
    .map(([repo, data]) => ({
      repo,
      failureCount: data.count,
      prCount: data.prCount,
    }))
    .filter(item => item.failureCount > 0) // Only show repos with actual failures
    .sort((a, b) => b.failureCount - a.failureCount)
    .slice(0, 5);

  // Activity by day (group dirspaces by date)
  const activityMap = new Map<string, { runs: number; prSet: Set<number> }>();

  for (const dirspace of dirspaces) {
    const date = dirspace.created_at.split('T')[0]; // Extract YYYY-MM-DD
    const existing = activityMap.get(date) || { runs: 0, prSet: new Set<number>() };
    existing.runs++;

    // Track unique PRs per day
    if (dirspace.kind && typeof dirspace.kind === 'object' && 'pull_number' in dirspace.kind) {
      existing.prSet.add(dirspace.kind.pull_number);
    }

    activityMap.set(date, existing);
  }

  const activityByDay = Array.from(activityMap.entries())
    .map(([date, data]) => ({
      date,
      runs: data.runs,
      prs: data.prSet.size,
    }))
    .sort((a, b) => a.date.localeCompare(b.date)); // Sort by date ascending

  // Open PRs (sorted by most recent activity)
  const openPRs = prsWithStacks
    .filter(pr => pr && pr.prNumber && pr.repo && pr.aggregateState && pr.stacks && pr.lastActivity)
    .map(pr => ({
      prNumber: pr.prNumber,
      prTitle: pr.prTitle || `PR #${pr.prNumber}`,
      repo: pr.repo,
      state: pr.aggregateState,
      stackCount: pr.stacks?.length || 0,
      lastActivity: pr.lastActivity,
    }))
    .sort((a, b) => {
      // Sort by last activity (most recent first)
      try {
        const dateA = new Date(a.lastActivity).getTime();
        const dateB = new Date(b.lastActivity).getTime();
        return dateB - dateA;
      } catch {
        return 0;
      }
    })
    .slice(0, 10); // Show top 10 most recent PRs

  return {
    totalPRs,
    totalStacks,
    totalRuns,
    uniqueRepos,
    prStateCounts,
    stackStateCounts,
    failureRate,
    topFailingStacks,
    topFailingRepos,
    activityByDay,
    openPRs,
    timeRange,
  };
}

/**
 * Generates timeline events from dirspaces for chronological activity view
 *
 * @param dirspaces - All dirspaces (runs)
 * @param stacksWithRuns - Array of stacks with runs (for context)
 * @param limit - Maximum number of events to return (default: 100)
 * @returns Array of timeline events sorted by timestamp descending
 */
export function generateTimelineData(
  dirspaces: Dirspace[],
  stacksWithRuns: StackWithRuns[],
  limit: number = 100
): TimelineEvent[] {
  // Create a map of PR metadata for quick lookup
  const prMetadataMap = new Map<number, { prTitle?: string }>();
  const stackNameMap = new Map<string, string>(); // dir:workspace -> stackName

  for (const stack of stacksWithRuns) {
    // Store PR metadata
    if (stack.prNumber && stack.prTitle) {
      prMetadataMap.set(stack.prNumber, { prTitle: stack.prTitle });
    }

    // Store stack name for each dirspace
    if (stack.stackInner.dirspaces) {
      const stackName = `${stack.stackOuter.name}/${stack.stackInner.name}`;
      for (const ds of stack.stackInner.dirspaces) {
        const key = `${ds.dirspace.dir}:${ds.dirspace.workspace}`;
        stackNameMap.set(key, stackName);
      }
    }
  }

  // Convert dirspaces to timeline events
  const events: TimelineEvent[] = dirspaces.map((dirspace) => {
    // Determine event type based on state
    let type: 'run_started' | 'run_completed' | 'run_failed';
    if (dirspace.state === 'failure') {
      type = 'run_failed';
    } else if (dirspace.state === 'running' || dirspace.state === 'queued') {
      type = 'run_started';
    } else {
      type = 'run_completed';
    }

    // Get PR context if available
    let prNumber: number | undefined;
    let prTitle: string | undefined;

    if (dirspace.kind && typeof dirspace.kind === 'object' && 'pull_number' in dirspace.kind) {
      prNumber = dirspace.kind.pull_number;
      const prMetadata = prMetadataMap.get(prNumber);
      prTitle = prMetadata?.prTitle || (dirspace.kind as any).pull_request_title;
    }

    // Get stack name from map
    const dirspaceKey = `${dirspace.dir}:${dirspace.workspace}`;
    const stackName = stackNameMap.get(dirspaceKey);

    // Use completed_at if available, otherwise created_at
    const timestamp = dirspace.completed_at || dirspace.created_at;

    return {
      id: dirspace.id,
      timestamp,
      type,
      runId: dirspace.run_id,
      runType: dirspace.run_type,
      runState: dirspace.state,
      prNumber,
      prTitle,
      repo: dirspace.repo,
      stackName,
      dir: dirspace.dir,
      workspace: dirspace.workspace,
      user: dirspace.user,
    };
  });

  // Sort by timestamp descending (newest first)
  events.sort((a, b) => {
    const dateA = new Date(a.timestamp).getTime();
    const dateB = new Date(b.timestamp).getTime();
    return dateB - dateA;
  });

  // Limit to most recent N events
  return events.slice(0, limit);
}
