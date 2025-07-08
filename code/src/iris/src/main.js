import './app.css'
import App from './App.svelte'

// Check for maintenance mode before any initialization
function checkMaintenanceMode() {
  // Check runtime config first (injected by server)
  if (typeof window !== 'undefined' && window.terrateamConfig) {
    const config = window.terrateamConfig;
    if (config.maintenanceMode === true || config.maintenanceMode === 'true') {
      return true;
    }
  }
  
  // Fallback to Vite build-time environment variables
  if (typeof import.meta !== 'undefined' && import.meta.env) {
    const viteMaintenanceMode = import.meta.env.VITE_TERRATEAM_MAINTENANCE;
    if (viteMaintenanceMode === 'true' || viteMaintenanceMode === true) {
      return true;
    }
  }
  
  return false;
}

// Exit early if in maintenance mode to prevent any API calls or initialization
const isMaintenanceMode = checkMaintenanceMode();
if (isMaintenanceMode) {
  // Start app immediately without Sentry or other initialization
  const app = new App({
    target: document.getElementById('app'),
  });
} else {

// Conditionally import and initialize Sentry only if analytics are enabled
async function initializeSentry() {
  // Check if analytics (including Sentry) are enabled
  let analyticsEnabled = false;
  
  // In development, prioritize Vite environment variables
  if (typeof import.meta !== 'undefined' && import.meta.env && import.meta.env.DEV) {
    const viteAnalytics = import.meta.env.VITE_TERRATEAM_UI_ANALYTICS;
    if (viteAnalytics) {
      analyticsEnabled = viteAnalytics === 'enabled';
    } else {
      // Fallback to window.terrateamConfig in development if Vite var not set
      analyticsEnabled = window.terrateamConfig?.ui_analytics === 'enabled';
    }
  } else {
    // Production: Check window.terrateamConfig (set by index.html template replacement)
    analyticsEnabled = window.terrateamConfig?.ui_analytics === 'enabled';
  }
  
  if (analyticsEnabled) {
    // Initialize PostHog first
    if (window.initPostHog) {
      window.initPostHog();
    }
    
    const Sentry = await import("@sentry/svelte");
    
    Sentry.init({
      dsn: "https://d0d17714697761a74f6fe1a4123126d4@o4509570379677696.ingest.de.sentry.io/4509570441281616",
      // Basic PII but be selective
      sendDefaultPii: false,
      integrations: [
        Sentry.browserTracingIntegration(),
        Sentry.replayIntegration({
          // Mask sensitive inputs but keep useful debugging info
          maskAllText: false,
          blockAllMedia: false,
          maskAllInputs: true, // Mask form inputs by default
          // Custom masking function for selective hiding
          maskTextFn: (text) => {
            // Mask things that look like tokens, keys, passwords
            if (/(?:password|token|key|secret|auth)/i.test(text)) {
              return '[Filtered]';
            }
            return text;
          },
          // Only capture network activity for our API
          networkDetailAllowUrls: [/localhost/, /app\.terrateam\.io/],
          networkCaptureBodies: true,
          networkRequestHeaders: ['Content-Type', 'Authorization'],
          networkResponseHeaders: ['Content-Type']
        })
      ],
      // Tracing
      tracesSampleRate: 1.0,
      // Set 'tracePropagationTargets' to control for which URLs distributed tracing should be enabled
      tracePropagationTargets: ["localhost", /^https:\/\/app\.terrateam\.io\/api/],
      // Session Replay
      replaysSessionSampleRate: 0.1,
      replaysOnErrorSampleRate: 1.0,
      // Additional options for good debugging
      attachStacktrace: true,
      beforeSend(event) {
        // Filter out sensitive data from error contexts
        if (event.extra) {
          Object.keys(event.extra).forEach(key => {
            if (/(?:password|token|key|secret|auth|credential)/i.test(key)) {
              event.extra[key] = '[Filtered]';
            }
          });
        }
        
        // Filter sensitive data from breadcrumbs
        if (event.breadcrumbs) {
          event.breadcrumbs.forEach(breadcrumb => {
            if (breadcrumb.data) {
              Object.keys(breadcrumb.data).forEach(key => {
                if (/(?:password|token|key|secret|auth|credential)/i.test(key)) {
                  breadcrumb.data[key] = '[Filtered]';
                }
              });
            }
          });
        }
        
        return event;
      }
    });
    
    return Sentry;
  } else {
    
    // Return a stub Sentry object for development
    return {
      setUser: () => {},
      setContext: () => {},
      setTag: () => {},
      addBreadcrumb: () => {},
      captureException: () => {},
      captureMessage: () => {},
      startTransaction: () => ({ finish: () => {} })
    };
  }
}

// Initialize Sentry first, then start the app
initializeSentry().then(async () => {
  // Also initialize the Sentry service reference
  const { initSentryReference } = await import('./lib/sentry.ts');
  await initSentryReference();
  const app = new App({
    target: document.getElementById('app'),
  })

  return app;
}).catch(err => {
  console.error('Failed to initialize application:', err);
});

} // End of maintenance mode check