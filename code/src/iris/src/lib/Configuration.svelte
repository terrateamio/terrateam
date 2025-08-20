<script lang="ts">
  // Auth handled by PageLayout
  import PageLayout from './components/layout/PageLayout.svelte';
  import { selectedInstallation, installations } from './stores';
  import { Icon } from './components';
  import hljs from 'highlight.js/lib/core';
  import yamlLang from 'highlight.js/lib/languages/yaml';
  import 'highlight.js/styles/github-dark.css';
  
  // Import our configuration engine
  import { generateConfig, getSecretsForProvider, CONFIG_PRESETS, type ConfigBuilderOptions } from './ConfigurationEngine';
  
  // Register YAML language
  hljs.registerLanguage('yaml', yamlLang);
  
  export let params: { installationId?: string } = {};

  // UI state
  let selectedMode: 'wizard' | 'custom' = 'wizard';
  let selectedPreset: keyof typeof CONFIG_PRESETS | null = null;
  
  // Config builder state - initialized from preset or empty
  let configOptions: ConfigBuilderOptions = { ...CONFIG_PRESETS.starter.options };
  
  // Generated config state
  let generatedConfig: string = '';
  let highlightedConfig: string = '';
  let copySuccess: boolean = false;
  let showToast: boolean = false;
  
  // Feature categories for organized display
  const featureCategories: Record<string, { name: string; icon: string; iconName: string; features: FeatureKey[] }> = {
    automation: {
      name: 'Automation & Workflows',
      icon: 'mdi:robot-outline',
      iconName: 'mdi:robot-outline',
      features: ['automerge', 'applyAfterMerge', 'applyRequirements', 'layeredRuns']
    },
    security: {
      name: 'Security & Compliance',
      icon: 'mdi:shield-check-outline',
      iconName: 'mdi:shield-check-outline',
      features: ['rbac', 'opa']
    },
    monitoring: {
      name: 'Monitoring & Insights',
      icon: 'mdi:chart-line',
      iconName: 'mdi:chart-line',
      features: ['costEstimation', 'driftDetection', 'slackNotifications']
    },
    advanced: {
      name: 'Advanced Patterns',
      icon: 'mdi:puzzle-outline',
      iconName: 'mdi:puzzle-outline',
      features: ['gitflow']
    }
  };

  // Auto-switch to static auth when Azure is selected (OIDC not supported yet)
  $: if (configOptions.provider === 'azure' && configOptions.authMethod === 'oidc') {
    configOptions = { ...configOptions, authMethod: 'static' };
  }

  // Generate config whenever options change
  $: generatedConfig = generateConfig(configOptions);
  
  // Highlight the YAML configuration whenever it changes
  $: if (generatedConfig) {
    if (generatedConfig.includes('No configuration file is required')) {
      // For the "no config needed" message, don't highlight
      highlightedConfig = generatedConfig;
    } else {
      // Highlight YAML syntax
      highlightedConfig = hljs.highlight(generatedConfig, { language: 'yaml' }).value;
    }
  }

  // When preset is selected, update config options
  function selectPreset(preset: keyof typeof CONFIG_PRESETS) {
    selectedPreset = preset;
    configOptions = { ...CONFIG_PRESETS[preset].options };
  }
  
  // Type helper for feature keys
  type FeatureKey = keyof Pick<ConfigBuilderOptions, 
    'costEstimation' | 'driftDetection' | 'automerge' | 'applyAfterMerge' | 
    'applyRequirements' | 'slackNotifications' | 'rbac' | 'layeredRuns' | 
    'gitflow' | 'opa'>;
  
  // Helper to select preset by string key
  function selectPresetByKey(key: string) {
    selectPreset(key as keyof typeof CONFIG_PRESETS);
  }
  
  // Helper to toggle feature
  function toggleFeature(feature: string) {
    const key = feature as FeatureKey;
    const oldValue = configOptions[key];
    const newValue = !oldValue;
    configOptions = { ...configOptions, [key]: newValue };
  }
  
  // Helper to check if feature is enabled
  // function isFeatureEnabled(feature: string): boolean {
  //   const isEnabled = configOptions[feature as FeatureKey];
  //   return isEnabled;
  // }
  
  // Helper to set provider
  function setProvider(provider: string) {
    configOptions = { ...configOptions, provider: provider as 'none' | 'aws' | 'gcp' | 'azure' };
    // For starter preset, always use static secrets
    if (selectedPreset === 'starter' && provider !== 'none') {
      configOptions = { ...configOptions, authMethod: 'static' };
    }
  }
  
  // Helper to set repo structure
  function setRepoStructure(structure: string) {
    configOptions = { ...configOptions, repoStructure: structure as 'directories' | 'tfvars' | 'workspaces' };
  }

  // Switch to custom mode
  function switchToCustom() {
    selectedMode = 'custom';
    // Keep current config options
  }

  async function copyToClipboard() {
    try {
      await navigator.clipboard.writeText(generatedConfig);
      copySuccess = true;
      showToast = true;
      
      // Reset the button state after 2 seconds
      setTimeout(() => {
        copySuccess = false;
      }, 2000);
      
      // Hide toast after 3 seconds
      setTimeout(() => {
        showToast = false;
      }, 3000);
    } catch (err) {
      console.error('Failed to copy:', err);
    }
  }

  function openDocumentation(url: string): void {
    window.open(url, '_blank');
  }

  // Auto-select installation if provided in URL
  $: if (params.installationId && $installations && $installations.length > 0) {
    const targetInstallation = $installations.find(inst => inst.id === params.installationId);
    if (targetInstallation && (!$selectedInstallation || $selectedInstallation.id !== targetInstallation.id)) {
      selectedInstallation.set(targetInstallation);
    }
  }

  // Feature info for tooltips
  const featureInfo: Record<FeatureKey, { name: string; description: string; docUrl: string }> = {
    costEstimation: { 
      name: 'Cost Estimation', 
      description: 'See cost impact before applying changes',
      docUrl: 'https://docs.terrateam.io/configuration-reference/cost-estimation/'
    },
    driftDetection: { 
      name: 'Drift Detection', 
      description: 'Detect unauthorized infrastructure changes',
      docUrl: 'https://docs.terrateam.io/advanced-workflows/drift-detection/'
    },
    automerge: { 
      name: 'Auto-merge', 
      description: 'Automatically merge PRs after successful apply',
      docUrl: 'https://docs.terrateam.io/configuration-reference/automerge/'
    },
    applyAfterMerge: { 
      name: 'Apply After Merge', 
      description: 'Automatically apply changes when PR is merged',
      docUrl: 'https://docs.terrateam.io/configuration-reference/apply-requirements/#apply-after-merge'
    },
    applyRequirements: { 
      name: 'Apply Requirements', 
      description: 'Require approvals before applying changes',
      docUrl: 'https://docs.terrateam.io/configuration-reference/apply-requirements/'
    },
    slackNotifications: { 
      name: 'Slack Notifications', 
      description: 'Send run updates to Slack',
      docUrl: 'https://docs.terrateam.io/integrations/webhooks/#slack-notifications'
    },
    rbac: { 
      name: 'Role-Based Access', 
      description: 'Control who can plan/apply by team or user',
      docUrl: 'https://docs.terrateam.io/security-and-compliance/role-based-access-control/'
    },
    layeredRuns: { 
      name: 'Layered Runs', 
      description: 'Run infrastructure in dependency order',
      docUrl: 'https://docs.terrateam.io/advanced-workflows/layered-runs/'
    },
    gitflow: { 
      name: 'Gitflow Workflow', 
      description: 'Structured branching with main/dev/feature',
      docUrl: 'https://docs.terrateam.io/advanced-workflows/gitflow/'
    },
    opa: { 
      name: 'Policy Checks', 
      description: 'Enforce policies with Open Policy Agent',
      docUrl: 'https://docs.terrateam.io/security-and-compliance/policy-enforcement-with-opa/'
    }
  };
