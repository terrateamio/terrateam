// Enhanced type definitions with runtime validation
// Combines generated API types with manual types and zod validation

import { z } from 'zod';
import type { components } from './api-types-generated';

// Re-export generated API component types for convenience
export type ApiComponents = components;
export type ApiSchemas = components['schemas'];

// Core API Types using generated schemas as base
export type Installation = ApiSchemas['installation'];
export type Repository = ApiSchemas['installation-repo'];
export type PullRequest = ApiSchemas['installation-pull-request'];
export type Dirspace = ApiSchemas['installation-dirspace'];
export type WorkManifest = ApiSchemas['installation-work-manifest'];
export type User = ApiSchemas['user'];
export type ServerConfig = ApiSchemas['server-config'];

// GitLab-specific types
export type GitLabGroup = ApiSchemas['gitlab-group'];
export type GitLabUser = ApiSchemas['gitlab-user'];
export type GitLabWebhook = ApiSchemas['gitlab-webhook'];
export type GitLabWhoAreYou = ApiSchemas['gitlab-whoareyou'];

// Zod validation schemas matching the API specification
export const InstallationSchema = z.object({
  account_status: z.string(),
  id: z.string(),
  name: z.string(),
  created_at: z.string(),
  tier: z.object({
    name: z.string(),
    features: z.object({
      num_users_per_month: z.number().optional(),
    }),
  }),
  trial_ends_at: z.string().optional(),
});

export const RepositorySchema = z.object({
  id: z.string(),
  installation_id: z.string(),
  name: z.string(),
  setup: z.boolean(),
  updated_at: z.string(),
});

export const PullRequestSchema = z.object({
  base_branch: z.string(),
  base_sha: z.string(),
  branch: z.string(),
  latest_work_manifest_run_at: z.string().optional(),
  merged_at: z.string().optional(),
  merged_sha: z.string().optional(),
  name: z.string(),
  owner: z.string(),
  pull_number: z.number(),
  repository: z.number(),
  sha: z.string(),
  state: z.enum(['open', 'closed', 'merged']),
  title: z.string().optional(),
  user: z.string().optional(),
});

export const UserSchema = z.object({
  id: z.string(),
  vcs: z.array(z.string()),
});

export const ServerConfigSchema = z.object({
  github: z.object({
    api_base_url: z.string(),
    app_client_id: z.string(),
    app_url: z.string(),
    web_base_url: z.string(),
  }).optional(),
  gitlab: z.object({
    api_base_url: z.string(),
    app_id: z.string(),
    redirect_url: z.string(),
    web_base_url: z.string(),
  }).optional(),
});

export const DirspaceStateSchema = z.enum([
  'aborted', 'failure', 'queued', 'running', 'success', 'unknown'
]);

export const DirspaceSchema = z.object({
  base_branch: z.string(),
  base_ref: z.string(),
  branch: z.string(),
  branch_ref: z.string(),
  completed_at: z.string().optional(),
  created_at: z.string(),
  dir: z.string(),
  environment: z.string().optional(),
  id: z.string(),
  kind: z.union([
    z.literal('drift'),
    z.literal('index'),
    z.object({ pull_number: z.number(), pull_request_title: z.string().optional() }),
  ]),
  owner: z.string(),
  repo: z.string(),
  run_id: z.string().optional(),
  run_type: z.enum(['apply', 'build-config', 'build-tree', 'index', 'plan']),
  state: DirspaceStateSchema,
  tag_query: z.string(),
  user: z.string().optional(),
  workspace: z.string(),
});

export const WorkManifestStateSchema = z.enum([
  'aborted', 'completed', 'queued', 'running'
]);

export const WorkManifestSchema = z.object({
  base_branch: z.string(),
  base_ref: z.string(),
  branch: z.string(),
  branch_ref: z.string(),
  completed_at: z.string().optional(),
  created_at: z.string(),
  dirspaces: z.array(z.object({
    dir: z.string(),
    workspace: z.string(),
    success: z.boolean().optional(),
  })),
  environment: z.string().optional(),
  id: z.string(),
  kind: z.union([
    z.literal('drift'),
    z.literal('index'),
    z.object({ pull_number: z.number(), pull_request_title: z.string().optional() }),
  ]),
  owner: z.string(),
  repo: z.string(),
  run_id: z.string().optional(),
  run_type: z.enum(['apply', 'build-config', 'build-tree', 'index', 'plan']),
  state: WorkManifestStateSchema,
  tag_query: z.string(),
  user: z.string().optional(),
});

// GitLab-specific schemas
export const GitLabGroupSchema = z.object({
  id: z.number(),
  name: z.string(),
});

export const GitLabUserSchema = z.object({
  username: z.string(),
  avatar_url: z.string().optional(),
});

export const GitLabWebhookSchema = z.object({
  state: z.string(),
  webhook_url: z.string(),
  webhook_secret: z.string().optional(),
});
export const GitLabWhoAreYouSchema = z.object({
  id: z.number(),
  username: z.string(),
});

