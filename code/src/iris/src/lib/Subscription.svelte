<script lang="ts">
  // Auth handled by PageLayout
  import { selectedInstallation, installations, installationsLoading } from './stores';
  
  import { analytics } from './analytics';
  import { currentVCSProvider } from './stores';
  import { VCS_PROVIDERS } from './vcs/providers';
  import { isSaasBillingMode } from './utils/environment';
  import PageLayout from './components/layout/PageLayout.svelte';
  import Button from './components/ui/Button.svelte';
  import Card from './components/ui/Card.svelte';
  import LoadingSpinner from './components/ui/LoadingSpinner.svelte';
  import { WEB3_FORMS_ACCESS_KEY, EXTERNAL_URLS } from './constants';

  // Get current VCS provider terminology
  $: currentProvider = $currentVCSProvider || 'github';
  $: terminology = VCS_PROVIDERS[currentProvider]?.terminology || VCS_PROVIDERS.github.terminology;
  
  // Helper functions for proper capitalization and articles
  $: articleForOrganization = terminology.organization.match(/^[aeiou]/i) ? 'an' : 'a';

  // Make subscription mode reactive
  $: isInSaasMode = isSaasBillingMode();

  function handleManageBilling(): void {
    analytics.trackBillingAction('manage_billing_clicked');
    window.open('https://billing.stripe.com/p/login/00geXngL2cQR0YofYY', '_blank');
  }

  function formatTrialEndDate(trialEndsAt?: string): string {
    if (!trialEndsAt) return '';
    
    const endDate = new Date(trialEndsAt);
    const now = new Date();
    const diffMs = endDate.getTime() - now.getTime();
    const diffDays = Math.ceil(diffMs / (1000 * 60 * 60 * 24));
    
    if (diffDays <= 0) {
      return 'Trial has ended';
    } else if (diffDays === 1) {
      return 'Trial ends tomorrow';
    } else if (diffDays <= 7) {
      return `Trial ends in ${diffDays} days`;
    } else {
      return `Trial ends on ${endDate.toLocaleDateString()}`;
    }
  }


  // Trial extension modal state
  let showExtendTrialModal = false;
  let trialExtensionForm = {
    name: '',
    email: '',
    organization: '',
    reason: '',
    additionalDays: '14'
  };

  // Form submission state
  let isSubmittingTrialExtension = false;
  let trialExtensionError: string | null = null;
  let trialExtensionSuccess = false;

  function openExtendTrialModal(): void {
    // Pre-populate form with available data
    if ($selectedInstallation) {
      trialExtensionForm.organization = $selectedInstallation.name;
    }
    showExtendTrialModal = true;
    // Prevent body scroll when modal is open
    document.body.classList.add('modal-open');
  }

  function closeExtendTrialModal(): void {
    showExtendTrialModal = false;
    trialExtensionSuccess = false;
    trialExtensionError = null;
    // Restore body scroll
    document.body.classList.remove('modal-open');
  }

  async function submitTrialExtension(): Promise<void> {
    if (isSubmittingTrialExtension) return;
    
    isSubmittingTrialExtension = true;
    trialExtensionError = null;
    trialExtensionSuccess = false;

    try {
      // Track trial extension request
      analytics.trackTrialExtensionRequest({
        organization: trialExtensionForm.organization,
        additional_days: trialExtensionForm.additionalDays,
        reason_length: trialExtensionForm.reason.length
      });

      // Build detailed message
      const message = `
Trial Extension Request Details:

Name: ${trialExtensionForm.name}
Email: ${trialExtensionForm.email}
${terminology.organization}: ${trialExtensionForm.organization}
Requested Extension: ${trialExtensionForm.additionalDays} days
Current Trial End Date: ${$selectedInstallation?.trial_ends_at || 'N/A'}

Reason for Extension:
${trialExtensionForm.reason}

---
This request was submitted via the Terrateam Iris trial extension form.
      `.trim();

      // Create JSON object for Web3Forms
      const formDataToSubmit = {
        access_key: WEB3_FORMS_ACCESS_KEY,
        subject: `[Trial Extension Request] ${trialExtensionForm.organization}`,
        email: trialExtensionForm.email,
        from_name: trialExtensionForm.name,
        message: message,
        reply_to: trialExtensionForm.email
      };

      const response = await fetch(EXTERNAL_URLS.WEB3_FORMS_ENDPOINT, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: JSON.stringify(formDataToSubmit)
      });

      const result = await response.json();

      if (response.status === 200 && result.success) {
        trialExtensionSuccess = true;
        
        // Reset form
        trialExtensionForm = {
          name: '',
          email: '',
          organization: $selectedInstallation?.name || '',
          reason: '',
          additionalDays: '14'
        };
      } else {
        throw new Error(result.message || 'Failed to submit trial extension request');
      }
    } catch (error) {
      console.error('Trial extension submission error:', error);
      trialExtensionError = error instanceof Error ? error.message : 'Failed to submit trial extension request';
    } finally {
      isSubmittingTrialExtension = false;
    }
  }

  // Close modal on Escape key
  function handleKeydown(event: KeyboardEvent) {
    if (event.key === 'Escape' && showExtendTrialModal) {
      closeExtendTrialModal();
    }
  }
</script>

<svelte:window on:keydown={handleKeydown} />

