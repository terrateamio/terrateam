// Enhanced API client with runtime validation and accurate types
// This is the new type-safe API client that replaces api.ts

import type { ApiRequestOptions } from './types';
import {
  type Installation,
  type Repository,
  type Dirspace,
  type WorkManifest,
  type User,
  type ServerConfig,
  type GitLabGroup,
  type GitLabUser,
  type GitLabWebhook,
  type GitLabWhoAreYou,
  validateRepository,
  validateUser,
  validateDirspace,
  validateServerConfig,
  validateInstallations,
  validateRepositories,
  validateDirspaces,
  validateWorkManifests,
  validateGitLabGroups,
  validateGitLabUser,
  validateGitLabWebhook,
  validateGitLabWhoAreYou,
} from './types';
import { sentryService } from './sentry';
import { get } from 'svelte/store';
import { selectedInstallation, currentVCSProvider } from './stores';
import type { VCSProvider } from './vcs/types';
import { getProviderApiPath } from './vcs/providers';

class ApiError extends Error {
  constructor(
    public message: string,
    public status: number,
    public response?: Response,
    public data?: unknown
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

export class ValidatedApiClient {
  private baseUrl: string;

  constructor(baseUrl: string = '') {
    this.baseUrl = baseUrl;
  }

  // Get the API path for the current or specified VCS provider
  private getProviderPath(provider?: VCSProvider): string {
    const currentProvider = provider || get(currentVCSProvider);
    return getProviderApiPath(currentProvider);
  }

  private lastResponseHeaders: Headers | null = null;
  
  private async request<T>(
    endpoint: string,
    options: ApiRequestOptions = {}
  ): Promise<T> {
    const {
      method = 'GET',
      headers = {},
      body,
      params,
    } = options;

    // Build URL with query parameters
    let url = `${this.baseUrl}${endpoint}`;
    if (params && Object.keys(params).length > 0) {
      const searchParams = new URLSearchParams(params);
      url += `?${searchParams.toString()}`;
    }

    // Prepare request options
    const requestOptions: RequestInit = {
      method,
      headers: {
        'Content-Type': 'application/json',
        ...headers,
      },
      credentials: 'include',
    };

    if (body) {
      requestOptions.body = body;
    }

    try {
      
      const response = await fetch(url, requestOptions);
      
      // Store headers for pagination
      this.lastResponseHeaders = response.headers;
      
      const responseText = await response.text();

      // Add breadcrumb for all API calls
      sentryService.addBreadcrumb(
        `API ${method} ${endpoint}`,
        'api',
        response.ok ? 'info' : 'error',
        {
          status: response.status,
          statusText: response.statusText
        }
      );

      if (!response.ok) {
        let errorData: unknown;
        try {
          errorData = responseText ? JSON.parse(responseText) : null;
        } catch {
          errorData = responseText;
        }
        
        const apiError = new ApiError(
          `HTTP ${response.status}: ${response.statusText}`,
          response.status,
          response,
          errorData
        );
        
        // Track API error in Sentry
        const currentInstallation = get(selectedInstallation);
        sentryService.captureApiError(
          apiError,
          endpoint,
          method,
          response.status,
          currentInstallation?.id
        );
        sentryService.addBreadcrumb(
          `API Error: ${method} ${endpoint}`,
          'api',
          'error',
          {
            status: response.status,
            statusText: response.statusText,
            errorData
          }
        );
        
        throw apiError;
      }

      return responseText ? JSON.parse(responseText) : ({} as T);
    } catch (error) {
      if (error instanceof ApiError) {
        throw error;
      }
      console.error('API request failed:', error);
      
      // Track network error in Sentry
      if (error instanceof Error) {
        const currentInstallation = get(selectedInstallation);
        sentryService.captureApiError(
          error,
          endpoint,
          method,
          0,
          currentInstallation?.id
        );
      }
      
      throw new ApiError(
        error instanceof Error ? error.message : 'Network error',
        0
      );
    }
  }

  // Utility methods
  async get<T>(endpoint: string, params?: Record<string, string>): Promise<T> {
    return this.request<T>(endpoint, { method: 'GET', params });
  }

  async post<T>(endpoint: string, data?: unknown): Promise<T> {
    return this.request<T>(endpoint, {
      method: 'POST',
      body: data ? JSON.stringify(data) : undefined,
    });
  }

  async put<T>(endpoint: string, data?: unknown): Promise<T> {
    return this.request<T>(endpoint, {
      method: 'PUT',
      body: data ? JSON.stringify(data) : undefined,
    });
  }

  async delete<T>(endpoint: string): Promise<T> {
    return this.request<T>(endpoint, { method: 'DELETE' });
  }

  // Validated API methods with runtime type checking

  // Server configuration
  async getServerConfig(): Promise<ServerConfig> {
    const response = await this.get('/api/v1/server/config');
    return validateServerConfig(response);
  }

  // User authentication
  async getCurrentUser(): Promise<User> {
    const response = await this.get('/api/v1/whoami');
    return validateUser(response);
  }

  // VCS user information (GitHub/GitLab)
  async getVCSUser(provider?: VCSProvider): Promise<{ avatar_url?: string; username: string }> {
    const providerPath = this.getProviderPath(provider);
    const response = await this.get(`${providerPath}/whoami`);
    
    // Validate the VCS user response structure
    if (!response || typeof response !== 'object' || !('username' in response)) {
      throw new ApiError('Invalid VCS user response format', 422);
    }

    return response as { avatar_url?: string; username: string };
  }

  // Legacy method for backward compatibility
  async getGitHubUser(): Promise<{ avatar_url?: string; username: string }> {
    return this.getVCSUser('github');
  }

  // Installations
  async getUserInstallations(provider?: VCSProvider): Promise<{ installations: Installation[] }> {
    const currentProvider = provider || get(currentVCSProvider);
    
    // GitLab uses a different path structure than GitHub
    let endpoint: string;
    if (currentProvider === 'gitlab') {
      endpoint = '/api/v1/gitlab/installations';
    } else {
      // GitHub uses /user/github/installations
      endpoint = '/api/v1/user/github/installations';
    }
    
    const response = await this.get(endpoint);
    
    // Validate the response structure
    if (!response || typeof response !== 'object' || !('installations' in response)) {
      throw new ApiError('Invalid installations response format', 422);
    }

    const installations = validateInstallations(response.installations);
    return { installations };
  }

  // Note: Individual installation endpoint not available in API
  // async getInstallation(installationId: string): Promise<Installation> {
  //   const response = await this.get(`/api/v1/github/installations/${installationId}`);
  //   return validateInstallation(response);
  // }

  // Repositories with cursor-based pagination
  async getInstallationRepos(
    installationId: string, 
    params?: { cursor?: string; page?: number },
    provider?: VCSProvider
  ): Promise<{ repositories: Repository[]; nextCursor?: string; hasMore: boolean }> {
    const providerPath = this.getProviderPath(provider);
    
    // Build the URL manually to avoid encoding issues with the cursor
    let endpoint = `${providerPath}/installations/${installationId}/repos`;
    
    if (params?.cursor) {
      // The API expects the cursor value without URL encoding
      // So we build the URL manually instead of using URLSearchParams
      endpoint += `?page=${params.cursor}`;
    }
    
    // Use the endpoint directly without additional params
    const response = await this.request(endpoint, { method: 'GET' });
    
    // Check Link header for pagination
    const linkHeader = this.lastResponseHeaders?.get('Link') || this.lastResponseHeaders?.get('link');
    
    // Validate the response structure
    if (!response || typeof response !== 'object' || !('repositories' in response)) {
      throw new ApiError('Invalid repositories response format', 422);
    }

    const repositories = validateRepositories(response.repositories);
    
    // Extract pagination info from Link header
    let nextCursor: string | undefined;
    let hasMore = false;
    
    // Parse Link header for pagination (RFC 5988)
    if (linkHeader) {
      const links = this.parseLinkHeader(linkHeader);
      
      if (links.next) {
        // Extract page parameter from next URL
        try {
          // The URL might be relative, so we need to handle it carefully
          const nextUrl = links.next.startsWith('http') 
            ? new URL(links.next)
            : new URL(links.next, 'https://app.terrateam.io');
          
          nextCursor = nextUrl.searchParams.get('page') || undefined;
          hasMore = true;
        } catch (e) {
          console.error('Failed to parse next URL from Link header:', e);
        }
      }
    }
    
    // Only check response body for pagination if we didn't find it in Link headers
    if (!nextCursor && !hasMore) {
      // Check for various pagination field formats
      // 1. Check for pagination metadata object
      if ('pagination' in response && response.pagination && typeof response.pagination === 'object') {
        const pagination = response.pagination as Record<string, any>;
        nextCursor = pagination.next_cursor || pagination.nextCursor || pagination.next || pagination.cursor;
        hasMore = pagination.has_more !== undefined ? pagination.has_more : 
                  pagination.hasMore !== undefined ? pagination.hasMore : !!nextCursor;
      }
      // 2. Check for next_cursor at top level
      else if ('next_cursor' in response || 'nextCursor' in response) {
        const resp = response as any;
        nextCursor = (resp.next_cursor || resp.nextCursor) as string | undefined;
        hasMore = !!nextCursor;
      }
      // 3. Check for next_page at top level
      else if ('next_page' in response || 'nextPage' in response) {
        const resp = response as any;
        nextCursor = (resp.next_page || resp.nextPage) as string | undefined;
        hasMore = !!nextCursor;
      }
      // 4. Check for next at top level
      else if ('next' in response) {
        nextCursor = response.next as string | undefined;
        hasMore = !!nextCursor;
      }
      // 5. Check for page_info object
      else if ('page_info' in response || 'pageInfo' in response) {
        const resp = response as any;
        const pageInfo = (resp.page_info || resp.pageInfo) as Record<string, any>;
        nextCursor = pageInfo.next_cursor || pageInfo.nextCursor || pageInfo.endCursor;
        hasMore = pageInfo.has_next_page !== undefined ? pageInfo.has_next_page : 
                  pageInfo.hasNextPage !== undefined ? pageInfo.hasNextPage : !!nextCursor;
      }
      // 6. Check meta/metadata
      else if ('meta' in response || 'metadata' in response) {
        const resp = response as any;
        const meta = (resp.meta || resp.metadata) as Record<string, any>;
        nextCursor = meta.next_cursor || meta.nextCursor || meta.next;
        hasMore = meta.has_more !== undefined ? meta.has_more : !!nextCursor;
      }
      // No pagination info found
      else {
        // If we didn't find pagination info and got exactly 20 repositories, assume there might be more
        if (repositories.length === 20) {
          hasMore = true;
        }
      }
    }
    
    return { repositories, nextCursor, hasMore };
  }
  
  // Parse Link header according to RFC 5988
  private parseLinkHeader(header: string): Record<string, string> {
    const links: Record<string, string> = {};
    
    // The API returns Link headers in RFC 5988 format
    // Example: <https://app.terrateam.io//api/v1/github/installations/48988185/repos?page=n,perderlo>; rel="next"
    
    // Use a more robust regex that captures the entire link structure
    // This handles URLs with commas in query parameters
    const linkRegex = /<([^>]+)>;\s*rel="([^"]+)"/g;
    let match;
    
    while ((match = linkRegex.exec(header)) !== null) {
      const [, url, rel] = match;
      links[rel] = url;
    }
    
    return links;
  }

