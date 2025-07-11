<script lang="ts">
  // Auth handled by PageLayout
  import PageLayout from './components/layout/PageLayout.svelte';
  import { WEB3_FORMS_ACCESS_KEY, EXTERNAL_URLS } from './constants';

  interface FormData {
    email: string;
    subject: string;
    message: string;
    priority: string;
  }

  let formData: FormData = {
    email: '',
    subject: '',
    message: '',
    priority: 'normal'
  };

  // Form submission state
  let isSubmitting = false;
  let submitError: string | null = null;
  let submitSuccess = false;

  // Tab state
  let activeTab: 'support' | 'community' | 'resources' | 'status' = 'support';

  function handleViewDocs(): void {
    window.open(EXTERNAL_URLS.DOCS, '_blank');
  }

  function handleJoinSlack(): void {
    window.open(EXTERNAL_URLS.SLACK, '_blank');
  }

  function handleGitHubIssues(): void {
    window.open(EXTERNAL_URLS.GITHUB_ISSUES, '_blank');
  }

  function handleGitHubDiscussions(): void {
    window.open(EXTERNAL_URLS.GITHUB_DISCUSSIONS, '_blank');
  }

  function handleScheduleCall(): void {
    window.open(EXTERNAL_URLS.CALENDLY, '_blank');
  }

  async function handleSubmitSupport(event: SubmitEvent): Promise<void> {
    event.preventDefault();
    
    if (isSubmitting) return;
    
    isSubmitting = true;
    submitError = null;
    submitSuccess = false;

    try {
      const formDataToSubmit = new FormData();
      formDataToSubmit.append('access_key', WEB3_FORMS_ACCESS_KEY);
      formDataToSubmit.append('email', formData.email);
      formDataToSubmit.append('subject', `[Terrateam Support] ${formData.subject}`);
      formDataToSubmit.append('message', `Priority: ${formData.priority}\n\nMessage:\n${formData.message}`);
      formDataToSubmit.append('from_name', 'Terrateam Support Form');
      formDataToSubmit.append('replyto', 'support@terrateam.io');

      const response = await fetch(EXTERNAL_URLS.WEB3_FORMS_ENDPOINT, {
        method: 'POST',
        body: formDataToSubmit
      });

      const result = await response.json();

      if (result.success) {
        submitSuccess = true;
        formData = { email: '', subject: '', message: '', priority: 'normal' };
      } else {
        throw new Error(result.message || 'Failed to submit form');
      }
    } catch (error) {
      console.error('Form submission error:', error);
      submitError = error instanceof Error ? error.message : 'Failed to submit support request';
    } finally {
      isSubmitting = false;
    }
  }

  function handleStatusPage(): void {
    window.open(EXTERNAL_URLS.STATUS_PAGE, '_blank');
  }

</script>