// API Response wrapper schemas
export const ApiResponseSchema = <T extends z.ZodTypeAny>(dataSchema: T) =>
  z.object({
    data: dataSchema.optional(),
    error: z.string().optional(),
    status: z.number(),
  });

export const PaginatedResponseSchema = <T extends z.ZodTypeAny>(itemSchema: T) =>
  z.object({
    data: z.array(itemSchema),
    pagination: z.object({
      page: z.number(),
      limit: z.number(),
      total: z.number(),
      has_more: z.boolean(),
    }).optional(),
  });

// Validation functions
export function validateInstallation(data: unknown): Installation {
  return InstallationSchema.parse(data);
}

export function validateRepository(data: unknown): Repository {
  return RepositorySchema.parse(data);
}

export function validatePullRequest(data: unknown): PullRequest {
  return PullRequestSchema.parse(data);
}

export function validateUser(data: unknown): User {
  return UserSchema.parse(data);
}

export function validateDirspace(data: unknown): Dirspace {
  return DirspaceSchema.parse(data);
}

export function validateWorkManifest(data: unknown): WorkManifest {
  return WorkManifestSchema.parse(data);
}

export function validateServerConfig(data: unknown): ServerConfig {
  return ServerConfigSchema.parse(data);
}

// Array validation functions
export function validateInstallations(data: unknown): Installation[] {
  return z.array(InstallationSchema).parse(data);
}

export function validateRepositories(data: unknown): Repository[] {
  return z.array(RepositorySchema).parse(data);
}

export function validatePullRequests(data: unknown): PullRequest[] {
  return z.array(PullRequestSchema).parse(data);
}

export function validateDirspaces(data: unknown): Dirspace[] {
  return z.array(DirspaceSchema).parse(data);
}

export function validateWorkManifests(data: unknown): WorkManifest[] {
  return z.array(WorkManifestSchema).parse(data);
}

// GitLab validation functions
export function validateGitLabGroup(data: unknown): GitLabGroup {
  return GitLabGroupSchema.parse(data);
}

export function validateGitLabGroups(data: unknown): GitLabGroup[] {
  return z.array(GitLabGroupSchema).parse(data);
}

export function validateGitLabUser(data: unknown): GitLabUser {
  return GitLabUserSchema.parse(data);
}

export function validateGitLabWebhook(data: unknown): GitLabWebhook {
  return GitLabWebhookSchema.parse(data);
}
export function validateGitLabWhoAreYou(data: unknown): GitLabWhoAreYou {
  return GitLabWhoAreYouSchema.parse(data);
}

// Legacy/Additional types for compatibility
export interface ApiResponse<T> {
  data?: T;
  error?: string;
  status: number;
}

export interface PaginatedResponse<T> {
  data: T[];
  pagination?: {
    page: number;
    limit: number;
    total: number;
    has_more: boolean;
  };
}

// Theme types
export type ThemeMode = 'light' | 'dark' | 'system';

export interface ThemeStore {
  subscribe: (callback: (value: ThemeMode) => void) => () => void;
  setTheme: (theme: ThemeMode) => void;
  init: () => void;
}

// API Client types
export interface ApiRequestOptions {
  method?: 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH';
  headers?: Record<string, string>;
  body?: string;
  params?: Record<string, string>;
}

export interface ApiClient {
  request<T>(endpoint: string, options?: ApiRequestOptions): Promise<T>;
  get<T>(endpoint: string, params?: Record<string, string>): Promise<T>;
  post<T>(endpoint: string, data?: unknown): Promise<T>;
  put<T>(endpoint: string, data?: unknown): Promise<T>;
  delete<T>(endpoint: string): Promise<T>;
}

// Route types for svelte-spa-router
export type RouteComponent = typeof import('svelte').SvelteComponent;
export type Routes = Record<string, RouteComponent>;

// Query types for advanced search
export interface SearchQuery {
  page?: string[];
  q?: string;
  sort?: 'asc' | 'desc';
  limit?: number;
}

// Cloud provider types (UI-only, not from API)
export interface CloudProvider {
  id: string;
  name: string;
  shortName: string;
  description: string;
  docUrl: string;
  iconName: string;
  iconColor: string;
  popular: boolean;
  features: string[];
}

// Error types
export interface ApiError {
  message: string;
  status: number;
  code?: string;
  details?: unknown;
}

// Type guards for safer type checking
export function isInstallation(value: unknown): value is Installation {
  try {
    InstallationSchema.parse(value);
    return true;
  } catch {
    return false;
  }
}

export function isRepository(value: unknown): value is Repository {
  try {
    RepositorySchema.parse(value);
    return true;
  } catch {
    return false;
  }
}

export function isPullRequest(value: unknown): value is PullRequest {
  try {
    PullRequestSchema.parse(value);
    return true;
  } catch {
    return false;
  }
}

export function isUser(value: unknown): value is User {
  try {
    UserSchema.parse(value);
    return true;
  } catch {
    return false;
  }
}
