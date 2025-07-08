import * as yaml from 'js-yaml';

export interface ConfigBuilderOptions {
  provider: 'none' | 'aws' | 'gcp' | 'azure';
  repoStructure: 'directories' | 'tfvars' | 'workspaces';
  multipleEnvironments: boolean;
  authMethod: 'static' | 'oidc';
  engine: 'terraform' | 'opentofu' | 'terragrunt' | 'cdktf' | 'pulumi';
  costEstimation: boolean;
  driftDetection: boolean;
  automerge: boolean;
  applyAfterMerge: boolean;
  applyRequirements: boolean;
  slackNotifications: boolean;
  rbac: boolean;
  layeredRuns: boolean;
  gitflow: boolean;
  opa: boolean;
}

interface WorkflowStep {
  type: string;
  [key: string]: unknown;
}

interface Workflow {
  plan?: WorkflowStep[];
  apply?: WorkflowStep[];
  [key: string]: unknown;
}

interface TerraformConfig {
  dirs?: Record<string, unknown>;
  workflows?: Workflow[];
  when_modified?: Record<string, unknown>;
  engine?: Record<string, unknown>;
  automerge?: Record<string, unknown>;
  hooks?: Record<string, unknown>;
  apply_requirements?: Record<string, unknown>;
  cost_estimation?: Record<string, unknown>;
  drift_detection?: Record<string, unknown>;
  drift?: Record<string, unknown>;
  workspaces?: Record<string, unknown>;
  access_control?: Record<string, unknown>;
  destination_branches?: Array<unknown>;
  tags?: Record<string, unknown>;
}

export function getSecretsForProvider(provider: string): string {
  switch (provider) {
    case 'none': return 'No secrets required';
    case 'aws': return 'AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY';
    case 'gcp': return 'GOOGLE_APPLICATION_CREDENTIALS';
    case 'azure': return 'ARM_CLIENT_ID, ARM_CLIENT_SECRET, and ARM_TENANT_ID';
    default: return 'provider-specific credentials';
  }
}

export function getProviderDocumentationUrl(provider: string): string {
  if (provider === 'none') return '';
  
  // All providers have their documentation under /cloud-providers/{provider}/
  const baseUrl = `https://docs.terrateam.io/cloud-providers/${provider}/`;
  
  // Each provider page covers both static secrets and OIDC setup
  return baseUrl;
}

