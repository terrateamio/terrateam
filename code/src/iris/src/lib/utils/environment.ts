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

// Upgrade nudge constants
const FREE_PLAN_RUN_LIMIT = 50;
const RUN_LIMIT_70_PERCENT = Math.floor(FREE_PLAN_RUN_LIMIT * 0.7); // 35
const RUN_LIMIT_90_PERCENT = Math.floor(FREE_PLAN_RUN_LIMIT * 0.9); // 45
const BILLING_PERIOD_DAYS = 30;

/**
 * Check if upgrade nudges are enabled
 */
export function areUpgradeNudgesEnabled(): boolean {
  if (typeof window !== 'undefined' && window.terrateamConfig?.upgrade_nudges) {
    const nudges = window.terrateamConfig.upgrade_nudges;
    return nudges === 'true';
  }
  return false;
}

/**
 * Get the run limit threshold for Free plan
 */
export function getRunLimitThreshold(): number {
  return FREE_PLAN_RUN_LIMIT;
}

/**
 * Get the 70% threshold for run limit alerts
 */
export function getRunLimit70Threshold(): number {
  return RUN_LIMIT_70_PERCENT;
}

/**
 * Get the 90% threshold for run limit alerts
 */
export function getRunLimit90Threshold(): number {
  return RUN_LIMIT_90_PERCENT;
}

/**
 * Calculate current billing period dates based on installation creation date
 * Returns the start and end dates of the current 30-day billing cycle
 */
export function getBillingPeriodDates(createdAt: string): { start: Date; end: Date; daysRemaining: number } {
  const installDate = new Date(createdAt);
  const now = new Date();
  
  // Calculate how many complete billing periods have passed
  const daysSinceInstall = Math.floor((now.getTime() - installDate.getTime()) / (1000 * 60 * 60 * 24));
  const completedPeriods = Math.floor(daysSinceInstall / BILLING_PERIOD_DAYS);
  
  // Calculate current billing period start
  const periodStart = new Date(installDate);
  periodStart.setDate(periodStart.getDate() + (completedPeriods * BILLING_PERIOD_DAYS));
  
  // Calculate current billing period end
  const periodEnd = new Date(periodStart);
  periodEnd.setDate(periodEnd.getDate() + BILLING_PERIOD_DAYS - 1);
  periodEnd.setHours(23, 59, 59, 999);
  
  // Calculate days remaining in current period
  const daysRemaining = Math.ceil((periodEnd.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
  
  return {
    start: periodStart,
    end: periodEnd,
    daysRemaining: Math.max(0, daysRemaining)
  };
}