<PageLayout 
  activeItem="billing" 
  title="Subscription"
  subtitle={isInSaasMode ? 
    ($selectedInstallation ? 
      `Manage billing for ${$selectedInstallation.name}` : 
      "Manage your subscription and billing") :
    "Enterprise options for self-hosted users"}
>
  <div class="max-w-6xl mx-auto">
    
    <!-- Self-hosted Environment Message -->
    {#if !isInSaasMode}
      <div class="text-center py-16">
        <!-- Hero Icon -->
        <div class="inline-flex items-center justify-center w-24 h-24 rounded-full bg-gradient-to-br from-blue-100 to-indigo-100 dark:from-blue-900/30 dark:to-indigo-900/30 mb-8">
          <svg class="w-12 h-12 text-blue-600 dark:text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z" />
          </svg>
        </div>
        
        <!-- Hero Content -->
        <h1 class="text-4xl font-bold text-gray-900 dark:text-gray-100 mb-4">
          Self-Hosted Terrateam
        </h1>
        <p class="text-xl text-gray-600 dark:text-gray-400 mb-12 max-w-3xl mx-auto">
          You're running the open-source version. Unlock enterprise features with centralized configuration, 
          advanced security, and dedicated support.
        </p>
        
        <!-- Plan Comparison -->
        <div class="grid lg:grid-cols-2 gap-8 max-w-5xl mx-auto mb-12">
          
          <!-- Current Plan -->
          <Card padding="lg" class="text-left relative">
            <div class="mb-6">
              <div class="flex items-center mb-4">
                <div class="w-12 h-12 bg-green-100 dark:bg-green-900/30 rounded-lg flex items-center justify-center mr-4">
                  <svg class="w-6 h-6 text-green-600 dark:text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                  </svg>
                </div>
                <div>
                  <h3 class="text-2xl font-bold text-gray-900 dark:text-gray-100">Open Source</h3>
                  <p class="text-sm text-gray-500 dark:text-gray-400">What you're using now</p>
                </div>
              </div>
            </div>
            
            <div class="space-y-4">
              <div class="flex items-start">
                <svg class="w-5 h-5 text-green-500 mr-3 mt-1 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                </svg>
                <span class="text-gray-700 dark:text-gray-300">Core Terraform automation</span>
              </div>
              <div class="flex items-start">
                <svg class="w-5 h-5 text-green-500 mr-3 mt-1 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                </svg>
                <span class="text-gray-700 dark:text-gray-300">Full infrastructure control</span>
              </div>
              <div class="flex items-start">
                <svg class="w-5 h-5 text-green-500 mr-3 mt-1 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                </svg>
                <span class="text-gray-700 dark:text-gray-300">Private environment hosting</span>
              </div>
              <div class="flex items-start">
                <svg class="w-5 h-5 text-green-500 mr-3 mt-1 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                </svg>
                <span class="text-gray-700 dark:text-gray-300">Community support</span>
              </div>
            </div>
          </Card>

          <!-- Enterprise Plan -->
          <Card padding="lg" class="text-left relative bg-gradient-to-br from-blue-50 to-indigo-50 dark:from-blue-900/20 dark:to-indigo-900/20 border-2 border-blue-200 dark:border-blue-700">
            <!-- Popular Badge -->
            <div class="absolute -top-3 left-6">
              <span class="bg-blue-600 text-white px-4 py-1 rounded-full text-xs font-semibold uppercase tracking-wide">
                Recommended
              </span>
            </div>
            
            <div class="mb-6 pt-2">
              <div class="flex items-center mb-4">
                <div class="w-12 h-12 bg-blue-100 dark:bg-blue-900/30 rounded-lg flex items-center justify-center mr-4">
                  <svg class="w-6 h-6 text-blue-600 dark:text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
                  </svg>
                </div>
                <div>
                  <h3 class="text-2xl font-bold text-gray-900 dark:text-gray-100">Enterprise Self-Hosted</h3>
                  <p class="text-sm text-blue-600 dark:text-blue-400 font-medium">Scale with confidence</p>
                </div>
              </div>
            </div>
            
            <div class="space-y-4">
              <div class="flex items-start">
                <svg class="w-5 h-5 text-blue-500 mr-3 mt-1 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                </svg>
                <span class="text-gray-700 dark:text-gray-300"><strong>Everything in Open Source</strong>, plus:</span>
              </div>
              <div class="flex items-start">
                <svg class="w-5 h-5 text-blue-500 mr-3 mt-1 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                </svg>
                <span class="text-gray-700 dark:text-gray-300">Centralized configuration management</span>
              </div>
              <div class="flex items-start">
                <svg class="w-5 h-5 text-blue-500 mr-3 mt-1 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                </svg>
                <span class="text-gray-700 dark:text-gray-300">Role-based access control (RBAC)</span>
              </div>
              <div class="flex items-start">
                <svg class="w-5 h-5 text-blue-500 mr-3 mt-1 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                </svg>
                <span class="text-gray-700 dark:text-gray-300">Policy gatekeeper & compliance</span>
              </div>
              <div class="flex items-start">
                <svg class="w-5 h-5 text-blue-500 mr-3 mt-1 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                </svg>
                <span class="text-gray-700 dark:text-gray-300">24/7 support & SLA guarantees</span>
              </div>
              <div class="flex items-start">
                <svg class="w-5 h-5 text-blue-500 mr-3 mt-1 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                </svg>
                <span class="text-gray-700 dark:text-gray-300">SSO & enterprise integrations</span>
              </div>
            </div>
          </Card>
        </div>
        
        <!-- Primary Actions -->
        <div class="flex flex-col sm:flex-row items-center justify-center gap-4 mb-12">
          <Button 
            variant="accent" 
            size="lg"
            on:click={() => window.open('https://terrateam.io/contact', '_blank')}
            class="px-8 py-3"
          >
            <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
            </svg>
            Get Enterprise Pricing
          </Button>
          <Button 
            variant="outline" 
            size="lg"
            on:click={() => window.open('https://docs.terrateam.io/self-hosted', '_blank')}
            class="px-8 py-3"
          >
            <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.746 0 3.332.477 4.5 1.253v13C19.832 18.477 18.246 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
            </svg>
            View Documentation
          </Button>
        </div>
        
        <!-- Contact Info -->
        <div class="text-center pt-8 border-t border-gray-200 dark:border-gray-700">
          <p class="text-gray-500 dark:text-gray-400 mb-4">
            Questions about enterprise features or need implementation help?
          </p>
          <Button 
            variant="outline" 
            size="md"
            on:click={() => window.location.hash = '#/support'}
          >
            <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            Contact Our Team
          </Button>
          
        </div>
      </div>
    {:else}
    <!-- Trial Warning Alert -->
    {#if $selectedInstallation?.trial_ends_at}
      {@const endDate = new Date($selectedInstallation.trial_ends_at)}
      {@const now = new Date()}
      {@const diffMs = endDate.getTime() - now.getTime()}
      {@const diffDays = Math.ceil(diffMs / (1000 * 60 * 60 * 24))}
      {#if diffDays <= 7 && diffDays > 0}
        <Card padding="lg" class="mb-6 border-2 border-orange-200 bg-orange-50">
          <div class="flex items-start space-x-4">
            <div class="flex-shrink-0">
              <div class="w-10 h-10 bg-orange-100 rounded-full flex items-center justify-center">
                <svg class="w-5 h-5 text-orange-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
                </svg>
              </div>
            </div>
            <div class="flex-1">
              <h3 class="text-lg font-semibold text-orange-800 mb-2">
                {diffDays === 1 ? 'Trial Ends Tomorrow' : `Trial Ends in ${diffDays} Days`}
              </h3>
              <p class="text-orange-700 mb-4">
                Your trial for <strong>{$selectedInstallation.name}</strong> expires on {endDate.toLocaleDateString()}. 
                Upgrade your subscription to continue using Terrateam without interruption.
              </p>
              <div class="flex space-x-3">
                <Button 
                  variant="accent" 
                  size="md"
                  on:click={handleManageBilling}
                >
                  <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
                  </svg>
                  Upgrade Now
                </Button>
                <Button 
                  variant="outline" 
                  size="md"
                  on:click={openExtendTrialModal}
                  class="border-orange-300 text-orange-700 hover:bg-orange-100 dark:hover:bg-gray-600 dark:hover:border-gray-600"
                >
                  <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                  Extend Trial
                </Button>
              </div>
            </div>
          </div>
        </Card>
      {:else if diffDays <= 0}
        <Card padding="lg" class="mb-6 border-2 border-red-200 bg-red-50">
          <div class="flex items-start space-x-4">
            <div class="flex-shrink-0">
              <div class="w-10 h-10 bg-red-100 rounded-full flex items-center justify-center">
                <svg class="w-5 h-5 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
            </div>
            <div class="flex-1">
              <h3 class="text-lg font-semibold text-red-800 mb-2">Trial Has Ended</h3>
              <p class="text-red-700 mb-4">
                Your trial for <strong>{$selectedInstallation.name}</strong> has expired. 
                Please upgrade your subscription to continue using Terrateam.
              </p>
              <div class="flex space-x-3">
                <Button 
                  variant="accent" 
                  size="md"
                  on:click={handleManageBilling}
                >
                  <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
                  </svg>
                  Upgrade Subscription
                </Button>
                <Button 
                  variant="outline" 
                  size="md"
                  on:click={openExtendTrialModal}
                  class="border-red-300 text-red-700 hover:bg-red-100 dark:hover:bg-gray-600 dark:hover:border-gray-600"
                >
                  <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                  Request Extension
                </Button>
              </div>
            </div>
          </div>
        </Card>
      {/if}
    {/if}

    <!-- Main Content Area -->
    <div class="space-y-8">
      
      <!-- Current Subscription Overview -->
      {#if !$selectedInstallation && $installationsLoading}
        <div class="text-center py-12">
          <LoadingSpinner size="lg" />
          <p class="text-gray-600 dark:text-gray-400 mt-4">Loading subscription information...</p>
        </div>
      {:else if !$selectedInstallation && !$installationsLoading && $installations.length === 0}
        <!-- Demo Mode / No Installations - Show Payment Upgrade -->
        <div class="text-center py-12">
          <div class="inline-flex items-center justify-center w-20 h-20 rounded-full bg-gradient-to-br from-blue-100 to-indigo-100 dark:from-blue-900/30 dark:to-indigo-900/30 mb-6">
            <svg class="w-10 h-10 text-blue-600 dark:text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z" />
            </svg>
          </div>
          
          <h1 class="text-3xl font-bold text-gray-900 dark:text-gray-100 mb-4">
            Ready to Get Started?
          </h1>
          <p class="text-xl text-gray-600 dark:text-gray-400 mb-8 max-w-2xl mx-auto">
            Connect your {VCS_PROVIDERS[currentProvider].displayName} {terminology.organization.toLowerCase()} to unlock Terrateam's powerful Terraform automation features.
          </p>
        </div>
        
        <!-- Upgrade Section -->
        <Card padding="lg" class="mb-8 border-2 border-blue-200 bg-gradient-to-br from-blue-50 to-indigo-50 dark:from-blue-900/20 dark:to-indigo-900/20">
          <div class="text-center">
            <h2 class="text-2xl font-bold text-gray-900 dark:text-gray-100 mb-4">
              Start Your Terrateam Journey
            </h2>
            <p class="text-gray-600 dark:text-gray-400 mb-8">
              Choose the plan that fits your team's needs. All plans include a free trial to get you started.
            </p>
            
            <!-- Pricing Options -->
            <div class="grid md:grid-cols-2 gap-6 max-w-4xl mx-auto mb-8">
              <!-- Monthly Plan -->
              <Card padding="lg" class="border-2 border-blue-300">
                <div class="text-center">
                  <h3 class="text-xl font-bold text-gray-900 dark:text-gray-100 mb-2">Basic Plan</h3>
                  <div class="mb-4">
                    <span class="text-3xl font-bold text-blue-600">$149</span>
                    <span class="text-gray-600 dark:text-gray-400">/month</span>
                  </div>
                  <ul class="text-left space-y-2 mb-6">
                    <li class="flex items-center">
                      <svg class="w-4 h-4 text-green-500 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                      </svg>
                      <span class="text-gray-700 dark:text-gray-300">Unlimited repositories</span>
                    </li>
                    <li class="flex items-center">
                      <svg class="w-4 h-4 text-green-500 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                      </svg>
                      <span class="text-gray-700 dark:text-gray-300">Advanced workflow automation</span>
                    </li>
                    <li class="flex items-center">
                      <svg class="w-4 h-4 text-green-500 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                      </svg>
                      <span class="text-gray-700 dark:text-gray-300">Team collaboration features</span>
                    </li>
                    <li class="flex items-center">
                      <svg class="w-4 h-4 text-green-500 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                      </svg>
                      <span class="text-gray-700 dark:text-gray-300">Slack Connect support</span>
                    </li>
                  </ul>
                  <Button 
                    variant="primary" 
                    size="lg"
                    on:click={() => window.open('https://buy.stripe.com/6oE15h4Yp1BU4V2fZ8', '_blank')}
                    class="w-full"
                  >
                    Start Monthly Plan
                  </Button>
                </div>
              </Card>
              
              <!-- Yearly Plan -->
              <Card padding="lg" class="border-2 border-green-300 relative">
                <!-- Best Value Badge -->
                <div class="absolute -top-3 left-1/2 transform -translate-x-1/2">
                  <span class="bg-green-600 text-white px-4 py-1 rounded-full text-xs font-semibold uppercase tracking-wide">
                    Best Value
                  </span>
                </div>
                <div class="text-center pt-2">
                  <h3 class="text-xl font-bold text-gray-900 dark:text-gray-100 mb-2">Basic Plan</h3>
                  <div class="mb-2">
                    <span class="text-3xl font-bold text-green-600">$134</span>
                    <span class="text-gray-600 dark:text-gray-400">/month</span>
                  </div>
                  <p class="text-sm text-green-600 font-medium mb-4">Billed annually • Save 10%</p>
                  <ul class="text-left space-y-2 mb-6">
                    <li class="flex items-center">
                      <svg class="w-4 h-4 text-green-500 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                      </svg>
                      <span class="text-gray-700 dark:text-gray-300">Everything in monthly plan</span>
                    </li>
                    <li class="flex items-center">
                      <svg class="w-4 h-4 text-green-500 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                      </svg>
                      <span class="text-gray-700 dark:text-gray-300"><strong>10% discount</strong> ($1,608/year)</span>
                    </li>
                    <li class="flex items-center">
                      <svg class="w-4 h-4 text-green-500 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                      </svg>
                      <span class="text-gray-700 dark:text-gray-300">Priority email support</span>
                    </li>
                    <li class="flex items-center">
                      <svg class="w-4 h-4 text-green-500 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                      </svg>
                      <span class="text-gray-700 dark:text-gray-300">Annual planning session</span>
                    </li>
                  </ul>
                  <Button 
                    variant="accent" 
                    size="lg"
                    on:click={() => window.open('https://buy.stripe.com/aEU9BN3Ul0xQ87e3cn', '_blank')}
                    class="w-full"
                  >
                    Start Yearly Plan
                  </Button>
                </div>
              </Card>
            </div>
            
            <!-- Enterprise Option -->
            <div class="text-center">
              <p class="text-gray-600 dark:text-gray-400 mb-4">
                Need enterprise features, custom integrations, dedicated support, or self-hosted options?
              </p>
              <Button 
                variant="outline" 
                size="lg"
                on:click={() => window.open('https://terrateam.io/contact', '_blank')}
                class="hover:text-current"
              >
                <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
                </svg>
                Contact Sales for Enterprise
              </Button>
            </div>
          </div>
        </Card>
        
        <!-- Getting Started Steps -->
        <Card padding="lg" class="bg-gray-50 dark:bg-gray-800">
          <div class="text-center">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-6">How to Get Started</h3>
            <div class="grid md:grid-cols-3 gap-6">
              <div class="text-center">
                <div class="inline-flex items-center justify-center w-12 h-12 rounded-full bg-blue-100 dark:bg-blue-900/30 mb-4">
                  <span class="text-blue-600 dark:text-blue-400 font-bold">1</span>
                </div>
                <h4 class="font-semibold text-gray-900 dark:text-gray-100 mb-2">Choose Your Plan</h4>
                <p class="text-sm text-gray-600 dark:text-gray-400">Select monthly or yearly billing</p>
              </div>
              <div class="text-center">
                <div class="inline-flex items-center justify-center w-12 h-12 rounded-full bg-blue-100 dark:bg-blue-900/30 mb-4">
                  <span class="text-blue-600 dark:text-blue-400 font-bold">2</span>
                </div>
                <h4 class="font-semibold text-gray-900 dark:text-gray-100 mb-2">Connect {VCS_PROVIDERS[currentProvider].displayName}</h4>
                <p class="text-sm text-gray-600 dark:text-gray-400">Install Terrateam in your {terminology.organization.toLowerCase()}</p>
              </div>
              <div class="text-center">
                <div class="inline-flex items-center justify-center w-12 h-12 rounded-full bg-blue-100 dark:bg-blue-900/30 mb-4">
                  <span class="text-blue-600 dark:text-blue-400 font-bold">3</span>
                </div>
                <h4 class="font-semibold text-gray-900 dark:text-gray-100 mb-2">Start Automating</h4>
                <p class="text-sm text-gray-600 dark:text-gray-400">Configure workflows and deploy</p>
              </div>
            </div>
          </div>
        </Card>
      {:else if !$selectedInstallation && !$installationsLoading && $installations.length > 0}
        <!-- User has installations but none selected -->
        <div class="text-center py-12">
          <div class="inline-flex items-center justify-center w-20 h-20 rounded-full bg-gradient-to-br from-orange-100 to-yellow-100 dark:from-orange-900/30 dark:to-yellow-900/30 mb-6">
            <svg class="w-10 h-10 text-orange-600 dark:text-orange-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
            </svg>
          </div>
          
          <h1 class="text-3xl font-bold text-gray-900 dark:text-gray-100 mb-4">
            Select {articleForOrganization} {terminology.organization}
          </h1>
          <p class="text-xl text-gray-600 dark:text-gray-400 mb-8 max-w-2xl mx-auto">
            Choose {articleForOrganization} {terminology.organization.toLowerCase()} from the sidebar to view its subscription and billing information.
          </p>
          
          <Button 
            variant="outline" 
            size="lg"
            on:click={() => window.location.hash = '#/getting-started'}
          >
            <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
            </svg>
            Go to Getting Started
          </Button>
        </div>
      {:else if $selectedInstallation}
        <!-- Header Section -->
        <div class="bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg px-8 py-12 mb-8">
          <div class="max-w-4xl mx-auto">
            <div class="flex items-center justify-between">
              <div>
                <h1 class="text-3xl font-bold text-gray-900 dark:text-gray-100 mb-2">
                  Subscription
                </h1>
                <p class="text-lg text-gray-600 dark:text-gray-400">
                  Manage billing and subscription for {$selectedInstallation.name}
                </p>
              </div>
              <div class="text-right">
                <div class="mb-4">
                  <div class="inline-flex items-center px-4 py-2 rounded-lg bg-white dark:bg-gray-800 shadow-sm border border-gray-200 dark:border-gray-700">
                    <div class="w-2 h-2 bg-green-400 rounded-full mr-2"></div>
                    <span class="text-sm font-medium text-gray-900 dark:text-gray-100">{$selectedInstallation.account_status}</span>
                  </div>
                </div>
                {#if $selectedInstallation.trial_ends_at}
                  <div>
                    <div class="inline-flex items-center px-3 py-1 rounded-full bg-orange-100 dark:bg-orange-900/30 border border-orange-200 dark:border-orange-700">
                      <svg class="w-3 h-3 text-orange-600 dark:text-orange-400 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                      </svg>
                      <span class="text-xs font-medium text-orange-700 dark:text-orange-300">{formatTrialEndDate($selectedInstallation.trial_ends_at)}</span>
                    </div>
                  </div>
                {/if}
              </div>
            </div>
          </div>
        </div>

        <!-- Current Plan Overview -->
        <div class="max-w-4xl mx-auto mb-8">
          <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 overflow-hidden">
            <!-- Plan Header -->
            <div class="bg-gray-50 dark:bg-gray-800/50 px-6 py-4 border-b border-gray-200 dark:border-gray-700">
              <div class="flex items-center justify-between">
                <div>
                  <h2 class="text-xl font-semibold text-gray-900 dark:text-gray-100">Current Plan</h2>
                  <p class="text-sm text-gray-600 dark:text-gray-400">Active subscription details</p>
                </div>
                <div class="flex items-center space-x-3">
                  <div class="text-right">
                    <p class="text-2xl font-bold text-gray-900 dark:text-gray-100">{$selectedInstallation.tier.name}</p>
                    <p class="text-sm text-gray-500 dark:text-gray-400">Plan</p>
                  </div>
                </div>
              </div>
            </div>

            <!-- Plan Details -->
            <div class="p-6">
              <div class="grid md:grid-cols-3 gap-6">
                <div class="space-y-1">
                  <p class="text-sm font-medium text-gray-500 dark:text-gray-400">{terminology.organization}</p>
                  <p class="text-base font-semibold text-gray-900 dark:text-gray-100">{$selectedInstallation.name}</p>
                </div>
                <div class="space-y-1">
                  <p class="text-sm font-medium text-gray-500 dark:text-gray-400">Installation ID</p>
                  <p class="text-base font-mono text-gray-900 dark:text-gray-100">{$selectedInstallation.id}</p>
                </div>
                {#if $selectedInstallation.trial_ends_at}
                  <div class="space-y-1">
                    <p class="text-sm font-medium text-gray-500 dark:text-gray-400">Trial Ends</p>
                    <p class="text-base font-semibold text-gray-900 dark:text-gray-100">{$selectedInstallation.trial_ends_at}</p>
                  </div>
                {/if}
              </div>
              
              {#if $selectedInstallation.tier.features && Object.keys($selectedInstallation.tier.features).length > 0}
                <div class="mt-6 pt-6 border-t border-gray-200 dark:border-gray-700">
                  <h3 class="text-sm font-medium text-gray-500 dark:text-gray-400 mb-3">Plan Features</h3>
                  <div class="grid md:grid-cols-2 gap-4">
                    {#each Object.entries($selectedInstallation.tier.features) as [featureKey, featureValue]}
                      <div class="space-y-1">
                        <p class="text-sm font-medium text-gray-500 dark:text-gray-400">{featureKey}</p>
                        <p class="text-base font-mono text-gray-900 dark:text-gray-100">
                          {featureValue === null ? 'null' : (typeof featureValue === 'string' && featureValue === '') ? '""' : featureValue}
                        </p>
                      </div>
                    {/each}
                  </div>
                </div>
              {/if}
            </div>
          </div>
        </div>
          
        <!-- Primary Action -->
        <div class="flex flex-col sm:flex-row items-center justify-center gap-4">
            <Button 
              variant="accent" 
              size="lg"
              on:click={handleManageBilling}
              class="px-8 py-3"
            >
              <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
              </svg>
              Manage Billing
            </Button>
            {#if $selectedInstallation.trial_ends_at}
              <Button 
                variant="outline" 
                size="lg"
                on:click={openExtendTrialModal}
                class="px-8 py-3 dark:hover:bg-gray-600 dark:hover:border-gray-600"
              >
                <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                Extend Trial
              </Button>
            {/if}
        </div>
        
        <!-- Payment Upgrade Section for Non-Paid Accounts -->
        {#if $selectedInstallation.account_status}
          <Card padding="lg" class="mb-8 border-2 border-blue-200 bg-gradient-to-br from-blue-50 to-indigo-50 dark:from-blue-900/20 dark:to-indigo-900/20">
            <div class="text-center">
              <h2 class="text-2xl font-bold text-gray-900 dark:text-gray-100 mb-4">
                Upgrade Your Plan
              </h2>
              <p class="text-gray-600 dark:text-gray-400 mb-8">
                Get unlimited access to all Terrateam features with our Basic plan.
              </p>
              
              <!-- Pricing Options -->
              <div class="grid md:grid-cols-2 gap-6 max-w-4xl mx-auto mb-8">
                <!-- Monthly Plan -->
                <Card padding="lg" class="border-2 border-blue-300">
                  <div class="text-center">
                    <h3 class="text-xl font-bold text-gray-900 dark:text-gray-100 mb-2">Basic Plan</h3>
                    <div class="mb-4">
                      <span class="text-3xl font-bold text-blue-600">$149</span>
                      <span class="text-gray-600 dark:text-gray-400">/month</span>
                    </div>
                    <ul class="text-left space-y-2 mb-6">
                      <li class="flex items-center">
                        <svg class="w-4 h-4 text-green-500 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                        </svg>
                        <span class="text-gray-700 dark:text-gray-300">Unlimited repositories</span>
                      </li>
                      <li class="flex items-center">
                        <svg class="w-4 h-4 text-green-500 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                        </svg>
                        <span class="text-gray-700 dark:text-gray-300">Advanced workflow automation</span>
                      </li>
                      <li class="flex items-center">
                        <svg class="w-4 h-4 text-green-500 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                        </svg>
                        <span class="text-gray-700 dark:text-gray-300">Team collaboration features</span>
                      </li>
                      <li class="flex items-center">
                        <svg class="w-4 h-4 text-green-500 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                        </svg>
                        <span class="text-gray-700 dark:text-gray-300">Slack Connect support</span>
                      </li>
                    </ul>
                    <Button 
                      variant="primary" 
                      size="lg"
                      on:click={() => window.open('https://buy.stripe.com/6oE15h4Yp1BU4V2fZ8', '_blank')}
                      class="w-full hover:text-black"
                    >
                      Upgrade to Monthly
                    </Button>
                  </div>
                </Card>
                
                <!-- Yearly Plan -->
                <Card padding="lg" class="border-2 border-green-300 relative">
                  <!-- Best Value Badge -->
                  <div class="absolute -top-3 left-1/2 transform -translate-x-1/2">
                    <span class="bg-green-600 text-white px-4 py-1 rounded-full text-xs font-semibold uppercase tracking-wide">
                      Best Value
                    </span>
                  </div>
                  <div class="text-center pt-2">
                    <h3 class="text-xl font-bold text-gray-900 dark:text-gray-100 mb-2">Basic Plan</h3>
                    <div class="mb-2">
                      <span class="text-3xl font-bold text-green-600">$134</span>
                      <span class="text-gray-600 dark:text-gray-400">/month</span>
                    </div>
                    <p class="text-sm text-green-600 font-medium mb-4">Billed annually • Save 10%</p>
                    <ul class="text-left space-y-2 mb-6">
                      <li class="flex items-center">
                        <svg class="w-4 h-4 text-green-500 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                        </svg>
                        <span class="text-gray-700 dark:text-gray-300">Everything in monthly plan</span>
                      </li>
                      <li class="flex items-center">
                        <svg class="w-4 h-4 text-green-500 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                        </svg>
                        <span class="text-gray-700 dark:text-gray-300"><strong>10% discount</strong> ($1,608/year)</span>
                      </li>
                      <li class="flex items-center">
                        <svg class="w-4 h-4 text-green-500 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                        </svg>
                        <span class="text-gray-700 dark:text-gray-300">Priority Slack Connect support</span>
                      </li>
                      <li class="flex items-center">
                        <svg class="w-4 h-4 text-green-500 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                        </svg>
                        <span class="text-gray-700 dark:text-gray-300">Annual planning session</span>
                      </li>
                    </ul>
                    <Button 
                      variant="accent" 
                      size="lg"
                      on:click={() => window.open('https://buy.stripe.com/aEU9BN3Ul0xQ87e3cn', '_blank')}
                      class="w-full"
                    >
                      Upgrade to Yearly
                    </Button>
                  </div>
                </Card>
              </div>
              
              <!-- Enterprise Option -->
              <div class="text-center">
                <p class="text-gray-600 dark:text-gray-400 mb-4">
                  Need enterprise features, custom integrations, dedicated support, or self-hosted options?
                </p>
                <Button 
                  variant="outline" 
                  size="lg"
                  on:click={() => window.open('https://terrateam.io/contact', '_blank')}
                  class="hover:text-black"
                >
                  <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
                  </svg>
                  Contact Sales for Enterprise
                </Button>
              </div>
            </div>
          </Card>
        {/if}
      {:else}
        <!-- Fallback case -->
        <div class="text-center py-12">
          <LoadingSpinner size="lg" />
          <p class="text-gray-600 dark:text-gray-400 mt-4">Loading subscription information...</p>
        </div>
      {/if}

      <!-- Quick Actions Grid -->
      <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 md:gap-6">
        <!-- View Invoices -->
        <Card padding="lg" class="text-center hover:shadow-lg transition-shadow">
          <div class="inline-flex items-center justify-center w-12 h-12 rounded-lg bg-blue-100 dark:bg-blue-900/30 mb-4">
            <svg class="w-6 h-6 text-blue-600 dark:text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
            </svg>
          </div>
          <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-2">View Invoices</h3>
          <p class="text-gray-600 dark:text-gray-400 text-sm">Access and download billing invoices and receipts</p>
        </Card>

        <!-- Update Payment -->
        <Card padding="lg" class="text-center hover:shadow-lg transition-shadow">
          <div class="inline-flex items-center justify-center w-12 h-12 rounded-lg bg-green-100 dark:bg-green-900/30 mb-4">
            <svg class="w-6 h-6 text-green-600 dark:text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z" />
            </svg>
          </div>
          <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-2">Payment Methods</h3>
          <p class="text-gray-600 dark:text-gray-400 text-sm">Update credit card and payment preferences</p>
        </Card>

        <!-- Plan Details -->
        <Card padding="lg" class="text-center hover:shadow-lg transition-shadow">
          <div class="inline-flex items-center justify-center w-12 h-12 rounded-lg bg-purple-100 dark:bg-purple-900/30 mb-4">
            <svg class="w-6 h-6 text-purple-600 dark:text-purple-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" />
            </svg>
          </div>
          <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-2">Plan Details</h3>
          <p class="text-gray-600 dark:text-gray-400 text-sm">View usage limits and renewal information</p>
        </Card>
      </div>

      <!-- Support Section -->
      <Card padding="lg" class="bg-gray-50 dark:bg-gray-800 border-gray-200 dark:border-gray-700">
        <div class="text-center">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-2">Need Help?</h3>
          <p class="text-gray-600 dark:text-gray-400 mb-6">
            Questions about your subscription or billing? Our support team is here to help.
          </p>
          <Button 
            variant="outline" 
            size="md"
            on:click={() => window.location.hash = '#/support'}
            class="hover:text-black"
          >
            <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            Contact Support
          </Button>
        </div>
      </Card>

    </div>
    {/if} <!-- End production SaaS check -->
  </div>
</PageLayout>

<!-- Trial Extension Modal - Only in production SaaS -->
{#if showExtendTrialModal && isInSaasMode}
  <!-- svelte-ignore a11y-click-events-have-key-events -->
  <!-- svelte-ignore a11y-no-static-element-interactions -->
  <div 
    class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50" 
    on:click={closeExtendTrialModal}
    on:keydown={(e) => e.key === 'Escape' && closeExtendTrialModal()}
  >
    <div 
      class="bg-white dark:bg-gray-800 rounded-lg shadow-xl max-w-md w-full max-h-[90vh] overflow-y-auto" 
      role="dialog" 
      aria-modal="true" 
      aria-label="Request Trial Extension"
      tabindex="-1"
    >
      <div class="p-4 md:p-6">
        <!-- Modal Header -->
        <div class="flex items-center justify-between mb-6">
          <h3 class="text-xl font-semibold text-gray-900 dark:text-gray-100">Request Trial Extension</h3>
          <button
            on:click={closeExtendTrialModal}
            class="text-gray-400 hover:text-gray-600 dark:text-gray-500 dark:hover:text-gray-300 transition-colors"
          >
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <!-- Success Message -->
        {#if trialExtensionSuccess}
          <div class="bg-green-50 border border-green-200 rounded-lg p-4 mb-6">
            <div class="flex items-start">
              <svg class="w-5 h-5 text-green-400 mr-3 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              <div>
                <p class="font-medium text-green-800">Request submitted successfully!</p>
                <p class="text-sm text-green-700 mt-1">
                  Our team will review your trial extension request and contact you within 1 business day.
                </p>
              </div>
            </div>
          </div>
        {/if}

        <!-- Error Message -->
        {#if trialExtensionError}
          <div class="bg-red-50 border border-red-200 rounded-lg p-4 mb-6">
            <div class="flex items-start">
              <svg class="w-5 h-5 text-red-400 mr-3 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-2.694-.833-3.464 0L3.34 16.5c-.77.833.192 2.5 1.732 2.5z" />
              </svg>
              <div>
                <p class="font-medium text-red-800">Failed to submit request</p>
                <p class="text-sm text-red-700 mt-1">
                  {trialExtensionError}
                </p>
              </div>
            </div>
          </div>
        {/if}

        <!-- Form -->
        <form on:submit|preventDefault={submitTrialExtension} class="space-y-4">
          <!-- Name -->
          <div>
            <label for="name" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Full Name *</label>
            <input
              id="name"
              type="text"
              bind:value={trialExtensionForm.name}
              required
              disabled={isSubmittingTrialExtension}
              class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 disabled:bg-gray-100 dark:disabled:bg-gray-600 disabled:cursor-not-allowed"
              placeholder="Your full name"
            />
          </div>

          <!-- Email -->
          <div>
            <label for="email" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Email Address *</label>
            <input
              id="email"
              type="email"
              bind:value={trialExtensionForm.email}
              required
              disabled={isSubmittingTrialExtension}
              class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 disabled:bg-gray-100 dark:disabled:bg-gray-600 disabled:cursor-not-allowed"
              placeholder="your.email@company.com"
            />
          </div>

          <!-- {terminology.organization} -->
          <div>
            <label for="organization" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">{terminology.organization}</label>
            <input
              id="organization"
              type="text"
              bind:value={trialExtensionForm.organization}
              readonly
              class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-gray-50 dark:bg-gray-600 text-gray-600 dark:text-gray-300"
            />
          </div>

          <!-- Requested Extension -->
          <div>
            <label for="additionalDays" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Requested Extension</label>
            <select
              id="additionalDays"
              bind:value={trialExtensionForm.additionalDays}
              disabled={isSubmittingTrialExtension}
              class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 disabled:bg-gray-100 dark:disabled:bg-gray-600 disabled:cursor-not-allowed"
            >
              <option value="7">7 days</option>
              <option value="14">14 days</option>
              <option value="30">30 days</option>
              <option value="custom">Other (please specify in reason)</option>
            </select>
          </div>

          <!-- Reason -->
          <div>
            <label for="reason" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Reason for Extension *</label>
            <textarea
              id="reason"
              bind:value={trialExtensionForm.reason}
              required
              rows="4"
              disabled={isSubmittingTrialExtension}
              class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 disabled:bg-gray-100 dark:disabled:bg-gray-600 disabled:cursor-not-allowed"
              placeholder="Please explain why you need a trial extension and how you're evaluating Terrateam..."
            ></textarea>
            <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">
              Help us understand your evaluation timeline and requirements.
            </p>
          </div>

          <!-- Form Actions -->
          <div class="flex space-x-3 pt-4">
            <Button 
              type="submit"
              variant="accent" 
              size="md"
              disabled={isSubmittingTrialExtension}
              class="flex-1 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {#if isSubmittingTrialExtension}
                <svg class="w-4 h-4 mr-2 animate-spin" fill="none" viewBox="0 0 24 24">
                  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                  <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"></path>
                </svg>
                Submitting...
              {:else}
                <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8" />
                </svg>
                Submit Request
              {/if}
            </Button>
            <Button 
              type="button"
              variant="outline" 
              size="md"
              on:click={closeExtendTrialModal}
              class="dark:hover:bg-gray-600 dark:hover:border-gray-600"
            >
              Cancel
            </Button>
          </div>
        </form>

        <!-- Help Text -->
        <div class="mt-6 p-4 bg-blue-50 dark:bg-blue-900/20 rounded-lg">
          <div class="flex">
            <svg class="w-5 h-5 text-blue-600 dark:text-blue-400 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <div class="ml-3">
              <p class="text-sm text-blue-800 dark:text-blue-200">
                <strong>What happens next?</strong><br>
                Our team will review your request and contact you within 1 business day. 
                Trial extensions are typically approved for legitimate evaluation needs.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
{/if}