export function generateConfig(options: ConfigBuilderOptions): string {
  // Check if any configuration is actually needed
  // Static secrets are the default, so they don't require config
  const needsConfig = (options.provider !== 'none' && options.authMethod === 'oidc') || 
                     options.multipleEnvironments || 
                     options.costEstimation || 
                     options.driftDetection || 
                     options.automerge || 
                     options.applyAfterMerge || 
                     options.applyRequirements ||
                     options.slackNotifications ||
                     options.rbac ||
                     options.layeredRuns ||
                     options.gitflow ||
                     options.opa;

  // If no configuration needed, return minimal setup
  if (!needsConfig) {
    const secretsMessage = options.provider !== 'none' 
      ? `\n#\n# For ${options.provider.toUpperCase()} authentication, add these secrets to your repository:\n# ${getSecretsForProvider(options.provider)}`
      : '';

    const steps = options.provider !== 'none' 
      ? `# 1. Add the required secrets to your GitHub repository\n# 2. Push Terraform files to any directory\n# 3. Open a pull request\n# 4. Terrateam will automatically plan your changes`
      : `# 1. Push Terraform files to any directory\n# 2. Open a pull request\n# 3. Terrateam will automatically plan your changes`;
    
    return `# Terrateam works out of the box with sensible defaults!\n# No configuration file is required for basic usage.\n#\n# This file is only needed when you want to customize behavior\n# such as OIDC authentication, workflows, or advanced features.\n#\n# To get started:\n${steps}${secretsMessage}`;
  }

  // Build configuration object
  const config: TerraformConfig = {} as TerraformConfig;
  
  // Check if we're only configuring OIDC (no other features)
  const onlyOIDC = options.provider !== 'none' && 
                   options.authMethod === 'oidc' && 
                   !options.multipleEnvironments && 
                   !options.costEstimation && 
                   !options.driftDetection && 
                   !options.automerge && 
                   !options.applyAfterMerge && 
                   !options.applyRequirements &&
                   !options.slackNotifications &&
                   !options.rbac &&
                   !options.layeredRuns &&
                   !options.gitflow &&
                   !options.opa;

  // Check what minimal features are selected (no environments or complex setup)
  const hasMinimalFeatures = !options.multipleEnvironments && 
                            options.provider === 'none' &&
                            (options.costEstimation || options.driftDetection || 
                             options.automerge || 
                             options.applyAfterMerge || options.applyRequirements ||
                             options.slackNotifications || options.rbac || options.layeredRuns ||
                             options.gitflow || options.opa);

  // Add setup comments based on selections
  let configComments = '';
  
  // For OIDC-only configs, use minimal comments
  if (onlyOIDC) {
    configComments = `# Terrateam Configuration - OIDC Authentication\n# \n# This minimal configuration enables ${options.provider.toUpperCase()} OIDC authentication.\n# Terrateam will work with any directory structure in your repository.\n#\n# Setup: Follow the ${options.provider.toUpperCase()} OIDC guide:\n# https://docs.terrateam.io/cloud-providers/${options.provider}/\n\n`;
  } else if (hasMinimalFeatures) {
    let featuresList = [];
    if (options.costEstimation) featuresList.push('Cost Estimation');
    if (options.driftDetection) featuresList.push('Drift Detection');
    if (options.automerge) featuresList.push('Auto-merge');
    if (options.applyAfterMerge) featuresList.push('Apply After Merge');
    if (options.applyRequirements) featuresList.push('Apply Requirements');
    if (options.slackNotifications) featuresList.push('Slack Notifications');
    if (options.rbac) featuresList.push('Role-Based Access Control');
    if (options.layeredRuns) featuresList.push('Layered Runs');
    if (options.gitflow) featuresList.push('Gitflow Workflow');
    if (options.opa) featuresList.push('OPA Policy Checks');
    
    const applyAfterMergeNote = options.applyAfterMerge 
      ? `\n# Note: Apply After Merge enables autoapply globally. For directory-specific\n# settings, use the 'dirs' configuration: https://docs.terrateam.io/configuration-reference/dirs/\n`
      : '';
    
    configComments = `# Terrateam Configuration\n# \n# This configuration enables: ${featuresList.join(', ')}\n# while using default behavior for repository structure and authentication.${applyAfterMergeNote}\n\n`;
  } else if (options.repoStructure === 'directories') {
    const authSetup = options.provider === 'none' 
      ? ``
      : options.authMethod === 'static' 
      ? `# Setup: Add GitHub repository secrets: ${getSecretsForProvider(options.provider)}\n# Documentation: https://docs.terrateam.io/cloud-providers/${options.provider}/`
      : `# Setup: Follow ${options.provider.toUpperCase()} OIDC guide: https://docs.terrateam.io/cloud-providers/${options.provider}/`;
    
    configComments = options.multipleEnvironments
      ? `# Repository Layout: Multiple environments using separate directories\n# environments/      - Environment-specific runs\n#   ├── production/   - Production infrastructure\n#   └── development/  - Development infrastructure\n${authSetup ? '#\n' + authSetup + '\n' : ''}\n`
      : `# Repository Layout: Simple directory structure\n# Your existing directory structure will work with Terrateam\n${authSetup ? '#\n' + authSetup + '\n' : ''}\n`;
  } else if (options.repoStructure === 'tfvars') {
    const authSetup = options.provider === 'none'
      ? ``
      : options.authMethod === 'static'
      ? `# Setup: Add GitHub repository secrets: ${getSecretsForProvider(options.provider)}`
      : `# Setup: Follow ${options.provider.toUpperCase()} OIDC guide: https://docs.terrateam.io/cloud-providers/${options.provider}/`;
    
    configComments = options.multipleEnvironments 
      ? `# Repository Layout: Multiple environments using tfvars files\n# terraform/         - Main Terraform code\n#   ├── main.tf       - Infrastructure definitions\n#   ├── variables.tf  - Variable declarations\n#   ├── production.tfvars   - Production values\n#   ├── development.tfvars  - Development values\n#   ├── backend-production.conf - Production state config\n#   └── backend-development.conf - Development state config\n#\n# Each environment has separate state files for isolation.\n# Backend configs are passed during terraform init.\n${authSetup ? '#\n' + authSetup + '\n' : ''}\n`
      : `# Repository Layout: Simple tfvars setup\n# Your existing tfvars file will work with Terrateam\n${authSetup ? '#\n' + authSetup + '\n' : ''}\n`;
  } else { // workspaces
    const authSetup = options.provider === 'none'
      ? ``
      : options.authMethod === 'static'
      ? `# Setup: Add GitHub repository secrets: ${getSecretsForProvider(options.provider)}`
      : `# Setup: Follow ${options.provider.toUpperCase()} OIDC guide: https://docs.terrateam.io/cloud-providers/${options.provider}/`;
    
    configComments = options.multipleEnvironments
      ? `# Repository Layout: Multiple environments using Terraform workspaces\n# terraform/         - Main Terraform code\n#   ├── main.tf       - Infrastructure definitions\n#   ├── variables.tf  - Variable declarations\n#   └── terraform.tf  - Backend/provider config\n#\n# Terraform Workspaces: development, production\n${authSetup ? '#\n' + authSetup + '\n' : ''}\n`
      : `# Repository Layout: Terraform workspaces\n# Your existing workspace setup will work with Terrateam\n${authSetup ? '#\n' + authSetup + '\n' : ''}\n`;
  }

  // Only generate directory structure if we have features beyond just OIDC or minimal features
  // (Terrateam works with any directory structure out of the box)
  if (needsConfig && !onlyOIDC && !hasMinimalFeatures && options.repoStructure === 'directories') {
    if (!options.multipleEnvironments) {
      // Single environment - minimal config, Terrateam works out of the box
      // No specific configuration needed for simple directory structure
    } else {
      // Multiple environments using glob patterns and workflows
      config.dirs = {
        "environments/production/**": {
          tags: ["production"]
        },
        "environments/development/**": {
          tags: ["development"]
        }
      };
      
      // Add workflows for each environment
      config.workflows = [
        {
          tag_query: "production",
          plan: [
            { type: "init" },
            { type: "plan" }
          ],
          apply: [
            { type: "init" },
            { type: "apply" }
          ]
        },
        {
          tag_query: "development",
          plan: [
            { type: "init" },
            { type: "plan" }
          ],
          apply: [
            { type: "init" },
            { type: "apply" }
          ]
        }
      ];
    }
  } else if (needsConfig && !onlyOIDC && !hasMinimalFeatures && options.repoStructure === 'tfvars') {
    if (!options.multipleEnvironments) {
      // Single environment - minimal config for tfvars
      // No specific configuration needed
    } else {
      // Multiple environments using tfvars files and workspaces        
      config.dirs = {
        "terraform": {
          create_and_select_workspace: false,
          tags: ["terraform"],
          workspaces: {
            "development": {
              tags: ["development"]
            },
            "production": {
              tags: ["production"]
            }
          }
        }
      };
      
      config.workflows = [
        {
          tag_query: "terraform and development",
          plan: [
            { type: "init", extra_args: ["-backend-config=backend-development.conf"] },
            { type: "plan", extra_args: ["-var-file=development.tfvars"] }
          ],
          apply: [
            { type: "init", extra_args: ["-backend-config=backend-development.conf"] },
            { type: "apply", extra_args: ["-var-file=development.tfvars"] }
          ]
        },
        {
          tag_query: "terraform and production",
          plan: [
            { type: "init", extra_args: ["-backend-config=backend-production.conf"] },
            { type: "plan", extra_args: ["-var-file=production.tfvars"] }
          ],
          apply: [
            { type: "init", extra_args: ["-backend-config=backend-production.conf"] },
            { type: "apply", extra_args: ["-var-file=production.tfvars"] }
          ]
        }
      ];
    }
  } else if (needsConfig && !onlyOIDC && !hasMinimalFeatures && options.repoStructure === 'workspaces') {
    if (!options.multipleEnvironments) {
      // Single workspace - minimal config
      // No specific configuration needed
    } else {
      // Multiple environments using workspaces - Terraform handles this natively
      // Just tag directories and let Terraform manage the workspaces
      config.dirs = {
        "terraform": {
          create_and_select_workspace: true,
          tags: ["terraform"],
          workspaces: {
            "development": {
              tags: ["development"]
            },
            "production": {
              tags: ["production"]
            }
          }
        }
      };
    }
  }

  // OIDC workflow configuration
  if (options.provider !== 'none' && options.authMethod === 'oidc') {
    const providerConfig = options.provider === 'aws'
      ? { provider: 'aws', role_arn: 'arn:aws:iam::123456789012:role/terrateam-role' }
      : options.provider === 'gcp' 
      ? { provider: 'gcp', service_account: 'terrateam@your-project.iam.gserviceaccount.com', workload_identity_provider: 'projects/123456789012/locations/global/workloadIdentityPools/terrateam-pool/providers/terrateam-provider' }
      : null;

    if (providerConfig) {
      // Only add workflows if they don't already exist
      if (!config.workflows) {
        config.workflows = [
          {
            tag_query: "",
            plan: [
              { type: "oidc", ...providerConfig },
              { type: "init" },
              { type: "plan" }
            ],
            apply: [
              { type: "oidc", ...providerConfig },
              { type: "init" },
              { type: "apply" }
            ]
          }
        ];
      } else {
        // Add OIDC to existing workflows
        config.workflows = config.workflows.map(workflow => ({
          ...workflow,
          plan: [
            { type: "oidc", ...providerConfig },
            ...(workflow.plan || [{ type: "init" }, { type: "plan" }])
          ],
          apply: [
            { type: "oidc", ...providerConfig },
            ...(workflow.apply || [{ type: "init" }, { type: "apply" }])
          ]
        }));
      }
    }
  }

  // Add apply requirements for production environments
  if (options.applyRequirements) {
    if (options.multipleEnvironments) {
      config.apply_requirements = {
        checks: [
          {
            tag_query: 'production',
            approved: {
              enabled: true,
              all_of: ['team:sre']
            },
            merge_conflicts: {
              enabled: true
            },
            status_checks: {
              enabled: true
            }
          },
          {
            tag_query: 'development',
            approved: {
              enabled: true,
              any_of: ['team:developers'],
              any_of_count: 1
            },
            merge_conflicts: {
              enabled: true
            },
            status_checks: {
              enabled: false
            }
          }
        ]
      };
    } else {
      // Single environment - basic approval requirements
      config.apply_requirements = {
        checks: [
          {
            tag_query: '',
            approved: {
              enabled: true,
              any_of_count: 1
            },
            merge_conflicts: {
              enabled: true
            },
            status_checks: {
              enabled: true
            }
          }
        ]
      };
    }
  }

  // Add cost estimation
  if (options.costEstimation && options.engine !== 'pulumi') {
    config.cost_estimation = {
      enabled: true
    };
  }

  // Add drift detection
  if (options.driftDetection) {
    config.drift = {
      enabled: true,
      schedules: {
        default: {
          tag_query: '',
          schedule: 'daily'
        }
      }
    };
  }

  // Add automerge
  if (options.automerge) {
    config.automerge = {
      enabled: true
    };
  }

  // Add apply after merge
  if (options.applyAfterMerge) {
    config.when_modified = {
      autoapply: true
    };
  }

  // Add Slack notifications
  if (options.slackNotifications) {
    // Create or update workflows
    if (!config.workflows) {
      config.workflows = [
        {
          tag_query: "",
          plan: [
            { type: "init" },
            { type: "plan" }
          ],
          apply: [
            { type: "init" },
            { type: "apply" }
          ]
        }
      ];
    }

    // Add Slack notification steps to each workflow
    config.workflows = config.workflows.map(workflow => {
      const planSteps = workflow.plan || [{ type: "init" }, { type: "plan" }];
      const applySteps = workflow.apply || [{ type: "init" }, { type: "apply" }];

      // Add Slack notification after plan
      const planWithNotification = [
        ...planSteps,
        {
          type: "run",
          cmd: ["sh", "-c", "curl -X POST -H 'Content-type: application/json' --data '{\"text\":\"Terraform plan completed for ${TERRATEAM_DIR}\"}' https://hooks.slack.com/services/YOUR/WEBHOOK/URL"],
          run_on: "always"
        }
      ];

      // Add Slack notification after apply
      const applyWithNotification = [
        ...applySteps,
        {
          type: "run",
          cmd: ["sh", "-c", "curl -X POST -H 'Content-type: application/json' --data '{\"text\":\"Terraform apply completed for ${TERRATEAM_DIR}\"}' https://hooks.slack.com/services/YOUR/WEBHOOK/URL"],
          run_on: "always"
        }
      ];

      return {
        ...workflow,
        plan: planWithNotification,
        apply: applyWithNotification
      };
    });
  }

  // Add Role-Based Access Control
  if (options.rbac) {
    if (options.multipleEnvironments) {
      config.access_control = {
        enabled: true,
        ci_config_update: ['team:sre'],
        terrateam_config_update: ['team:sre'],
        unlock: ['team:sre'],
        files: {
          'bin/rotate-prod-secrets.sh': ['role:admin']
        },
        policies: [
          {
            tag_query: 'production',
            plan: ['team:sre'],
            apply: ['team:sre'],
            apply_with_superapproval: ['team:developers'],
            superapproval: ['team:security']
          },
          {
            tag_query: 'development',
            plan: ['team:developers'],
            apply: ['team:developers'],
            apply_force: ['team:developers']
          },
          {
            tag_query: '',
            plan: ['*'],
            apply: ['team:sre']
          }
        ]
      };
    } else {
      config.access_control = {
        enabled: true,
        policies: [
          {
            tag_query: '',
            plan: ['*'],
            apply: ['team:sre']
          }
        ]
      };
    }
  }

  // Add Layered Runs - example with network -> database -> application layers
  if (options.layeredRuns) {
    if (!config.dirs) {
      config.dirs = {};
    }
    
    // Add example layered infrastructure
    config.dirs = {
      ...config.dirs,
      "network": {
        when_modified: {
          file_patterns: ["${DIR}/*.tf"]
        }
      },
      "database": {
        when_modified: {
          depends_on: "dir:network",
          file_patterns: ["${DIR}/*.tf"]
        }
      },
      "application": {
        when_modified: {
          depends_on: "dir:database",
          file_patterns: ["${DIR}/*.tf"]
        }
      }
    };
  }

  // Add Gitflow configuration
  if (options.gitflow) {
    // Add tags for branch identification
    config.tags = {
      ...config.tags,
      dest_branch: {
        main: '^main$',
        dev: '^dev$'
      }
    };

    // Add destination branches configuration
    config.destination_branches = [
      {
        branch: 'main',
        source_branches: ['dev']
      },
      {
        branch: 'dev',
        source_branches: ['*', '!main']
      }
    ];
  }

  // Add OPA Policy Checks
  if (options.opa) {
    // Create or update workflows
    if (!config.workflows) {
      config.workflows = [
        {
          tag_query: "",
          plan: [
            { type: "init" },
            { type: "plan" }
          ],
          apply: [
            { type: "init" },
            { type: "apply" }
          ]
        }
      ];
    }

    // Add conftest step after plan in each workflow
    config.workflows = config.workflows.map(workflow => {
      const planSteps = workflow.plan || [{ type: "init" }, { type: "plan" }];
      const planIndex = planSteps.findIndex((step: { type?: string }) => step.type === "plan");
      if (planIndex !== -1) {
        const conftestStep = {
          type: "conftest",
          extra_args: ["--policy", "policies/"]
        };
        // Insert conftest after plan step
        const newPlanSteps = [
          ...planSteps.slice(0, planIndex + 1),
          conftestStep,
          ...planSteps.slice(planIndex + 1)
        ];
        return {
          ...workflow,
          plan: newPlanSteps
        };
      }
      return workflow;
    });
  }

  // Generate YAML
  try {
    if (Object.keys(config).length === 0) {
      // This shouldn't happen since we check needsConfig above
      return '# Error: No configuration generated';
    }
    
    const yamlOutput = yaml.dump(config, {
      quotingType: '"',
      forceQuotes: false,
      indent: 2,
      lineWidth: -1,
      noRefs: true,
      sortKeys: false,
      schema: yaml.JSON_SCHEMA
    });
    
    // Format the YAML nicely
    return configComments + yamlOutput
      .replace(/(\w+):\s*null/g, '$1:') // Remove null values
      .replace(/^(\s*)-\s*/gm, '$1- ') // Normalize list item spacing
      .replace(/:\s*$/gm, ':') // Clean up empty values
      .trim();
  } catch (error) {
    console.error('YAML generation error:', error);
    return '# Error generating YAML config';
  }
}

