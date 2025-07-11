// Global type declarations for Terrateam UI

declare global {
  interface Window {
    terrateamConfig?: {
      ui_analytics?: 'enabled' | 'disabled';
      ui_subscription?: 'disabled' | 'oss' | 'saas';
      maintenanceMode?: boolean | string;
      maintenanceMessage?: string;
    };
    posthog: {
      init: (key: string, options?: Record<string, unknown>) => void;
      capture: (event: string, properties?: Record<string, unknown>) => void;
      identify: (userId: string, properties?: Record<string, unknown>) => void;
      setPersonProperties: (properties: Record<string, unknown>) => void;
      reset: () => void;
    };
  }
}

export {};