  async getRepository(installationId: string, repoId: string, provider?: VCSProvider): Promise<Repository> {
    const providerPath = this.getProviderPath(provider);
    const response = await this.get(`${providerPath}/installations/${installationId}/repos/${repoId}`);
    return validateRepository(response);
  }

  async refreshInstallationRepos(installationId: string, provider?: VCSProvider): Promise<{ id: string }> {
    const providerPath = this.getProviderPath(provider);
    const response = await this.post(`${providerPath}/installations/${installationId}/repos/refresh`);
    
    // Validate the response structure
    if (!response || typeof response !== 'object' || !('id' in response)) {
      throw new ApiError('Invalid refresh response format', 422);
    }
    
    return { id: response.id as string };
  }

  // Dirspaces with pagination
  async getInstallationDirspaces(
    installationId: string, 
    params?: { q?: string; tz?: string; limit?: number; d?: string; page?: string[] },
    provider?: VCSProvider
  ): Promise<{ dirspaces: Dirspace[]; nextCursor?: string; hasMore: boolean }> {
    const providerPath = this.getProviderPath(provider);
    
    // Always use dirspaces endpoint - it handles all Tag Query Language queries including repo: filters
    let endpoint = `${providerPath}/installations/${installationId}/dirspaces`;
    
    if (params) {
      const queryParams = new URLSearchParams();
      if (params.q) queryParams.set('q', params.q);
      if (params.tz) queryParams.set('tz', params.tz);
      if (params.limit) queryParams.set('limit', params.limit.toString());
      if (params.d) queryParams.set('d', params.d);
      
      // Handle page array parameter for cursor-based pagination
      if (params.page && params.page.length > 0) {
        params.page.forEach(cursor => {
          queryParams.append('page', cursor);
        });
      }
      
      const queryString = queryParams.toString();
      if (queryString) endpoint += `?${queryString}`;
    }
    
    const response = await this.get(endpoint);
    
    // Validate the response structure
    if (!response || typeof response !== 'object') {
      throw new ApiError('Invalid response format', 422);
    }

    if ('dirspaces' in response) {
      const dirspaces = validateDirspaces(response.dirspaces);

      // The dirspaces API doesn't return pagination metadata
      // The caller should use date-based pagination with created_at filters
      return { dirspaces, hasMore: false };
    } else {
      throw new ApiError('Invalid dirspaces response format - expected dirspaces', 422);
    }
  }

