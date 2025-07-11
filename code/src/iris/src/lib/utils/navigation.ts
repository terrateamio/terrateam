// Navigation utilities for installation-scoped URLs

import { get } from 'svelte/store';
import { selectedInstallation } from '../stores';

/**
 * Navigate to an installation-scoped path
 * @param path - The path without installation ID (e.g., '/runs/123' or '/dashboard')
 * @param installationId - Optional specific installation ID, defaults to current selected installation
 */
export function navigateToInstallationPath(path: string, installationId?: string): void {
  const currentInstallation = installationId || get(selectedInstallation)?.id;
  
  if (!currentInstallation) {
    console.warn('Cannot navigate: no installation selected');
    return;
  }
  
  // Ensure path starts with /
  const cleanPath = path.startsWith('/') ? path : `/${path}`;
  
  // Build installation-scoped URL
  const fullPath = `#/i/${currentInstallation}${cleanPath}`;
  
  window.location.hash = fullPath;
}

/**
 * Navigate to a run detail page
 * @param runId - The run/work manifest ID
 * @param installationId - Optional specific installation ID
 */
export function navigateToRun(runId: string, installationId?: string): void {
  navigateToInstallationPath(`/runs/${runId}`, installationId);
}

/**
 * Navigate to runs list with optional query
 * @param query - Optional search query (e.g., 'state:success')
 * @param installationId - Optional specific installation ID
 */
export function navigateToRuns(query?: string, installationId?: string): void {
  const basePath = '/runs';
  const pathWithQuery = query ? `${basePath}?q=${encodeURIComponent(query)}` : basePath;
  navigateToInstallationPath(pathWithQuery, installationId);
}

/**
 * Navigate to repositories list
 * @param installationId - Optional specific installation ID
 */
export function navigateToRepositories(installationId?: string): void {
  navigateToInstallationPath('/repositories', installationId);
}

/**
 * Navigate to a repository detail page
 * @param repositoryId - The repository ID
 * @param installationId - Optional specific installation ID
 */
export function navigateToRepository(repositoryId: string, installationId?: string): void {
  navigateToInstallationPath(`/repositories/${repositoryId}`, installationId);
}

/**
 * Navigate to workspaces with optional query parameters
 * @param params - Optional query parameters (e.g., { since: '2024-01-01' })
 * @param installationId - Optional specific installation ID
 */
export function navigateToWorkspaces(params?: Record<string, string>, installationId?: string): void {
  let path = '/workspaces';
  
  if (params) {
    const queryString = new URLSearchParams(params).toString();
    path = `${path}?${queryString}`;
  }
  
  navigateToInstallationPath(path, installationId);
}

/**
 * Navigate to a specific workspace detail page
 * @param repo - Repository name
 * @param dir - Directory path
 * @param workspace - Workspace name
 * @param installationId - Optional specific installation ID
 */
export function navigateToWorkspace(repo: string, dir: string, workspace: string, installationId?: string): void {
  const path = `/workspaces/${repo}/${encodeURIComponent(dir)}/${encodeURIComponent(workspace)}`;
  navigateToInstallationPath(path, installationId);
}

/**
 * Navigate to dashboard
 * @param installationId - Optional specific installation ID
 */
export function navigateToDashboard(installationId?: string): void {
  navigateToInstallationPath('/dashboard', installationId);
}