export const CONFIG_PRESETS = {
  starter: {
    name: 'Starter',
    description: 'Simple configuration to get started',
    icon: 'mdi:play-circle-outline',
    options: {
      provider: 'none' as const,
      repoStructure: 'directories' as const,
      multipleEnvironments: false,
      authMethod: 'static' as const,
      engine: 'terraform' as const,
      costEstimation: false,
      driftDetection: false,
      automerge: false,
      applyAfterMerge: false,
      applyRequirements: false,
      slackNotifications: false,
      rbac: false,
      layeredRuns: false,
      gitflow: false,
      opa: false
    }
  },
  
  team: {
    name: 'Team',
    description: 'Collaboration features for small teams',
    icon: 'mdi:account-group-outline',
    options: {
      provider: 'aws' as const, // Most common, but user can change
      repoStructure: 'directories' as const,
      multipleEnvironments: true,
      authMethod: 'static' as const,
      engine: 'terraform' as const,
      costEstimation: true,
      driftDetection: true,
      automerge: false,
      applyAfterMerge: false,
      applyRequirements: true,
      slackNotifications: true,
      rbac: true,
      layeredRuns: false,
      gitflow: false,
      opa: false
    }
  },
  
  advanced: {
    name: 'Advanced',
    description: 'Full governance and compliance features',
    icon: 'mdi:rocket-launch-outline',
    options: {
      provider: 'aws' as const,
      repoStructure: 'directories' as const,
      multipleEnvironments: true,
      authMethod: 'oidc' as const,
      engine: 'terraform' as const,
      costEstimation: true,
      driftDetection: true,
      automerge: false,
      applyAfterMerge: false,
      applyRequirements: true,
      slackNotifications: true,
      rbac: true,
      layeredRuns: true,
      gitflow: false,
      opa: true
    }
  }
};