  async getDirspace(installationId: string, dirspaceId: string, provider?: VCSProvider): Promise<Dirspace> {
    const providerPath = this.getProviderPath(provider);
    const response = await this.get(`${providerPath}/installations/${installationId}/dirspaces/${dirspaceId}`);
    return validateDirspace(response);
  }

  // Work Manifests
  async getInstallationWorkManifests(installationId: string, provider?: VCSProvider): Promise<{ work_manifests: WorkManifest[] }> {
    const providerPath = this.getProviderPath(provider);
    const response = await this.get(`${providerPath}/installations/${installationId}/work-manifests`);
    
    // Validate the response structure
    if (!response || typeof response !== 'object' || !('work_manifests' in response)) {
      throw new ApiError('Invalid work manifests response format', 422);
    }

    const work_manifests = validateWorkManifests(response.work_manifests);
    return { work_manifests };
  }

  async getWorkManifest(installationId: string, workManifestId: string, provider?: VCSProvider): Promise<WorkManifest> {
    const providerPath = this.getProviderPath(provider);
    // Use query-based approach as shown in the OCaml UI
    const response = await this.get(`${providerPath}/installations/${installationId}/work-manifests`, {
      q: `id:${workManifestId}`
    });
    
    // Validate the response structure
    if (!response || typeof response !== 'object' || !('work_manifests' in response)) {
      throw new ApiError('Invalid work manifests response format', 422);
    }

    const work_manifests = validateWorkManifests(response.work_manifests);
    
    if (work_manifests.length === 0) {
      throw new ApiError(`Work manifest not found: ${workManifestId}`, 404);
    }
    
    return work_manifests[0];
  }

