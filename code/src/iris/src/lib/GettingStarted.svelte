<script lang="ts">
  import PageLayout from './components/layout/PageLayout.svelte';
  import { api, isApiError } from './api';
  import { onMount } from 'svelte';
  import type { Installation, Repository, GitLabGroup, ServerConfig } from './types';
  import { repositoryService } from './services/repository-service';
  import { Icon } from './components';
  import { currentVCSProvider } from './stores';
  import { get } from 'svelte/store';
  import { VCS_PROVIDERS } from './vcs/providers';
  import GitLabSetup from './GitLabSetup.svelte';
  import { analytics } from './analytics';
  import { onDestroy } from 'svelte';

  // Track time spent
  let startTime = Date.now();
  let lastStepTime = Date.now();

  // Wizard state
  type WizardStep = 'assessment' | 'path-selection' | 'github-demo-setup' | 'gitlab-demo-setup' | 'github-repo-setup' | 'gitlab-setup' | 'validation' | 'success';
  type DemoStep = 'install-app' | 'fork' | 'enable-actions' | 'make-changes' | 'success';
  type GitLabDemoStep = 'select-group' | 'fork' | 'add-bot' | 'configure-webhook' | 'push-test' | 'configure-variables' | 'make-changes' | 'success';
  type RepoStep = 'install-app' | 'select-repo' | 'add-workflow' | 'configure' | 'test' | 'success';
  type GitLabStep = 'select-group' | 'select-repo' | 'add-bot' | 'configure-webhook' | 'push-test' | 'configure-variables' | 'add-pipeline' | 'success';
  let currentStep: WizardStep = 'assessment';
  let selectedPath: 'demo' | 'repo' | null = null;
  let currentDemoStep: DemoStep = 'install-app';
  let currentGitLabDemoStep: GitLabDemoStep = 'select-group';
  let currentRepoStep: RepoStep = 'install-app';
  let currentGitLabStep: GitLabStep = 'select-group';

  // Server configuration
  let serverConfig: ServerConfig | null = null;
  let githubAppUrl: string = 'https://github.com/apps/terrateam-action'; // fallback URL

  // API data
  let installations: Installation[] = [];
  let selectedInstallation: Installation | null = null;
  let selectedInstallationId: string = '';
  let repositories: Repository[] = [];
  let isLoadingAssessment = true;
  let assessmentError: string | null = null;

  // Assessment results
  let hasInstallations = false;
  let hasConfiguredRepos = false;
  let recommendedPath: 'demo' | 'repo' = 'demo';
  
  // GitLab setup state
  let showGitLabSetup = false;
  
  // Get current VCS provider terminology
  $: currentProvider = $currentVCSProvider || 'github';
  $: terminology = VCS_PROVIDERS[currentProvider]?.terminology || VCS_PROVIDERS.github.terminology;

  // Demo wizard state
  let demoStepCompleted = {
    'install-app': false,
    fork: false,
    'enable-actions': false,
    'make-changes': false
  };
  let checkingAppInstallation = false;

  // GitLab Demo wizard state
  let gitlabDemoStepCompleted = {
    'select-group': false,
    fork: false,
    'add-bot': false,
    'configure-webhook': false,
    'push-test': false,
    'configure-variables': false,
    'make-changes': false
  };
  let checkingBotAdded = false;
  let botVerificationError: string | null = null;
  let gitlabDemoGroups: GitLabGroup[] = [];
  let selectedGitLabDemoGroup: GitLabGroup | null = null;
  let isLoadingGitLabGroups = false;
  let gitlabGroupsError: string | null = null;
  let forkedProjectPath: string = '';  // Store the forked project path
  let webhookUrl: string = '';
  let webhookSecret: string = '';
  let isDemoCheckingPushTest = false;
  let demoPushTestError: string | null = null;
  let demoPushTestSuccess = false;
  let checkingWebhook = false;
  let webhookVerificationError: string | null = null;

  // Repository wizard state
  let repoStepCompleted = {
    'install-app': false,
    'select-repo': false,
    'add-workflow': false,
    'configure': false,
    'test': false
  };
  let selectedRepository: Repository | null = null;
  let isLoadingRepos = false;
  let repoLoadError: string | null = null;

  // GitLab wizard state
  let gitlabStepCompleted = {
    'select-group': false,
    'select-repo': false,
    'add-bot': false,
    'configure-webhook': false,
    'push-test': false,
    'configure-variables': false,
    'add-pipeline': false
  };
  let gitlabGroups: GitLabGroup[] = [];
  let selectedGitLabGroup: GitLabGroup | null = null;
  let isLoadingGitLabSetupGroups = false;
  let gitlabSetupGroupsError: string | null = null;
  let gitlabRepos: Repository[] = [];
  let manualGitLabProject = '';
  let isAddingGitLabProject = false;
  let checkingGitLabBot = false;
  let gitlabBotError: string | null = null;
  let gitlabBotUsername: string | null = null;
  let copiedYaml = false;
  let isCheckingPushTest = false;
  let pushTestError: string | null = null;
  let pushTestSuccess = false;

  onMount(async () => {
    // Track getting started page view
    analytics.track('getting_started_viewed', {
      vcs_provider: get(currentVCSProvider)
    });

    // Fetch server config first to get GitHub app URL
    try {
      serverConfig = await api.getServerConfig();
      if (serverConfig?.github?.app_url) {
        githubAppUrl = serverConfig.github.app_url;
      }
    } catch (error) {
      console.error('Failed to fetch server config:', error);
      // Will use fallback URL
    }

    await runSmartAssessment();
    // Fetch GitLab bot username if we're showing GitLab setup
    if (get(currentVCSProvider) === 'gitlab') {
      await loadGitLabBotUsername();
    }
  });

  onDestroy(() => {
    // Track abandonment if user leaves before completing
    if (currentStep !== 'success') {
      const timeSpent = Math.round((Date.now() - startTime) / 1000);
      analytics.track('getting_started_abandoned', {
        last_step: currentStep,
        last_demo_step: currentDemoStep,
        last_gitlab_demo_step: currentGitLabDemoStep,
        last_repo_step: currentRepoStep,
        last_gitlab_step: currentGitLabStep,
        path: selectedPath,
        vcs_provider: currentProvider,
        time_spent_seconds: timeSpent,
        has_installations: hasInstallations,
        has_configured_repos: hasConfiguredRepos,
        selected_repository: selectedRepository?.name,
        selected_gitlab_group: selectedGitLabGroup?.name || selectedGitLabDemoGroup?.name
      });
    }
  });

  async function runSmartAssessment(): Promise<void> {
    try {
      isLoadingAssessment = true;
      assessmentError = null;

      // Check user's current installations
      const provider = get(currentVCSProvider);
      
      // For GitLab, check if we should show the setup wizard
      if (provider === 'gitlab') {
        try {
          const installationsResponse = await api.getUserInstallations(provider);
          installations = installationsResponse.installations;
          hasInstallations = installations.length > 0;
        } catch (error) {
          // If GitLab installations endpoint returns 404, show setup wizard
          if (isApiError(error) && error.status === 404) {
            showGitLabSetup = true;
            currentStep = 'path-selection';
            isLoadingAssessment = false;
            // Load GitLab bot username
            await loadGitLabBotUsername();
            return;
          }
          throw error;
        }
      } else {
        // GitHub flow remains the same
        const installationsResponse = await api.getUserInstallations(provider);
        installations = installationsResponse.installations;
        hasInstallations = installations.length > 0;
      }
      
      // Initialize selected installation if we have installations
      if (hasInstallations && !selectedInstallation) {
        selectedInstallation = installations[0];
        selectedInstallationId = installations[0].id;
      }

      if (hasInstallations) {
        // Check if any repos are already configured
        for (const installation of installations) {
          try {
            const dirspacesResponse = await api.getInstallationDirspaces(installation.id);
            if (dirspacesResponse.dirspaces && dirspacesResponse.dirspaces.length > 0) {
              hasConfiguredRepos = true;
              break;
            }
          } catch (error) {
            // Continue checking other installations
          }
        }
      }

      // Smart recommendation based on assessment
      if (hasConfiguredRepos) {
        recommendedPath = 'repo'; // User already has working setup
      } else if (hasInstallations) {
        recommendedPath = 'repo'; // User has installations, help them configure
      } else {
        recommendedPath = 'demo'; // New user, start with demo
      }

      currentStep = 'path-selection';
    } catch (error) {
      console.error('Assessment failed:', error);
      assessmentError = 'Unable to assess your current setup. You can still proceed with manual setup.';
      currentStep = 'path-selection';
    } finally {
      isLoadingAssessment = false;
    }
  }

  function selectPath(path: 'demo' | 'repo'): void {
    selectedPath = path;

    // Track path selection
    analytics.track('getting_started_path_selected', {
      path: path,
      vcs_provider: currentProvider,
      has_installations: hasInstallations,
      has_configured_repos: hasConfiguredRepos
    });

    if (path === 'demo') {
      // Branch demo based on VCS provider - explicit GitHub vs GitLab
      if (currentProvider === 'gitlab') {
        currentStep = 'gitlab-demo-setup';
        // Load GitLab groups for demo
        loadGitLabGroups();
        // Load GitLab bot username
        loadGitLabBotUsername();
      } else {
        currentStep = 'github-demo-setup';
      }
    } else {
      // Branch repo setup based on VCS provider - explicit GitHub vs GitLab
      if (currentProvider === 'gitlab') {
        currentStep = 'gitlab-setup';
        loadGitLabSetupGroups();
        // Load GitLab bot username
        loadGitLabBotUsername();
      } else {
        currentStep = 'github-repo-setup';
        // Always start at the install-app step to give users the option to install on different orgs
      }
    }
  }

  function goBack(): void {
    switch (currentStep) {
      case 'github-demo-setup':
      case 'gitlab-demo-setup':
      case 'github-repo-setup':
      case 'gitlab-setup':
        currentStep = 'path-selection';
        selectedPath = null;
        break;
      case 'validation':
        if (selectedPath === 'demo') {
          if (currentProvider === 'gitlab') {
            currentStep = 'gitlab-demo-setup';
          } else {
            currentStep = 'github-demo-setup';
          }
        } else if (currentProvider === 'gitlab') {
          currentStep = 'gitlab-setup';
        } else {
          currentStep = 'github-repo-setup';
        }
        break;
      default:
        currentStep = 'path-selection';
    }
  }

  function openExternalLink(url: string, linkType?: string): void {
    // Track external link clicks
    analytics.track('getting_started_external_link_clicked', {
      url: url,
      link_type: linkType || 'unknown',
      current_step: currentStep,
      current_demo_step: currentDemoStep,
      current_repo_step: currentRepoStep,
      path: selectedPath,
      vcs_provider: currentProvider
    });

    window.open(url, '_blank');
  }
  
  // GitLab setup handlers
  function handleGitLabSetupComplete(groupId: number): void {
    showGitLabSetup = false;
    
    // After setup is complete, navigate to the dashboard with proper GitLab installation ID
    // GitLab installations use the group ID as the installation ID
    window.location.hash = `#/i/${groupId}/dashboard`;
  }
  
  function handleGitLabSetupCancel(): void {
    showGitLabSetup = false;
    currentStep = 'assessment';
    runSmartAssessment();
  }

  function openConfigurationWizard(): void {
    if (selectedInstallation) {
      window.location.hash = `#/i/${selectedInstallation.id}/configuration`;
    } else {
      window.location.hash = '#/configuration';
    }
  }

  // Demo wizard functions
  function markDemoStepComplete(step: DemoStep): void {
    if (step !== 'success') {
      demoStepCompleted[step] = true;
    }
    
    // Track step completion
    analytics.track('getting_started_step_completed', {
      path: 'demo',
      vcs_provider: 'github',
      step: step,
      step_index: ['install-app', 'fork', 'enable-actions', 'make-changes'].indexOf(step) + 1
    });

    // Auto-advance to next step
    const steps: DemoStep[] = ['install-app', 'fork', 'enable-actions', 'make-changes', 'success'];
    const currentIndex = steps.indexOf(currentDemoStep);
    if (currentIndex < steps.length - 1) {
      currentDemoStep = steps[currentIndex + 1];
    }

    // Track completion of entire flow
    if (currentDemoStep === 'success') {
      const timeSpent = Math.round((Date.now() - startTime) / 1000);
      analytics.track('getting_started_completed', {
        path: 'demo',
        vcs_provider: 'github',
        time_spent_seconds: timeSpent
      });
    }
  }

  function goToDemoStep(step: DemoStep): void {
    currentDemoStep = step;
  }
  
  function goToGitLabDemoStep(step: GitLabDemoStep): void {
    currentGitLabDemoStep = step;
  }

  // GitLab demo wizard functions
  async function loadGitLabGroups(): Promise<void> {
    try {
      isLoadingGitLabGroups = true;
      gitlabGroupsError = null;
      gitlabDemoGroups = await api.getGitLabGroups();
    } catch (error) {
      console.error('Failed to load GitLab groups:', error);
      gitlabGroupsError = 'Failed to load groups. Please try again.';
    } finally {
      isLoadingGitLabGroups = false;
    }
  }

  function selectGitLabDemoGroup(group: GitLabGroup): void {
    selectedGitLabDemoGroup = group;
    // Pre-fill the expected project path
    forkedProjectPath = `${group.name}/kick-the-tires`;

    // Track group selection
    analytics.track('getting_started_gitlab_group_selected', {
      path: 'demo',
      vcs_provider: 'gitlab',
      group: group.name,
      group_type: group.kind
    });

    markGitLabDemoStepComplete('select-group');
  }

  function markGitLabDemoStepComplete(step: GitLabDemoStep): void {
    if (step !== 'success') {
      gitlabDemoStepCompleted[step] = true;
    }
    
    // Track step completion
    analytics.track('getting_started_step_completed', {
      path: 'demo',
      vcs_provider: 'gitlab',
      step: step,
      step_index: ['select-group', 'fork', 'add-bot', 'configure-webhook', 'push-test', 'configure-variables', 'make-changes'].indexOf(step) + 1,
      group: selectedGitLabDemoGroup?.name
    });

    // Auto-advance to next step
    const steps: GitLabDemoStep[] = ['select-group', 'fork', 'add-bot', 'configure-webhook', 'push-test', 'configure-variables', 'make-changes', 'success'];
    const currentIndex = steps.indexOf(currentGitLabDemoStep);
    if (currentIndex < steps.length - 1) {
      currentGitLabDemoStep = steps[currentIndex + 1];
    }
    
    // Track completion of entire flow
    if (currentGitLabDemoStep === 'success') {
      const timeSpent = Math.round((Date.now() - startTime) / 1000);
      analytics.track('getting_started_completed', {
        path: 'demo',
        vcs_provider: 'gitlab',
        time_spent_seconds: timeSpent,
        group: selectedGitLabDemoGroup?.name
      });
    }

    // Load webhook config when entering webhook step
    if (currentGitLabDemoStep === 'configure-webhook' && selectedGitLabDemoGroup) {
      loadWebhookConfig();
    }
  }

  async function loadWebhookConfig(): Promise<void> {
    if (!selectedGitLabDemoGroup) return;

    try {
      const config = await api.getGitLabWebhookConfig(selectedGitLabDemoGroup.id.toString());
      webhookUrl = config.webhook_url;
      webhookSecret = config.webhook_secret || '';
    } catch (error) {
      console.error('Failed to load webhook config:', error);
      // Set defaults if API fails
      webhookUrl = 'https://api.terrateam.io/webhook/gitlab';
      webhookSecret = 'Contact support for webhook secret';
    }
  }
  
  async function checkWebhook(): Promise<void> {
    if (!selectedGitLabDemoGroup) return;
    
    try {
      checkingWebhook = true;
      webhookVerificationError = null;
      
      // Track webhook verification attempt
      analytics.track('getting_started_gitlab_webhook_check', {
        path: 'demo',
        vcs_provider: 'gitlab',
        group: selectedGitLabDemoGroup.name
      });

      const config = await api.getGitLabWebhookConfig(selectedGitLabDemoGroup.id.toString());
      const isActive = config.state === 'active';
      
      if (isActive) {
        webhookVerificationError = null;

        // Track successful webhook configuration
        analytics.track('getting_started_gitlab_webhook_configured', {
          path: 'demo',
          vcs_provider: 'gitlab',
          group: selectedGitLabDemoGroup.name
        });

        markGitLabDemoStepComplete('configure-webhook');
      } else {
        webhookVerificationError = 'Webhook is not active yet. Please test it with a Push Event in GitLab.';
      }
    } catch (error) {
      console.error('Failed to check webhook:', error);
      webhookVerificationError = 'Unable to verify webhook. Please ensure you\'ve added it and tested with a Push Event.';
    } finally {
      checkingWebhook = false;
    }
  }

  async function checkBotAdded(): Promise<void> {
    try {
      checkingBotAdded = true;
      botVerificationError = null;
      
      // Track bot verification attempt
      analytics.track('getting_started_gitlab_bot_check', {
        path: 'demo',
        vcs_provider: 'gitlab',
        group: selectedGitLabDemoGroup?.name
      });

      // For GitLab demo, check if the bot was added to the selected group
      if (selectedGitLabDemoGroup) {
        // Always check via API, even for personal namespace
        try {
          const isAdded = await api.checkGitLabGroupMembership(Number(selectedGitLabDemoGroup.id));
          if (isAdded) {
            botVerificationError = null;

            // Track successful bot addition
            analytics.track('getting_started_gitlab_bot_added', {
              path: 'demo',
              vcs_provider: 'gitlab',
              group: selectedGitLabDemoGroup.name
            });
            
            markGitLabDemoStepComplete('add-bot');
          } else {
            botVerificationError = `The bot has not been added yet. Please add @${gitlabBotUsername || 'terrateam-bot'} as a Developer to your group.`;
          }
        } catch (apiError) {
          // If the check fails, show an error
          console.error('Failed to check bot membership:', apiError);
          botVerificationError = `Unable to verify bot was added. Please ensure @${gitlabBotUsername || 'terrateam-bot'} is added as a Developer to your group.`;
        }
      } else {
        botVerificationError = 'No group selected. Please go back and select a group.';
      }
      
    } catch (error) {
      console.error('Failed to check bot status:', error);
      botVerificationError = 'Unable to check bot status. You can continue manually using "Skip Verification".';
    } finally {
      checkingBotAdded = false;
    }
  }

  async function checkAppInstallation(): Promise<void> {
    try {
      checkingAppInstallation = true;
      
      // Track app installation check
      analytics.track('getting_started_check_installation', {
        path: 'demo',
        vcs_provider: currentProvider,
        had_installations_before: hasInstallations
      });
      
      // Re-fetch installations to see if app was installed
      const installationsResponse = await api.getUserInstallations();
      const newInstallations = installationsResponse.installations;
      
      // If we already had installations, just proceed
      if (hasInstallations && installations.length > 0) {
        markDemoStepComplete('install-app');
      }
      // Check if we have more installations than before
      else if (newInstallations.length > installations.length) {
        installations = newInstallations;
        hasInstallations = true;
        
        // Track successful installation
        analytics.track('getting_started_app_installed', {
          path: 'demo',
          vcs_provider: currentProvider,
          installation_count: newInstallations.length
        });
        markDemoStepComplete('install-app');
      } else {
        // Show message that we didn't detect the installation
        alert('We didn\'t detect the GitHub App installation. Make sure you installed it and try again, or continue manually.');
      }
    } catch (error) {
      console.error('Failed to check app installation:', error);
      alert('Unable to check installation status. You can continue manually.');
    } finally {
      checkingAppInstallation = false;
    }
  }

  // Repository wizard functions
  function markRepoStepComplete(step: RepoStep): void {
    if (step !== 'success') {
      repoStepCompleted[step] = true;
    }
    
    // Track step completion
    analytics.track('getting_started_step_completed', {
      path: 'repo',
      vcs_provider: currentProvider,
      step: step,
      step_index: ['install-app', 'select-repo', 'add-workflow', 'configure', 'test'].indexOf(step) + 1,
      repository: selectedRepository?.name
    });
    
    // Auto-advance to next step
    const steps: RepoStep[] = ['install-app', 'select-repo', 'add-workflow', 'configure', 'test', 'success'];
    const currentIndex = steps.indexOf(currentRepoStep);
    if (currentIndex < steps.length - 1) {
      currentRepoStep = steps[currentIndex + 1];
    }
    
    // Track completion of entire flow
    if (currentRepoStep === 'success') {
      const timeSpent = Math.round((Date.now() - startTime) / 1000);
      analytics.track('getting_started_completed', {
        path: 'repo',
        vcs_provider: currentProvider,
        time_spent_seconds: timeSpent,
        repository: selectedRepository?.name,
        installation: selectedInstallation?.name
      });
    }
  }

  function goToRepoStep(step: RepoStep): void {
    currentRepoStep = step;
  }

  async function loadRepositories(forceRefresh: boolean = false): Promise<void> {
    if (!selectedInstallation) return;
    
    try {
      isLoadingRepos = true;
      repoLoadError = null;
      
      // Load repositories from centralized service
      const result = await repositoryService.loadRepositories(selectedInstallation, forceRefresh);
      repositories = result.repositories;
      
      if (result.error) {
        repoLoadError = result.error;
      }
      
    } catch (error) {
      console.error('Failed to load repositories:', error);
      repoLoadError = 'Unable to load repositories. Please try again.';
    } finally {
      isLoadingRepos = false;
    }
  }

  async function refreshRepositories(): Promise<void> {
    if (!selectedInstallation || isLoadingRepos) return;
    
    try {
      isLoadingRepos = true;
      repoLoadError = null;

      // Call the refresh endpoint - this triggers a background job to sync with GitHub
      const refreshResponse = await api.refreshInstallationRepos(selectedInstallation.id);
      
      // Poll the task status
      let attempts = 0;
      const maxAttempts = 30; // 30 seconds max
      
      while (attempts < maxAttempts) {
        await new Promise(resolve => setTimeout(resolve, 1000)); // Wait 1 second
        
        try {
          const taskStatus = await api.getTask(refreshResponse.id);
          
          if (taskStatus.state === 'completed') {
            // Refresh completed successfully, reload repositories with force refresh
            await loadRepositories(true);
            break;
          } else if (taskStatus.state === 'failed' || taskStatus.state === 'aborted') {
            throw new Error(`Repository refresh ${taskStatus.state}`);
          }
        } catch (taskError) {
          console.warn('Failed to check task status:', taskError);
          // Continue polling even if status check fails
        }
        
        attempts++;
      }
      
      if (attempts >= maxAttempts) {
        // Timeout - still reload repositories as they might have been updated
        await loadRepositories(true);
      }
    } catch (err) {
      console.error('Error refreshing repositories:', err);
      repoLoadError = 'Failed to refresh repositories. Please try again.';
    } finally {
      isLoadingRepos = false;
    }
  }

  function selectRepository(repo: Repository): void {
    selectedRepository = repo;
    
    // Track repository selection
    analytics.track('getting_started_repository_selected', {
      path: 'repo',
      vcs_provider: currentProvider,
      repository: repo.name,
      repository_setup_status: repo.setup ? 'complete' : 'pending',
      installation: selectedInstallation?.name
    });
    
    markRepoStepComplete('select-repo');
  }

  // Automatically refresh repositories when installation is selected and we're on select-repo step
  // This ensures we get the latest repository list from GitHub, including recently installed repos
  $: if (selectedInstallation && currentRepoStep === 'select-repo') {
    refreshRepositories();
  }

  async function checkRepoAppInstallation(): Promise<void> {
    try {
      checkingAppInstallation = true;
      
      // Re-fetch installations to see if app was installed
      const installationsResponse = await api.getUserInstallations();
      const newInstallations = installationsResponse.installations;
      
      // If we already had installations, just proceed
      if (hasInstallations && installations.length > 0) {
        markRepoStepComplete('install-app');
      }
      // Check if we have more installations than before
      else if (newInstallations.length > installations.length) {
        installations = newInstallations;
        hasInstallations = true;
        markRepoStepComplete('install-app');
        
        // Set the first installation as selected if none selected
        if (!selectedInstallation && newInstallations.length > 0) {
          selectedInstallation = newInstallations[0];
          selectedInstallationId = newInstallations[0].id;
        }
      } else {
        // Show message that we didn't detect the installation
        alert('We didn\'t detect the GitHub App installation. Make sure you installed it and try again, or continue manually.');
      }
    } catch (error) {
      console.error('Failed to check app installation:', error);
      alert('Unable to check installation status. You can continue manually.');
    } finally {
      checkingAppInstallation = false;
    }
  }

  // GitLab wizard functions
  function markGitLabStepComplete(step: GitLabStep): void {
    if (step !== 'success') {
      gitlabStepCompleted[step] = true;
    }
    
    // Track step completion
    analytics.track('getting_started_step_completed', {
      path: 'repo',
      vcs_provider: 'gitlab',
      step: step,
      step_index: ['select-group', 'select-repo', 'add-bot', 'configure-webhook', 'push-test', 'configure-variables', 'add-pipeline'].indexOf(step) + 1,
      group: selectedGitLabGroup?.name,
      repository: manualGitLabProject
    });
    
    // Auto-advance to next step
    const steps: GitLabStep[] = ['select-group', 'select-repo', 'add-bot', 'configure-webhook', 'push-test', 'configure-variables', 'add-pipeline', 'success'];
    const currentIndex = steps.indexOf(currentGitLabStep);
    if (currentIndex < steps.length - 1) {
      currentGitLabStep = steps[currentIndex + 1];
    }
    
    // Track completion of entire flow
    if (currentGitLabStep === 'success') {
      const timeSpent = Math.round((Date.now() - startTime) / 1000);
      analytics.track('getting_started_completed', {
        path: 'repo',
        vcs_provider: 'gitlab',
        time_spent_seconds: timeSpent,
        group: selectedGitLabGroup?.name,
        repository: manualGitLabProject
      });
    }
    
    // Load webhook config when entering configure-webhook step
    if (currentGitLabStep === 'configure-webhook' && selectedGitLabGroup) {
      loadGitLabWebhookConfig();
    }
  }

  function goToGitLabStep(step: GitLabStep): void {
    currentGitLabStep = step;
  }

  // GitLab group and repository management
  async function loadGitLabSetupGroups(): Promise<void> {
    try {
      isLoadingGitLabSetupGroups = true;
      gitlabSetupGroupsError = null;
      gitlabGroups = await api.getGitLabGroups();
    } catch (error) {
      console.error('Failed to load GitLab groups:', error);
      gitlabSetupGroupsError = 'Failed to load groups. Please try again.';
    } finally {
      isLoadingGitLabSetupGroups = false;
    }
  }

  function selectGitLabGroup(group: GitLabGroup): void {
    selectedGitLabGroup = group;
    
    // Track group selection
    analytics.track('getting_started_gitlab_group_selected', {
      path: 'repo',
      vcs_provider: 'gitlab',
      group: group.name,
      group_type: group.kind
    });
    
    // Clear previously selected repo when group changes
    markGitLabStepComplete('select-group');
  }


  async function addGitLabProject(): Promise<void> {
    if (!manualGitLabProject.trim() || !selectedGitLabGroup) return;
    
    try {
      isAddingGitLabProject = true;
      
      // Construct the full repository path
      const repoName = manualGitLabProject.trim();
      const fullPath = `${selectedGitLabGroup.name}/${repoName}`;
      
      // Track repository addition
      analytics.track('getting_started_gitlab_repo_added', {
        path: 'repo',
        vcs_provider: 'gitlab',
        group: selectedGitLabGroup.name,
        repository: repoName,
        full_path: fullPath
      });
      
      // Create a temporary repository object
      // In a real implementation, this would call an API to register the project
      const newRepo: Repository = {
        id: `manual-${Date.now()}`, // Temporary ID
        name: fullPath, // Store the full path as the name
        installation_id: selectedGitLabGroup.id.toString(),
        setup: false, // Will be set to true once webhook events are received
        updated_at: new Date().toISOString()
      };
      
      // Add to the list if not already present
      const exists = gitlabRepos.some(r => r.name === newRepo.name);
      if (!exists) {
        gitlabRepos = [...gitlabRepos, newRepo];
        // Don't clear manualGitLabProject - we need it for the webhook URL
        // Auto-advance to the next step
        markGitLabStepComplete('select-repo');
      } else {
        // Repository already exists in the list
      }
    } catch (error) {
      console.error('Failed to add GitLab project:', error);
    } finally {
      isAddingGitLabProject = false;
    }
  }

  async function loadGitLabWebhookConfig(): Promise<void> {
    if (!selectedGitLabGroup) return;

    try {
      const config = await api.getGitLabWebhookConfig(selectedGitLabGroup.id.toString());
      webhookUrl = config.webhook_url;
      webhookSecret = config.webhook_secret || '';
    } catch (error) {
      console.error('Failed to load GitLab webhook config:', error);
      // Set defaults if API fails
      webhookUrl = 'https://api.terrateam.io/webhook/gitlab';
      webhookSecret = 'Contact support for webhook secret';
    }
  }

  async function loadGitLabBotUsername(): Promise<void> {
    try {
      const botInfo = await api.getGitLabBotInfo();
      gitlabBotUsername = botInfo.username;
    } catch (error) {
      console.error('Failed to load GitLab bot username:', error);
      // Fallback to default if API fails
      gitlabBotUsername = 'terrateam-bot';
    }
  }

  async function verifyBotAdded(): Promise<void> {
    if (!selectedGitLabGroup) return;
    
    try {
      checkingGitLabBot = true;
      gitlabBotError = null;
      
      // Track bot verification attempt
      analytics.track('getting_started_gitlab_bot_check', {
        path: 'repo',
        vcs_provider: 'gitlab',
        group: selectedGitLabGroup.name
      });
      
      // Check if the bot has been added to the group
      const isMember = await api.checkGitLabGroupMembership(selectedGitLabGroup.id);
      
      if (isMember) {
        // Track successful bot addition
        analytics.track('getting_started_gitlab_bot_added', {
          path: 'repo',
          vcs_provider: 'gitlab',
          group: selectedGitLabGroup.name
        });
        
        // Bot is verified, proceed to next step
        markGitLabStepComplete('add-bot');
      } else {
        gitlabBotError = `The Terrateam bot (@${gitlabBotUsername || 'terrateam-bot'}) has not been added to the group yet. Please add the bot as a Developer first.`;
      }
    } catch (error) {
      console.error('Failed to verify bot membership:', error);
      gitlabBotError = 'Failed to verify bot status. Please try again.';
    } finally {
      checkingGitLabBot = false;
    }
  }

  async function checkPushTestStatus(): Promise<void> {
    if (!selectedGitLabGroup || !manualGitLabProject) return;
    
    try {
      isCheckingPushTest = true;
      pushTestError = null;

      // First check if webhook is active
      const webhookConfig = await api.getGitLabWebhookConfig(selectedGitLabGroup.id.toString());
      
      if (webhookConfig.state !== 'active') {
        pushTestError = 'Webhook configuration not active. Please ensure the webhook is properly configured.';
        return;
      }
      
      // Clear repository cache and load fresh data
      repositoryService.clearCache(selectedGitLabGroup.id.toString());
      
      // Create a fake installation object for the repository service
      const installation: Installation = {
        id: selectedGitLabGroup.id.toString(),
        name: selectedGitLabGroup.name,
        account_status: 'active',
        tier: {
          name: 'free',
          features: {}
        }
      };
      
      // Load repositories from API
      const result = await repositoryService.loadRepositories(installation, true);
      
      // Use the manual project name for the regular GitLab flow
      const repoName = manualGitLabProject.trim();
      
      // Check if the repository exists in the list
      const repoExists = result.repositories.some(repo => 
        repo.name.toLowerCase() === repoName.toLowerCase()
      );
      
      if (repoExists) {
        pushTestSuccess = true;
        // Auto-advance after a short delay to show success message
        setTimeout(() => {
          markGitLabStepComplete('push-test');
        }, 2000);
      } else {
        pushTestError = `Repository "${repoName}" not found in Terrateam. Please ensure you've completed the webhook test in GitLab.`;
      }
    } catch (error) {
      console.error('Failed to check push test status:', error);
      pushTestError = 'Failed to check status. Please try again.';
    } finally {
      isCheckingPushTest = false;
    }
  }

  async function checkDemoPushTestStatus(): Promise<void> {
    if (!selectedGitLabDemoGroup || !forkedProjectPath) return;
    
    try {
      isDemoCheckingPushTest = true;
      demoPushTestError = null;

      // First check if webhook is active
      const webhookConfig = await api.getGitLabWebhookConfig(selectedGitLabDemoGroup.id.toString());
      
      if (webhookConfig.state !== 'active') {
        demoPushTestError = 'Webhook configuration not active. Please ensure the webhook is properly configured.';
        return;
      }
      
      // Clear repository cache and load fresh data
      repositoryService.clearCache(selectedGitLabDemoGroup.id.toString());
      
      // Create a fake installation object for the repository service
      const installation: Installation = {
        id: selectedGitLabDemoGroup.id.toString(),
        name: selectedGitLabDemoGroup.name,
        account_status: 'active',
        tier: {
          name: 'free',
          features: {}
        }
      };
      
      // Load repositories from API
      const result = await repositoryService.loadRepositories(installation, true);
      
      // Extract the repository name from the forked path (e.g., "groupname/kick-the-tires" -> "kick-the-tires")
      const repoName = forkedProjectPath.split('/').pop() || '';
      
      // Check if the repository exists in the list
      const repoExists = result.repositories.some(repo => 
        repo.name.toLowerCase() === repoName.toLowerCase()
      );
      
      if (repoExists) {
        demoPushTestSuccess = true;
        // Auto-advance after a short delay to show success message
        setTimeout(() => {
          markGitLabDemoStepComplete('push-test');
        }, 2000);
      } else {
        demoPushTestError = `Repository "${repoName}" not found in Terrateam. Please ensure you've completed the webhook test in GitLab.`;
      }
    } catch (error) {
      console.error('Failed to check demo push test status:', error);
      demoPushTestError = 'Failed to check status. Please try again.';
    } finally {
      isDemoCheckingPushTest = false;
    }
  }

  // Load GitLab groups when entering the GitLab setup flow
  $: if (currentStep === 'gitlab-setup' && currentGitLabStep === 'select-group') {
    loadGitLabSetupGroups();
  }
  
  async function verifyWebhook(): Promise<void> {
    if (!selectedGitLabGroup) return;
    
    try {
      checkingWebhook = true;
      webhookVerificationError = null;
      
      const config = await api.getGitLabWebhookConfig(selectedGitLabGroup.id.toString());
      const isActive = config.state === 'active';
      
      if (isActive) {
        webhookVerificationError = null;
        markGitLabStepComplete('configure-webhook');
      } else {
        webhookVerificationError = 'Webhook is not active yet. Please test it with a Push Event in GitLab.';
      }
    } catch (error) {
      console.error('Failed to check webhook:', error);
      webhookVerificationError = 'Unable to verify webhook. Please ensure you\'ve added it and tested with a Push Event.';
    } finally {
      checkingWebhook = false;
    }
  }