</script>

<PageLayout activeItem="configuration" title="Terrateam Configuration" subtitle="Generate and customize your Terrateam configuration">
  <div class="h-full flex flex-col">
    
    <!-- Mode Selection -->
    {#if selectedMode === 'wizard' && !selectedPreset}
      <!-- Preset Selection Screen -->
      <div class="max-w-7xl mx-auto w-full px-2 sm:px-4">
        <div class="mb-6 sm:mb-8 text-center">
          <h2 class="text-2xl sm:text-3xl font-bold text-gray-900 dark:text-gray-100 mb-2 sm:mb-3">Choose Your Configuration Path</h2>
          <p class="text-base sm:text-lg text-gray-600 dark:text-gray-400 mb-2">Select a template to get started quickly, or build a custom configuration</p>
          <p class="text-sm text-gray-500 dark:text-gray-500 flex items-center justify-center gap-2">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 15l-2 5L9 9l11 4-5 2zm0 0l5 5M7.188 2.239l1.416 7.041m3.23 3.23l7.042 1.416M10.83 13.17l-7.041 1.416l7.04 1.414z" />
            </svg>
            Click any option below to generate your configuration
          </p>
        </div>

        <!-- Free Onboarding Support Banner -->
        <div class="mb-6 sm:mb-8 bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-blue-900/20 dark:to-indigo-900/20 rounded-xl p-5 sm:p-6 border border-blue-200 dark:border-blue-800">
          <div class="flex flex-col items-center text-center gap-4">
            <div class="w-14 h-14 bg-blue-100 dark:bg-blue-900/50 rounded-full flex items-center justify-center">
              <Icon icon="mdi:headset" width="28" height="28" class="text-blue-600 dark:text-blue-400" />
            </div>
            <div class="max-w-lg">
              <h3 class="text-lg sm:text-xl font-semibold text-gray-900 dark:text-gray-100 mb-2">Need help getting started?</h3>
              <p class="text-sm sm:text-base text-gray-600 dark:text-gray-400 leading-relaxed">
                We offer <span class="font-semibold text-blue-600 dark:text-blue-400">free onboarding support calls</span> to help you configure Terrateam for your specific needs.
              </p>
            </div>
            <button 
              on:click={() => window.open('https://calendly.com/terrateam/30-minute-chat', '_blank')}
              class="w-full sm:w-auto inline-flex items-center justify-center px-6 py-3 bg-blue-600 hover:bg-blue-700 text-white font-medium text-sm sm:text-base rounded-lg transition-all duration-200 shadow-md hover:shadow-lg transform hover:-translate-y-0.5"
            >
              <Icon icon="mdi:calendar-clock" width="20" height="20" class="mr-2" />
              Schedule a Call
            </button>
          </div>
        </div>

        <!-- Preset Cards -->
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6 mb-6 sm:mb-8">
          {#each Object.entries(CONFIG_PRESETS) as [key, preset]}
            <button
              on:click={() => selectPresetByKey(key)}
              class="relative bg-white dark:bg-gray-800 rounded-xl border-2 border-gray-200 dark:border-gray-700 p-4 sm:p-6 text-left hover:border-blue-500 hover:shadow-xl hover:-translate-y-1 transition-all duration-200 group cursor-pointer overflow-hidden h-full flex flex-col"
            >
              <!-- Hover gradient overlay -->
              <div class="absolute inset-0 bg-gradient-to-br from-blue-500/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-200"></div>
              
              <!-- Click to select badge -->
              <div class="absolute top-3 right-3 bg-blue-600 text-white text-xs px-2 py-1 rounded-full opacity-0 group-hover:opacity-100 transition-opacity duration-200 flex items-center gap-1">
                <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 15l-2 5L9 9l11 4-5 2z" />
                </svg>
                Click to select
              </div>
              
              <!-- Card content -->
              <div class="relative flex-1 flex flex-col">
                <div class="mb-4 transform group-hover:scale-110 transition-transform duration-200">
                  <Icon icon={preset.icon} width="32" height="32" class="text-gray-600 dark:text-gray-400 group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors" />
                </div>
                <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-2 group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors">
                  {preset.name}
                </h3>
                <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">{preset.description}</p>
                
                <!-- Feature highlights -->
                <div class="pt-4 border-t border-gray-200 dark:border-gray-700">
                  {#if key === 'starter'}
                    <div class="text-xs text-green-600 dark:text-green-400 font-medium">
                      ✓ Choose your provider<br>
                      ✓ Minimal configuration<br>
                      ✓ Add features later
                    </div>
                    <div class="mt-3 text-xs text-gray-500 dark:text-gray-400">
                      <strong>Best for:</strong> Getting started quickly
                    </div>
                  {:else if key === 'team'}
                    <div class="text-xs text-blue-600 dark:text-blue-400 font-medium">
                      ✓ Cost tracking<br>
                      ✓ Access controls<br>
                      ✓ Slack notifications
                    </div>
                    <div class="mt-3 text-xs text-gray-500 dark:text-gray-400">
                      <strong>Best for:</strong> Small teams
                    </div>
                  {:else if key === 'advanced'}
                    <div class="text-xs text-purple-600 dark:text-purple-400 font-medium">
                      ✓ OIDC authentication<br>
                      ✓ Policy enforcement<br>
                      ✓ Full governance
                    </div>
                    <div class="mt-3 text-xs text-gray-500 dark:text-gray-400">
                      <strong>Best for:</strong> Large organizations
                    </div>
                  {/if}
                </div>
                
                <!-- Action Button -->
                <div class="mt-4 pt-4 border-t border-gray-200 dark:border-gray-700">
                  <div class="flex items-center justify-between">
                    <span class="text-xs font-medium text-blue-600 dark:text-blue-400 group-hover:text-blue-700 dark:group-hover:text-blue-300">Generate Config</span>
                    <svg class="w-4 h-4 text-blue-600 dark:text-blue-400 group-hover:translate-x-1 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7l5 5m0 0l-5 5m5-5H6" />
                    </svg>
                  </div>
                </div>
              </div>
            </button>
          {/each}
          
          <!-- Custom Configuration Card -->
          <button
            on:click={switchToCustom}
            class="relative bg-white dark:bg-gray-800 rounded-xl border-2 border-gray-200 dark:border-gray-700 p-4 sm:p-6 text-left hover:border-purple-500 hover:shadow-xl hover:-translate-y-1 transition-all duration-200 group cursor-pointer overflow-hidden h-full flex flex-col"
          >
            <!-- Hover gradient overlay -->
            <div class="absolute inset-0 bg-gradient-to-br from-purple-500/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-200"></div>
            
            <!-- Click to select badge -->
            <div class="absolute top-3 right-3 bg-purple-600 text-white text-xs px-2 py-1 rounded-full opacity-0 group-hover:opacity-100 transition-opacity duration-200 flex items-center gap-1">
              <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 15l-2 5L9 9l11 4-5 2z" />
              </svg>
              Click to build
            </div>
            
            <!-- Card content -->
            <div class="relative flex-1 flex flex-col">
              <div class="mb-4 transform group-hover:scale-110 transition-transform duration-200">
                <Icon icon="mdi:tools" width="32" height="32" class="text-gray-600 dark:text-gray-400 group-hover:text-purple-600 dark:group-hover:text-purple-400 transition-colors" />
              </div>
              <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-2 group-hover:text-purple-600 dark:group-hover:text-purple-400 transition-colors">
                Custom
              </h3>
              <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">Build your configuration from scratch</p>
              
              <div class="pt-4 border-t border-gray-200 dark:border-gray-700">
                <div class="text-xs text-purple-600 dark:text-purple-400 font-medium">
                  ✓ Full control<br>
                  ✓ Mix & match features<br>
                  ✓ Advanced options
                </div>
                <div class="mt-3 text-xs text-gray-500 dark:text-gray-400">
                  <strong>Best for:</strong> Specific requirements
                </div>
              </div>
              
              <!-- Action Button -->
              <div class="mt-4 pt-4 border-t border-gray-200 dark:border-gray-700">
                <div class="flex items-center justify-between">
                  <span class="text-xs font-medium text-purple-600 dark:text-purple-400 group-hover:text-purple-700 dark:group-hover:text-purple-300">Build Custom Config</span>
                  <svg class="w-4 h-4 text-purple-600 dark:text-purple-400 group-hover:translate-x-1 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7l5 5m0 0l-5 5m5-5H6" />
                  </svg>
                </div>
              </div>
            </div>
          </button>
        </div>

        <!-- Two column layout: Guide and Comparison -->
        <div class="grid grid-cols-1 xl:grid-cols-5 gap-6 mt-8">
          <!-- Left column: Visual guide -->
          <div class="xl:col-span-2 bg-gray-50 dark:bg-gray-800/50 rounded-xl p-4 sm:p-6 border border-gray-200 dark:border-gray-700">
            <h3 class="text-base sm:text-sm font-semibold text-gray-900 dark:text-gray-100 mb-4 flex items-center">
              <Icon icon="mdi:book-open-variant" width="20" height="20" class="mr-2 text-gray-600 dark:text-gray-400" />
              How it Works
            </h3>
            
            <!-- Repository structure -->
            <div class="mb-6">
              <h4 class="text-xs font-medium text-gray-700 dark:text-gray-300 mb-3 uppercase tracking-wider">Repository Structure</h4>
              <div class="bg-white dark:bg-gray-900 rounded-lg p-3 sm:p-4 border border-gray-200 dark:border-gray-700 font-mono text-xs overflow-x-auto">
                <div class="flex items-center text-gray-700 dark:text-gray-300 mb-1">
                  <Icon icon="mdi:github" width="16" height="16" class="mr-2" />
                  <span class="font-semibold">my-terraform-repo</span>
                </div>
                <div class="border-l-2 border-gray-300 dark:border-gray-600 ml-2 pl-3">
                  <div class="flex items-center text-gray-600 dark:text-gray-400">
                    <Icon icon="mdi:folder" width="16" height="16" class="mr-2" />
                    <span>.terrateam/</span>
                  </div>
                  <div class="ml-4 mt-1">
                    <div class="flex flex-col sm:flex-row sm:items-center gap-1">
                      <div class="flex items-center text-green-600 dark:text-green-400 font-semibold">
                        <Icon icon="mdi:file-code" width="16" height="16" class="mr-2" />
                        <span>config.yml</span>
                      </div>
                      <span class="ml-6 sm:ml-2 text-xs font-normal text-gray-500">← Your config</span>
                    </div>
                  </div>
                  <div class="flex items-center text-gray-600 dark:text-gray-400 mt-1">
                    <Icon icon="mdi:folder" width="16" height="16" class="mr-2" />
                    <span>terraform/</span>
                  </div>
                  <div class="ml-4 mt-1">
                    <div class="flex items-center text-gray-500 dark:text-gray-500">
                      <Icon icon="mdi:file" width="16" height="16" class="mr-2" />
                      <span>main.tf</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            
            <!-- Quick steps -->
            <div>
              <h4 class="text-xs font-medium text-gray-700 dark:text-gray-300 mb-3 uppercase tracking-wider">Quick Steps</h4>
              <ol class="space-y-3 text-sm text-gray-600 dark:text-gray-400">
                <li class="flex items-start">
                  <span class="inline-flex items-center justify-center w-5 h-5 rounded-full bg-blue-100 dark:bg-blue-900/50 text-blue-600 dark:text-blue-400 text-xs font-semibold mr-2 flex-shrink-0 mt-0.5">1</span>
                  <span>Select a template or build custom</span>
                </li>
                <li class="flex items-start">
                  <span class="inline-flex items-center justify-center w-5 h-5 rounded-full bg-blue-100 dark:bg-blue-900/50 text-blue-600 dark:text-blue-400 text-xs font-semibold mr-2 flex-shrink-0 mt-0.5">2</span>
                  <span>Copy generated configuration</span>
                </li>
                <li class="flex items-start">
                  <span class="inline-flex items-center justify-center w-5 h-5 rounded-full bg-blue-100 dark:bg-blue-900/50 text-blue-600 dark:text-blue-400 text-xs font-semibold mr-2 flex-shrink-0 mt-0.5">3</span>
                  <span class="break-words">Commit to <code class="bg-gray-100 dark:bg-gray-800 px-1 rounded text-xs whitespace-nowrap">.terrateam/config.yml</code></span>
                </li>
                <li class="flex items-start">
                  <span class="inline-flex items-center justify-center w-5 h-5 rounded-full bg-blue-100 dark:bg-blue-900/50 text-blue-600 dark:text-blue-400 text-xs font-semibold mr-2 flex-shrink-0 mt-0.5">4</span>
                  <span>Open PR to activate</span>
                </li>
              </ol>
            </div>
          </div>

          <!-- Right column: Available Features -->
          <div class="xl:col-span-3 bg-gradient-to-br from-gray-50 to-white dark:from-gray-800 dark:to-gray-800/50 rounded-xl border border-gray-200 dark:border-gray-700 overflow-hidden shadow-sm">
            <div class="p-5 sm:p-6 border-b border-gray-200 dark:border-gray-700 bg-white/80 dark:bg-gray-800/80 backdrop-blur-sm">
              <h3 class="text-lg sm:text-base font-semibold text-gray-900 dark:text-gray-100">Available Features</h3>
              <p class="text-sm sm:text-xs text-gray-600 dark:text-gray-400 mt-1">All features are included in every Terrateam plan</p>
            </div>
            <div class="p-5 sm:p-6">
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-6 sm:gap-5">
                <!-- Core Features -->
                <div class="bg-white dark:bg-gray-800/50 rounded-lg p-4 border border-gray-100 dark:border-gray-700/50">
                  <h4 class="text-sm font-semibold text-gray-900 dark:text-gray-100 mb-3 flex items-center">
                    <Icon icon="mdi:robot-outline" width="18" height="18" class="mr-2 text-blue-600 dark:text-blue-400" />
                    Core Automation
                  </h4>
                  <ul class="space-y-2">
                    <li class="text-sm text-gray-600 dark:text-gray-400 flex items-start">
                      <span class="text-green-500 mr-2 mt-0.5">✓</span>
                      <span>Automated plan & apply</span>
                    </li>
                    <li class="text-sm text-gray-600 dark:text-gray-400 flex items-start">
                      <span class="text-green-500 mr-2 mt-0.5">✓</span>
                      <span>Multi-environment support</span>
                    </li>
                    <li class="text-sm text-gray-600 dark:text-gray-400 flex items-start">
                      <span class="text-green-500 mr-2 mt-0.5">✓</span>
                      <span>Directory & workspace management</span>
                    </li>
                    <li class="text-sm text-gray-600 dark:text-gray-400 flex items-start">
                      <span class="text-green-500 mr-2 mt-0.5">✓</span>
                      <span>GitOps workflow</span>
                    </li>
                  </ul>
                </div>
                  
                <!-- Monitoring & Insights -->
                <div class="bg-white dark:bg-gray-800/50 rounded-lg p-4 border border-gray-100 dark:border-gray-700/50">
                  <h4 class="text-sm font-semibold text-gray-900 dark:text-gray-100 mb-3 flex items-center">
                    <Icon icon="mdi:chart-line" width="18" height="18" class="mr-2 text-purple-600 dark:text-purple-400" />
                    Monitoring & Insights
                  </h4>
                  <ul class="space-y-2">
                    <li class="text-sm text-gray-600 dark:text-gray-400 flex items-start">
                      <span class="text-green-500 mr-2 mt-0.5">✓</span>
                      <span>Cost estimation</span>
                    </li>
                    <li class="text-sm text-gray-600 dark:text-gray-400 flex items-start">
                      <span class="text-green-500 mr-2 mt-0.5">✓</span>
                      <span>Drift detection</span>
                    </li>
                    <li class="text-sm text-gray-600 dark:text-gray-400 flex items-start">
                      <span class="text-green-500 mr-2 mt-0.5">✓</span>
                      <span>Slack notifications</span>
                    </li>
                    <li class="text-sm text-gray-600 dark:text-gray-400 flex items-start">
                      <span class="text-green-500 mr-2 mt-0.5">✓</span>
                      <span>Detailed logs & metrics</span>
                    </li>
                  </ul>
                </div>
                
                <!-- Security & Compliance -->
                <div class="bg-white dark:bg-gray-800/50 rounded-lg p-4 border border-gray-100 dark:border-gray-700/50">
                  <h4 class="text-sm font-semibold text-gray-900 dark:text-gray-100 mb-3 flex items-center">
                    <Icon icon="mdi:shield-check-outline" width="18" height="18" class="mr-2 text-green-600 dark:text-green-400" />
                    Security & Compliance
                  </h4>
                  <ul class="space-y-2">
                    <li class="text-sm text-gray-600 dark:text-gray-400 flex items-start">
                      <span class="text-green-500 mr-2 mt-0.5">✓</span>
                      <span>OIDC authentication</span>
                    </li>
                    <li class="text-sm text-gray-600 dark:text-gray-400 flex items-start">
                      <span class="text-green-500 mr-2 mt-0.5">✓</span>
                      <span>Role-based access control</span>
                    </li>
                    <li class="text-sm text-gray-600 dark:text-gray-400 flex items-start">
                      <span class="text-green-500 mr-2 mt-0.5">✓</span>
                      <span>Policy as Code (OPA)</span>
                    </li>
                    <li class="text-sm text-gray-600 dark:text-gray-400 flex items-start">
                      <span class="text-green-500 mr-2 mt-0.5">✓</span>
                      <span>Private runners</span>
                    </li>
                  </ul>
                </div>
                
                <!-- Advanced Patterns -->
                <div class="bg-white dark:bg-gray-800/50 rounded-lg p-4 border border-gray-100 dark:border-gray-700/50">
                  <h4 class="text-sm font-semibold text-gray-900 dark:text-gray-100 mb-3 flex items-center">
                    <Icon icon="mdi:puzzle-outline" width="18" height="18" class="mr-2 text-orange-600 dark:text-orange-400" />
                    Advanced Patterns
                  </h4>
                  <ul class="space-y-2">
                    <li class="text-sm text-gray-600 dark:text-gray-400 flex items-start">
                      <span class="text-green-500 mr-2 mt-0.5">✓</span>
                      <span>Layered runs</span>
                    </li>
                    <li class="text-sm text-gray-600 dark:text-gray-400 flex items-start">
                      <span class="text-green-500 mr-2 mt-0.5">✓</span>
                      <span>Automerge</span>
                    </li>
                    <li class="text-sm text-gray-600 dark:text-gray-400 flex items-start">
                      <span class="text-green-500 mr-2 mt-0.5">✓</span>
                      <span>Apply after merge</span>
                    </li>
                    <li class="text-sm text-gray-600 dark:text-gray-400 flex items-start">
                      <span class="text-green-500 mr-2 mt-0.5">✓</span>
                      <span>Apply requirements</span>
                    </li>
                  </ul>
                </div>
              </div>
              
              <div class="mt-4 pt-4 border-t border-gray-200 dark:border-gray-700">
                <a 
                  href="https://docs.terrateam.io/"
                  target="_blank"
                  rel="noopener noreferrer"
                  class="text-xs text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300 font-medium flex items-center"
                >
                  View all features in documentation
                  <Icon icon="mdi:open-in-new" width="14" height="14" class="ml-1" />
                </a>
              </div>
            </div>
          </div>
        </div>
      </div>

    {:else}
      <!-- Configuration Builder (Wizard or Custom) -->
      <div class="mb-6">
        <!-- Breadcrumb / Mode indicator -->
        <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 mb-6">
          <div class="flex items-center flex-wrap gap-x-2 text-sm">
            <button 
              on:click={() => { selectedMode = 'wizard'; selectedPreset = null; }}
              class="text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300"
            >
              Configuration
            </button>
            <span class="text-gray-400">/</span>
            <span class="text-gray-900 dark:text-gray-100 font-medium">
              {#if selectedPreset}
                <span class="inline-block">{CONFIG_PRESETS[selectedPreset].name}</span>
                <span class="hidden sm:inline"> Configuration</span>
              {:else}
                Custom Configuration
              {/if}
            </span>
          </div>
          
          {#if selectedMode === 'wizard' && selectedPreset}
            <button
              on:click={switchToCustom}
              class="text-sm text-purple-600 dark:text-purple-400 hover:text-purple-700 dark:hover:text-purple-300 font-medium whitespace-nowrap"
            >
              Customize Further →
            </button>
          {/if}
        </div>

        {#if selectedMode === 'wizard' && selectedPreset}
          <!-- Wizard Mode with Preset -->
          <div class="bg-blue-50 dark:bg-blue-900/20 rounded-xl border border-blue-200 dark:border-blue-800 p-4 sm:p-6 mb-6">
            <div class="flex flex-col sm:flex-row sm:items-start gap-4">
              <div class="flex justify-center sm:block">
                <Icon icon={CONFIG_PRESETS[selectedPreset].icon} width="48" height="48" class="text-blue-600 dark:text-blue-400" />
              </div>
              <div class="flex-1 text-center sm:text-left">
                <h3 class="text-lg sm:text-xl font-bold text-blue-900 dark:text-blue-100 mb-2">
                  {CONFIG_PRESETS[selectedPreset].name} Configuration
                </h3>
                <p class="text-sm sm:text-base text-blue-800 dark:text-blue-200 mb-4">
                  {CONFIG_PRESETS[selectedPreset].description}
                </p>
                
                <!-- Quick customization for all presets -->
                <div class="space-y-4">
                    <!-- Provider selection -->
                    <div>
                      <div class="block text-sm font-medium text-blue-900 dark:text-blue-100 mb-3">
                        Cloud Provider
                      </div>
                      <div class="grid grid-cols-2 sm:grid-cols-4 gap-3">
                        {#each ['none', 'aws', 'gcp', 'azure'] as provider}
                          <button
                            on:click={() => setProvider(provider)}
                            class="p-4 sm:p-3 rounded-lg border-2 transition-all flex flex-col items-center gap-2 {
                              configOptions.provider === provider 
                                ? 'border-blue-500 bg-blue-100 dark:bg-blue-900/50 shadow-md' 
                                : 'border-gray-300 dark:border-gray-600 hover:border-blue-300 bg-white dark:bg-gray-800'
                            }"
                          >
                            {#if provider === 'none'}
                              <Icon icon="mdi:wrench-outline" width="28" height="28" class="text-gray-600 dark:text-gray-400" />
                              <div class="text-xs font-medium">None</div>
                            {:else if provider === 'aws'}
                              <Icon icon="logos:aws" width="28" height="28" />
                              <div class="text-xs font-medium">AWS</div>
                            {:else if provider === 'gcp'}
                              <Icon icon="logos:google-cloud" width="28" height="28" />
                              <div class="text-xs font-medium">GCP</div>
                            {:else if provider === 'azure'}
                              <Icon icon="logos:microsoft-azure" width="28" height="28" />
                              <div class="text-xs font-medium">Azure</div>
                            {/if}
                          </button>
                        {/each}
                      </div>
                      
                      <!-- Documentation link for starter and team with provider -->
                      {#if (selectedPreset === 'starter' || selectedPreset === 'team') && configOptions.provider !== 'none'}
                        <div class="mt-3 p-3 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-800">
                          <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2">
                            <div class="flex items-start sm:items-center text-xs sm:text-sm text-blue-700 dark:text-blue-300">
                              <Icon icon="mdi:information-outline" width="16" height="16" class="mr-2 flex-shrink-0 mt-0.5 sm:mt-0" />
                              <span>
                                Setup requires adding secrets to your GitHub repository
                              </span>
                            </div>
                            <a 
                              href="https://docs.terrateam.io/cloud-providers/{configOptions.provider}/"
                              target="_blank"
                              rel="noopener noreferrer"
                              class="text-xs sm:text-sm text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300 flex items-center self-start sm:self-auto whitespace-nowrap"
                              on:click|stopPropagation
                            >
                              View Setup Guide
                              <Icon icon="mdi:open-in-new" width="14" height="14" class="ml-1" />
                            </a>
                          </div>
                        </div>
                      {/if}
                    </div>

                    {#if selectedPreset === 'advanced' && configOptions.provider !== 'none'}
                      <!-- Auth method for advanced -->
                      <div>
                        <div class="block text-sm font-medium text-blue-900 dark:text-blue-100 mb-2">
                          Authentication Method
                        </div>
                        <div class="grid grid-cols-2 gap-2">
                          <button
                            on:click={() => configOptions = { ...configOptions, authMethod: 'static' }}
                            class="p-3 rounded-lg border-2 transition-all {
                              configOptions.authMethod === 'static'
                                ? 'border-blue-500 bg-blue-100 dark:bg-blue-900/50'
                                : 'border-gray-300 dark:border-gray-600 hover:border-blue-300'
                            }"
                          >
                            <Icon icon="mdi:key-outline" width="24" height="24" class="text-gray-600 dark:text-gray-400 mb-1" />
                            <div class="text-sm font-medium">Static Secrets</div>
                            <div class="text-xs text-gray-600 dark:text-gray-400">Easier setup</div>
                          </button>
                          <button
                            on:click={() => configOptions.provider !== 'azure' && (configOptions = { ...configOptions, authMethod: 'oidc' })}
                            disabled={configOptions.provider === 'azure'}
                            class="p-3 rounded-lg border-2 transition-all {
                              configOptions.provider === 'azure' 
                                ? 'border-gray-200 dark:border-gray-700 opacity-50 cursor-not-allowed'
                                : configOptions.authMethod === 'oidc'
                                  ? 'border-blue-500 bg-blue-100 dark:bg-blue-900/50'
                                  : 'border-gray-300 dark:border-gray-600 hover:border-blue-300'
                            }"
                          >
                            <Icon icon="mdi:shield-lock-outline" width="24" height="24" class="text-gray-600 dark:text-gray-400 mb-1" />
                            <div class="text-sm font-medium">OIDC</div>
                            <div class="text-xs text-gray-600 dark:text-gray-400">
                              {configOptions.provider === 'azure' ? 'Coming soon' : 'More secure'}
                            </div>
                          </button>
                        </div>
                        
                        <!-- Documentation link for selected auth method -->
                        {#if configOptions.authMethod === 'static' || configOptions.authMethod === 'oidc'}
                          <div class="mt-3 p-3 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-800">
                            <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2">
                              <div class="flex items-start sm:items-center text-xs sm:text-sm text-blue-700 dark:text-blue-300">
                                <Icon icon="mdi:information-outline" width="16" height="16" class="mr-2 flex-shrink-0 mt-0.5 sm:mt-0" />
                                <span>
                                  {#if configOptions.authMethod === 'static'}
                                    Setup requires adding secrets to your GitHub repository
                                  {:else}
                                    OIDC provides secure, temporary credentials
                                  {/if}
                                </span>
                              </div>
                              <a 
                                href="https://docs.terrateam.io/cloud-providers/{configOptions.provider}/"
                                target="_blank"
                                rel="noopener noreferrer"
                                class="text-xs sm:text-sm text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300 flex items-center self-start sm:self-auto whitespace-nowrap"
                                on:click|stopPropagation
                              >
                                View Setup Guide
                                <Icon icon="mdi:open-in-new" width="14" height="14" class="ml-1" />
                              </a>
                            </div>
                          </div>
                        {/if}
                      </div>
                    {/if}
                  </div>
              </div>
            </div>
          </div>
        {:else}
          <!-- Custom Mode - Full Configuration -->
          <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <!-- Left Column: Basic Setup -->
            <div class="space-y-6">
              <div class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6">
                <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-4">Basic Setup</h3>
                
                <!-- Cloud Provider -->
                <div class="mb-4">
                  <div class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                    Cloud Provider
                  </div>
                  <div class="grid grid-cols-2 gap-2">
                    {#each [
                      { value: 'none', icon: '🔧', name: 'None' },
                      { value: 'aws', icon: 'logos:aws', name: 'AWS' },
                      { value: 'gcp', icon: 'logos:google-cloud', name: 'GCP' },
                      { value: 'azure', icon: 'logos:microsoft-azure', name: 'Azure' }
                    ] as provider}
                      <button
                        on:click={() => setProvider(provider.value)}
                        class="p-3 rounded-lg border-2 transition-all {
                          configOptions.provider === provider.value
                            ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/20'
                            : 'border-gray-300 dark:border-gray-600 hover:border-gray-400'
                        }"
                      >
                        {#if provider.icon.includes(':')}
                          <Icon icon={provider.icon} width="32" height="32" class="mx-auto mb-1" />
                        {:else}
                          <div class="text-2xl mb-1">{provider.icon}</div>
                        {/if}
                        <div class="text-sm font-medium">{provider.name}</div>
                      </button>
                    {/each}
                  </div>
                </div>

                <!-- Authentication Method -->
                {#if configOptions.provider !== 'none'}
                  <div class="mb-4">
                    <div class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                      Authentication Method
                    </div>
                    <div class="grid grid-cols-2 gap-2">
                      <button
                        on:click={() => configOptions = { ...configOptions, authMethod: 'static' }}
                        class="p-4 rounded-lg border-2 transition-all {
                          configOptions.authMethod === 'static'
                            ? 'border-green-500 bg-green-50 dark:bg-green-900/20'
                            : 'border-gray-300 dark:border-gray-600 hover:border-gray-400'
                        }"
                      >
                        <Icon icon="mdi:key-outline" width="24" height="24" class="text-gray-600 dark:text-gray-400 mb-1" />
                        <div class="text-sm font-medium">Static Secrets</div>
                        <div class="text-xs text-gray-600 dark:text-gray-400">GitHub secrets</div>
                      </button>
                      <button
                        on:click={() => configOptions.provider !== 'azure' && (configOptions = { ...configOptions, authMethod: 'oidc' })}
                        disabled={configOptions.provider === 'azure'}
                        class="p-4 rounded-lg border-2 transition-all {
                          configOptions.provider === 'azure'
                            ? 'border-gray-200 dark:border-gray-700 opacity-50 cursor-not-allowed'
                            : configOptions.authMethod === 'oidc'
                              ? 'border-orange-500 bg-orange-50 dark:bg-orange-900/20'
                              : 'border-gray-300 dark:border-gray-600 hover:border-gray-400'
                        }"
                      >
                        <Icon icon="mdi:shield-lock-outline" width="24" height="24" class="text-gray-600 dark:text-gray-400 mb-1" />
                        <div class="text-sm font-medium">OIDC</div>
                        <div class="text-xs text-gray-600 dark:text-gray-400">
                          {configOptions.provider === 'azure' ? 'Coming soon' : 'Recommended'}
                        </div>
                      </button>
                    </div>
                    
                    <!-- Documentation link for selected auth method -->
                    {#if configOptions.authMethod === 'static' || configOptions.authMethod === 'oidc'}
                      <div class="mt-3 p-3 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-800">
                        <div class="flex items-center justify-between">
                          <div class="flex items-center text-sm text-blue-700 dark:text-blue-300">
                            <Icon icon="mdi:information-outline" width="16" height="16" class="mr-2" />
                            <span>
                              {#if configOptions.authMethod === 'static'}
                                Setup requires adding secrets to your GitHub repository
                              {:else}
                                OIDC provides secure, temporary credentials
                              {/if}
                            </span>
                          </div>
                          <a 
                            href="https://docs.terrateam.io/cloud-providers/{configOptions.provider}/"
                            target="_blank"
                            rel="noopener noreferrer"
                            class="text-sm text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300 flex items-center"
                            on:click|stopPropagation
                          >
                            View Setup Guide
                            <Icon icon="mdi:open-in-new" width="14" height="14" class="ml-1" />
                          </a>
                        </div>
                      </div>
                    {/if}
                  </div>
                {/if}

                <!-- Repository Structure -->
                <div class="mb-4">
                  <div class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                    Repository Structure
                  </div>
                  <div class="space-y-2">
                    {#each [
                      { value: 'directories', icon: '📁', name: 'Directories', desc: 'Separate folders' },
                      { value: 'tfvars', icon: '📄', name: 'tfvars Files', desc: 'Variable files' },
                      { value: 'workspaces', icon: '🔀', name: 'Workspaces', desc: 'Terraform workspaces' }
                    ] as structure}
                      <button
                        on:click={() => setRepoStructure(structure.value)}
                        class="w-full p-3 rounded-lg border-2 text-left transition-all {
                          configOptions.repoStructure === structure.value
                            ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/20'
                            : 'border-gray-300 dark:border-gray-600 hover:border-gray-400'
                        }"
                      >
                        <div class="flex items-center">
                          <div class="text-lg mr-3">{structure.icon}</div>
                          <div>
                            <div class="text-sm font-medium">{structure.name}</div>
                            <div class="text-xs text-gray-600 dark:text-gray-400">{structure.desc}</div>
                          </div>
                        </div>
                      </button>
                    {/each}
                  </div>
                </div>

                <!-- Multiple Environments -->
                <div>
                  <button
                    on:click={() => configOptions = { ...configOptions, multipleEnvironments: !configOptions.multipleEnvironments }}
                    class="w-full p-3 rounded-lg border-2 transition-all {
                      configOptions.multipleEnvironments
                        ? 'border-purple-500 bg-purple-50 dark:bg-purple-900/20'
                        : 'border-gray-300 dark:border-gray-600 hover:border-gray-400'
                    }"
                  >
                    <div>
                      <div class="flex items-center justify-between">
                        <div class="flex items-center">
                          <div class="text-lg mr-3">🏗️</div>
                          <div class="flex items-center gap-3">
                            <span class="text-sm font-medium">Multiple Environments</span>
                            <a 
                              href="https://docs.terrateam.io/advanced-workflows/multiple-environments/"
                              target="_blank"
                              rel="noopener noreferrer"
                              on:click|stopPropagation
                              class="text-gray-400 hover:text-blue-600 dark:hover:text-blue-400 transition-colors"
                              title="Learn more about Multiple Environments (opens in new tab)"
                            >
                              <Icon icon="mdi:open-in-new" width="16" height="16" />
                            </a>
                          </div>
                        </div>
                        <div class="w-5 h-5 rounded border-2 flex-shrink-0 ml-3 {
                          configOptions.multipleEnvironments
                            ? 'bg-purple-500 border-purple-500'
                            : 'border-gray-400'
                        } flex items-center justify-center">
                          {#if configOptions.multipleEnvironments}
                            <svg class="w-3 h-3 text-white" fill="currentColor" viewBox="0 0 20 20">
                              <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
                            </svg>
                          {/if}
                        </div>
                      </div>
                    </div>
                  </button>
                </div>

                <!-- Private Runners -->
                <div class="mt-4">
                  <div class="p-4 rounded-lg border-2 border-gray-300 dark:border-gray-600 bg-gray-50 dark:bg-gray-900/50">
                    <div class="flex items-start">
                      <div class="text-lg mr-3 flex-shrink-0">🔒</div>
                      <div class="flex-1 min-w-0">
                        <div class="flex flex-wrap items-center gap-2 mb-2">
                          <span class="text-sm font-medium text-gray-900 dark:text-gray-100">Private Runners</span>
                          <span class="text-xs px-2 py-0.5 bg-green-100 dark:bg-green-900/50 text-green-700 dark:text-green-400 rounded-full font-medium whitespace-nowrap">Security Feature</span>
                        </div>
                        <p class="text-xs text-gray-600 dark:text-gray-400 mb-3">
                          Run Terrateam on your own infrastructure for enhanced security and compliance. 
                          Private runners keep your code and secrets within your network.
                        </p>
                        <div class="flex flex-col gap-2">
                          <div class="text-xs text-gray-500 dark:text-gray-500">
                            <span class="block mb-1">Configured in:</span>
                            <code class="bg-gray-200 dark:bg-gray-800 px-1.5 py-0.5 rounded text-xs break-all">.github/workflows/terrateam.yml</code>
                          </div>
                          <a 
                            href="https://docs.terrateam.io/security-and-compliance/private-runners/"
                            target="_blank"
                            rel="noopener noreferrer"
                            class="text-xs text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300 flex items-center font-medium self-start"
                          >
                            Setup Guide
                            <Icon icon="mdi:open-in-new" width="14" height="14" class="ml-1" />
                          </a>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <!-- Right Column: Features -->
            <div class="space-y-6">
              <div class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6">
                <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-4">Features</h3>
                
                {#each Object.entries(featureCategories) as [, category]}
                  <div class="mb-6 last:mb-0">
                    <h4 class="text-sm font-medium text-gray-700 dark:text-gray-300 mb-3 flex items-center">
                      <Icon icon={category.iconName} width="20" height="20" class="mr-2 text-gray-600 dark:text-gray-400" />
                      {category.name}
                    </h4>
                    <div class="space-y-2">
                      {#each category.features as feature}
                        <button
                          on:click={() => toggleFeature(feature)}
                          class="w-full p-3 rounded-lg border transition-all text-left {configOptions[feature] 
                            ? 'border-purple-500 bg-purple-50 dark:bg-purple-900/20' 
                            : 'border-gray-300 dark:border-gray-600 hover:border-gray-400'
                          }"
                        >
                          <div class="flex items-center justify-between">
                            <div class="flex-1">
                              <div class="flex items-center gap-2">
                                <span class="text-sm font-medium">{featureInfo[feature].name}</span>
                                <a 
                                  href={featureInfo[feature].docUrl}
                                  target="_blank"
                                  rel="noopener noreferrer"
                                  on:click|stopPropagation
                                  class="text-gray-400 hover:text-blue-600 dark:hover:text-blue-400 transition-colors"
                                  title="Learn more about {featureInfo[feature].name} (opens in new tab)"
                                >
                                  <Icon icon="mdi:open-in-new" width="16" height="16" />
                                </a>
                              </div>
                              <div class="text-xs text-gray-600 dark:text-gray-400">
                                {featureInfo[feature].description}
                              </div>
                            </div>
                            <div class="flex items-center ml-3">
                              <div class="w-5 h-5 rounded border-2 flex items-center justify-center"
                                class:bg-purple-500={configOptions[feature]}
                                class:border-purple-500={configOptions[feature]}
                                class:border-gray-400={!configOptions[feature]}
                              >
                                {#if configOptions[feature]}
                                  <svg class="w-3 h-3 text-white" fill="currentColor" viewBox="0 0 20 20">
                                    <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
                                  </svg>
                                {/if}
                              </div>
                            </div>
                          </div>
                        </button>
                      {/each}
                    </div>
                  </div>
                {/each}
              </div>
            </div>
          </div>
        {/if}
      </div>

      <!-- Configuration Preview -->
      {#if selectedPreset === 'starter' && configOptions.provider === 'none'}
        <!-- Special message for starter with no provider -->
        <div class="bg-green-50 dark:bg-green-900/20 rounded-lg border border-green-200 dark:border-green-800 p-6">
          <div class="flex items-start">
            <div class="flex-shrink-0">
              <Icon icon="mdi:check-circle" width="24" height="24" class="text-green-600 dark:text-green-400" />
            </div>
            <div class="ml-3">
              <h3 class="text-lg font-semibold text-green-900 dark:text-green-100 mb-2">
                No Configuration Needed!
              </h3>
              <p class="text-green-800 dark:text-green-200 mb-4">
                Terrateam works out of the box without any cloud provider credentials. This is perfect for:
              </p>
              <ul class="list-disc list-inside text-green-800 dark:text-green-200 space-y-1 mb-4">
                <li>Testing Terrateam with demo Terraform code</li>
                <li>Learning Terraform without cloud costs</li>
                <li>Running local Terraform providers</li>
                <li>Using Terraform for non-cloud resources</li>
              </ul>
              <div class="bg-white dark:bg-green-800/30 rounded-lg p-4 border border-green-300 dark:border-green-700">
                <h4 class="font-semibold text-green-900 dark:text-green-100 mb-2">Quick Start:</h4>
                <ol class="text-sm text-green-800 dark:text-green-200 space-y-1">
                  <li>1. Push any Terraform files to your repository</li>
                  <li>2. Open a pull request</li>
                  <li>3. Terrateam will automatically run <code class="bg-green-100 dark:bg-green-800 px-1 rounded">terraform plan</code></li>
                </ol>
              </div>
              <p class="text-sm text-green-700 dark:text-green-300 mt-4">
                💡 When you're ready to use cloud resources, come back here and select your cloud provider above.
              </p>
            </div>
          </div>
        </div>
      {:else if selectedPreset === 'starter' && configOptions.provider !== 'none'}
        <!-- Special message for starter with cloud provider (static secrets only) -->
        <div class="bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-800 p-4 sm:p-6">
          <div class="flex flex-col sm:flex-row sm:items-start gap-3">
            <div class="flex-shrink-0 flex justify-center sm:block">
              <Icon icon="mdi:cloud-check" width="24" height="24" class="text-blue-600 dark:text-blue-400" />
            </div>
            <div class="flex-1">
              <h3 class="text-base sm:text-lg font-semibold text-blue-900 dark:text-blue-100 mb-2 text-center sm:text-left">
                No Configuration File Needed
              </h3>
              <p class="text-sm sm:text-base text-blue-800 dark:text-blue-200 mb-4 text-center sm:text-left">
                Terrateam works automatically with {configOptions.provider.toUpperCase()} using GitHub secrets. You don't need a configuration file!
              </p>
              
              <div class="bg-white dark:bg-blue-800/30 rounded-lg p-3 sm:p-4 border border-blue-300 dark:border-blue-700 mb-4">
                <h4 class="font-semibold text-blue-900 dark:text-blue-100 mb-3 text-sm sm:text-base">Quick Setup:</h4>
                <ol class="text-xs sm:text-sm text-blue-800 dark:text-blue-200 space-y-3">
                  <li class="flex items-start">
                    <span class="font-semibold mr-2 flex-shrink-0">1.</span>
                    <div class="flex-1 min-w-0">
                      <span class="block mb-2">Add these secrets to your GitHub repository:</span>
                      <div class="font-mono text-xs bg-blue-100 dark:bg-blue-800 p-2 rounded overflow-x-auto">
                        {getSecretsForProvider(configOptions.provider)}
                      </div>
                    </div>
                  </li>
                  <li class="flex items-start">
                    <span class="font-semibold mr-2 flex-shrink-0">2.</span>
                    <span class="flex-1">Push Terraform files to any directory in your repository</span>
                  </li>
                  <li class="flex items-start">
                    <span class="font-semibold mr-2 flex-shrink-0">3.</span>
                    <div class="flex-1">
                      <span>Open a pull request - Terrateam will automatically run </span>
                      <code class="inline bg-blue-100 dark:bg-blue-800 px-1.5 py-0.5 rounded text-xs">terraform plan</code>
                    </div>
                  </li>
                </ol>
              </div>
              
              <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
                <p class="text-xs sm:text-sm text-blue-700 dark:text-blue-300 text-center sm:text-left">
                  💡 Want to add features later? Use the Custom configuration option.
                </p>
                <a 
                  href="https://docs.terrateam.io/cloud-providers/{configOptions.provider}/"
                  target="_blank"
                  rel="noopener noreferrer"
                  class="text-sm text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300 font-medium flex items-center"
                >
                  {configOptions.provider.toUpperCase()} Setup Guide
                  <Icon icon="mdi:open-in-new" width="14" height="14" class="ml-1" />
                </a>
              </div>
            </div>
          </div>
        </div>
      {:else if selectedPreset !== 'starter'}
        <div class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700">
        <div class="border-b border-gray-200 dark:border-gray-700 p-3 md:p-4">
          <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
            <div>
              <h3 class="font-semibold text-sm md:text-base text-gray-900 dark:text-gray-100">
                {generatedConfig.includes('No configuration file is required') ? 'Getting Started' : 'Configuration Preview'}
              </h3>
              <p class="text-xs md:text-sm text-gray-600 dark:text-gray-400">
                {generatedConfig.includes('No configuration file is required') 
                  ? 'No config file needed - Terrateam works out of the box!' 
                  : 'Live preview of your .terrateam/config.yml'}
              </p>
            </div>
            <button
              on:click={() => copyToClipboard()}
              class="inline-flex items-center justify-center px-2.5 md:px-3 py-1.5 md:py-2 border rounded-md text-xs md:text-sm font-medium transition-all duration-200 {copySuccess 
                ? 'border-green-500 text-green-700 dark:text-green-300 bg-green-50 dark:bg-green-900/20' 
                : 'border-gray-300 dark:border-gray-600 text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-700 hover:bg-gray-50 dark:hover:bg-gray-600'}"
            >
              {#if copySuccess}
                <svg class="w-3 md:w-4 h-3 md:h-4 mr-1.5 md:mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                </svg>
                Copied!
              {:else}
                <svg class="w-3 md:w-4 h-3 md:h-4 mr-1.5 md:mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
                </svg>
                Copy
              {/if}
            </button>
          </div>
        </div>
        <div class="p-3 md:p-4">
          {#if generatedConfig.includes('No configuration file is required')}
            <pre class="bg-gray-50 dark:bg-gray-900 rounded-lg p-3 md:p-4 text-xs font-mono overflow-x-auto whitespace-pre-wrap transition-all duration-300 {copySuccess ? 'ring-2 ring-green-500 ring-opacity-50' : ''}"><code>{generatedConfig}</code></pre>
          {:else}
            <pre class="config-hljs bg-gray-50 dark:bg-gray-900 rounded-lg p-3 md:p-4 text-xs font-mono overflow-x-auto whitespace-pre-wrap transition-all duration-300 {copySuccess ? 'ring-2 ring-green-500 ring-opacity-50' : ''}"><code class="language-yaml">{@html highlightedConfig}</code></pre>
          {/if}
        </div>
      </div>

      <!-- Next Steps -->
      <div class="mt-6 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-800 p-4">
        <div class="flex items-start">
          <div class="flex-shrink-0">
            <svg class="w-5 h-5 text-blue-600 dark:text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <div class="ml-3 flex-1">
            <h4 class="text-sm font-semibold text-blue-900 dark:text-blue-100 mb-2">Next Steps</h4>
            {#if generatedConfig.includes('No configuration file is required')}
              <ol class="text-sm text-blue-800 dark:text-blue-200 space-y-1">
                <li>1. No configuration file needed!</li>
                {#if configOptions.provider !== 'none'}
                  <li>2. Add {getSecretsForProvider(configOptions.provider)} to your GitHub repository secrets</li>
                  <li>3. Push Terraform files to any directory</li>
                  <li>4. Open a pull request - Terrateam will automatically plan your changes</li>
                {:else}
                  <li>2. Push Terraform files to any directory</li>
                  <li>3. Open a pull request - Terrateam will automatically plan your changes</li>
                {/if}
              </ol>
            {:else}
              <ol class="text-sm text-blue-800 dark:text-blue-200 space-y-1">
                <li>1. Copy the generated configuration</li>
                <li>2. Tailor the configuration to match your repository structure and requirements</li>
                <li>3. Create <code class="bg-blue-100 dark:bg-blue-800 px-1 rounded">.terrateam/config.yml</code> in your repository</li>
                {#if configOptions.provider !== 'none'}
                  <li>4. {configOptions.authMethod === 'static' 
                    ? `Add ${getSecretsForProvider(configOptions.provider)} to GitHub secrets` 
                    : `Configure ${configOptions.provider.toUpperCase()} OIDC`}</li>
                  <li>5. Create a pull request to test your configuration</li>
                {:else}
                  <li>4. Create a pull request to test your configuration</li>
                {/if}
              </ol>
            {/if}
            <div class="mt-3 flex flex-col sm:flex-row sm:items-center gap-2 sm:gap-0">
              <button 
                on:click={() => openDocumentation('https://docs.terrateam.io/')}
                class="text-xs md:text-sm text-blue-700 dark:text-blue-300 hover:text-blue-900 dark:hover:text-blue-100 underline"
              >
                View documentation
              </button>
              <span class="hidden sm:inline mx-1 md:mx-2 text-blue-600 dark:text-blue-400">·</span>
              <button 
                on:click={() => openDocumentation('https://terrateam.io/slack')}
                class="text-xs md:text-sm text-blue-700 dark:text-blue-300 hover:text-blue-900 dark:hover:text-blue-100 underline"
              >
                Get help on Slack
              </button>
              <span class="hidden sm:inline mx-1 md:mx-2 text-blue-600 dark:text-blue-400">·</span>
              <button 
                on:click={() => window.open('https://calendly.com/terrateam/30-minute-chat', '_blank')}
                class="text-xs md:text-sm text-blue-700 dark:text-blue-300 hover:text-blue-900 dark:hover:text-blue-100 underline"
              >
                Schedule free onboarding call
              </button>
            </div>
          </div>
        </div>
      </div>
      {/if}
    {/if}
  </div>
  
  <!-- Toast Notification -->
  {#if showToast}
    <div class="fixed bottom-4 right-4 left-4 sm:left-auto z-50 config-animate-slide-up">
      <div class="bg-green-600 text-white px-4 md:px-6 py-2.5 md:py-3 rounded-lg shadow-lg flex items-center space-x-3">
        <svg class="w-4 md:w-5 h-4 md:h-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        <div>
          <p class="font-medium text-sm md:text-base">Configuration copied!</p>
          <p class="text-xs md:text-sm text-green-100">Ready to paste into .terrateam/config.yml</p>
        </div>
      </div>
    </div>
  {/if}
</PageLayout>