  // Work Manifest Outputs
  async getWorkManifestOutputs(
    installationId: string, 
    workManifestId: string, 
    params?: { 
      q?: string; 
      limit?: number; 
      lite?: boolean;
      page?: string;
    },
    provider?: VCSProvider
  ): Promise<{ outputs: unknown[] }> {
    const providerPath = this.getProviderPath(provider);
    let endpoint = `${providerPath}/installations/${installationId}/work-manifests/${workManifestId}/outputs`;
    
    if (params) {
      const queryParams = new URLSearchParams();
      if (params.q) queryParams.set('q', params.q);
      if (params.limit) queryParams.set('limit', params.limit.toString());
      if (params.lite !== undefined) queryParams.set('lite', params.lite.toString());
      if (params.page) queryParams.set('page', params.page);
      
      const queryString = queryParams.toString();
      if (queryString) endpoint += `?${queryString}`;
    }
    
    const response = await this.get(endpoint);
    
    // API returns { steps: [...] } not { outputs: [...] }
    if (!response || typeof response !== 'object' || !('steps' in response)) {
      throw new ApiError('Invalid outputs response format', 422);
    }

    // Convert steps to outputs for consistent interface
    return { outputs: response.steps as unknown[] };
  }

  // Note: Workflow steps endpoint not available in API
  // async getInstallationWorkflowSteps(installationId: string): Promise<{ steps: unknown[] }> {
  //   const response = await this.get(`/api/v1/github/installations/${installationId}/workflow-steps`);
  //   
  //   // Note: workflow steps don't have a specific schema yet, so we return as unknown
  //   if (!response || typeof response !== 'object' || !('steps' in response)) {
  //     throw new ApiError('Invalid workflow steps response format', 422);
  //   }
  //
  //   return response as { steps: unknown[] };
  // }