</script>

<PageLayout activeItem="getting-started" title="Getting Started">
  <div class="max-w-4xl mx-auto px-4 py-8">
    
    <!-- Progress Bar -->
    <div class="mb-8">
      <div class="flex items-center justify-between mb-2">
        <span class="text-sm font-medium text-gray-900 dark:text-gray-100">Setup Progress</span>
        <span class="text-sm text-gray-500 dark:text-gray-400">
          {#if currentStep === 'assessment'}
            Analyzing your setup...
          {:else if currentStep === 'path-selection'}
            Choose your path
          {:else if currentStep === 'github-demo-setup'}
            GitHub demo setup
          {:else if currentStep === 'gitlab-demo-setup'}
            GitLab demo setup
          {:else if currentStep === 'github-repo-setup'}
            GitHub repository setup
          {:else if currentStep === 'gitlab-setup'}
            GitLab setup
          {:else if currentStep === 'validation'}
            Validating setup
          {:else}
            Complete!
          {/if}
        </span>
      </div>
      <div class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
        <div 
          class="bg-blue-600 h-2 rounded-full transition-all duration-300 {
            currentStep === 'assessment' ? 'w-[10%]' :
            currentStep === 'path-selection' ? 'w-1/4' :
            currentStep === 'github-demo-setup' || currentStep === 'gitlab-demo-setup' || currentStep === 'github-repo-setup' || currentStep === 'gitlab-setup' ? 'w-[60%]' :
            currentStep === 'validation' ? 'w-4/5' :
            'w-full'
          }"
        ></div>
      </div>
    </div>

    <!-- Header -->
    <div class="text-center mb-8">
      <img src="/assets/images/logo-symbol.svg" alt="Terrateam" class="w-12 h-12 mx-auto mb-4" />
      <h1 class="text-3xl font-bold mb-2 text-blue-600 dark:text-blue-400">Getting Started with Terrateam</h1>
      <p class="text-gray-600 dark:text-gray-400">We'll help you set up Terraform automation in minutes</p>
    </div>

    <!-- Wizard Content -->
    <div class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6">
      
      {#if currentStep === 'assessment'}
        <!-- Assessment Step -->
        <div class="text-center py-12">
          <div class="inline-flex items-center justify-center w-16 h-16 bg-blue-100 dark:bg-blue-900/30 rounded-full mb-6">
            <Icon icon="mdi:magnify" class="text-blue-600 dark:text-blue-400" width="32" />
          </div>
          <h2 class="text-xl font-semibold text-gray-900 dark:text-gray-100 mb-2">Analyzing Your Setup</h2>
          <p class="text-gray-600 dark:text-gray-400 mb-6">We're checking your current Terrateam configuration...</p>
          
          {#if isLoadingAssessment}
            <div class="flex items-center justify-center">
              <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
            </div>
          {:else if assessmentError}
            <div class="bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg p-4">
              <p class="text-yellow-800 dark:text-yellow-200 text-sm">{assessmentError}</p>
            </div>
          {/if}
        </div>

      {:else if currentStep === 'path-selection'}
        <!-- Path Selection Step -->
        {#if showGitLabSetup && currentProvider === 'gitlab'}
          <!-- GitLab Setup Wizard -->
          <GitLabSetup 
            onComplete={handleGitLabSetupComplete}
            onCancel={handleGitLabSetupCancel}
          />
        {:else}
          <div class="mb-6">
            <h2 class="text-xl font-semibold text-gray-900 dark:text-gray-100 mb-2">Choose Your Setup Path</h2>
            
            <!-- Assessment Results -->
            {#if !assessmentError}
              <div class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-4 mb-6">
                <h3 class="font-medium text-blue-900 dark:text-blue-100 mb-2">What we found:</h3>
                <div class="space-y-1 text-sm text-blue-800 dark:text-blue-200">
                  <div class="flex items-center">
                    <Icon icon={hasInstallations ? "mdi:check" : "mdi:close"} 
                                  class={hasInstallations ? "text-green-600" : "text-gray-400"} 
                                  width="16" />
                    <span class="ml-2">
                      {hasInstallations ? `Found ${installations.length} ${VCS_PROVIDERS[currentProvider].displayName} installation${installations.length > 1 ? 's' : ''}` : `No ${VCS_PROVIDERS[currentProvider].displayName} installations found`}
                    </span>
                  </div>
                  <div class="flex items-center">
                    <Icon icon={hasConfiguredRepos ? "mdi:check" : "mdi:close"} 
                                  class={hasConfiguredRepos ? "text-green-600" : "text-gray-400"} 
                                  width="16" />
                    <span class="ml-2">
                      {hasConfiguredRepos ? 'Found configured repositories' : 'No configured repositories found'}
                    </span>
                  </div>
                </div>
                
                {#if recommendedPath === 'demo'}
                  <p class="mt-3 text-sm font-medium text-blue-900 dark:text-blue-100 flex items-center">
                    <Icon icon="mdi:lightbulb" class="text-yellow-500 mr-2" width="16" />
                  We recommend starting with the demo to learn how Terrateam works
                </p>
              {:else}
                <p class="mt-3 text-sm font-medium text-blue-900 dark:text-blue-100 flex items-center">
                  <Icon icon="mdi:lightbulb" class="text-yellow-500 mr-2" width="16" />
                  We recommend setting up your existing repository
                </p>
              {/if}
            </div>
          {/if}
        </div>

        <!-- Path Options -->
        <div class="grid md:grid-cols-2 gap-6">
          <!-- Demo Path -->
          <button
            on:click={() => selectPath('demo')}
            class="text-left p-6 border-2 border-gray-200 dark:border-gray-600 rounded-lg hover:border-blue-500 dark:hover:border-blue-400 transition-colors {recommendedPath === 'demo' ? 'ring-2 ring-blue-500 border-blue-500' : ''}"
          >
            <div class="flex items-center justify-between mb-4">
              <div class="flex items-center justify-center w-10 h-10 bg-green-100 dark:bg-green-900/30 rounded-lg">
                <Icon icon="mdi:flash" class="text-green-600 dark:text-green-400" width="20" />
              </div>
              {#if recommendedPath === 'demo'}
                <span class="bg-blue-100 dark:bg-blue-900/30 text-blue-800 dark:text-blue-200 text-xs px-2 py-1 rounded-full font-medium">Recommended</span>
              {/if}
            </div>
            
            <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-2">Try the Demo</h3>
            <p class="text-gray-600 dark:text-gray-400 text-sm mb-4">
              Learn Terrateam with a safe sandbox environment. No cloud credentials needed.
            </p>
            
            <div class="space-y-2">
              <div class="flex items-center text-sm text-gray-600 dark:text-gray-400">
                <Icon icon="mdi:check" class="text-green-500 mr-2" width="16" />
                No cloud setup required
              </div>
              <div class="flex items-center text-sm text-gray-600 dark:text-gray-400">
                <Icon icon="mdi:check" class="text-green-500 mr-2" width="16" />
                See Terraform plans instantly
              </div>
              <div class="flex items-center text-sm text-gray-600 dark:text-gray-400">
                <Icon icon="mdi:check" class="text-green-500 mr-2" width="16" />
                2-3 minutes to complete
              </div>
            </div>
          </button>

          <!-- Repository Path -->
          <button
            on:click={() => selectPath('repo')}
            class="text-left p-6 border-2 border-gray-200 dark:border-gray-600 rounded-lg hover:border-blue-500 dark:hover:border-blue-400 transition-colors {recommendedPath === 'repo' ? 'ring-2 ring-blue-500 border-blue-500' : ''}"
          >
            <div class="flex items-center justify-between mb-4">
              <div class="flex items-center justify-center w-10 h-10 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                <Icon icon="mdi:source-repository" class="text-blue-600 dark:text-blue-400" width="20" />
              </div>
              {#if recommendedPath === 'repo'}
                <span class="bg-blue-100 dark:bg-blue-900/30 text-blue-800 dark:text-blue-200 text-xs px-2 py-1 rounded-full font-medium">Recommended</span>
              {/if}
            </div>
            
            <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-2">Connect Your Repository</h3>
            <p class="text-gray-600 dark:text-gray-400 text-sm mb-4">
              Set up Terrateam with your existing Terraform code and real infrastructure.
            </p>
            
            <div class="space-y-2">
              <div class="flex items-center text-sm text-gray-600 dark:text-gray-400">
                <Icon icon="mdi:check" class="text-green-500 mr-2" width="16" />
                Works with existing repos
              </div>
              <div class="flex items-center text-sm text-gray-600 dark:text-gray-400">
                <Icon icon="mdi:check" class="text-green-500 mr-2" width="16" />
                Real infrastructure automation
              </div>
              <div class="flex items-center text-sm text-gray-600 dark:text-gray-400">
                <Icon icon="mdi:check" class="text-green-500 mr-2" width="16" />
                5-10 minutes to complete
              </div>
            </div>
          </button>
        </div>
        {/if}

      {:else if currentStep === 'github-demo-setup'}
        <!-- GitHub Demo Setup Wizard -->
        <div class="mb-6">
          <div class="flex items-center justify-between mb-6">
            <h2 class="text-xl font-semibold text-gray-900 dark:text-gray-100">GitHub Demo Setup</h2>
            <button
              on:click={goBack}
              class="text-sm text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-200 flex items-center"
            >
              <Icon icon="mdi:arrow-left" class="mr-1" width="16" />
              Back
            </button>
          </div>

          <!-- Demo Steps Progress -->
          <div class="mb-8">
            <div class="flex items-center justify-between mb-4">
              {#each (currentProvider === 'gitlab' ? [
                {step: 'fork', index: 0, label: '1'},
                {step: 'enable-pipelines', index: 1, label: '2'},
                {step: 'add-bot', index: 2, label: '3'},
                {step: 'make-changes', index: 3, label: '4'},
                {step: 'success', index: 4, label: '5'}
              ] : [
                {step: 'install-app', index: 0, label: '1'},
                {step: 'fork', index: 1, label: '2'},
                {step: 'enable-actions', index: 2, label: '3'},
                {step: 'make-changes', index: 3, label: '4'},
                {step: 'success', index: 4, label: '5'}
              ]) as stepInfo}
                <div class="flex items-center {stepInfo.index < 4 ? 'flex-1' : ''}">
                  <div class="flex items-center justify-center w-8 h-8 rounded-full text-sm font-medium
                              {currentDemoStep === stepInfo.step ? 'bg-blue-600 text-white' : 
                               (stepInfo.step === 'fork' && demoStepCompleted.fork) ||
                               (stepInfo.step === 'enable-actions' && demoStepCompleted['enable-actions']) ||
                               (stepInfo.step === 'install-app' && demoStepCompleted['install-app']) ||
                               (stepInfo.step === 'make-changes' && demoStepCompleted['make-changes'])
                               ? 'bg-green-600 text-white' : 
                               'bg-gray-200 dark:bg-gray-600 text-gray-600 dark:text-gray-400'}">
                    {#if (stepInfo.step === 'fork' && demoStepCompleted.fork) ||
                         (stepInfo.step === 'enable-actions' && demoStepCompleted['enable-actions']) ||
                         (stepInfo.step === 'install-app' && demoStepCompleted['install-app']) ||
                         (stepInfo.step === 'make-changes' && demoStepCompleted['make-changes'])}
                      <Icon icon="mdi:check" class="text-white" width="16" />
                    {:else}
                      {stepInfo.label}
                    {/if}
                  </div>
                  {#if stepInfo.index < 4}
                    <div class="flex-1 h-1 mx-2 {
                      (stepInfo.step === 'fork' && demoStepCompleted.fork) ||
                      (stepInfo.step === 'enable-actions' && demoStepCompleted['enable-actions']) ||
                      (stepInfo.step === 'install-app' && demoStepCompleted['install-app']) ||
                      (stepInfo.step === 'make-changes' && demoStepCompleted['make-changes'])
                      ? 'bg-green-600' : 'bg-gray-200 dark:bg-gray-600'}"></div>
                  {/if}
                </div>
              {/each}
            </div>
            <div class="text-center text-sm text-gray-500 dark:text-gray-400">
              Step {['install-app', 'fork', 'enable-actions', 'make-changes', 'success'].indexOf(currentDemoStep) + 1} of 5
            </div>
          </div>

          <!-- Step Content -->
          {#if currentDemoStep === 'install-app'}
            <div class="bg-green-50 dark:bg-green-900/20 rounded-lg p-6">
              <div class="flex items-start">
                <div class="flex-shrink-0">
                  <div class="w-10 h-10 bg-green-600 rounded-lg flex items-center justify-center">
                    <Icon icon="mdi:download" class="text-white" width="20" />
                  </div>
                </div>
                <div class="ml-4 flex-1">
                  <h3 class="text-lg font-semibold text-green-900 dark:text-green-100 mb-2">Step 1: Install Terrateam GitHub App</h3>
                  <p class="text-green-800 dark:text-green-200 mb-4">
                    Install the Terrateam GitHub App on your organization to enable Terraform automation.
                  </p>
                  
                  {#if hasInstallations}
                    <div class="bg-green-100 dark:bg-green-900/30 rounded-lg p-4 mb-4 border border-green-200 dark:border-green-700">
                      <div class="flex items-center">
                        <Icon icon="mdi:check-circle" class="text-green-600 mr-2" width="20" />
                        <span class="text-green-800 dark:text-green-200 font-medium">
                          Great! We detected {installations.length} GitHub installation{installations.length > 1 ? 's' : ''}.
                        </span>
                      </div>
                    </div>
                  {:else}
                    <div class="bg-white dark:bg-gray-800 rounded-lg p-4 mb-4 border border-green-200 dark:border-green-700">
                      <div class="flex items-center justify-between">
                        <div>
                          <div class="font-medium text-gray-900 dark:text-gray-100">Terrateam GitHub App</div>
                          <div class="text-sm text-gray-600 dark:text-gray-400">Enables Terraform automation in your repositories</div>
                        </div>
                        <Icon icon="mdi:github" class="text-gray-400" width="24" />
                      </div>
                    </div>
                  {/if}

                  <div class="bg-blue-50 dark:bg-blue-900/30 rounded-lg p-4 mb-4 border border-blue-200 dark:border-blue-700">
                    <div class="flex items-start">
                      <Icon icon="mdi:information" class="text-blue-600 dark:text-blue-400 mr-2 mt-0.5" width="20" />
                      <div class="text-sm text-blue-800 dark:text-blue-200">
                        <p class="font-medium mb-1">Demo in a different organization?</p>
                        <p>You can install the app on any organization where you want to run the demo.</p>
                      </div>
                    </div>
                  </div>

                  <div class="flex items-center space-x-3">
                    <button
                      on:click={() => openExternalLink(githubAppUrl, 'github_app_install')}
                      class="bg-green-600 hover:bg-green-700 text-white px-4 py-2 rounded-lg text-sm font-medium flex items-center"
                    >
                      <Icon icon="mdi:download" class="mr-2" width="16" />
                      Install GitHub App
                    </button>
                    <button
                      on:click={checkAppInstallation}
                      disabled={checkingAppInstallation}
                      class="border border-green-600 text-green-600 dark:text-green-400 px-4 py-2 rounded-lg text-sm font-medium hover:bg-green-50 dark:hover:bg-green-900/30 disabled:opacity-50"
                    >
                      {#if checkingAppInstallation}
                        <Icon icon="mdi:loading" class="animate-spin mr-2" width="16" />
                        Checking...
                      {:else if hasInstallations}
                        Continue
                      {:else}
                        Check Installation
                      {/if}
                    </button>
                  </div>
                </div>
              </div>
            </div>

          {:else if currentDemoStep === 'fork'}
            <div class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-6">
              <div class="flex items-start">
                <div class="flex-shrink-0">
                  <div class="w-10 h-10 bg-blue-600 rounded-lg flex items-center justify-center">
                    <Icon icon="mdi:source-fork" class="text-white" width="20" />
                  </div>
                </div>
                <div class="ml-4 flex-1">
                  <h3 class="text-lg font-semibold text-blue-900 dark:text-blue-100 mb-2">Step 2: Fork the Demo Repository</h3>
                  <p class="text-blue-800 dark:text-blue-200 mb-4">
                    Fork our demo repository to your GitHub account. This gives you your own copy to experiment with.
                  </p>
                  
                  <div class="bg-white dark:bg-gray-800 rounded-lg p-4 mb-4 border border-blue-200 dark:border-blue-700">
                    <div class="flex items-center justify-between">
                      <div>
                        <div class="font-medium text-gray-900 dark:text-gray-100">terrateam-demo/kick-the-tires</div>
                        <div class="text-sm text-gray-600 dark:text-gray-400">Safe demo repository with null resources</div>
                      </div>
                      <Icon icon="mdi:github" class="text-gray-400" width="24" />
                    </div>
                  </div>

                  <div class="flex items-center space-x-3">
                    <button
                      on:click={() => {
                        const repoUrl = currentProvider === 'gitlab' 
                          ? 'https://gitlab.com/terrateam-demo/kick-the-tires'
                          : 'https://github.com/terrateam-demo/kick-the-tires';
                        openExternalLink(repoUrl);
                      }}
                      class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg text-sm font-medium flex items-center"
                    >
                      <Icon icon="mdi:source-fork" class="mr-2" width="16" />
                      Fork {terminology.repository}
                    </button>
                    <button
                      on:click={() => markDemoStepComplete('fork')}
                      class="border border-blue-600 text-blue-600 dark:text-blue-400 px-4 py-2 rounded-lg text-sm font-medium hover:bg-blue-50 dark:hover:bg-blue-900/30"
                    >
                      I've forked it
                    </button>
                    <button
                      on:click={() => goToDemoStep('install-app')}
                      class="border border-gray-300 text-gray-600 dark:text-gray-400 px-4 py-2 rounded-lg text-sm font-medium hover:bg-gray-50 dark:hover:bg-gray-700"
                    >
                      Go Back
                    </button>
                  </div>
                </div>
              </div>
            </div>

          {:else if currentDemoStep === 'enable-actions'}
            <div class="bg-orange-50 dark:bg-orange-900/20 rounded-lg p-6">
              <div class="flex items-start">
                <div class="flex-shrink-0">
                  <div class="w-10 h-10 bg-orange-600 rounded-lg flex items-center justify-center">
                    <Icon icon="mdi:play-circle" class="text-white" width="20" />
                  </div>
                </div>
                <div class="ml-4 flex-1">
                  <h3 class="text-lg font-semibold text-orange-900 dark:text-orange-100 mb-2">Step 3: Enable GitHub Actions</h3>
                  <p class="text-orange-800 dark:text-orange-200 mb-4">
                    Forked repositories disable workflows by default for security. Let's enable them.
                  </p>
                  
                  <div class="bg-white dark:bg-gray-800 rounded-lg p-4 mb-4 border border-orange-200 dark:border-orange-700">
                    <div class="space-y-2 text-sm">
                      <div class="flex items-center">
                        <Icon icon="mdi:numeric-1-circle" class="text-orange-600 mr-2" width="16" />
                        <span class="text-gray-700 dark:text-gray-300">Go to your forked repository</span>
                      </div>
                      <div class="flex items-center">
                        <Icon icon="mdi:numeric-2-circle" class="text-orange-600 mr-2" width="16" />
                        <span class="text-gray-700 dark:text-gray-300">Click the <strong>Actions</strong> tab</span>
                      </div>
                      <div class="flex items-center">
                        <Icon icon="mdi:numeric-3-circle" class="text-orange-600 mr-2" width="16" />
                        <span class="text-gray-700 dark:text-gray-300">Click <strong>"I understand my workflows, go ahead and enable them"</strong></span>
                      </div>
                    </div>
                  </div>

                  <div class="flex items-center space-x-3">
                    <button
                      on:click={() => markDemoStepComplete('enable-actions')}
                      class="bg-orange-600 hover:bg-orange-700 text-white px-4 py-2 rounded-lg text-sm font-medium"
                    >
                      Actions Enabled
                    </button>
                    <button
                      on:click={() => goToDemoStep('fork')}
                      class="border border-gray-300 text-gray-600 dark:text-gray-400 px-4 py-2 rounded-lg text-sm font-medium hover:bg-gray-50 dark:hover:bg-gray-700"
                    >
                      Go Back
                    </button>
                  </div>
                </div>
              </div>
            </div>

          {:else if currentDemoStep === 'make-changes'}
            <div class="bg-purple-50 dark:bg-purple-900/20 rounded-lg p-6">
              <div class="flex items-start">
                <div class="flex-shrink-0">
                  <div class="w-10 h-10 bg-purple-600 rounded-lg flex items-center justify-center">
                    <Icon icon="mdi:file-edit" class="text-white" width="20" />
                  </div>
                </div>
                <div class="ml-4 flex-1">
                  <h3 class="text-lg font-semibold text-purple-900 dark:text-purple-100 mb-2">Step 4: Make Your First Change</h3>
                  <p class="text-purple-800 dark:text-purple-200 mb-4">
                    Now let's make a change to see Terrateam in action! We'll edit a file and create a pull request.
                  </p>
                  
                  <div class="bg-white dark:bg-gray-800 rounded-lg p-4 mb-4 border border-purple-200 dark:border-purple-700">
                    <div class="space-y-3 text-sm">
                      <div class="flex items-start">
                        <Icon icon="mdi:numeric-1-circle" class="text-purple-600 mr-2 mt-0.5" width="16" />
                        <div>
                          <div class="text-gray-700 dark:text-gray-300">Edit <code class="bg-gray-100 dark:bg-gray-700 px-1 rounded">dev/main.tf</code></div>
                          <div class="text-gray-500 dark:text-gray-400 text-xs">Change <code>null_resource_count = 0</code> to <code>null_resource_count = 1</code></div>
                        </div>
                      </div>
                      <div class="flex items-center">
                        <Icon icon="mdi:numeric-2-circle" class="text-purple-600 mr-2" width="16" />
                        <span class="text-gray-700 dark:text-gray-300">Create a new branch and push your changes</span>
                      </div>
                      <div class="flex items-center">
                        <Icon icon="mdi:numeric-3-circle" class="text-purple-600 mr-2" width="16" />
                        <span class="text-gray-700 dark:text-gray-300">Open a pull request</span>
                      </div>
                      <div class="flex items-center">
                        <Icon icon="mdi:numeric-4-circle" class="text-purple-600 mr-2" width="16" />
                        <span class="text-gray-700 dark:text-gray-300">Watch Terrateam automatically comment with the plan!</span>
                      </div>
                    </div>
                  </div>

                  <div class="bg-blue-50 dark:bg-blue-900/30 rounded p-3 mb-4">
                    <div class="flex items-start">
                      <Icon icon="mdi:lightbulb" class="text-blue-600 mr-2 mt-0.5" width="16" />
                      <div class="text-sm text-blue-800 dark:text-blue-200">
                        <strong>Pro tip:</strong> When you're ready to apply the changes, comment <code class="bg-blue-100 dark:bg-blue-800 px-1 rounded">terrateam apply</code> on your PR.
                      </div>
                    </div>
                  </div>

                  <div class="flex items-center space-x-3">
                    <button
                      on:click={() => markDemoStepComplete('make-changes')}
                      class="bg-purple-600 hover:bg-purple-700 text-white px-4 py-2 rounded-lg text-sm font-medium"
                    >
                      I've created a PR
                    </button>
                    <button
                      on:click={() => goToDemoStep('enable-actions')}
                      class="border border-gray-300 text-gray-600 dark:text-gray-400 px-4 py-2 rounded-lg text-sm font-medium hover:bg-gray-50 dark:hover:bg-gray-700"
                    >
                      Go Back
                    </button>
                  </div>
                </div>
              </div>
            </div>

          {:else if currentDemoStep === 'success'}
            <div class="text-center py-12">
              <div class="inline-flex items-center justify-center w-16 h-16 bg-green-100 dark:bg-green-900/30 rounded-full mb-6">
                <Icon icon="mdi:check-circle" class="text-green-600 dark:text-green-400" width="32" />
              </div>
              <h3 class="text-2xl font-semibold text-gray-900 dark:text-gray-100 mb-2 flex items-center justify-center">
                <Icon icon="mdi:party-popper" class="text-purple-600 dark:text-purple-400 mr-2" width="28" />
                Demo Complete!
              </h3>
              <p class="text-gray-600 dark:text-gray-400 mb-6">
                You've successfully set up the Terrateam demo and seen how Terraform automation works with pull requests.
              </p>
              
              <div class="bg-green-50 dark:bg-green-900/20 rounded-lg p-6 mb-6 max-w-md mx-auto">
                <h4 class="font-semibold text-green-900 dark:text-green-100 mb-3">What you've learned:</h4>
                <div class="space-y-2 text-sm text-green-800 dark:text-green-200">
                  <div class="flex items-center">
                    <Icon icon="mdi:check" class="text-green-600 mr-2" width="16" />
                    How to set up Terrateam with GitHub
                  </div>
                  <div class="flex items-center">
                    <Icon icon="mdi:check" class="text-green-600 mr-2" width="16" />
                    Automatic Terraform plans on PRs
                  </div>
                  <div class="flex items-center">
                    <Icon icon="mdi:check" class="text-green-600 mr-2" width="16" />
                    How to apply changes with commands
                  </div>
                </div>
              </div>

              <div class="flex justify-center space-x-4">
                <button
                  on:click={() => {currentStep = 'path-selection'; selectedPath = null; currentDemoStep = 'install-app';}}
                  class="border border-gray-300 text-gray-600 dark:text-gray-400 px-6 py-2 rounded-lg text-sm font-medium hover:bg-gray-50 dark:hover:bg-gray-700"
                >
                  Start Over
                </button>
                <button
                  on:click={() => selectPath('repo')}
                  class="bg-blue-600 hover:bg-blue-700 text-white px-6 py-2 rounded-lg text-sm font-medium"
                >
                  Set Up My Repository
                </button>
              </div>
            </div>
          {/if}
        </div>

      {:else if currentStep === 'gitlab-demo-setup'}
        <!-- GitLab Demo Setup Wizard -->
        <div class="mb-6">
          <div class="flex items-center justify-between mb-6">
            <h2 class="text-xl font-semibold text-gray-900 dark:text-gray-100">GitLab Demo Setup</h2>
            <button
              on:click={goBack}
              class="text-sm text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-200 flex items-center"
            >
              <Icon icon="mdi:arrow-left" class="mr-1" width="16" />
              Back
            </button>
          </div>

          <!-- GitLab Demo Steps Progress -->
          <div class="mb-8">
            <div class="flex items-center justify-between mb-4">
              {#each [
                {step: 'select-group', index: 0, label: '1'},
                {step: 'fork', index: 1, label: '2'},
                {step: 'add-bot', index: 2, label: '3'},
                {step: 'configure-webhook', index: 3, label: '4'},
                {step: 'push-test', index: 4, label: '5'},
                {step: 'configure-variables', index: 5, label: '6'},
                {step: 'make-changes', index: 6, label: '7'},
                {step: 'success', index: 7, label: '8'}
              ] as stepInfo}
                <div class="flex items-center {stepInfo.index < 7 ? 'flex-1' : ''}">
                  <div class="flex items-center justify-center w-8 h-8 rounded-full text-sm font-medium
                              {currentGitLabDemoStep === stepInfo.step ? 'bg-blue-600 text-white' : 
                               (stepInfo.step === 'select-group' && gitlabDemoStepCompleted['select-group']) ||
                               (stepInfo.step === 'fork' && gitlabDemoStepCompleted.fork) ||
                               (stepInfo.step === 'add-bot' && gitlabDemoStepCompleted['add-bot']) ||
                               (stepInfo.step === 'configure-webhook' && gitlabDemoStepCompleted['configure-webhook']) ||
                               (stepInfo.step === 'push-test' && gitlabDemoStepCompleted['push-test']) ||
                               (stepInfo.step === 'configure-variables' && gitlabDemoStepCompleted['configure-variables']) ||
                               (stepInfo.step === 'make-changes' && gitlabDemoStepCompleted['make-changes'])
                               ? 'bg-green-600 text-white' : 
                               'bg-gray-200 dark:bg-gray-600 text-gray-600 dark:text-gray-400'}">
                    {#if (stepInfo.step === 'select-group' && gitlabDemoStepCompleted['select-group']) ||
                         (stepInfo.step === 'fork' && gitlabDemoStepCompleted.fork) ||
                         (stepInfo.step === 'add-bot' && gitlabDemoStepCompleted['add-bot']) ||
                         (stepInfo.step === 'configure-webhook' && gitlabDemoStepCompleted['configure-webhook']) ||
                         (stepInfo.step === 'push-test' && gitlabDemoStepCompleted['push-test']) ||
                         (stepInfo.step === 'configure-variables' && gitlabDemoStepCompleted['configure-variables']) ||
                         (stepInfo.step === 'make-changes' && gitlabDemoStepCompleted['make-changes'])}
                      <Icon icon="mdi:check" width="16" />
                    {:else}
                      {stepInfo.label}
                    {/if}
                  </div>
                  {#if stepInfo.index < 7}
                    <div class="flex-1 h-0.5 mx-2 {
                      (stepInfo.step === 'select-group' && (gitlabDemoStepCompleted.fork || ['fork', 'add-bot', 'configure-webhook', 'push-test', 'configure-variables', 'make-changes'].includes(currentGitLabDemoStep))) ||
                      (stepInfo.step === 'fork' && (gitlabDemoStepCompleted['add-bot'] || ['add-bot', 'configure-webhook', 'push-test', 'configure-variables', 'make-changes'].includes(currentGitLabDemoStep))) ||
                      (stepInfo.step === 'add-bot' && (gitlabDemoStepCompleted['configure-webhook'] || ['configure-webhook', 'push-test', 'configure-variables', 'make-changes'].includes(currentGitLabDemoStep))) ||
                      (stepInfo.step === 'configure-webhook' && (gitlabDemoStepCompleted['push-test'] || ['push-test', 'configure-variables', 'make-changes'].includes(currentGitLabDemoStep))) ||
                      (stepInfo.step === 'push-test' && (gitlabDemoStepCompleted['configure-variables'] || ['configure-variables', 'make-changes'].includes(currentGitLabDemoStep))) ||
                      (stepInfo.step === 'configure-variables' && (gitlabDemoStepCompleted['make-changes'] || currentGitLabDemoStep === 'make-changes'))
                      ? 'bg-green-500' : 'bg-gray-200 dark:bg-gray-600'
                    }"></div>
                  {/if}
                </div>
              {/each}
            </div>
            <div class="text-center text-sm text-gray-500 dark:text-gray-400">
              Step {['select-group', 'fork', 'add-bot', 'configure-webhook', 'push-test', 'configure-variables', 'make-changes', 'success'].indexOf(currentGitLabDemoStep) + 1} of 8
            </div>
          </div>

          <!-- GitLab Demo Step Content -->
          {#if currentGitLabDemoStep === 'select-group'}
            <div class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-6">
              <div class="mb-4">
                <h3 class="text-lg font-semibold text-blue-900 dark:text-blue-100 mb-2">
                  Select a GitLab Group
                </h3>
                <p class="text-blue-800 dark:text-blue-200">
                  Choose which GitLab group you'll use for the demo. You'll fork the demo project into this group.
                </p>
              </div>

              {#if isLoadingGitLabGroups}
                <div class="flex justify-center py-8">
                  <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
                </div>
              {:else if gitlabGroupsError}
                <div class="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4 mb-4">
                  <p class="text-red-800 dark:text-red-200 text-sm">{gitlabGroupsError}</p>
                </div>
                <button 
                  on:click={loadGitLabGroups}
                  class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg text-sm font-medium"
                >
                  Try Again
                </button>
              {:else if gitlabDemoGroups.length === 0}
                <div class="bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg p-4">
                  <div class="flex items-start">
                    <Icon icon="mdi:alert" class="text-yellow-600 dark:text-yellow-400 mr-2 mt-0.5" width="20" />
                    <div>
                      <p class="text-yellow-800 dark:text-yellow-200 text-sm font-medium mb-1">
                        No GitLab groups found
                      </p>
                      <p class="text-yellow-700 dark:text-yellow-300 text-xs">
                        Terrateam requires a GitLab group to operate. Personal namespaces are not supported.
                        Please create a group or ask to be added to an existing group first.
                      </p>
                    </div>
                  </div>
                </div>
              {:else}
                <div class="space-y-2 max-h-64 overflow-y-auto">
                  {#each gitlabDemoGroups as group}
                    <button
                      on:click={() => selectGitLabDemoGroup(group)}
                      class="w-full text-left p-3 rounded-lg border transition-colors
                             {selectedGitLabDemoGroup?.id === group.id 
                               ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/30' 
                               : 'border-gray-300 dark:border-gray-600 hover:border-blue-400 dark:hover:border-blue-500 hover:bg-gray-50 dark:hover:bg-gray-700'}"
                    >
                      <div class="flex items-center">
                        <Icon icon="mdi:folder-account" class="text-blue-600 mr-3" width="20" />
                        <span class="font-medium text-gray-900 dark:text-gray-100">{group.name}</span>
                      </div>
                    </button>
                  {/each}
                </div>
              {/if}
            </div>

          {:else if currentGitLabDemoStep === 'fork'}
            <div class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-6">
              <div class="flex items-start">
                <div class="flex-shrink-0">
                  <div class="flex items-center justify-center w-10 h-10 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                    <Icon icon="mdi:source-fork" class="text-blue-600 dark:text-blue-400" width="20" />
                  </div>
                </div>
                <div class="ml-4 flex-1">
                  <h3 class="text-lg font-medium text-blue-900 dark:text-blue-100 mb-2">
                    Fork the Demo Project
                  </h3>
                  <p class="text-blue-800 dark:text-blue-200 mb-4">
                    Fork our demo GitLab project to {selectedGitLabDemoGroup ? `the ${selectedGitLabDemoGroup.name} group` : 'your account'}. This contains a simple Terraform configuration you can experiment with safely.
                  </p>

                  <div class="space-y-4">
                    <div class="flex items-center space-x-3">
                      <button
                        on:click={() => openExternalLink('https://gitlab.com/terrateam-demo/kick-the-tires')}
                        class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg text-sm font-medium flex items-center"
                      >
                        <Icon icon="mdi:source-fork" class="mr-2" width="16" />
                        Fork Project
                      </button>
                    </div>
                    
                    <div class="bg-blue-100 dark:bg-blue-900/30 rounded-lg p-4">
                      <label for="forked-project-path" class="block text-sm font-medium text-blue-900 dark:text-blue-100 mb-2">
                        After forking, enter your project path:
                      </label>
                      <input
                        id="forked-project-path"
                        type="text"
                        bind:value={forkedProjectPath}
                        placeholder="groupname/kick-the-tires"
                        class="w-full px-3 py-2 border border-blue-300 dark:border-blue-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 placeholder-gray-500 dark:placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500"
                      />
                    </div>
                    
                    <button
                      on:click={() => {
                        if (forkedProjectPath.trim()) {
                          markGitLabDemoStepComplete('fork');
                        } else {
                          alert('Please enter your forked project path');
                        }
                      }}
                      class="border border-blue-600 text-blue-600 dark:text-blue-400 px-4 py-2 rounded-lg text-sm font-medium hover:bg-blue-50 dark:hover:bg-blue-900/30"
                    >
                      Continue
                    </button>
                  </div>
                </div>
              </div>
            </div>

          {:else if currentGitLabDemoStep === 'add-bot'}
            <div class="bg-green-50 dark:bg-green-900/20 rounded-lg p-6">
              <div class="flex items-start">
                <div class="flex-shrink-0">
                  <div class="flex items-center justify-center w-10 h-10 bg-green-100 dark:bg-green-900/30 rounded-lg">
                    <Icon icon="mdi:robot" class="text-green-600 dark:text-green-400" width="20" />
                  </div>
                </div>
                <div class="ml-4 flex-1">
                  <h3 class="text-lg font-medium text-green-900 dark:text-green-100 mb-2">
                    Add Terrateam Bot
                  </h3>
                  <p class="text-green-800 dark:text-green-200 mb-4">
                    Add the Terrateam bot to the <strong>{selectedGitLabDemoGroup?.name || 'selected'}</strong> group. This bot will manage Terraform operations and provide feedback on merge requests.
                  </p>

                  <div class="bg-green-100 dark:bg-green-900/30 rounded-lg p-4 mb-4">
                    <h4 class="font-medium text-green-900 dark:text-green-100 mb-2">Instructions:</h4>
                    <ol class="list-decimal list-inside space-y-1 text-sm text-green-800 dark:text-green-200">
                      <li>
                        <a 
                          href="https://gitlab.com/groups/{selectedGitLabDemoGroup?.name || ''}/-/group_members" 
                          target="_blank"
                          rel="noopener noreferrer"
                          class="inline-flex items-center font-medium text-green-700 dark:text-green-300 underline hover:text-green-600 dark:hover:text-green-200"
                        >
                          Open your group members page
                          <Icon icon="mdi:open-in-new" class="ml-1" width="16" />
                        </a>
                      </li>
                      <li>Click <strong>Invite members</strong></li>
                      <li>Add user: <code class="bg-green-200 dark:bg-green-800 px-1 rounded">@{gitlabBotUsername || 'terrateam-bot'}</code></li>
                      <li>Set role to <strong>Developer</strong> or higher</li>
                      <li>Click <strong>Invite</strong></li>
                    </ol>
                  </div>

                  {#if botVerificationError}
                    <div class="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-700 rounded-lg p-4 mb-4">
                      <div class="flex items-start">
                        <Icon icon="mdi:alert-circle" class="text-red-600 dark:text-red-400 mr-2 mt-0.5" width="20" />
                        <p class="text-sm text-red-800 dark:text-red-200">{botVerificationError}</p>
                      </div>
                    </div>
                  {/if}

                  <div class="flex items-center space-x-3">
                    <button
                      on:click={checkBotAdded}
                      disabled={checkingBotAdded}
                      class="bg-green-600 hover:bg-green-700 text-white px-4 py-2 rounded-lg text-sm font-medium disabled:opacity-50 disabled:cursor-not-allowed flex items-center"
                    >
                      {#if checkingBotAdded}
                        <svg class="w-4 h-4 mr-2 animate-spin" fill="none" viewBox="0 0 24 24">
                          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"></path>
                        </svg>
                        Checking...
                      {:else}
                        <Icon icon="mdi:check" class="mr-2" width="16" />
                        Verify Bot Added
                      {/if}
                    </button>
                    <button
                      on:click={() => markGitLabDemoStepComplete('add-bot')}
                      class="border border-green-600 text-green-600 dark:text-green-400 px-4 py-2 rounded-lg text-sm font-medium hover:bg-green-50 dark:hover:bg-green-900/30"
                    >
                      Skip Verification
                    </button>
                  </div>
                </div>
              </div>
            </div>

          {:else if currentGitLabDemoStep === 'configure-webhook'}
            <div class="bg-yellow-50 dark:bg-yellow-900/20 rounded-lg p-6">
              <div class="flex items-start">
                <div class="flex-shrink-0">
                  <div class="flex items-center justify-center w-10 h-10 bg-yellow-100 dark:bg-yellow-900/30 rounded-lg">
                    <Icon icon="mdi:webhook" class="text-yellow-600 dark:text-yellow-400" width="20" />
                  </div>
                </div>
                <div class="ml-4 flex-1">
                  <h3 class="text-lg font-medium text-yellow-900 dark:text-yellow-100 mb-2">
                    Configure Webhook
                  </h3>
                  <p class="text-yellow-800 dark:text-yellow-200 mb-4">
                    Add a webhook to your forked project so Terrateam can respond to merge requests and code changes.
                  </p>

                  <div class="bg-yellow-100 dark:bg-yellow-900/30 rounded-lg p-4 mb-4">
                    <h4 class="font-medium text-yellow-900 dark:text-yellow-100 mb-2">Instructions:</h4>
                    <ol class="list-decimal list-inside space-y-2 text-sm text-yellow-800 dark:text-yellow-200">
                      <li>
                        <a 
                          href="https://gitlab.com/{forkedProjectPath}/-/hooks" 
                          target="_blank"
                          rel="noopener noreferrer"
                          class="inline-flex items-center font-medium text-yellow-700 dark:text-yellow-300 underline hover:text-yellow-600 dark:hover:text-yellow-200"
                        >
                          Open your project webhooks
                          <Icon icon="mdi:open-in-new" class="ml-1" width="16" />
                        </a>
                      </li>
                      <li>Click <strong>Add new webhook</strong></li>
                      <li>URL: <code class="bg-yellow-200 dark:bg-yellow-800 px-1 rounded break-all">{webhookUrl || 'Loading...'}</code></li>
                      <li>Secret token: <code class="bg-yellow-200 dark:bg-yellow-800 px-1 rounded break-all">{webhookSecret || 'Loading...'}</code></li>
                      <li>Enable these triggers:
                        <ul class="list-disc list-inside ml-4 mt-1">
                          <li>Push events</li>
                          <li>Comments</li>
                          <li>Merge request events</li>
                        </ul>
                      </li>
                      <li>Click <strong>Add webhook</strong></li>
                    </ol>
                  </div>

                  {#if webhookVerificationError}
                    <div class="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-700 rounded-lg p-4 mb-4">
                      <div class="flex items-start">
                        <Icon icon="mdi:alert-circle" class="text-red-600 dark:text-red-400 mr-2 mt-0.5" width="20" />
                        <p class="text-sm text-red-800 dark:text-red-200">{webhookVerificationError}</p>
                      </div>
                    </div>
                  {/if}

                  <div class="flex items-center space-x-3">
                    <button
                      on:click={checkWebhook}
                      disabled={checkingWebhook}
                      class="bg-yellow-600 hover:bg-yellow-700 text-white px-4 py-2 rounded-lg text-sm font-medium disabled:opacity-50 disabled:cursor-not-allowed flex items-center"
                    >
                      {#if checkingWebhook}
                        <svg class="w-4 h-4 mr-2 animate-spin" fill="none" viewBox="0 0 24 24">
                          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"></path>
                        </svg>
                        Checking...
                      {:else}
                        <Icon icon="mdi:check" class="mr-2" width="16" />
                        Verify Webhook
                      {/if}
                    </button>
                    <button
                      on:click={() => markGitLabDemoStepComplete('configure-webhook')}
                      class="border border-yellow-600 text-yellow-600 dark:text-yellow-400 px-4 py-2 rounded-lg text-sm font-medium hover:bg-yellow-50 dark:hover:bg-yellow-900/30"
                    >
                      Skip Verification
                    </button>
                  </div>
                </div>
              </div>
            </div>

          {:else if currentGitLabDemoStep === 'push-test'}
            <div class="bg-indigo-50 dark:bg-indigo-900/20 rounded-lg p-6">
              <div class="flex items-start">
                <div class="flex-shrink-0">
                  <div class="flex items-center justify-center w-10 h-10 bg-indigo-100 dark:bg-indigo-900/30 rounded-lg">
                    <Icon icon="mdi:test-tube" class="text-indigo-600 dark:text-indigo-400" width="20" />
                  </div>
                </div>
                <div class="ml-4 flex-1">
                  <h3 class="text-lg font-semibold text-indigo-900 dark:text-indigo-100 mb-2">Test Webhook Connection</h3>
                  <p class="text-indigo-800 dark:text-indigo-200 mb-4">
                    Let's verify the webhook is properly configured by triggering a test event.
                  </p>
                  
                  <div class="bg-white dark:bg-gray-800 rounded-lg p-4 mb-4 border border-indigo-200 dark:border-indigo-700">
                    <h4 class="font-medium text-gray-900 dark:text-gray-100 mb-3">Instructions:</h4>
                    <ol class="list-decimal list-inside space-y-2 text-sm text-gray-700 dark:text-gray-300">
                      <li>
                        Navigate to your repository settings
                        {#if forkedProjectPath}
                          <div class="mt-1 ml-5">
                            <a 
                              href="https://gitlab.com/{forkedProjectPath}/-/hooks" 
                              target="_blank"
                              rel="noopener noreferrer"
                              class="inline-flex items-center text-indigo-600 dark:text-indigo-400 hover:underline text-xs"
                            >
                              Open Webhooks Settings
                              <Icon icon="mdi:open-in-new" class="ml-1" width="12" />
                            </a>
                          </div>
                        {/if}
                      </li>
                      <li>Find the Terrateam webhook in the list</li>
                      <li>Click <strong>Test</strong> → <strong>Push events</strong></li>
                      <li>Wait for the test to complete</li>
                    </ol>
                  </div>

                  {#if demoPushTestError}
                    <div class="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4 mb-4">
                      <p class="text-red-800 dark:text-red-200 text-sm">{demoPushTestError}</p>
                    </div>
                  {/if}

                  {#if demoPushTestSuccess}
                    <div class="bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg p-4 mb-4">
                      <p class="text-green-800 dark:text-green-200 text-sm">✅ Webhook received! Your installation is now active.</p>
                    </div>
                  {/if}

                  <div class="bg-indigo-100 dark:bg-indigo-900/30 rounded-lg p-3 mb-4">
                    <div class="flex items-start">
                      <Icon icon="mdi:information" class="text-indigo-600 mr-2 mt-0.5" width="16" />
                      <div class="text-sm text-indigo-800 dark:text-indigo-200">
                        <strong>Why this step?</strong> Testing the webhook ensures it's properly configured and can communicate with Terrateam.
                      </div>
                    </div>
                  </div>

                  <div class="flex items-center space-x-3">
                    <button
                      on:click={() => checkDemoPushTestStatus()}
                      disabled={isDemoCheckingPushTest}
                      class="bg-indigo-600 hover:bg-indigo-700 disabled:bg-gray-400 text-white px-4 py-2 rounded-lg text-sm font-medium"
                    >
                      {isDemoCheckingPushTest ? 'Checking...' : 'Check Status'}
                    </button>
                    <button
                      on:click={() => markGitLabDemoStepComplete('push-test')}
                      class="border border-gray-300 text-gray-600 dark:text-gray-400 px-4 py-2 rounded-lg text-sm font-medium hover:bg-gray-50 dark:hover:bg-gray-700"
                    >
                      Skip for Now
                    </button>
                  </div>
                </div>
              </div>
            </div>

          {:else if currentGitLabDemoStep === 'configure-variables'}
            <div class="bg-purple-50 dark:bg-purple-900/20 rounded-lg p-6">
              <div class="flex items-start">
                <div class="flex-shrink-0">
                  <div class="flex items-center justify-center w-10 h-10 bg-purple-100 dark:bg-purple-900/30 rounded-lg">
                    <Icon icon="mdi:cog" class="text-purple-600 dark:text-purple-400" width="20" />
                  </div>
                </div>
                <div class="ml-4 flex-1">
                  <h3 class="text-lg font-medium text-purple-900 dark:text-purple-100 mb-2">
                    Configure CI/CD Variables
                  </h3>
                  <p class="text-purple-800 dark:text-purple-200 mb-4">
                    Configure project settings to allow Terrateam to pass credentials securely to your Terraform runs.
                  </p>

                  <div class="bg-purple-100 dark:bg-purple-900/30 rounded-lg p-4 mb-4">
                    <h4 class="font-medium text-purple-900 dark:text-purple-100 mb-2">Instructions:</h4>
                    <ol class="list-decimal list-inside space-y-2 text-sm text-purple-800 dark:text-purple-200">
                      <li>
                        <a 
                          href="https://gitlab.com/{forkedProjectPath}/-/settings/ci_cd" 
                          target="_blank"
                          rel="noopener noreferrer"
                          class="inline-flex items-center font-medium text-purple-700 dark:text-purple-300 underline hover:text-purple-600 dark:hover:text-purple-200"
                        >
                          Open your project CI/CD settings
                          <Icon icon="mdi:open-in-new" class="ml-1" width="16" />
                        </a>
                      </li>
                      <li>Expand the <strong>Variables</strong> section</li>
                      <li>Find <strong>"Minimum role to use pipeline variables"</strong></li>
                      <li>Select <strong>Developer</strong> from the dropdown</li>
                      <li>Click <strong>Save changes</strong></li>
                    </ol>
                  </div>

                  <div class="bg-amber-50 dark:bg-amber-900/30 rounded p-3 mb-4">
                    <div class="flex items-start">
                      <Icon icon="mdi:shield-lock" class="text-amber-600 mr-2 mt-0.5" width="16" />
                      <div class="text-sm text-amber-800 dark:text-amber-200">
                        <strong>Why this is needed:</strong> This setting allows the Terrateam bot (@{gitlabBotUsername || 'terrateam-bot'} with Developer role) to run pipelines with variables that contain your cloud credentials and Terraform configuration.
                      </div>
                    </div>
                  </div>

                  <div class="flex items-center space-x-3">
                    <button
                      on:click={() => markGitLabDemoStepComplete('configure-variables')}
                      class="bg-purple-600 hover:bg-purple-700 text-white px-4 py-2 rounded-lg text-sm font-medium flex items-center"
                    >
                      <Icon icon="mdi:check" class="mr-2" width="16" />
                      Variables Configured
                    </button>
                    <button
                      on:click={() => goToGitLabDemoStep('configure-webhook')}
                      class="border border-gray-300 text-gray-600 dark:text-gray-400 px-4 py-2 rounded-lg text-sm font-medium hover:bg-gray-50 dark:hover:bg-gray-700"
                    >
                      Go Back
                    </button>
                  </div>
                </div>
              </div>
            </div>

          {:else if currentGitLabDemoStep === 'make-changes'}
            <div class="bg-purple-50 dark:bg-purple-900/20 rounded-lg p-6">
              <div class="flex items-start">
                <div class="flex-shrink-0">
                  <div class="w-10 h-10 bg-purple-600 rounded-lg flex items-center justify-center">
                    <Icon icon="mdi:file-edit" class="text-white" width="20" />
                  </div>
                </div>
                <div class="ml-4 flex-1">
                  <h3 class="text-lg font-semibold text-purple-900 dark:text-purple-100 mb-2">Make Your First Change</h3>
                  <p class="text-purple-800 dark:text-purple-200 mb-4">
                    Now let's make a change to see Terrateam in action! We'll edit a file and create a merge request in your 
                    <a 
                      href="https://gitlab.com/{forkedProjectPath}" 
                      target="_blank"
                      rel="noopener noreferrer"
                      class="font-medium text-purple-700 dark:text-purple-300 underline hover:text-purple-600 dark:hover:text-purple-200"
                    >
                      forked repository
                    </a>.
                  </p>
                  
                  <div class="bg-white dark:bg-gray-800 rounded-lg p-4 mb-4 border border-purple-200 dark:border-purple-700">
                    <div class="space-y-3 text-sm">
                      <div class="flex items-start">
                        <Icon icon="mdi:numeric-1-circle" class="text-purple-600 mr-2 mt-0.5" width="16" />
                        <div>
                          <div class="text-gray-700 dark:text-gray-300">
                            Edit 
                            <a 
                              href="https://gitlab.com/{forkedProjectPath}/-/edit/main/dev/main.tf" 
                              target="_blank"
                              rel="noopener noreferrer"
                              class="inline-flex items-center font-mono bg-purple-100 dark:bg-purple-900/30 px-2 py-0.5 rounded text-purple-700 dark:text-purple-300 underline hover:bg-purple-200 dark:hover:bg-purple-900/50 transition-colors"
                            >
                              dev/main.tf
                              <Icon icon="mdi:open-in-new" class="ml-1" width="14" />
                            </a>
                          </div>
                          <div class="text-gray-500 dark:text-gray-400 text-xs">Change <code>null_resource_count = 0</code> to <code>null_resource_count = 1</code></div>
                        </div>
                      </div>
                      <div class="flex items-center">
                        <Icon icon="mdi:numeric-2-circle" class="text-purple-600 mr-2" width="16" />
                        <span class="text-gray-700 dark:text-gray-300">Create a new branch and push your changes</span>
                      </div>
                      <div class="flex items-center">
                        <Icon icon="mdi:numeric-3-circle" class="text-purple-600 mr-2" width="16" />
                        <span class="text-gray-700 dark:text-gray-300">Open a merge request</span>
                      </div>
                      <div class="flex items-center">
                        <Icon icon="mdi:numeric-4-circle" class="text-purple-600 mr-2" width="16" />
                        <span class="text-gray-700 dark:text-gray-300">Watch Terrateam automatically comment with the plan!</span>
                      </div>
                    </div>
                  </div>

                  <div class="bg-blue-50 dark:bg-blue-900/30 rounded p-3 mb-4">
                    <div class="flex items-start">
                      <Icon icon="mdi:lightbulb" class="text-blue-600 mr-2 mt-0.5" width="16" />
                      <div class="text-sm text-blue-800 dark:text-blue-200">
                        <strong>Pro tip:</strong> When you're ready to apply the changes, comment <code class="bg-blue-100 dark:bg-blue-800 px-1 rounded">terrateam apply</code> on your MR.
                      </div>
                    </div>
                  </div>

                  <div class="flex items-center space-x-3">
                    <button
                      on:click={() => markGitLabDemoStepComplete('make-changes')}
                      class="bg-purple-600 hover:bg-purple-700 text-white px-4 py-2 rounded-lg text-sm font-medium"
                    >
                      I've created an MR
                    </button>
                    <button
                      on:click={() => goToGitLabDemoStep('configure-variables')}
                      class="border border-gray-300 text-gray-600 dark:text-gray-400 px-4 py-2 rounded-lg text-sm font-medium hover:bg-gray-50 dark:hover:bg-gray-700"
                    >
                      Go Back
                    </button>
                  </div>
                </div>
              </div>
            </div>

          {:else if currentGitLabDemoStep === 'success'}
            <div class="text-center py-12">
              <div class="inline-flex items-center justify-center w-16 h-16 bg-green-100 dark:bg-green-900/30 rounded-full mb-6">
                <Icon icon="mdi:check-circle" class="text-green-600 dark:text-green-400" width="32" />
              </div>
              
              <h3 class="text-2xl font-semibold text-gray-900 dark:text-gray-100 mb-4 flex items-center justify-center">
                <Icon icon="mdi:party-popper" class="mr-2 text-green-600 dark:text-green-400" width="28" />
                GitLab Demo Complete!
              </h3>
              
              <p class="text-gray-600 dark:text-gray-400 mb-6">
                You've successfully set up the Terrateam demo and seen how Terraform automation works with GitLab merge requests.
              </p>
              
              <div class="bg-green-50 dark:bg-green-900/20 rounded-lg p-6 mb-6 max-w-md mx-auto">
                <h4 class="font-semibold text-green-900 dark:text-green-100 mb-3">What you've learned:</h4>
                <div class="space-y-2 text-sm text-green-800 dark:text-green-200">
                  <div class="flex items-center">
                    <Icon icon="mdi:check" class="text-green-600 mr-2 flex-shrink-0" width="16" />
                    How to set up Terrateam with GitLab
                  </div>
                  <div class="flex items-center">
                    <Icon icon="mdi:check" class="text-green-600 mr-2 flex-shrink-0" width="16" />
                    Automatic plans on merge requests
                  </div>
                  <div class="flex items-center">
                    <Icon icon="mdi:check" class="text-green-600 mr-2 flex-shrink-0" width="16" />
                    GitLab CI/CD integration
                  </div>
                  <div class="flex items-center">
                    <Icon icon="mdi:check" class="text-green-600 mr-2 flex-shrink-0" width="16" />
                    Bot-managed Terraform workflows
                  </div>
                </div>
              </div>

              <div class="flex justify-center space-x-4">
                <button
                  on:click={() => {selectedPath = null; currentStep = 'path-selection'; currentGitLabDemoStep = 'fork';}}
                  class="border border-gray-300 text-gray-600 dark:text-gray-400 px-6 py-2 rounded-lg text-sm font-medium hover:bg-gray-50 dark:hover:bg-gray-700"
                >
                  Start Over
                </button>
                <button
                  on:click={() => selectPath('repo')}
                  class="bg-blue-600 hover:bg-blue-700 text-white px-6 py-2 rounded-lg text-sm font-medium"
                >
                  Set Up My Project
                </button>
              </div>
            </div>
          {/if}
        </div>

      {:else if currentStep === 'github-repo-setup'}
        <!-- Repository Setup Wizard -->
        <div class="mb-6">
          <div class="flex items-center justify-between mb-6">
            <h2 class="text-xl font-semibold text-gray-900 dark:text-gray-100">Repository Setup</h2>
            <button
              on:click={goBack}
              class="text-sm text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-200 flex items-center"
            >
              <Icon icon="mdi:arrow-left" class="mr-1" width="16" />
              Back
            </button>
          </div>

          <!-- Repository Steps Progress -->
          <div class="mb-8">
            <div class="flex items-center justify-between mb-4">
              {#each [
                {step: 'install-app', index: 0, label: '1'},
                {step: 'select-repo', index: 1, label: '2'},
                {step: 'add-workflow', index: 2, label: '3'},
                {step: 'configure', index: 3, label: '4'},
                {step: 'test', index: 4, label: '5'},
                {step: 'success', index: 5, label: '6'}
              ] as stepInfo}
                <div class="flex items-center {stepInfo.index < 5 ? 'flex-1' : ''}">
                  <div class="flex items-center justify-center w-8 h-8 rounded-full text-sm font-medium
                              {currentRepoStep === stepInfo.step ? 'bg-blue-600 text-white' : 
                               (stepInfo.step === 'install-app' && repoStepCompleted['install-app']) ||
                               (stepInfo.step === 'select-repo' && repoStepCompleted['select-repo']) ||
                               (stepInfo.step === 'add-workflow' && repoStepCompleted['add-workflow']) ||
                               (stepInfo.step === 'configure' && repoStepCompleted.configure) ||
                               (stepInfo.step === 'test' && repoStepCompleted.test)
                               ? 'bg-green-600 text-white' : 
                               'bg-gray-200 dark:bg-gray-600 text-gray-600 dark:text-gray-400'}">
                    {#if (stepInfo.step === 'install-app' && repoStepCompleted['install-app']) ||
                         (stepInfo.step === 'select-repo' && repoStepCompleted['select-repo']) ||
                         (stepInfo.step === 'add-workflow' && repoStepCompleted['add-workflow']) ||
                         (stepInfo.step === 'configure' && repoStepCompleted.configure) ||
                         (stepInfo.step === 'test' && repoStepCompleted.test)}
                      <Icon icon="mdi:check" class="text-white" width="16" />
                    {:else}
                      {stepInfo.label}
                    {/if}
                  </div>
                  {#if stepInfo.index < 5}
                    <div class="flex-1 h-1 mx-2 {
                      (stepInfo.step === 'install-app' && repoStepCompleted['install-app']) ||
                      (stepInfo.step === 'select-repo' && repoStepCompleted['select-repo']) ||
                      (stepInfo.step === 'add-workflow' && repoStepCompleted['add-workflow']) ||
                      (stepInfo.step === 'configure' && repoStepCompleted.configure) ||
                      (stepInfo.step === 'test' && repoStepCompleted.test)
                      ? 'bg-green-600' : 'bg-gray-200 dark:bg-gray-600'}"></div>
                  {/if}
                </div>
              {/each}
            </div>
            <div class="text-center text-sm text-gray-500 dark:text-gray-400">
              Step {['install-app', 'select-repo', 'add-workflow', 'configure', 'test', 'success'].indexOf(currentRepoStep) + 1} of 6
            </div>
          </div>

          <!-- Repository Step Content -->
          {#if currentRepoStep === 'install-app'}
            <div class="bg-green-50 dark:bg-green-900/20 rounded-lg p-6">
              <div class="flex items-start">
                <div class="flex-shrink-0">
                  <div class="w-10 h-10 bg-green-600 rounded-lg flex items-center justify-center">
                    <Icon icon="mdi:download" class="text-white" width="20" />
                  </div>
                </div>
                <div class="ml-4 flex-1">
                  <h3 class="text-lg font-semibold text-green-900 dark:text-green-100 mb-2">Step 1: Install Terrateam GitHub App</h3>
                  <p class="text-green-800 dark:text-green-200 mb-4">
                    Install the Terrateam GitHub App on your organization to enable Terraform automation.
                  </p>
                  
                  {#if hasInstallations}
                    <div class="bg-green-100 dark:bg-green-900/30 rounded-lg p-4 mb-4 border border-green-200 dark:border-green-700">
                      <div class="flex items-center">
                        <Icon icon="mdi:check-circle" class="text-green-600 mr-2" width="20" />
                        <span class="text-green-800 dark:text-green-200 font-medium">
                          Great! We detected {installations.length} GitHub installation{installations.length > 1 ? 's' : ''}.
                        </span>
                      </div>
                    </div>
                  {:else}
                    <div class="bg-white dark:bg-gray-800 rounded-lg p-4 mb-4 border border-green-200 dark:border-green-700">
                      <div class="flex items-center justify-between">
                        <div>
                          <div class="font-medium text-gray-900 dark:text-gray-100">Terrateam GitHub App</div>
                          <div class="text-sm text-gray-600 dark:text-gray-400">Enables Terraform automation in your repositories</div>
                        </div>
                        <Icon icon="mdi:github" class="text-gray-400" width="24" />
                      </div>
                    </div>
                  {/if}

                  <div class="bg-blue-50 dark:bg-blue-900/30 rounded-lg p-4 mb-4 border border-blue-200 dark:border-blue-700">
                    <div class="flex items-start">
                      <Icon icon="mdi:information" class="text-blue-600 dark:text-blue-400 mr-2 mt-0.5" width="20" />
                      <div class="text-sm text-blue-800 dark:text-blue-200">
                        <p class="font-medium mb-1">Repository in a different organization?</p>
                        <p>You can install the app on any organization where your repository is located.</p>
                      </div>
                    </div>
                  </div>

                  <div class="flex items-center space-x-3">
                    <button
                      on:click={() => openExternalLink(githubAppUrl, 'github_app_install')}
                      class="bg-green-600 hover:bg-green-700 text-white px-4 py-2 rounded-lg text-sm font-medium flex items-center"
                    >
                      <Icon icon="mdi:download" class="mr-2" width="16" />
                      Install GitHub App
                    </button>
                    <button
                      on:click={checkRepoAppInstallation}
                      disabled={checkingAppInstallation}
                      class="border border-green-600 text-green-600 dark:text-green-400 px-4 py-2 rounded-lg text-sm font-medium hover:bg-green-50 dark:hover:bg-green-900/30 disabled:opacity-50"
                    >
                      {#if checkingAppInstallation}
                        <Icon icon="mdi:loading" class="animate-spin mr-2" width="16" />
                        Checking...
                      {:else if hasInstallations}
                        Continue
                      {:else}
                        Check Installation
                      {/if}
                    </button>
                  </div>
                </div>
              </div>
            </div>

          {:else if currentRepoStep === 'select-repo'}
            <div class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-6">
              <div class="flex items-start">
                <div class="flex-shrink-0">
                  <div class="w-10 h-10 bg-blue-600 rounded-lg flex items-center justify-center">
                    <Icon icon="mdi:source-repository" class="text-white" width="20" />
                  </div>
                </div>
                <div class="ml-4 flex-1">
                  <h3 class="text-lg font-semibold text-blue-900 dark:text-blue-100 mb-2">Step 2: Select Repository</h3>
                  <p class="text-blue-800 dark:text-blue-200 mb-4">
                    Choose the repository where you want to enable Terrateam automation.
                  </p>
                  
                  {#if installations.length > 1}
                    <div class="mb-4">
                      <label for="organization-select" class="block text-sm font-medium text-blue-900 dark:text-blue-100 mb-2">{VCS_PROVIDERS[currentProvider].displayName} {terminology.organization}:</label>
                      <select 
                        id="organization-select"
                        bind:value={selectedInstallationId}
                        on:change={() => {
                          selectedInstallation = installations.find(i => i.id === selectedInstallationId) || null;
                        }}
                        class="w-full p-2 border border-blue-200 dark:border-blue-700 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100"
                      >
                        <option value="">Select a {terminology.organization}...</option>
                        {#each installations as installation}
                          <option value={installation.id}>{installation.name}</option>
                        {/each}
                      </select>
                    </div>
                  {:else if installations.length === 1}
                    {#if !selectedInstallation}
                      {selectedInstallation = installations[0]}
                      {selectedInstallationId = installations[0].id}
                    {/if}
                    <div class="bg-blue-100 dark:bg-blue-900/30 rounded-lg p-3 mb-4 border border-blue-200 dark:border-blue-700">
                      <div class="flex items-center">
                        <Icon icon="mdi:github" class="text-blue-600 mr-2" width="16" />
                        <span class="text-blue-800 dark:text-blue-200 font-medium">{installations[0].name}</span>
                      </div>
                    </div>
                  {/if}

                  {#if selectedInstallation}
                    <div class="mb-4">
                      <div class="flex items-center justify-between mb-2">
                        <span class="block text-sm font-medium text-blue-900 dark:text-blue-100">Choose Repository:</span>
                        <button
                          on:click={refreshRepositories}
                          disabled={isLoadingRepos}
                          class="text-xs text-blue-600 dark:text-blue-400 hover:underline disabled:opacity-50"
                        >
                          {isLoadingRepos ? 'Refreshing...' : 'Refresh'}
                        </button>
                      </div>
                      
                      <div class="bg-blue-100 dark:bg-blue-900/30 rounded-lg p-3 mb-3 border border-blue-200 dark:border-blue-700">
                        <div class="flex items-start">
                          <Icon icon="mdi:information" class="text-blue-600 dark:text-blue-400 mr-2 mt-0.5" width="16" />
                          <div class="text-sm text-blue-800 dark:text-blue-200">
                            <p class="font-medium mb-1">Repository Access</p>
                            <p>Only repositories where the GitHub app is installed and enabled will appear here. If you don't see your repository, you may need to <button on:click={() => openExternalLink(githubAppUrl)} class="font-medium text-blue-700 dark:text-blue-300 underline hover:text-blue-600 dark:hover:text-blue-200">configure app access</button> first.</p>
                          </div>
                        </div>
                      </div>
                      
                      {#if isLoadingRepos}
                        <div class="flex items-center justify-center p-8">
                          <div class="animate-spin rounded-full h-6 w-6 border-b-2 border-blue-600"></div>
                        </div>
                      {:else if repoLoadError}
                        <div class="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4">
                          <p class="text-red-800 dark:text-red-200 text-sm">{repoLoadError}</p>
                        </div>
                      {:else if repositories.length === 0}
                        <div class="bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg p-4">
                          <div class="flex items-start">
                            <Icon icon="mdi:alert" class="text-yellow-600 mr-3 mt-0.5" width="20" />
                            <div class="flex-1">
                              <p class="text-yellow-800 dark:text-yellow-200 text-sm font-medium mb-2">No repositories found</p>
                              <p class="text-yellow-700 dark:text-yellow-300 text-sm mb-3">
                                The GitHub App doesn't have access to any repositories in this organization. You may need to configure repository access.
                              </p>
                              <button
                                on:click={() => openExternalLink(githubAppUrl, 'github_app_install')}
                                class="bg-yellow-600 hover:bg-yellow-700 text-white px-3 py-2 rounded text-sm font-medium flex items-center"
                              >
                                <Icon icon="mdi:cog" class="mr-2" width="16" />
                                Configure App Access
                              </button>
                            </div>
                          </div>
                        </div>
                      {:else}
                        <div class="max-h-60 overflow-y-auto border border-blue-200 dark:border-blue-700 rounded-lg">
                          {#each repositories as repo}
                            <button
                              on:click={() => selectRepository(repo)}
                              class="w-full text-left p-3 border-b border-blue-100 dark:border-blue-800 last:border-b-0 hover:bg-blue-50 dark:hover:bg-blue-900/30 {selectedRepository?.id === repo.id ? 'bg-blue-100 dark:bg-blue-900/50' : ''}"
                            >
                              <div class="flex items-center justify-between">
                                <div>
                                  <div class="font-medium text-gray-900 dark:text-gray-100">{repo.name}</div>
                                  <div class="text-sm text-gray-600 dark:text-gray-400">Repository setup: {repo.setup ? 'Complete' : 'Pending'}</div>
                                </div>
                                {#if selectedRepository?.id === repo.id}
                                  <Icon icon="mdi:check-circle" class="text-blue-600" width="20" />
                                {/if}
                              </div>
                            </button>
                          {/each}
                        </div>
                      {/if}
                    </div>
                  {/if}

                  <div class="flex items-center space-x-3">
                    {#if selectedRepository}
                      <button
                        on:click={() => markRepoStepComplete('select-repo')}
                        class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg text-sm font-medium"
                      >
                        Continue with {selectedRepository.name}
                      </button>
                    {/if}
                    <button
                      on:click={() => goToRepoStep('install-app')}
                      class="border border-gray-300 text-gray-600 dark:text-gray-400 px-4 py-2 rounded-lg text-sm font-medium hover:bg-gray-50 dark:hover:bg-gray-700"
                    >
                      Go Back
                    </button>
                  </div>
                </div>
              </div>
            </div>

          {:else if currentRepoStep === 'add-workflow'}
            <div class="bg-orange-50 dark:bg-orange-900/20 rounded-lg p-6">
              <div class="flex items-start">
                <div class="flex-shrink-0">
                  <div class="w-10 h-10 bg-orange-600 rounded-lg flex items-center justify-center">
                    <Icon icon="mdi:file-plus" class="text-white" width="20" />
                  </div>
                </div>
                <div class="ml-4 flex-1">
                  <h3 class="text-lg font-semibold text-orange-900 dark:text-orange-100 mb-2">Step 3: Add GitHub Actions Workflow</h3>
                  <p class="text-orange-800 dark:text-orange-200 mb-4">
                    Add the Terrateam workflow file to your repository's default branch to enable automation.
                  </p>
                  
                  <div class="bg-white dark:bg-gray-800 rounded-lg p-4 mb-4 border border-orange-200 dark:border-orange-700">
                    <div class="space-y-3 text-sm">
                      <div class="flex items-start">
                        <Icon icon="mdi:numeric-1-circle" class="text-orange-600 mr-2 mt-0.5" width="16" />
                        <div>
                          <div class="text-gray-700 dark:text-gray-300">Create a new branch in <strong>{selectedRepository?.name}</strong></div>
                          <code class="block bg-gray-100 dark:bg-gray-700 p-2 rounded mt-1 text-xs">
                            git checkout -b add-terrateam-workflow
                          </code>
                        </div>
                      </div>
                      
                      <div class="flex items-start">
                        <Icon icon="mdi:numeric-2-circle" class="text-orange-600 mr-2 mt-0.5" width="16" />
                        <div>
                          <div class="text-gray-700 dark:text-gray-300">Create the workflow directory and file</div>
                          <code class="block bg-gray-100 dark:bg-gray-700 p-2 rounded mt-1 text-xs">
                            mkdir -p .github/workflows<br/>
                            curl -o .github/workflows/terrateam.yml https://raw.githubusercontent.com/terrateamio/terrateam-example/refs/heads/main/github/actions/workflows/default/terrateam.yml
                          </code>
                        </div>
                      </div>
                      
                      <div class="flex items-start">
                        <Icon icon="mdi:numeric-3-circle" class="text-orange-600 mr-2 mt-0.5" width="16" />
                        <div>
                          <div class="text-gray-700 dark:text-gray-300">Commit and push the workflow</div>
                          <code class="block bg-gray-100 dark:bg-gray-700 p-2 rounded mt-1 text-xs">
                            git add .github/workflows/terrateam.yml<br/>
                            git commit -m "Add Terrateam workflow"<br/>
                            git push -u origin add-terrateam-workflow
                          </code>
                        </div>
                      </div>
                      
                      <div class="flex items-start">
                        <Icon icon="mdi:numeric-4-circle" class="text-orange-600 mr-2 mt-0.5" width="16" />
                        <div>
                          <div class="text-gray-700 dark:text-gray-300">Create a pull request and merge it to your default branch</div>
                        </div>
                      </div>
                    </div>
                  </div>

                  <div class="bg-blue-50 dark:bg-blue-900/30 rounded p-3 mb-4">
                    <div class="flex items-start">
                      <Icon icon="mdi:information" class="text-blue-600 mr-2 mt-0.5" width="16" />
                      <div class="text-sm text-blue-800 dark:text-blue-200">
                        <strong>Important:</strong> The workflow file must be in your default branch (usually <code>main</code> or <code>master</code>) to be active.
                      </div>
                    </div>
                  </div>

                  <div class="flex items-center space-x-3">
                    <button
                      on:click={() => markRepoStepComplete('add-workflow')}
                      class="bg-orange-600 hover:bg-orange-700 text-white px-4 py-2 rounded-lg text-sm font-medium"
                    >
                      Workflow Added
                    </button>
                    <button
                      on:click={() => goToRepoStep('select-repo')}
                      class="border border-gray-300 text-gray-600 dark:text-gray-400 px-4 py-2 rounded-lg text-sm font-medium hover:bg-gray-50 dark:hover:bg-gray-700"
                    >
                      Go Back
                    </button>
                  </div>
                </div>
              </div>
            </div>

          {:else if currentRepoStep === 'configure'}
            <div class="bg-purple-50 dark:bg-purple-900/20 rounded-lg p-6">
              <div class="flex items-start">
                <div class="flex-shrink-0">
                  <div class="w-10 h-10 bg-purple-600 rounded-lg flex items-center justify-center">
                    <Icon icon="mdi:cog" class="text-white" width="20" />
                  </div>
                </div>
                <div class="ml-4 flex-1">
                  <h3 class="text-lg font-semibold text-purple-900 dark:text-purple-100 mb-2">Step 4: Configure Cloud Credentials</h3>
                  <p class="text-purple-800 dark:text-purple-200 mb-4">
                    Set up cloud provider credentials so Terrateam can manage your infrastructure.
                  </p>
                  
                  <div class="bg-white dark:bg-gray-800 rounded-lg p-4 mb-4 border border-purple-200 dark:border-purple-700">
                    <div class="space-y-3 text-sm">
                      <div class="flex items-start">
                        <Icon icon="mdi:numeric-1-circle" class="text-purple-600 mr-2 mt-0.5" width="16" />
                        <div>
                          <div class="text-gray-700 dark:text-gray-300">Go to your repository settings</div>
                          <div class="text-gray-500 dark:text-gray-400 text-xs">Settings → Secrets and variables → Actions</div>
                        </div>
                      </div>
                      
                      <div class="flex items-start">
                        <Icon icon="mdi:numeric-2-circle" class="text-purple-600 mr-2 mt-0.5" width="16" />
                        <div>
                          <div class="text-gray-700 dark:text-gray-300">Add your cloud provider credentials as repository secrets</div>
                          <div class="text-gray-500 dark:text-gray-400 text-xs">
                            AWS: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY<br/>
                            GCP: GOOGLE_CREDENTIALS (service account JSON)<br/>
                            Azure: ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_SUBSCRIPTION_ID, ARM_TENANT_ID
                          </div>
                        </div>
                      </div>
                      
                      <div class="flex items-start">
                        <Icon icon="mdi:numeric-3-circle" class="text-purple-600 mr-2 mt-0.5" width="16" />
                        <div>
                          <div class="text-gray-700 dark:text-gray-300">Make sure your Terraform configurations are ready</div>
                          <div class="text-gray-500 dark:text-gray-400 text-xs">Valid .tf files with proper provider configurations</div>
                        </div>
                      </div>
                    </div>
                  </div>

                  <div class="bg-amber-50 dark:bg-amber-900/30 rounded p-3 mb-4">
                    <div class="flex items-start">
                      <Icon icon="mdi:shield-lock" class="text-amber-600 mr-2 mt-0.5" width="16" />
                      <div class="text-sm text-amber-800 dark:text-amber-200">
                        <strong>Security tip:</strong> Consider using OIDC for enhanced security instead of static credentials. Check our cloud provider guides for OIDC setup instructions.
                      </div>
                    </div>
                  </div>

                  <div class="flex items-center space-x-3">
                    <button
                      on:click={() => markRepoStepComplete('configure')}
                      class="bg-purple-600 hover:bg-purple-700 text-white px-4 py-2 rounded-lg text-sm font-medium"
                    >
                      Credentials Configured
                    </button>
                    <button
                      on:click={() => goToRepoStep('add-workflow')}
                      class="border border-gray-300 text-gray-600 dark:text-gray-400 px-4 py-2 rounded-lg text-sm font-medium hover:bg-gray-50 dark:hover:bg-gray-700"
                    >
                      Go Back
                    </button>
                  </div>
                </div>
              </div>
            </div>

          {:else if currentRepoStep === 'test'}
            <div class="bg-teal-50 dark:bg-teal-900/20 rounded-lg p-6">
              <div class="flex items-start">
                <div class="flex-shrink-0">
                  <div class="w-10 h-10 bg-teal-600 rounded-lg flex items-center justify-center">
                    <Icon icon="mdi:test-tube" class="text-white" width="20" />
                  </div>
                </div>
                <div class="ml-4 flex-1">
                  <h3 class="text-lg font-semibold text-teal-900 dark:text-teal-100 mb-2">Test Your Setup</h3>
                  <p class="text-teal-800 dark:text-teal-200 mb-4">
                    Let's test your Terrateam setup by making a change and creating a pull request.
                  </p>
                  
                  <div class="bg-white dark:bg-gray-800 rounded-lg p-4 mb-4 border border-teal-200 dark:border-teal-700">
                    <div class="space-y-3 text-sm">
                      <div class="flex items-start">
                        <Icon icon="mdi:numeric-1-circle" class="text-teal-600 mr-2 mt-0.5" width="16" />
                        <div>
                          <div class="text-gray-700 dark:text-gray-300">Make a change to any <code class="bg-gray-100 dark:bg-gray-700 px-1 rounded">.tf</code> file in your repository</div>
                          <div class="text-gray-500 dark:text-gray-400 text-xs">Even a small comment change will work for testing</div>
                        </div>
                      </div>
                      
                      <div class="flex items-start">
                        <Icon icon="mdi:numeric-2-circle" class="text-teal-600 mr-2 mt-0.5" width="16" />
                        <div>
                          <div class="text-gray-700 dark:text-gray-300">Create a new branch and commit your changes</div>
                          <code class="block bg-gray-100 dark:bg-gray-700 p-2 rounded mt-1 text-xs">
                            git checkout -b test-terrateam<br/>
                            git add -A<br/>
                            git commit -m "Test Terrateam setup"<br/>
                            git push -u origin test-terrateam
                          </code>
                        </div>
                      </div>
                      
                      <div class="flex items-start">
                        <Icon icon="mdi:numeric-3-circle" class="text-teal-600 mr-2 mt-0.5" width="16" />
                        <div>
                          <div class="text-gray-700 dark:text-gray-300">Open a pull request</div>
                          <div class="text-gray-500 dark:text-gray-400 text-xs">Terrateam should automatically comment with the terraform plan!</div>
                        </div>
                      </div>
                      
                      <div class="flex items-start">
                        <Icon icon="mdi:numeric-4-circle" class="text-teal-600 mr-2 mt-0.5" width="16" />
                        <div>
                          <div class="text-gray-700 dark:text-gray-300">If you want to apply the changes, comment <code class="bg-gray-100 dark:bg-gray-700 px-1 rounded">terrateam apply</code></div>
                        </div>
                      </div>
                    </div>
                  </div>

                  <div class="bg-green-50 dark:bg-green-900/30 rounded p-3 mb-4">
                    <div class="flex items-start">
                      <Icon icon="mdi:lightbulb" class="text-green-600 mr-2 mt-0.5" width="16" />
                      <div class="text-sm text-green-800 dark:text-green-200">
                        <strong>Success indicators:</strong> Look for Terrateam's bot comment with the terraform plan output and green status checks.
                      </div>
                    </div>
                  </div>

                  <div class="flex items-center space-x-3">
                    <button
                      on:click={() => markRepoStepComplete('test')}
                      class="bg-teal-600 hover:bg-teal-700 text-white px-4 py-2 rounded-lg text-sm font-medium"
                    >
                      It Works!
                    </button>
                    <button
                      on:click={() => goToRepoStep('configure')}
                      class="border border-gray-300 text-gray-600 dark:text-gray-400 px-4 py-2 rounded-lg text-sm font-medium hover:bg-gray-50 dark:hover:bg-gray-700"
                    >
                      Go Back
                    </button>
                  </div>
                </div>
              </div>
            </div>

          {:else if currentRepoStep === 'success'}
            <div class="text-center py-12">
              <div class="inline-flex items-center justify-center w-16 h-16 bg-green-100 dark:bg-green-900/30 rounded-full mb-6">
                <Icon icon="mdi:check-circle" class="text-green-600 dark:text-green-400" width="32" />
              </div>
              <h3 class="text-2xl font-semibold text-gray-900 dark:text-gray-100 mb-2 flex items-center justify-center">
                <Icon icon="mdi:party-popper" class="text-purple-600 dark:text-purple-400 mr-2" width="28" />
                Repository Setup Complete!
              </h3>
              <p class="text-gray-600 dark:text-gray-400 mb-6">
                Terrateam is now configured for <strong>{selectedRepository?.name}</strong>. You're ready to automate your Terraform workflows!
              </p>
              
              <div class="bg-green-50 dark:bg-green-900/20 rounded-lg p-6 mb-6 max-w-md mx-auto">
                <h4 class="font-semibold text-green-900 dark:text-green-100 mb-3">What you've set up:</h4>
                <div class="space-y-2 text-sm text-green-800 dark:text-green-200">
                  <div class="flex items-center">
                    <Icon icon="mdi:check" class="text-green-600 mr-2" width="16" />
                    GitHub App installed and configured
                  </div>
                  <div class="flex items-center">
                    <Icon icon="mdi:check" class="text-green-600 mr-2" width="16" />
                    Terrateam workflow active in your repository
                  </div>
                  <div class="flex items-center">
                    <Icon icon="mdi:check" class="text-green-600 mr-2" width="16" />
                    Cloud credentials securely configured
                  </div>
                  <div class="flex items-center">
                    <Icon icon="mdi:check" class="text-green-600 mr-2" width="16" />
                    Automated Terraform plans on pull requests
                  </div>
                </div>
              </div>

              <div class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-6 mb-6 max-w-md mx-auto">
                <h4 class="font-semibold text-blue-900 dark:text-blue-100 mb-3 flex items-center">
                  <Icon icon="mdi:rocket-launch" class="text-blue-600 dark:text-blue-400 mr-2" width="20" />
                  Ready for Advanced Configuration?
                </h4>
                <p class="text-sm text-blue-800 dark:text-blue-200 mb-4">
                  Take your Terrateam setup to the next level with our Configuration Wizard. 
                  Generate custom workflows, set up advanced features, and optimize for your specific use case.
                </p>
                <button
                  on:click={openConfigurationWizard}
                  class="w-full bg-blue-600 hover:bg-blue-700 text-white px-4 py-3 rounded-lg text-sm font-medium flex items-center justify-center"
                >
                  <Icon icon="mdi:auto-fix" class="mr-2" width="20" />
                  Open Configuration Wizard
                </button>
              </div>

              <div class="flex justify-center space-x-4">
                <button
                  on:click={() => window.location.hash = '#/repositories'}
                  class="bg-gray-600 hover:bg-gray-700 text-white px-6 py-2 rounded-lg text-sm font-medium"
                >
                  View My Repositories
                </button>
                <button
                  on:click={() => openExternalLink('https://docs.terrateam.io/')}
                  class="border border-gray-300 text-gray-600 dark:text-gray-400 px-6 py-2 rounded-lg text-sm font-medium hover:bg-gray-50 dark:hover:bg-gray-700"
                >
                  Read Documentation
                </button>
              </div>
            </div>
          {/if}
        </div>

      {:else if currentStep === 'gitlab-setup'}
        <!-- GitLab Setup Wizard -->
        <div class="mb-6">
          <div class="flex items-center justify-between mb-6">
            <h2 class="text-xl font-semibold text-gray-900 dark:text-gray-100">GitLab Setup</h2>
            <button
              on:click={goBack}
              class="text-sm text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-200 flex items-center"
            >
              <Icon icon="mdi:arrow-left" class="mr-1" width="16" />
              Back
            </button>
          </div>

          <!-- GitLab Steps Progress -->
          <div class="mb-8">
            <div class="flex items-center justify-between mb-4">
              {#each [
                {step: 'select-group', index: 0, label: '1'},
                {step: 'select-repo', index: 1, label: '2'},
                {step: 'add-bot', index: 2, label: '3'},
                {step: 'configure-webhook', index: 3, label: '4'},
                {step: 'push-test', index: 4, label: '5'},
                {step: 'configure-variables', index: 5, label: '6'},
                {step: 'add-pipeline', index: 6, label: '7'},
                {step: 'success', index: 7, label: '8'}
              ] as stepInfo}
                <div class="flex items-center {stepInfo.index < 7 ? 'flex-1' : ''}">
                  <div class="flex items-center justify-center w-8 h-8 rounded-full text-sm font-medium
                              {currentGitLabStep === stepInfo.step ? 'bg-blue-600 text-white' : 
                               (stepInfo.step === 'select-group' && gitlabStepCompleted['select-group']) ||
                               (stepInfo.step === 'select-repo' && gitlabStepCompleted['select-repo']) ||
                               (stepInfo.step === 'add-bot' && gitlabStepCompleted['add-bot']) ||
                               (stepInfo.step === 'configure-webhook' && gitlabStepCompleted['configure-webhook']) ||
                               (stepInfo.step === 'push-test' && gitlabStepCompleted['push-test']) ||
                               (stepInfo.step === 'configure-variables' && gitlabStepCompleted['configure-variables']) ||
                               (stepInfo.step === 'add-pipeline' && gitlabStepCompleted['add-pipeline'])
                               ? 'bg-green-600 text-white' : 
                               'bg-gray-200 dark:bg-gray-600 text-gray-600 dark:text-gray-400'}">
                    {#if (stepInfo.step === 'select-group' && gitlabStepCompleted['select-group']) ||
                         (stepInfo.step === 'select-repo' && gitlabStepCompleted['select-repo']) ||
                         (stepInfo.step === 'add-bot' && gitlabStepCompleted['add-bot']) ||
                         (stepInfo.step === 'configure-webhook' && gitlabStepCompleted['configure-webhook']) ||
                         (stepInfo.step === 'push-test' && gitlabStepCompleted['push-test']) ||
                         (stepInfo.step === 'configure-variables' && gitlabStepCompleted['configure-variables']) ||
                         (stepInfo.step === 'add-pipeline' && gitlabStepCompleted['add-pipeline'])}
                      <Icon icon="mdi:check" class="text-white" width="16" />
                    {:else}
                      {stepInfo.label}
                    {/if}
                  </div>
                  {#if stepInfo.index < 7}
                    <div class="flex-1 h-1 mx-2 {
                      (stepInfo.step === 'select-group' && gitlabStepCompleted['select-group']) ||
                      (stepInfo.step === 'select-repo' && gitlabStepCompleted['select-repo']) ||
                      (stepInfo.step === 'add-bot' && gitlabStepCompleted['add-bot']) ||
                      (stepInfo.step === 'configure-webhook' && gitlabStepCompleted['configure-webhook']) ||
                      (stepInfo.step === 'push-test' && gitlabStepCompleted['push-test']) ||
                      (stepInfo.step === 'configure-variables' && gitlabStepCompleted['configure-variables']) ||
                      (stepInfo.step === 'add-pipeline' && gitlabStepCompleted['add-pipeline'])
                      ? 'bg-green-600' : 'bg-gray-200 dark:bg-gray-600'}"></div>
                  {/if}
                </div>
              {/each}
            </div>
            <div class="text-center text-sm text-gray-500 dark:text-gray-400">
              Step {['select-group', 'select-repo', 'add-bot', 'configure-webhook', 'push-test', 'configure-variables', 'add-pipeline', 'success'].indexOf(currentGitLabStep) + 1} of 8
            </div>
          </div>

          <!-- GitLab Step Content -->
          {#if currentGitLabStep === 'select-group'}
            <div class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-6">
              <div class="flex items-start">
                <div class="flex-shrink-0">
                  <div class="w-10 h-10 bg-blue-600 rounded-lg flex items-center justify-center">
                    <Icon icon="mdi:account-group" class="text-white" width="20" />
                  </div>
                </div>
                <div class="ml-4 flex-1">
                  <h3 class="text-lg font-semibold text-blue-900 dark:text-blue-100 mb-2">Select GitLab Group</h3>
                  <p class="text-blue-800 dark:text-blue-200 mb-4">
                    Choose the GitLab group where you want to connect your repository.
                  </p>
                  
                  {#if isLoadingGitLabSetupGroups}
                    <div class="flex items-center justify-center p-8">
                      <div class="animate-spin rounded-full h-6 w-6 border-b-2 border-blue-600"></div>
                    </div>
                  {:else if gitlabSetupGroupsError}
                    <div class="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4 mb-4">
                      <p class="text-red-800 dark:text-red-200 text-sm">{gitlabSetupGroupsError}</p>
                    </div>
                    <div class="flex items-center space-x-3">
                      <button
                        on:click={loadGitLabSetupGroups}
                        class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg text-sm font-medium"
                      >
                        Retry
                      </button>
                    </div>
                  {:else if gitlabGroups.length === 0}
                    <div class="bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg p-4 mb-4">
                      <p class="text-yellow-800 dark:text-yellow-200 text-sm">
                        No GitLab groups found. You need to be a member of a GitLab group to connect repositories.
                      </p>
                    </div>
                  {:else}
                    <div class="max-h-60 overflow-y-auto border border-blue-200 dark:border-blue-700 rounded-lg mb-4">
                      {#each gitlabGroups as group}
                        <button
                          on:click={() => selectGitLabGroup(group)}
                          class="w-full text-left p-3 border-b border-blue-100 dark:border-blue-800 last:border-b-0 hover:bg-blue-50 dark:hover:bg-blue-900/30 {selectedGitLabGroup?.id === group.id ? 'bg-blue-100 dark:bg-blue-900/50' : ''}"
                        >
                          <div class="flex items-center justify-between">
                            <div>
                              <div class="font-medium text-gray-900 dark:text-gray-100">{group.name}</div>
                            </div>
                            {#if selectedGitLabGroup?.id === group.id}
                              <Icon icon="mdi:check-circle" class="text-blue-600" width="20" />
                            {/if}
                          </div>
                        </button>
                      {/each}
                    </div>
                    
                    {#if selectedGitLabGroup}
                      <div class="flex items-center space-x-3">
                        <button
                          on:click={() => markGitLabStepComplete('select-group')}
                          class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg text-sm font-medium"
                        >
                          Continue with {selectedGitLabGroup.name}
                        </button>
                      </div>
                    {/if}
                  {/if}
                </div>
              </div>
            </div>

          {:else if currentGitLabStep === 'select-repo'}
            <div class="bg-green-50 dark:bg-green-900/20 rounded-lg p-6">
              <div class="flex items-start">
                <div class="flex-shrink-0">
                  <div class="w-10 h-10 bg-green-600 rounded-lg flex items-center justify-center">
                    <Icon icon="mdi:source-repository" class="text-white" width="20" />
                  </div>
                </div>
                <div class="ml-4 flex-1">
                  <h3 class="text-lg font-semibold text-green-900 dark:text-green-100 mb-2">Select Repository</h3>
                  <p class="text-green-800 dark:text-green-200 mb-4">
                    Choose the repository where you want to enable Terrateam automation.
                  </p>
                  
                  {#if selectedGitLabGroup}
                    <div class="bg-green-100 dark:bg-green-900/30 rounded-lg p-3 mb-4 border border-green-200 dark:border-green-700">
                      <div class="flex items-center">
                        <Icon icon="mdi:account-group" class="text-green-600 mr-2" width="16" />
                        <span class="text-green-800 dark:text-green-200 font-medium">{selectedGitLabGroup.name}</span>
                      </div>
                    </div>
                    
                    <div class="bg-white dark:bg-gray-800 rounded-lg p-4 mb-4 border border-green-200 dark:border-green-700">
                      <h4 class="text-sm font-medium text-gray-900 dark:text-gray-100 mb-3">Add Repository</h4>
                      <div class="space-y-3">
                        <div>
                          <label for="gitlab-project-name" class="block text-sm text-gray-700 dark:text-gray-300 mb-1">
                            Enter your repository name
                          </label>
                          <div class="flex items-center space-x-2">
                            <div class="flex-1 flex items-center">
                              <span class="px-3 py-2 bg-gray-100 dark:bg-gray-700 border border-r-0 border-gray-300 dark:border-gray-600 rounded-l-lg text-gray-600 dark:text-gray-400 text-sm">
                                {selectedGitLabGroup?.name}/
                              </span>
                              <input
                                id="gitlab-project-name"
                                type="text"
                                bind:value={manualGitLabProject}
                                placeholder="my-terraform-repo"
                                class="flex-1 px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-r-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100 placeholder-gray-500 dark:placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-green-500 focus:border-transparent"
                                on:keypress={(e) => {
                                  if (e.key === 'Enter' && manualGitLabProject.trim()) {
                                    addGitLabProject();
                                  }
                                }}
                              />
                            </div>
                            <button
                              on:click={addGitLabProject}
                              disabled={!manualGitLabProject.trim() || isAddingGitLabProject}
                              class="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:bg-gray-300 disabled:cursor-not-allowed text-sm font-medium"
                            >
                              {isAddingGitLabProject ? 'Adding...' : 'Continue'}
                            </button>
                          </div>
                        </div>
                      </div>
                    </div>
                  {/if}


                  <div class="flex items-center space-x-3 mt-4">
                    <button
                      on:click={() => goToGitLabStep('select-group')}
                      class="border border-gray-300 text-gray-600 dark:text-gray-400 px-4 py-2 rounded-lg text-sm font-medium hover:bg-gray-50 dark:hover:bg-gray-700"
                    >
                      Go Back
                    </button>
                  </div>
                </div>
              </div>
            </div>

          {:else if currentGitLabStep === 'add-bot'}
            <div class="bg-green-50 dark:bg-green-900/20 rounded-lg p-6">
              <div class="flex items-start">
                <div class="flex-shrink-0">
                  <div class="flex items-center justify-center w-10 h-10 bg-green-100 dark:bg-green-900/30 rounded-lg">
                    <Icon icon="mdi:robot" class="text-green-600 dark:text-green-400" width="20" />
                  </div>
                </div>
                <div class="ml-4 flex-1">
                  <h3 class="text-lg font-medium text-green-900 dark:text-green-100 mb-2">
                    Add Terrateam Bot
                  </h3>
                  <p class="text-green-800 dark:text-green-200 mb-4">
                    Add the Terrateam bot to the <strong>{selectedGitLabGroup?.name || 'selected'}</strong> group. This bot will manage Terraform operations and provide feedback on merge requests.
                  </p>

                  <div class="bg-green-100 dark:bg-green-900/30 rounded-lg p-4 mb-4">
                    <h4 class="font-medium text-green-900 dark:text-green-100 mb-2">Instructions:</h4>
                    <ol class="list-decimal list-inside space-y-1 text-sm text-green-800 dark:text-green-200">
                      <li>
                        <a 
                          href="https://gitlab.com/groups/{selectedGitLabGroup?.name || ''}/-/group_members" 
                          target="_blank"
                          rel="noopener noreferrer"
                          class="inline-flex items-center font-medium text-green-700 dark:text-green-300 underline hover:text-green-600 dark:hover:text-green-200"
                        >
                          Open your group members page
                          <Icon icon="mdi:open-in-new" class="ml-1" width="16" />
                        </a>
                      </li>
                      <li>Click <strong>Invite members</strong></li>
                      <li>Add user: <code class="bg-green-200 dark:bg-green-800 px-1 rounded">@{gitlabBotUsername || 'terrateam-bot'}</code></li>
                      <li>Set role to <strong>Developer</strong> or higher</li>
                      <li>Click <strong>Invite</strong></li>
                    </ol>
                  </div>

                  {#if gitlabBotError}
                    <div class="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-700 rounded-lg p-4 mb-4">
                      <div class="flex items-start">
                        <Icon icon="mdi:alert-circle" class="text-red-600 dark:text-red-400 mr-2 mt-0.5" width="20" />
                        <p class="text-sm text-red-800 dark:text-red-200">{gitlabBotError}</p>
                      </div>
                    </div>
                  {/if}

                  <div class="flex items-center space-x-3">
                    <button
                      on:click={verifyBotAdded}
                      disabled={checkingGitLabBot}
                      class="bg-green-600 hover:bg-green-700 text-white px-4 py-2 rounded-lg text-sm font-medium disabled:opacity-50 disabled:cursor-not-allowed flex items-center"
                    >
                      {#if checkingGitLabBot}
                        <svg class="w-4 h-4 mr-2 animate-spin" fill="none" viewBox="0 0 24 24">
                          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"></path>
                        </svg>
                        Checking...
                      {:else}
                        <Icon icon="mdi:check" class="mr-2" width="16" />
                        Verify Bot Added
                      {/if}
                    </button>
                    <button
                      on:click={() => markGitLabStepComplete('add-bot')}
                      class="border border-green-600 text-green-600 dark:text-green-400 px-4 py-2 rounded-lg text-sm font-medium hover:bg-green-50 dark:hover:bg-green-900/30"
                    >
                      Skip Verification
                    </button>
                    <button
                      on:click={() => goToGitLabStep('select-repo')}
                      class="border border-gray-300 text-gray-600 dark:text-gray-400 px-4 py-2 rounded-lg text-sm font-medium hover:bg-gray-50 dark:hover:bg-gray-700"
                    >
                      Go Back
                    </button>
                  </div>
                </div>
              </div>
            </div>

          {:else if currentGitLabStep === 'configure-webhook'}
            <div class="bg-yellow-50 dark:bg-yellow-900/20 rounded-lg p-6">
              <div class="flex items-start">
                <div class="flex-shrink-0">
                  <div class="flex items-center justify-center w-10 h-10 bg-yellow-100 dark:bg-yellow-900/30 rounded-lg">
                    <Icon icon="mdi:webhook" class="text-yellow-600 dark:text-yellow-400" width="20" />
                  </div>
                </div>
                <div class="ml-4 flex-1">
                  <h3 class="text-lg font-medium text-yellow-900 dark:text-yellow-100 mb-2">
                    Configure Webhook
                  </h3>
                  <p class="text-yellow-800 dark:text-yellow-200 mb-4">
                    Add a webhook to your project so Terrateam can respond to merge requests and code changes.
                  </p>

                  <div class="bg-yellow-100 dark:bg-yellow-900/30 rounded-lg p-4 mb-4">
                    <h4 class="font-medium text-yellow-900 dark:text-yellow-100 mb-2">Instructions:</h4>
                    <ol class="list-decimal list-inside space-y-2 text-sm text-yellow-800 dark:text-yellow-200">
                      <li>
                        <a 
                          href="https://gitlab.com/{selectedGitLabGroup?.name || ''}/{manualGitLabProject || ''}/-/hooks" 
                          target="_blank"
                          rel="noopener noreferrer"
                          class="inline-flex items-center font-medium text-yellow-700 dark:text-yellow-300 underline hover:text-yellow-600 dark:hover:text-yellow-200"
                        >
                          Open your project webhooks
                          <Icon icon="mdi:open-in-new" class="ml-1" width="16" />
                        </a>
                      </li>
                      <li>Click <strong>Add new webhook</strong></li>
                      <li>URL: <code class="bg-yellow-200 dark:bg-yellow-800 px-1 rounded break-all">{webhookUrl || 'Loading...'}</code></li>
                      <li>Secret token: <code class="bg-yellow-200 dark:bg-yellow-800 px-1 rounded break-all">{webhookSecret || 'Loading...'}</code></li>
                      <li>Enable these triggers:
                        <ul class="list-disc list-inside ml-4 mt-1">
                          <li>Push events</li>
                          <li>Comments</li>
                          <li>Merge request events</li>
                        </ul>
                      </li>
                      <li>Click <strong>Add webhook</strong></li>
                    </ol>
                  </div>

                  {#if webhookVerificationError}
                    <div class="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-700 rounded-lg p-4 mb-4">
                      <div class="flex items-start">
                        <Icon icon="mdi:alert-circle" class="text-red-600 dark:text-red-400 mr-2 mt-0.5" width="20" />
                        <p class="text-sm text-red-800 dark:text-red-200">{webhookVerificationError}</p>
                      </div>
                    </div>
                  {/if}

                  <div class="flex items-center space-x-3">
                    <button
                      on:click={verifyWebhook}
                      disabled={checkingWebhook}
                      class="bg-yellow-600 hover:bg-yellow-700 text-white px-4 py-2 rounded-lg text-sm font-medium disabled:opacity-50 disabled:cursor-not-allowed flex items-center"
                    >
                      {#if checkingWebhook}
                        <svg class="w-4 h-4 mr-2 animate-spin" fill="none" viewBox="0 0 24 24">
                          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"></path>
                        </svg>
                        Checking...
                      {:else}
                        <Icon icon="mdi:check" class="mr-2" width="16" />
                        Verify Webhook
                      {/if}
                    </button>
                    <button
                      on:click={() => markGitLabStepComplete('configure-webhook')}
                      class="border border-yellow-600 text-yellow-600 dark:text-yellow-400 px-4 py-2 rounded-lg text-sm font-medium hover:bg-yellow-50 dark:hover:bg-yellow-900/30"
                    >
                      Skip Verification
                    </button>
                  </div>
                </div>
              </div>
            </div>

          {:else if currentGitLabStep === 'push-test'}
            <div class="bg-indigo-50 dark:bg-indigo-900/20 rounded-lg p-6">
              <div class="flex items-start">
                <div class="flex-shrink-0">
                  <div class="flex items-center justify-center w-10 h-10 bg-indigo-100 dark:bg-indigo-900/30 rounded-lg">
                    <Icon icon="mdi:test-tube" class="text-indigo-600 dark:text-indigo-400" width="20" />
                  </div>
                </div>
                <div class="ml-4 flex-1">
                  <h3 class="text-lg font-semibold text-indigo-900 dark:text-indigo-100 mb-2">Test Webhook Connection</h3>
                  <p class="text-indigo-800 dark:text-indigo-200 mb-4">
                    Let's verify the webhook is properly configured by triggering a test event.
                  </p>
                  
                  <div class="bg-white dark:bg-gray-800 rounded-lg p-4 mb-4 border border-indigo-200 dark:border-indigo-700">
                    <h4 class="font-medium text-gray-900 dark:text-gray-100 mb-3">Instructions:</h4>
                    <ol class="list-decimal list-inside space-y-2 text-sm text-gray-700 dark:text-gray-300">
                      <li>
                        Navigate to your repository settings
                        {#if selectedGitLabGroup && manualGitLabProject}
                          <div class="mt-1 ml-5">
                            <a 
                              href="https://gitlab.com/{selectedGitLabGroup.name}/{manualGitLabProject}/-/hooks" 
                              target="_blank"
                              rel="noopener noreferrer"
                              class="inline-flex items-center text-indigo-600 dark:text-indigo-400 hover:underline text-xs"
                            >
                              Open Webhooks Settings
                              <Icon icon="mdi:open-in-new" class="ml-1" width="12" />
                            </a>
                          </div>
                        {/if}
                      </li>
                      <li>Find the Terrateam webhook in the list</li>
                      <li>Click <strong>Test</strong> → <strong>Push events</strong></li>
                      <li>Wait for the test to complete</li>
                    </ol>
                  </div>

                  {#if pushTestError}
                    <div class="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4 mb-4">
                      <p class="text-red-800 dark:text-red-200 text-sm">{pushTestError}</p>
                    </div>
                  {/if}

                  {#if pushTestSuccess}
                    <div class="bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg p-4 mb-4">
                      <p class="text-green-800 dark:text-green-200 text-sm">✅ Webhook received! Your installation is now active.</p>
                    </div>
                  {/if}

                  <div class="bg-indigo-100 dark:bg-indigo-900/30 rounded-lg p-3 mb-4">
                    <div class="flex items-start">
                      <Icon icon="mdi:information" class="text-indigo-600 mr-2 mt-0.5" width="16" />
                      <div class="text-sm text-indigo-800 dark:text-indigo-200">
                        <strong>Why this step?</strong> Testing the webhook ensures it's properly configured and can communicate with Terrateam.
                      </div>
                    </div>
                  </div>

                  <div class="flex items-center space-x-3">
                    <button
                      on:click={() => checkPushTestStatus()}
                      disabled={isCheckingPushTest}
                      class="bg-indigo-600 hover:bg-indigo-700 disabled:bg-gray-400 text-white px-4 py-2 rounded-lg text-sm font-medium"
                    >
                      {isCheckingPushTest ? 'Checking...' : 'Check Status'}
                    </button>
                    <button
                      on:click={() => markGitLabStepComplete('push-test')}
                      class="border border-gray-300 text-gray-600 dark:text-gray-400 px-4 py-2 rounded-lg text-sm font-medium hover:bg-gray-50 dark:hover:bg-gray-700"
                    >
                      Skip for Now
                    </button>
                  </div>
                </div>
              </div>
            </div>

          {:else if currentGitLabStep === 'configure-variables'}
            <div class="bg-purple-50 dark:bg-purple-900/20 rounded-lg p-6">
              <div class="flex items-start">
                <div class="flex-shrink-0">
                  <div class="w-10 h-10 bg-purple-600 rounded-lg flex items-center justify-center">
                    <Icon icon="mdi:cog" class="text-white" width="20" />
                  </div>
                </div>
                <div class="ml-4 flex-1">
                  <h3 class="text-lg font-semibold text-purple-900 dark:text-purple-100 mb-2">Configure CI/CD Variables</h3>
                  <p class="text-purple-800 dark:text-purple-200 mb-4">
                    Configure project settings to allow Terrateam to pass credentials securely to your Terraform runs.
                  </p>
                  
                  <div class="bg-white dark:bg-gray-800 rounded-lg p-4 mb-4 border border-purple-200 dark:border-purple-700">
                    <div class="space-y-3 text-sm">
                      <div class="flex items-start">
                        <Icon icon="mdi:numeric-1-circle" class="text-purple-600 mr-2 mt-0.5" width="16" />
                        <div>
                          <div class="text-gray-700 dark:text-gray-300">Go to your GitLab project CI/CD settings</div>
                          <div class="text-gray-500 dark:text-gray-400 text-xs">
                            {#if selectedGitLabGroup && manualGitLabProject}
                              <a 
                                href="https://gitlab.com/{selectedGitLabGroup.name}/{manualGitLabProject}/-/settings/ci_cd" 
                                target="_blank"
                                rel="noopener noreferrer"
                                class="inline-flex items-center text-purple-600 dark:text-purple-400 hover:underline"
                              >
                                Project → Settings → CI/CD
                                <Icon icon="mdi:open-in-new" class="ml-1" width="12" />
                              </a>
                            {:else}
                              Project → Settings → CI/CD
                            {/if}
                          </div>
                        </div>
                      </div>
                      
                      <div class="flex items-start">
                        <Icon icon="mdi:numeric-2-circle" class="text-purple-600 mr-2 mt-0.5" width="16" />
                        <div>
                          <div class="text-gray-700 dark:text-gray-300">Expand the <strong>Variables</strong> section</div>
                        </div>
                      </div>
                      
                      <div class="flex items-start">
                        <Icon icon="mdi:numeric-3-circle" class="text-purple-600 mr-2 mt-0.5" width="16" />
                        <div>
                          <div class="text-gray-700 dark:text-gray-300">Find <strong>"Minimum role to use pipeline variables"</strong></div>
                        </div>
                      </div>
                      
                      <div class="flex items-start">
                        <Icon icon="mdi:numeric-4-circle" class="text-purple-600 mr-2 mt-0.5" width="16" />
                        <div>
                          <div class="text-gray-700 dark:text-gray-300">Select <strong>Developer</strong> from the dropdown</div>
                          <div class="text-gray-500 dark:text-gray-400 text-xs">This allows the Terrateam bot (@{gitlabBotUsername || 'terrateam-bot'}) to use pipeline variables</div>
                        </div>
                      </div>
                      
                      <div class="flex items-start">
                        <Icon icon="mdi:numeric-5-circle" class="text-purple-600 mr-2 mt-0.5" width="16" />
                        <div>
                          <div class="text-gray-700 dark:text-gray-300">Click <strong>Save changes</strong></div>
                        </div>
                      </div>
                    </div>
                  </div>

                  <div class="bg-amber-50 dark:bg-amber-900/30 rounded p-3 mb-4">
                    <div class="flex items-start">
                      <Icon icon="mdi:shield-lock" class="text-amber-600 mr-2 mt-0.5" width="16" />
                      <div class="text-sm text-amber-800 dark:text-amber-200">
                        <strong>Important:</strong> This allows the Terrateam bot (@{gitlabBotUsername || 'terrateam-bot'}) to run pipelines with variables containing your cloud credentials and Terraform configuration.
                      </div>
                    </div>
                  </div>

                  <div class="flex items-center space-x-3">
                    <button
                      on:click={() => markGitLabStepComplete('configure-variables')}
                      class="bg-purple-600 hover:bg-purple-700 text-white px-4 py-2 rounded-lg text-sm font-medium"
                    >
                      CI/CD Configured
                    </button>
                    <button
                      on:click={() => goToGitLabStep('configure-webhook')}
                      class="border border-gray-300 text-gray-600 dark:text-gray-400 px-4 py-2 rounded-lg text-sm font-medium hover:bg-gray-50 dark:hover:bg-gray-700"
                    >
                      Go Back
                    </button>
                  </div>
                </div>
              </div>
            </div>

          {:else if currentGitLabStep === 'add-pipeline'}
            <div class="bg-teal-50 dark:bg-teal-900/20 rounded-lg p-6">
              <div class="flex items-start">
                <div class="flex-shrink-0">
                  <div class="w-10 h-10 bg-teal-600 rounded-lg flex items-center justify-center">
                    <Icon icon="mdi:file-code" class="text-white" width="20" />
                  </div>
                </div>
                <div class="ml-4 flex-1">
                  <h3 class="text-lg font-semibold text-teal-900 dark:text-teal-100 mb-2">Add .gitlab-ci.yml File</h3>
                  <p class="text-teal-800 dark:text-teal-200 mb-4">
                    Add the Terrateam CI/CD template to your repository to enable Terraform automation.
                  </p>
                  
                  <div class="bg-white dark:bg-gray-800 rounded-lg p-4 mb-4 border border-teal-200 dark:border-teal-700">
                    <div class="space-y-3 text-sm">
                      <div class="flex items-start">
                        <Icon icon="mdi:numeric-1-circle" class="text-teal-600 mr-2 mt-0.5" width="16" />
                        <div>
                          <div class="text-gray-700 dark:text-gray-300">
                            Create or edit <code class="bg-gray-100 dark:bg-gray-700 px-2 py-1 rounded">.gitlab-ci.yml</code> in 
                            {#if selectedGitLabGroup && manualGitLabProject}
                              <a 
                                href="https://gitlab.com/{selectedGitLabGroup.name}/{manualGitLabProject}" 
                                target="_blank"
                                rel="noopener noreferrer"
                                class="inline-flex items-center font-medium text-teal-700 dark:text-teal-300 underline hover:text-teal-600 dark:hover:text-teal-200"
                              >
                                your repository root
                                <Icon icon="mdi:open-in-new" class="ml-1" width="14" />
                              </a>
                            {:else}
                              your repository root
                            {/if}
                          </div>
                        </div>
                      </div>
                      
                      <div class="flex items-start">
                        <Icon icon="mdi:numeric-2-circle" class="text-teal-600 mr-2 mt-0.5" width="16" />
                        <div>
                          <div class="text-gray-700 dark:text-gray-300">Add this content:</div>
                          <div class="mt-2 bg-gray-50 dark:bg-gray-700 p-3 rounded border relative">
                            <button
                              on:click={() => {
                                const yamlContent = `# .gitlab-ci.yml - Using the terrateam template

include:
  - project: 'terrateam-io/terrateam-template'
    file: 'terrateam-template.yml'

stages:
  - terrateam

terrateam_job:
  extends: .terrateam_template`;
                                navigator.clipboard.writeText(yamlContent);
                                copiedYaml = true;
                                setTimeout(() => copiedYaml = false, 2000);
                              }}
                              class="absolute top-2 right-2 px-2 py-1 {copiedYaml ? 'bg-green-600' : 'bg-teal-600 hover:bg-teal-700'} text-white rounded text-xs flex items-center transition-colors"
                            >
                              <Icon icon={copiedYaml ? "mdi:check" : "mdi:content-copy"} class="mr-1" width="14" />
                              {copiedYaml ? 'Copied!' : 'Copy'}
                            </button>
                            <pre class="text-xs text-gray-800 dark:text-gray-200 overflow-x-auto pr-16"><code># .gitlab-ci.yml - Using the terrateam template

include:
  - project: 'terrateam-io/terrateam-template'
    file: 'terrateam-template.yml'

stages:
  - terrateam

terrateam_job:
  extends: .terrateam_template</code></pre>
                          </div>
                        </div>
                      </div>
                      
                      <div class="flex items-start">
                        <Icon icon="mdi:numeric-3-circle" class="text-teal-600 mr-2 mt-0.5" width="16" />
                        <div>
                          <div class="text-gray-700 dark:text-gray-300">Commit and push to your default branch</div>
                        </div>
                      </div>
                    </div>
                  </div>

                  <div class="bg-blue-50 dark:bg-blue-900/30 rounded p-3 mb-4">
                    <div class="flex items-start">
                      <Icon icon="mdi:information" class="text-blue-600 mr-2 mt-0.5" width="16" />
                      <div class="text-sm text-blue-800 dark:text-blue-200">
                        <strong>Note:</strong> If you already have a .gitlab-ci.yml file, you'll need to integrate these rules with your existing jobs. Contact support for help with complex setups.
                      </div>
                    </div>
                  </div>

                  <div class="flex items-center space-x-3">
                    <button
                      on:click={() => markGitLabStepComplete('add-pipeline')}
                      class="bg-teal-600 hover:bg-teal-700 text-white px-4 py-2 rounded-lg text-sm font-medium"
                    >
                      Pipeline Added
                    </button>
                    <button
                      on:click={() => goToGitLabStep('configure-variables')}
                      class="border border-gray-300 text-gray-600 dark:text-gray-400 px-4 py-2 rounded-lg text-sm font-medium hover:bg-gray-50 dark:hover:bg-gray-700"
                    >
                      Go Back
                    </button>
                  </div>
                </div>
              </div>
            </div>

          {:else if currentGitLabStep === 'success'}
            <div class="text-center py-12">
              <div class="inline-flex items-center justify-center w-16 h-16 bg-green-100 dark:bg-green-900/30 rounded-full mb-6">
                <Icon icon="mdi:check-circle" class="text-green-600 dark:text-green-400" width="32" />
              </div>
              <h3 class="text-2xl font-semibold text-gray-900 dark:text-gray-100 mb-2 flex items-center justify-center">
                <Icon icon="mdi:party-popper" class="text-purple-600 dark:text-purple-400 mr-2" width="28" />
                GitLab Setup Complete!
              </h3>
              <p class="text-gray-600 dark:text-gray-400 mb-6">
                Terrateam is now configured for <strong>{selectedGitLabGroup?.name || 'your GitLab group'}</strong>. You're ready to automate your Terraform workflows!
              </p>
              
              <div class="bg-green-50 dark:bg-green-900/20 rounded-lg p-6 mb-6 max-w-md mx-auto">
                <h4 class="font-semibold text-green-900 dark:text-green-100 mb-3">What you've set up:</h4>
                <div class="space-y-2 text-sm text-green-800 dark:text-green-200">
                  <div class="flex items-center">
                    <Icon icon="mdi:check" class="text-green-600 mr-2 flex-shrink-0" width="16" />
                    GitLab group selected and configured
                  </div>
                  <div class="flex items-center">
                    <Icon icon="mdi:check" class="text-green-600 mr-2 flex-shrink-0" width="16" />
                    Terrateam bot added as Developer
                  </div>
                  <div class="flex items-center">
                    <Icon icon="mdi:check" class="text-green-600 mr-2 flex-shrink-0" width="16" />
                    Webhook configured for events
                  </div>
                  <div class="flex items-center">
                    <Icon icon="mdi:check" class="text-green-600 mr-2 flex-shrink-0" width="16" />
                    CI/CD variables configured
                  </div>
                  <div class="flex items-center">
                    <Icon icon="mdi:check" class="text-green-600 mr-2 flex-shrink-0" width="16" />
                    GitLab CI pipeline added
                  </div>
                </div>
              </div>

              <div class="flex justify-center space-x-4">
                <button
                  on:click={() => window.location.hash = '#/repositories'}
                  class="bg-gray-600 hover:bg-gray-700 text-white px-6 py-2 rounded-lg text-sm font-medium"
                >
                  View Repositories
                </button>
                <button
                  on:click={() => openExternalLink('https://docs.terrateam.io/')}
                  class="border border-gray-300 text-gray-600 dark:text-gray-400 px-6 py-2 rounded-lg text-sm font-medium hover:bg-gray-50 dark:hover:bg-gray-700"
                >
                  Read Documentation
                </button>
              </div>
            </div>
          {/if}
        </div>
      {/if}
      
    </div>

    <!-- Help Section -->
    <div class="text-center mt-8">
      <p class="text-sm text-gray-500 dark:text-gray-400">
        Need help? Check the 
        <button 
          on:click={() => openExternalLink('https://docs.terrateam.io/')}
          class="text-blue-600 dark:text-blue-400 hover:underline"
        >
          documentation
        </button> 
        or get help on 
        <button 
          on:click={() => openExternalLink('https://terrateam.io/slack')}
          class="text-blue-600 dark:text-blue-400 hover:underline"
        >
          Slack
        </button>.
      </p>
    </div>
    
  </div>
</PageLayout>