<PageLayout activeItem="support" title="Support">
    <main class="flex-1 p-6">
      <div class="max-w-4xl mx-auto">
        <!-- Support Overview -->
        <div class="text-center mb-12">
          <div class="inline-flex items-center justify-center w-16 h-16 rounded-full mb-6 brand-icon-bg">
            <svg class="w-8 h-8 brand-icon-color" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <h2 class="text-3xl font-bold text-brand-primary mb-4">How can we help you?</h2>
          <p class="text-xl text-brand-secondary max-w-2xl mx-auto">
            Get the support you need to successfully deploy and manage your infrastructure with Terrateam.
          </p>
        </div>

        <!-- Tab Navigation -->
        <div class="mb-8">
          <div class="flex justify-center">
            <div class="bg-white dark:bg-gray-800 rounded-lg p-2 shadow-lg border">
              <div class="flex space-x-1">
                <button
                  on:click={() => activeTab = 'support'}
                  class="px-6 py-3 rounded-lg text-sm font-semibold transition-colors
                    {activeTab === 'support' 
                      ? 'bg-blue-600 text-white shadow-md' 
                      : 'text-brand-secondary hover:text-brand-primary hover:bg-gray-50 dark:hover:bg-gray-700'}"
                >
                  <svg class="w-4 h-4 inline mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 4.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                  </svg>
                  Technical Support
                </button>
                <button
                  on:click={() => activeTab = 'community'}
                  class="px-6 py-3 rounded-lg text-sm font-semibold transition-colors
                    {activeTab === 'community' 
                      ? 'bg-blue-600 text-white shadow-md' 
                      : 'text-brand-secondary hover:text-brand-primary hover:bg-gray-50 dark:hover:bg-gray-700'}"
                >
                  <svg class="w-4 h-4 inline mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
                  </svg>
                  Community
                </button>
                <button
                  on:click={() => activeTab = 'resources'}
                  class="px-6 py-3 rounded-lg text-sm font-semibold transition-colors
                    {activeTab === 'resources' 
                      ? 'bg-blue-600 text-white shadow-md' 
                      : 'text-brand-secondary hover:text-brand-primary hover:bg-gray-50 dark:hover:bg-gray-700'}"
                >
                  <svg class="w-4 h-4 inline mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.746 0 3.332.477 4.5 1.253v13C19.832 18.477 18.246 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
                  </svg>
                  Resources
                </button>
                <button
                  on:click={() => activeTab = 'status'}
                  class="px-6 py-3 rounded-lg text-sm font-semibold transition-colors
                    {activeTab === 'status' 
                      ? 'bg-blue-600 text-white shadow-md' 
                      : 'text-brand-secondary hover:text-brand-primary hover:bg-gray-50 dark:hover:bg-gray-700'}"
                >
                  <svg class="w-4 h-4 inline mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                  Status
                </button>
              </div>
            </div>
          </div>
        </div>

        <!-- Tab Content -->
        {#if activeTab === 'support'}
          <!-- Technical Support Section -->
          <div class="mb-8">
            <div class="text-center mb-8">
              <h3 class="text-2xl font-bold text-brand-primary mb-4">Technical Support</h3>
              <p class="text-lg text-brand-secondary max-w-2xl mx-auto">
                Need help with your Terrateam setup? Our technical support team typically responds within 1 business hour.
              </p>
            </div>
            
            <div class="card-bg rounded-lg shadow-lg border p-8 max-w-3xl mx-auto">
              <!-- Email Option -->
              <div class="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-4 mb-6">
                <div class="flex items-start">
                  <svg class="w-5 h-5 text-blue-400 mr-3 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 12a4 4 0 10-8 0 4 4 0 008 0zm0 0v1.5a2.5 2.5 0 005 0V12a9 9 0 10-9 9m4.5-1.206a8.959 8.959 0 01-4.5 1.207" />
                  </svg>
                  <div>
                    <p class="font-medium text-blue-800 dark:text-blue-400">Prefer Email?</p>
                    <p class="text-sm text-blue-700 dark:text-blue-300">
                      You can also reach us directly at{' '}
                      <a href="mailto:support@terrateam.io" class="underline hover:no-underline font-semibold">
                        support@terrateam.io
                      </a>
                    </p>
                  </div>
                </div>
              </div>

              <!-- Success Message -->
              {#if submitSuccess}
                <div class="bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg p-4 mb-6">
                  <div class="flex items-start">
                    <svg class="w-5 h-5 text-green-400 mr-3 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                    <div>
                      <p class="font-medium text-green-800 dark:text-green-400">Support request submitted successfully!</p>
                      <p class="text-sm text-green-700 dark:text-green-300">
                        We'll get back to you within 1 business hour.
                      </p>
                    </div>
                  </div>
                </div>
              {/if}

              <!-- Error Message -->
              {#if submitError}
                <div class="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4 mb-6">
                  <div class="flex items-start">
                    <svg class="w-5 h-5 text-red-400 mr-3 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-2.694-.833-3.464 0L3.34 16.5c-.77.833.192 2.5 1.732 2.5z" />
                    </svg>
                    <div>
                      <p class="font-medium text-red-800 dark:text-red-400">Failed to submit support request</p>
                      <p class="text-sm text-red-700 dark:text-red-300">
                        {submitError}
                      </p>
                    </div>
                  </div>
                </div>
              {/if}

              <form on:submit={handleSubmitSupport} class="space-y-6">
                <!-- Email -->
                <div>
                  <label for="email" class="block text-sm font-medium text-brand-secondary mb-2">Your Email Address</label>
                  <input
                    type="email"
                    id="email"
                    bind:value={formData.email}
                    placeholder="your.email@company.com"
                    required
                    class="w-full px-4 py-3 border border-brand-primary rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-primary focus:border-transparent bg-brand-primary text-brand-primary placeholder-gray-500 dark:placeholder-gray-400"
                  />
                </div>

                <!-- Priority -->
                <div>
                  <label for="priority" class="block text-sm font-medium text-brand-secondary mb-2">Priority</label>
                  <select
                    id="priority"
                    bind:value={formData.priority}
                    class="w-full px-4 py-3 border border-brand-primary rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-primary focus:border-transparent bg-brand-primary text-brand-primary"
                  >
                    <option value="low">Low - General question</option>
                    <option value="normal">Normal - Standard support</option>
                    <option value="high">High - Business impacting</option>
                    <option value="urgent">Urgent - System down</option>
                  </select>
                </div>

                <!-- Subject -->
                <div>
                  <label for="subject" class="block text-sm font-medium text-brand-secondary mb-2">Subject</label>
                  <input
                    type="text"
                    id="subject"
                    bind:value={formData.subject}
                    placeholder="Brief description of your issue"
                    required
                    class="w-full px-4 py-3 border border-brand-primary rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-primary focus:border-transparent bg-brand-primary text-brand-primary placeholder-gray-500 dark:placeholder-gray-400"
                  />
                </div>

                <!-- Message -->
                <div>
                  <label for="message" class="block text-sm font-medium text-brand-secondary mb-2">Message</label>
                  <textarea
                    id="message"
                    bind:value={formData.message}
                    placeholder="Describe your issue in detail. Include any error messages, steps to reproduce, and your current setup."
                    required
                    rows="6"
                    class="w-full px-4 py-3 border border-brand-primary rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-primary focus:border-transparent bg-brand-primary text-brand-primary placeholder-gray-500 dark:placeholder-gray-400 resize-vertical"
                  ></textarea>
                </div>

                <!-- Form Actions -->
                <div class="flex justify-center">
                  <button
                    type="submit"
                    disabled={isSubmitting}
                    class="inline-flex items-center justify-center px-8 py-3 font-semibold rounded-lg transition-colors accent-bg disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    {#if isSubmitting}
                      <svg class="w-5 h-5 mr-2 animate-spin" fill="none" viewBox="0 0 24 24">
                        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"></path>
                      </svg>
                      Submitting...
                    {:else}
                      <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8" />
                      </svg>
                      Submit Support Request
                    {/if}
                  </button>
                </div>
              </form>
            </div>
          </div>
        {:else if activeTab === 'community'}
          <!-- Community Section -->
          <div class="mb-8">
            <div class="bg-brand-tertiary rounded-lg p-8 border border-brand-secondary max-w-3xl mx-auto">
              <div class="text-center mb-6">
                <h3 class="text-2xl font-bold text-brand-primary mb-4">Join Our Slack Community</h3>
                <div class="flex items-center justify-center mb-4">
                  <div class="inline-flex items-center justify-center w-16 h-16 rounded-full slack-icon-bg">
                    <svg class="w-8 h-8 text-white" fill="currentColor" viewBox="0 0 24 24">
                      <path d="M5.042 15.165a2.528 2.528 0 0 0-2.52 2.523A2.528 2.528 0 0 0 5.042 20.21a2.528 2.528 0 0 0 2.52-2.522 2.528 2.528 0 0 0-2.52-2.523zM17.5 15.165a2.528 2.528 0 0 0-2.52 2.523A2.528 2.528 0 0 0 17.5 20.21a2.528 2.528 0 0 0 2.52-2.522 2.528 2.528 0 0 0-2.52-2.523z"/>
                      <path d="M17.5 11.014a4.6 4.6 0 0 0-2.778-4.231 4.6 4.6 0 0 0-4.834.635A4.6 4.6 0 0 0 5.042 11.5a4.6 4.6 0 0 0 4.635 4.635 4.6 4.6 0 0 0 4.236-2.777 4.6 4.6 0 0 0 3.587-4.344z"/>
                      <path d="M12 2C6.478 2 2 6.478 2 12s4.478 10 10 10 10-4.478 10-10S17.522 2 12 2z"/>
                    </svg>
                  </div>
                </div>
                <p class="text-lg text-brand-primary">
                  Get instant help from Terrateam engineers and connect with other users. It's the fastest way to get answers, troubleshoot issues, and share your infrastructure setups.
                </p>
              </div>
              <div class="flex justify-center">
                <button
                  on:click={handleJoinSlack}
                  class="inline-flex items-center justify-center px-8 py-4 text-lg font-semibold rounded-lg transition-colors shadow-lg slack-button"
                >
                  <svg class="w-6 h-6 mr-3" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M5.042 15.165a2.528 2.528 0 0 0-2.52 2.523A2.528 2.528 0 0 0 5.042 20.21a2.528 2.528 0 0 0 2.52-2.522 2.528 2.528 0 0 0-2.52-2.523zM17.5 15.165a2.528 2.528 0 0 0-2.52 2.523A2.528 2.528 0 0 0 17.5 20.21a2.528 2.528 0 0 0 2.52-2.522 2.528 2.528 0 0 0-2.52-2.523z"/>
                    <path d="M17.5 11.014a4.6 4.6 0 0 0-2.778-4.231 4.6 4.6 0 0 0-4.834.635A4.6 4.6 0 0 0 5.042 11.5a4.6 4.6 0 0 0 4.635 4.635 4.6 4.6 0 0 0 4.236-2.777 4.6 4.6 0 0 0 3.587-4.344z"/>
                    <path d="M12 2C6.478 2 2 6.478 2 12s4.478 10 10 10 10-4.478 10-10S17.522 2 12 2z"/>
                  </svg>
                  Join Slack Community
                </button>
              </div>
            </div>

            <!-- GitHub Community -->
            <div class="grid md:grid-cols-2 gap-6 mt-8 max-w-4xl mx-auto">
              <!-- GitHub Issues -->
              <div class="card-bg rounded-lg p-8 shadow border text-center">
                <div class="inline-flex items-center justify-center w-12 h-12 rounded-lg mb-6 brand-icon-bg">
                  <svg class="w-6 h-6 brand-icon-color" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/>
                  </svg>
                </div>
                <h4 class="text-xl font-bold text-brand-primary mb-4">GitHub Issues</h4>
                <p class="text-brand-secondary mb-6">
                  Report bugs, request features, or track existing issues.
                </p>
                <button
                  on:click={handleGitHubIssues}
                  class="w-full inline-flex items-center justify-center px-6 py-3 font-semibold rounded-lg transition-colors accent-bg"
                >
                  <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
                  </svg>
                  View Issues
                </button>
              </div>

              <!-- GitHub Discussions -->
              <div class="card-bg rounded-lg p-8 shadow border text-center">
                <div class="inline-flex items-center justify-center w-12 h-12 rounded-lg mb-6 brand-icon-bg">
                  <svg class="w-6 h-6 brand-icon-color" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M1.75 1h12.5c.966 0 1.75.784 1.75 1.75v9.5A1.75 1.75 0 0114.25 14H8.061l-2.574 2.573A1.458 1.458 0 013 15.543V14H1.75A1.75 1.75 0 010 12.25v-9.5C0 1.784.784 1 1.75 1zM1.5 2.75v9.5c0 .138.112.25.25.25h2a.75.75 0 01.75.75v2.19l2.72-2.72a.75.75 0 01.53-.22h6.5a.25.25 0 00.25-.25v-9.5a.25.25 0 00-.25-.25H1.75a.25.25 0 00-.25.25z"/>
                    <path d="M22.5 8.75a.25.25 0 00-.25-.25h-3.5a.75.75 0 010-1.5h3.5c.966 0 1.75.784 1.75 1.75v9.5A1.75 1.75 0 0122.25 20H21v1.543a1.458 1.458 0 01-2.487 1.03L15.939 20H10.75A1.75 1.75 0 019 18.25v-1.465a.75.75 0 011.5 0v1.465c0 .138.112.25.25.25h5.5a.75.75 0 01.53.22l2.72 2.72v-2.19a.75.75 0 01.75-.75h2a.25.25 0 00.25-.25v-9.5z"/>
                  </svg>
                </div>
                <h4 class="text-xl font-bold text-brand-primary mb-4">GitHub Discussions</h4>
                <p class="text-brand-secondary mb-6">
                  Join conversations and share knowledge with the community.
                </p>
                <button
                  on:click={handleGitHubDiscussions}
                  class="w-full inline-flex items-center justify-center px-6 py-3 font-semibold rounded-lg transition-colors accent-bg"
                >
                  <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
                  </svg>
                  Join Discussions
                </button>
              </div>
            </div>
          </div>
        {:else if activeTab === 'resources'}
          <!-- Resources Section -->
          <div class="mb-8">
            <div class="text-center mb-8">
              <h3 class="text-2xl font-bold text-brand-primary mb-4">Documentation & Resources</h3>
              <p class="text-lg text-brand-secondary max-w-2xl mx-auto">
                Everything you need to get started and master Terrateam.
              </p>
            </div>

            <div class="grid md:grid-cols-2 gap-6 max-w-4xl mx-auto">
              <!-- Documentation -->
              <div class="card-bg rounded-lg p-8 shadow border text-center">
                <div class="inline-flex items-center justify-center w-12 h-12 rounded-lg mb-6 brand-icon-bg">
                  <svg class="w-6 h-6 brand-icon-color" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.746 0 3.332.477 4.5 1.253v13C19.832 18.477 18.246 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
                  </svg>
                </div>
                <h4 class="text-xl font-bold text-brand-primary mb-4">Documentation</h4>
                <p class="text-brand-secondary mb-6">
                  Everything you need to configure Terrateam and automate GitHub workflows.
                </p>
                <button
                  on:click={handleViewDocs}
                  class="w-full inline-flex items-center justify-center px-6 py-3 font-semibold rounded-lg transition-colors accent-bg"
                >
                  <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
                  </svg>
                  View Docs
                </button>
              </div>

              <!-- Schedule a Call -->
              <div class="card-bg rounded-lg p-8 shadow border text-center">
                <div class="inline-flex items-center justify-center w-12 h-12 rounded-lg mb-6 brand-icon-bg">
                  <svg class="w-6 h-6 brand-icon-color" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                  </svg>
                </div>
                <h4 class="text-xl font-bold text-brand-primary mb-4">Schedule a Call</h4>
                <p class="text-brand-secondary mb-6">
                  Book a 30-minute chat with our team for personalized help.
                </p>
                <button
                  on:click={handleScheduleCall}
                  class="w-full inline-flex items-center justify-center px-6 py-3 font-semibold rounded-lg transition-colors accent-bg"
                >
                  <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                  </svg>
                  Book a Call
                </button>
              </div>
            </div>
          </div>
        {:else if activeTab === 'status'}
          <!-- Status Section -->
          <div class="mb-8">
            <div class="text-center mb-8">
              <h3 class="text-2xl font-bold text-brand-primary mb-4">Service Status</h3>
              <p class="text-lg text-brand-secondary max-w-2xl mx-auto">
                Check the current status of Terrateam services and view recent incidents.
              </p>
            </div>
            
            <div class="card-bg rounded-lg shadow-lg border p-8 max-w-3xl mx-auto text-center">
              <div class="inline-flex items-center justify-center w-16 h-16 rounded-full mb-6 brand-icon-bg">
                <svg class="w-8 h-8 brand-icon-color" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
              
              <h4 class="text-xl font-bold text-brand-primary mb-4">Real-time Service Status</h4>
              <p class="text-brand-secondary mb-6">
                Visit our status page for real-time information about service availability, ongoing incidents, and scheduled maintenance.
              </p>
              
              <button
                on:click={handleStatusPage}
                class="inline-flex items-center justify-center px-8 py-3 font-semibold rounded-lg transition-colors accent-bg"
              >
                <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
                </svg>
                View Status Page
              </button>
            </div>
          </div>
        {/if}

    </div>
</PageLayout>