  // Admin operations (if needed)
  async getInstallationWorkManifest(installationId: string, workManifestId: string): Promise<WorkManifest> {
    // Use the same query-based approach
    return this.getWorkManifest(installationId, workManifestId);
  }

  // Admin drift operations
  async getAdminDrifts(): Promise<{ results: Array<{
    id: string;
    name: string;
    owner: string;
    created_at: string;
    completed_at?: string;
    state: string;
    run_type: string;
    unlocked: boolean;
  }> }> {
    const response = await this.get('/api/v1/admin/drifts');
    
    // Validate the response structure
    if (!response || typeof response !== 'object' || !('results' in response)) {
      throw new ApiError('Invalid admin drifts response format', 422);
    }

    return response as { results: Array<{
      id: string;
      name: string;
      owner: string;
      created_at: string;
      completed_at?: string;
      state: string;
      run_type: string;
      unlocked: boolean;
    }> };
  }

  // Task operations
  async getTask(taskId: string): Promise<{
    id: string;
    name: string;
    state: 'aborted' | 'pending' | 'running' | 'completed' | 'failed';
    updated_at: string;
  }> {
    const response = await this.get(`/api/v1/tasks/${taskId}`);
    
    // Validate the response structure
    if (!response || typeof response !== 'object' || 
        !('id' in response) || !('name' in response) || 
        !('state' in response) || !('updated_at' in response)) {
      throw new ApiError('Invalid task response format', 422);
    }

    return response as {
      id: string;
      name: string;
      state: 'aborted' | 'pending' | 'running' | 'completed' | 'failed';
      updated_at: string;
    };
  }

  // GitLab-specific operations
  async getGitLabGroups(): Promise<GitLabGroup[]> {
    const response = await this.get('/api/v1/gitlab/groups');
    
    // API returns array directly, not wrapped in object
    if (!Array.isArray(response)) {
      throw new ApiError('Invalid GitLab groups response format', 422);
    }
    
    return validateGitLabGroups(response);
  }

  async checkGitLabGroupMembership(groupId: number): Promise<boolean> {
    const response = await this.get(`/api/v1/gitlab/groups/${groupId}/is-member`);
    
    // Validate the response structure
    if (!response || typeof response !== 'object' || !('result' in response)) {
      throw new ApiError('Invalid GitLab group membership response format', 422);
    }
    
    return response.result as boolean;
  }

  async getGitLabWebhookConfig(installationId: string): Promise<GitLabWebhook> {
    const response = await this.get(`/api/v1/gitlab/installations/${installationId}/webhook`);
    return validateGitLabWebhook(response);
  }

  // GitLab user operations (already have generic getVCSUser for this)
  async getGitLabUser(): Promise<GitLabUser> {
    const response = await this.get('/api/v1/gitlab/whoami');
    return validateGitLabUser(response);
  }

  // Get GitLab bot information
  async getGitLabBotInfo(): Promise<GitLabWhoAreYou> {
    const response = await this.get('/api/v1/gitlab/whoareyou');
    return validateGitLabWhoAreYou(response);
  }

}

// Create and export the API client instance
export const api = new ValidatedApiClient();

// Export the error class for error handling
export { ApiError };

// Re-export validation functions for convenience
export {
  validateInstallation,
  validateRepository,
  validateUser,
  validateDirspace,
  validateWorkManifest,
  validateServerConfig,
  validateInstallations,
  validateRepositories,
  validateDirspaces,
  validateWorkManifests,
  validateGitLabGroups,
  validateGitLabUser,
  validateGitLabWebhook,
} from './types';

// Type-safe error handling utility
export function isApiError(error: unknown): error is ApiError {
  return error instanceof ApiError;
}

// Validation error handling
export function handleValidationError(error: unknown): string {
  if (error instanceof Error) {
    // Check if it's a Zod validation error
    if ('issues' in error && Array.isArray(error.issues)) {
      const issues = error.issues as Array<{ path: string[]; message: string }>;
      return `Validation failed: ${issues.map((issue) => `${issue.path.join('.')}: ${issue.message}`).join(', ')}`;
    }
    return error.message;
  }
  return 'Unknown validation error';
}