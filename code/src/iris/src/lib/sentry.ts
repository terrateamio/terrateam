// Sentry error tracking service
// Provides type-safe error tracking and user context management

import type { User } from './types';

// Dynamic Sentry import that respects environment
let Sentry: SentryLib | null = null;

interface SentryLib {
  setUser: (user: Record<string, unknown> | null) => void;
  setContext: (key: string, context: Record<string, unknown>) => void;
  setTag: (key: string, value: string | number | boolean) => void;
  addBreadcrumb: (breadcrumb: Record<string, unknown>) => void;
  captureException: (error: Error, context?: Record<string, unknown>) => void;
  captureMessage: (message: string, level?: unknown) => void;
}

// Initialize Sentry reference (this will be called by main.js)
async function initSentryReference() {
  const { isAnalyticsEnabled } = await import('./utils/environment');
  const shouldLoadSentry = isAnalyticsEnabled();
  
  if (shouldLoadSentry) {
    const sentryModule = await import('@sentry/svelte');
    Sentry = sentryModule as unknown as SentryLib;
  } else {
    // Stub for development
    Sentry = {
      setUser: () => {},
      setContext: () => {},
      setTag: () => {},
      addBreadcrumb: () => {},
      captureException: () => {},
      captureMessage: () => {},
    } as SentryLib;
  }
  return Sentry;
}

class SentryService {
  // Set user context for error tracking
  setUser(user: User | null): void {
    if (!Sentry) return;
    
    if (user) {
      Sentry.setUser({
        id: user.id.toString(),
      });
    } else {
      Sentry.setUser(null);
    }
  }

  // Set additional context for the current session
  setContext(key: string, context: Record<string, unknown>): void {
    if (!Sentry) return;
    Sentry.setContext(key, context);
  }

  // Set tags for categorizing errors
  setTag(key: string, value: string | number | boolean): void {
    if (!Sentry) return;
    Sentry.setTag(key, value);
  }

  // Add breadcrumb for debugging
  addBreadcrumb(
    message: string,
    category: string,
    level: 'debug' | 'info' | 'warning' | 'error' = 'info',
    data?: Record<string, unknown>
  ): void {
    if (!Sentry) return;
    Sentry.addBreadcrumb({
      message,
      category,
      level,
      data,
      timestamp: Date.now() / 1000,
    });
  }

  // Capture a custom error with context
  captureError(error: Error, context?: Record<string, unknown>): void {
    if (!Sentry) return;
    Sentry.captureException(error, {
      extra: context,
    });
  }

  // Capture a message (non-error event)
  captureMessage(message: string, level: unknown = 'info'): void {
    if (!Sentry) return;
    Sentry.captureMessage(message, level);
  }

  // Track API errors with additional context
  captureApiError(
    error: Error,
    endpoint: string,
    method: string,
    status?: number,
    installationId?: string
  ): void {
    this.captureError(error, {
      api_endpoint: endpoint,
      api_method: method,
      api_status: status,
      installation_id: installationId,
    });
  }

  // Start a span for performance monitoring
  startSpan(name: string, op: string): void {
    // Note: In newer Sentry versions, transactions are started automatically
    // We'll just add a breadcrumb for manual tracking
    this.addBreadcrumb(`Started operation: ${name}`, 'transaction', 'info', { op });
  }

  // Track page navigation performance
  trackPageNavigation(from: string, to: string): void {
    this.addBreadcrumb(
      `Navigated from ${from} to ${to}`,
      'navigation',
      'info',
      { from, to }
    );
  }

  // Track user actions
  trackUserAction(action: string, details?: Record<string, unknown>): void {
    this.addBreadcrumb(
      action,
      'user',
      'info',
      details
    );
  }

  // Update installation context
  setInstallationContext(installationId: string, installationName: string, tier?: string): void {
    this.setContext('installation', {
      id: installationId,
      name: installationName,
      tier: tier || 'unknown',
    });
    this.setTag('installation_id', installationId);
    this.setTag('tier', tier || 'unknown');
  }
}

// Export singleton instance
export const sentryService = new SentryService();

// Export Sentry reference and initialization function
export { Sentry, initSentryReference };