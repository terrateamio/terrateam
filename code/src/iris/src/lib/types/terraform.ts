/**
 * Terraform Plan Visualization Type Definitions
 * These types support parsing and visualizing Terraform plan outputs
 */

// Resource change types
export type ChangeType = 'create' | 'update' | 'delete' | 'replace' | 'no-change';

// Resource node in the dependency graph
export interface ResourceNode {
  id: string;                    // Resource address (e.g., "aws_instance.web")
  type: string;                  // Resource type (e.g., "aws_instance")
  name: string;                  // Resource name (e.g., "web")
  provider: string;              // Provider name (e.g., "aws")
  changeType: ChangeType;        // Type of change
  before: Record<string, unknown>;   // State before change
  after: Record<string, unknown>;    // State after change
  attributes?: Record<string, unknown>; // Additional attributes
  module?: string;               // Module path if in a module
}

// Set of changes in the plan
export interface ChangeSet {
  create: ResourceNode[];
  update: ResourceNode[];
  delete: ResourceNode[];
  replace: ResourceNode[];
  unchanged: ResourceNode[];
  total: number;
}

// Parsed Terraform plan
export interface ParsedPlan {
  resources: ResourceNode[];
  changes: ChangeSet;
  outputs?: Record<string, unknown>;
  plannedValues?: unknown;
  priorState?: unknown;
  configuration?: unknown;
}


// Terraform JSON plan format (partial)
export interface TerraformJsonPlan {
  format_version?: string;
  terraform_version?: string;
  planned_values?: {
    root_module?: TerraformModule;
    outputs?: Record<string, unknown>;
  };
  resource_changes?: TerraformResourceChange[];
  output_changes?: Record<string, unknown>;
  prior_state?: unknown;
  configuration?: {
    provider_config?: Record<string, unknown>;
    root_module?: TerraformModule;
  };
}

// Terraform module structure
export interface TerraformModule {
  resources?: TerraformResource[];
  child_modules?: TerraformModule[];
  module_calls?: Record<string, unknown>;
  variables?: Record<string, unknown>;
  outputs?: Record<string, unknown>;
}

// Terraform resource in configuration
export interface TerraformResource {
  address: string;
  mode: 'managed' | 'data';
  type: string;
  name: string;
  provider_name?: string;
  schema_version?: number;
  values?: Record<string, unknown>;
  sensitive_values?: Record<string, unknown>;
  depends_on?: string[];
  expressions?: Record<string, unknown>;
}

// Terraform resource change
export interface TerraformResourceChange {
  address: string;
  module_address?: string;
  mode: 'managed' | 'data';
  type: string;
  name: string;
  provider_name: string;
  change: {
    actions: Array<'create' | 'read' | 'update' | 'delete' | 'no-op'>;
    before: unknown;
    after: unknown;
    after_unknown?: unknown;
    before_sensitive?: unknown;
    after_sensitive?: unknown;
    importing?: unknown;
  };
}


// Diff view data
export interface DiffLine {
  type: 'added' | 'removed' | 'modified' | 'unchanged';
  lineNo: number;
  before?: string;
  after?: string;
  text: string;
  indicator: '+' | '-' | '~' | ' ';
}

// Resource diff
export interface ResourceDiff {
  resource: ResourceNode;
  lines: DiffLine[];
  summary: {
    added: number;
    removed: number;
    modified: number;
  };
}