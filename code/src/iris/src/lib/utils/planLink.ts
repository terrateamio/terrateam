/** A Tag Query Language term matching `value` exactly. The whole term is
 *  quoted so a path with spaces, parentheses or quotes stays one term. */
function tagTerm(key: string, value: string): string {
  return `"${key}:${value.replace(/[\\"]/g, '\\$&')}"`;
}

/** Runs query for the plans of one dirspace of one pull request. The runs
 *  endpoint returns the newest first. */
export function latestPlanQuery(prNumber: number, repo: string, dir: string, workspace: string): string {
  return [
    `pr:${prNumber}`,
    tagTerm('repo', repo),
    tagTerm('dir', dir),
    tagTerm('workspace', workspace),
    'type:plan',
  ].join(' and ');
}

/** Run detail path that opens on the steps of one dirspace. */
export function runDirspacePath(runId: string, dir: string, workspace: string): string {
  return `/runs/${runId}?${new URLSearchParams({ dir, workspace })}`;
}

/** The dirspace a run detail query string names, or null. */
export function dirspaceOfQuery(querystring: string | undefined): { dir: string; workspace: string } | null {
  const q = new URLSearchParams(querystring ?? '');
  const dir = q.get('dir');
  const workspace = q.get('workspace');
  return dir !== null && workspace !== null ? { dir, workspace } : null;
}
