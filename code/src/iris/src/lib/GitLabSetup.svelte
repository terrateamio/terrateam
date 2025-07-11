<script lang="ts">
  import { api } from './api';
  import type { GitLabGroup } from './types';
  import LoadingSpinner from './components/ui/LoadingSpinner.svelte';
  import Button from './components/ui/Button.svelte';
  import Card from './components/ui/Card.svelte';
  import ErrorMessage from './components/ui/ErrorMessage.svelte';
  import 'iconify-icon';

  export let onComplete: (groupId: number) => void = () => {};
  export let onCancel: () => void = () => {};

  type SetupStep = 'select-group' | 'add-user' | 'configure-webhook' | 'complete';
  
  let currentStep: SetupStep = 'select-group';
  let selectedGroup: GitLabGroup | null = null;
  let groups: GitLabGroup[] = [];
  let isLoadingGroups = true;
  let groupsError: string | null = null;
  
  // Bot user step state
  let botUsername = '';
  let isCheckingBotUser = false;
  let botUserVerified = false;
  let botCheckError: string | null = null;
  
  // Webhook step state
  let webhookUrl = '';
  let webhookSecret = '';
  let isCheckingWebhook = false;
  let webhookVerified = false;
  let webhookCheckError: string | null = null;

  // Load groups on mount
  async function loadGroups() {
    try {
      isLoadingGroups = true;
      groupsError = null;
      groups = await api.getGitLabGroups();
    } catch (error) {
      console.error('Failed to load GitLab groups:', error);
      groupsError = 'Failed to load groups. Please try again.';
    } finally {
      isLoadingGroups = false;
    }
  }

  // Load bot info when entering add-user step
  async function loadBotInfo() {
    try {
      const botInfo = await api.getGitLabUser();
      botUsername = botInfo.username;
    } catch (error) {
      console.error('Failed to load bot info:', error);
      botUsername = 'terrateam-bot'; // Fallback
    }
  }

  // Check if bot user has been added to the group
  async function checkBotUser() {
    if (!selectedGroup) return;
    
    try {
      isCheckingBotUser = true;
      botCheckError = null;
      botUserVerified = await api.checkGitLabGroupMembership(selectedGroup.id);
      
      if (!botUserVerified) {
        botCheckError = `The user ${botUsername} has not been added to the group yet. Please add them as a Developer.`;
      }
    } catch (error) {
      console.error('Failed to check bot membership:', error);
      botCheckError = 'Failed to verify bot user. Please try again.';
    } finally {
      isCheckingBotUser = false;
    }
  }

  // Load webhook configuration
  async function loadWebhookConfig() {
    if (!selectedGroup) return;
    
    try {
      const config = await api.getGitLabWebhookConfig(selectedGroup.id.toString());
      webhookUrl = config.webhook_url;
      webhookSecret = config.webhook_secret || '';
    } catch (error) {
      console.error('Failed to load webhook config:', error);
      // Set defaults if API fails
      webhookUrl = 'https://api.terrateam.io/webhook/gitlab';
      webhookSecret = 'Contact support for webhook secret';
    }
  }

  // Check if webhook is configured and active
  async function checkWebhook() {
    if (!selectedGroup) return;
    
    try {
      isCheckingWebhook = true;
      webhookCheckError = null;
      
      const config = await api.getGitLabWebhookConfig(selectedGroup.id.toString());
      webhookVerified = config.state === 'active';
      
      if (!webhookVerified) {
        webhookCheckError = 'Webhook is not active yet. Please test it with a Push Event in GitLab.';
      }
    } catch (error) {
      console.error('Failed to check webhook:', error);
      webhookCheckError = 'Failed to verify webhook. Please try again.';
    } finally {
      isCheckingWebhook = false;
    }
  }

  // Navigation functions
  function selectGroup(group: GitLabGroup) {
    selectedGroup = group;
    currentStep = 'add-user';
    loadBotInfo();
  }

  function goToWebhookStep() {
    currentStep = 'configure-webhook';
    loadWebhookConfig();
  }

  function completeSetup() {
    if (selectedGroup) {
      onComplete(selectedGroup.id);
    }
  }

  // Start by loading groups
  loadGroups();
</script>

