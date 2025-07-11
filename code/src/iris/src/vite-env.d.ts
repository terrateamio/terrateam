/// <reference types="vite/client" />

// Runtime configuration injected by the server
interface TerrateamConfig {
  // Analytics configuration
  ui_analytics?: 'enabled' | 'disabled';
  
  // Subscription UI mode
  ui_subscription?: 'disabled' | 'oss' | 'saas';
  
  // Maintenance mode
  maintenanceMode?: boolean | 'true' | 'false';
  maintenanceMessage?: string;
}

// Extend Window interface to include runtime config
declare global {
  interface Window {
    terrateamConfig?: TerrateamConfig;
  }
}