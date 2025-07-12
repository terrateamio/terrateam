// Analytics service to wrap PostHog functionality
// Provides type-safe event tracking and user identification

declare global {
  interface Window {
    posthog: PostHogLib;
  }
}

interface PostHogLib {
  init: (key: string, options?: Record<string, unknown>) => void;
  capture: (event: string, properties?: Record<string, unknown>) => void;
  identify: (userId: string, properties?: Record<string, unknown>) => void;
  setPersonProperties: (properties: Record<string, unknown>) => void;
  reset: () => void;
}

interface UserProperties {
  email?: string;
  name?: string;
  organization?: string;
  tier?: string;
  installation_id?: string;
  user_id?: string;
  vcs?: string[];
  github_username?: string;
  github_avatar_url?: string;
  [key: string]: unknown; // Allow any additional properties
}

interface EventProperties {
  [key: string]: unknown;
}

class Analytics {
  private isInitialized(): boolean {
    const initialized = typeof window !== 'undefined' && !!window.posthog;
    if (!initialized && typeof window !== 'undefined') {
      console.warn('PostHog not initialized');
    }
    return initialized;
  }
  
  // Debug method to check if PostHog is working
  isReady(): boolean {
    return this.isInitialized();
  }

  // Identify a user with properties
  identify(userId: string, properties?: UserProperties): void {
    if (!this.isInitialized()) return;
    
    try {
      window.posthog.identify(userId, properties);
    } catch (error) {
      console.warn('Analytics identify failed:', error);
    }
  }

  // Track an event with optional properties
  track(eventName: string, properties?: EventProperties): void {
    if (!this.isInitialized()) return;
    
    try {
      window.posthog.capture(eventName, properties);
    } catch (error) {
      console.warn('Analytics track failed:', error);
    }
  }

  // Set user properties
  setUserProperties(properties: UserProperties): void {
    if (!this.isInitialized()) return;
    
    try {
      window.posthog.setPersonProperties(properties);
    } catch (error) {
      console.warn('Analytics setUserProperties failed:', error);
    }
  }

  // Reset analytics (for logout)
  reset(): void {
    if (!this.isInitialized()) return;
    
    try {
      window.posthog.reset();
    } catch (error) {
      console.warn('Analytics reset failed:', error);
    }
  }

  // Common event tracking methods
  trackPageView(pageName: string, properties?: EventProperties): void {
    this.track('page_viewed', {
      page: pageName,
      ...properties
    });
  }

  trackNavigation(from: string, to: string): void {
    this.track('navigation', {
      from,
      to
    });
  }

  trackInstallationSwitch(installationId: string, installationName: string): void {
    this.track('installation_switched', {
      installation_id: installationId,
      installation_name: installationName
    });
  }

  trackRunAction(action: string, runId: string, properties?: EventProperties): void {
    this.track('run_action', {
      action,
      run_id: runId,
      ...properties
    });
  }

  trackTrialExtensionRequest(properties?: EventProperties): void {
    this.track('trial_extension_requested', properties);
  }

  trackBillingAction(action: string, properties?: EventProperties): void {
    this.track('billing_action', {
      action,
      ...properties
    });
  }

  trackRepositoryAction(action: string, repositoryName: string, properties?: EventProperties): void {
    this.track('repository_action', {
      action,
      repository_name: repositoryName,
      ...properties
    });
  }

  trackWorkspaceAction(action: string, workspace: string, directory: string, properties?: EventProperties): void {
    this.track('workspace_action', {
      action,
      workspace,
      directory,
      ...properties
    });
  }

  trackFilterUsage(filterType: string, filterValue: string, context: string): void {
    this.track('filter_used', {
      filter_type: filterType,
      filter_value: filterValue,
      context
    });
  }

  trackSearchQuery(query: string, context: string, resultCount?: number): void {
    this.track('search_performed', {
      query,
      context,
      result_count: resultCount
    });
  }
}

// Export singleton instance
export const analytics = new Analytics();

// Export types for external use
export type { UserProperties, EventProperties };
