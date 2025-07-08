/**
 * Maintenance mode detection utilities
 * Supports both build-time and runtime environment variable detection
 */

export interface MaintenanceConfig {
  isMaintenanceMode: boolean;
  message?: string;
}

/**
 * Detect maintenance mode from environment variables
 * Supports both Vite build-time variables and runtime window.terrateamConfig
 */
export function getMaintenanceConfig(): MaintenanceConfig {
  // Check runtime config first (injected by server)
  if (typeof window !== 'undefined' && window.terrateamConfig) {
    const config = window.terrateamConfig;
    if (config.maintenanceMode === true || config.maintenanceMode === 'true') {
      return {
        isMaintenanceMode: true,
        message: config.maintenanceMessage || undefined
      };
    }
  }
  
  // Fallback to Vite build-time environment variables
  if (typeof import.meta !== 'undefined' && import.meta.env) {
    const viteMaintenanceMode = import.meta.env.VITE_TERRATEAM_MAINTENANCE;
    const viteMaintenanceMessage = import.meta.env.VITE_TERRATEAM_MAINTENANCE_MESSAGE;
    
    if (viteMaintenanceMode === 'true') {
      return {
        isMaintenanceMode: true,
        message: viteMaintenanceMessage || undefined
      };
    }
  }
  
  return {
    isMaintenanceMode: false
  };
}

export default getMaintenanceConfig;