<div class="max-w-4xl mx-auto">
  <!-- Progress Steps -->
  {#if currentStep !== 'select-group'}
    <div class="mb-8">
      <div class="flex items-center justify-between">
        {#each [
          { step: 'add-user', label: 'Add Bot User', icon: 'mdi:account-plus' },
          { step: 'configure-webhook', label: 'Configure Webhook', icon: 'mdi:webhook' }
        ] as stepInfo, index}
          <div class="flex items-center {index < 1 ? 'flex-1' : ''}">
            <div class="flex items-center">
              <div class="flex items-center justify-center w-10 h-10 rounded-full {
                currentStep === stepInfo.step ? 'bg-blue-600 text-white' :
                (stepInfo.step === 'add-user' && currentStep === 'configure-webhook')
                  ? 'bg-green-600 text-white' 
                  : 'bg-gray-300 dark:bg-gray-600 text-gray-600 dark:text-gray-400'
              }">
                <iconify-icon icon={stepInfo.icon} width="20"></iconify-icon>
              </div>
              <span class="ml-2 text-sm font-medium {
                currentStep === stepInfo.step ? 'text-gray-900 dark:text-gray-100' : 'text-gray-500 dark:text-gray-400'
              }">{stepInfo.label}</span>
            </div>
            {#if index < 1}
              <div class="flex-1 mx-4">
                <div class="h-1 bg-gray-300 dark:bg-gray-600 rounded-full">
                  <div class="h-1 rounded-full w-full {
                    (stepInfo.step === 'add-user' && currentStep === 'configure-webhook')
                      ? 'bg-green-600' 
                      : 'bg-transparent'
                  }"></div>
                </div>
              </div>
            {/if}
          </div>
        {/each}
      </div>
    </div>
  {/if}

  {#if currentStep === 'select-group'}
    <div class="text-center mb-8">
      <h1 class="text-3xl font-bold text-gray-900 dark:text-gray-100 mb-2">
        Terrateam on GitLab
      </h1>
      <p class="text-lg text-gray-600 dark:text-gray-400">
        Choose a group to install Terrateam
      </p>
    </div>

    {#if isLoadingGroups}
      <div class="flex justify-center py-12">
        <LoadingSpinner size="lg" />
      </div>
    {:else if groupsError}
      <ErrorMessage type="error" message={groupsError} />
      <div class="mt-4 flex justify-center">
        <Button variant="primary" on:click={loadGroups}>
          Try Again
        </Button>
      </div>
    {:else if groups.length === 0}
      <Card padding="lg">
        <div class="text-center">
          <iconify-icon icon="mdi:folder-alert-outline" class="text-6xl text-gray-400 mb-4"></iconify-icon>
          <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-2">
            No GitLab Groups Found
          </h3>
          <p class="text-gray-600 dark:text-gray-400 mb-4">
            You don't have access to any GitLab groups. Please create a group or get added to one first.
          </p>
          <Button variant="outline" on:click={onCancel}>
            Cancel
          </Button>
        </div>
      </Card>
    {:else}
      <div class="space-y-3">
        {#each groups as group}
          <Card 
            padding="md" 
            hover 
            clickable
            on:click={() => selectGroup(group)}
          >
            <div class="flex items-center justify-between">
              <div class="flex items-center space-x-3">
                <iconify-icon icon="mdi:folder-account" class="text-2xl text-blue-600"></iconify-icon>
                <div>
                  <h3 class="font-semibold text-gray-900 dark:text-gray-100">
                    {group.name}
                  </h3>
                </div>
              </div>
              <iconify-icon icon="mdi:chevron-right" class="text-gray-400"></iconify-icon>
            </div>
          </Card>
        {/each}
      </div>
      
      <div class="mt-6 flex justify-center">
        <Button variant="outline" on:click={onCancel}>
          Cancel
        </Button>
      </div>
    {/if}

  {:else if currentStep === 'add-user'}
    <div class="text-center mb-8">
      <h1 class="text-3xl font-bold text-gray-900 dark:text-gray-100 mb-2">
        Add the Terrateam user to the GitLab group
      </h1>
      <p class="text-lg text-gray-600 dark:text-gray-400">
        Add the user as a "Developer" role
      </p>
    </div>

    <Card padding="lg">
      <div class="space-y-6">
        <div class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-4">
          <h3 class="font-semibold text-blue-900 dark:text-blue-100 mb-2">
            Instructions:
          </h3>
          <ol class="list-decimal list-inside space-y-2 text-blue-800 dark:text-blue-200">
            <li>Go to your GitLab group</li>
            <li>Navigate to Project > Manage > Members</li>
            <li>Click "Invite members"</li>
            <li>Add the user: <code class="bg-blue-100 dark:bg-blue-800 px-2 py-1 rounded gitlab-code">{botUsername}</code></li>
            <li>Select "Developer" role</li>
            <li>Click "Invite"</li>
          </ol>
        </div>

        {#if selectedGroup}
          <div class="text-center">
            <p class="text-gray-700 dark:text-gray-300 mb-4">
              Add the user <strong>{botUsername}</strong> to the group <strong>{selectedGroup.name}</strong>
            </p>
          </div>
        {/if}

        {#if botCheckError}
          <ErrorMessage type="warning" message={botCheckError} />
        {/if}

        {#if botUserVerified}
          <div class="bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-700 rounded-lg p-4">
            <div class="flex items-center">
              <iconify-icon icon="mdi:check-circle" class="text-green-600 text-xl mr-2"></iconify-icon>
              <span class="text-green-800 dark:text-green-200">
                Bot user verified! Click Next to continue.
              </span>
            </div>
          </div>
        {/if}

        <div class="flex justify-center space-x-4">
          <Button 
            variant="primary" 
            on:click={checkBotUser}
            loading={isCheckingBotUser}
            disabled={isCheckingBotUser}
          >
            Check
          </Button>
          <Button 
            variant="accent" 
            on:click={goToWebhookStep}
            disabled={!botUserVerified}
          >
            Next
          </Button>
        </div>
      </div>
    </Card>

  {:else if currentStep === 'configure-webhook'}
    <div class="text-center mb-8">
      <h1 class="text-3xl font-bold text-gray-900 dark:text-gray-100 mb-2">
        Add the Terrateam webhook to your repository
      </h1>
      <p class="text-lg text-gray-600 dark:text-gray-400">
        Add the following webhook to all projects in this group that you want Terrateam to operate on
      </p>
    </div>

    <Card padding="lg">
      <div class="space-y-6">
        <div class="text-gray-700 dark:text-gray-300 mb-4">
          <p class="mb-2">
            Add the following webhook to all projects in this group that you want Terrateam to operate on.
          </p>
        </div>

        <div class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-4">
          <div class="space-y-3">
            <div>
              <div class="block text-sm font-medium text-blue-900 dark:text-blue-100 mb-1">
                URL:
              </div>
              <code class="block bg-blue-100 dark:bg-blue-800 px-3 py-2 rounded text-sm break-all gitlab-code">
                {webhookUrl}
              </code>
            </div>
            {#if webhookSecret}
              <div>
                <div class="block text-sm font-medium text-blue-900 dark:text-blue-100 mb-1">
                  Use the following webhook secret:
                </div>
                <code class="block bg-blue-100 dark:bg-blue-800 px-3 py-2 rounded text-sm break-all gitlab-code">
                  {webhookSecret}
                </code>
              </div>
            {/if}
          </div>
        </div>

        <div class="text-gray-700 dark:text-gray-300 mt-4">
          <p>
            After you have added the webhook, test the webhook with a Push Event then click the Check button to verify the webhook was received.
          </p>
        </div>

        {#if webhookCheckError}
          <ErrorMessage type="warning" message={webhookCheckError} />
        {/if}

        {#if webhookVerified}
          <div class="bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-700 rounded-lg p-4">
            <div class="flex items-center">
              <iconify-icon icon="mdi:check-circle" class="text-green-600 text-xl mr-2"></iconify-icon>
              <span class="text-green-800 dark:text-green-200">
                Webhook verified! Click Next to complete setup.
              </span>
            </div>
          </div>
        {/if}

        <div class="flex justify-center space-x-4">
          <Button 
            variant="primary" 
            on:click={checkWebhook}
            loading={isCheckingWebhook}
            disabled={isCheckingWebhook}
          >
            Check
          </Button>
          <Button 
            variant="accent" 
            on:click={completeSetup}
            disabled={!webhookVerified}
          >
            Complete Setup
          </Button>
        </div>
      </div>
    </Card>
  {/if}
</div>

