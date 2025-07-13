// Environment utilities for controlling UI features
// This provides explicit control over analytics and subscription features

export type AnalyticsMode = 'enabled' | 'disabled';
export type SubscriptionMode = 'disabled' | 'oss' | 'saas';

/**
 * Check if analytics (PostHog, Sentry) should be enabled
 * Controlled by runtime configuration
 */
export function isAnalyticsEnabled(): boolean {
  // Check window.terrateamConfig (set by index.html template replacement)
  if (typeof window !== 'undefined' && window.terrateamConfig?.ui_analytics) {
    const enabled = window.terrateamConfig.ui_analytics === 'enabled';
    return enabled;
  }
  
  // Default to disabled
  return false;
}

/**
 * Get the subscription UI mode
 * Controlled by runtime configuration
 */
export function getSubscriptionMode(): SubscriptionMode {
  // Check window.terrateamConfig (set by index.html template replacement)
  if (typeof window !== 'undefined' && window.terrateamConfig?.ui_subscription) {
    const mode = window.terrateamConfig.ui_subscription;
    if (mode === 'disabled' || mode === 'oss' || mode === 'saas') {
      return mode;
    }
  }
  
  // Default to OSS mode
  return 'oss';
}

/**
 * Check if subscription menu should be shown
 * Returns false only if mode is 'disabled'
 */
export function shouldShowSubscriptionMenu(): boolean {
  return getSubscriptionMode() !== 'disabled';
}

/**
 * Check if this is SaaS billing mode
 * Returns true only if mode is 'saas'
 */
export function isSaasBillingMode(): boolean {
  return getSubscriptionMode() === 'saas';
}

/**
 * Check if this is OSS/self-hosted mode
 * Returns true if mode is 'oss'
 */
export function isOssMode(): boolean {
  return getSubscriptionMode() === 'oss';
}

