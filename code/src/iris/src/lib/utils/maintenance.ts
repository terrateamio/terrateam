/**
 * Maintenance mode detection utilities
 */

export interface MaintenanceConfig {
  isMaintenanceMode: boolean;
  message?: string;
}

/**
 * Detect maintenance mode from runtime configuration
 */
export function getMaintenanceConfig(): MaintenanceConfig {
  // Check runtime config (injected by server)
  if (typeof window !== 'undefined' && window.terrateamConfig) {
    const config = window.terrateamConfig;
    if (config.maintenanceMode === true || config.maintenanceMode === 'true') {
      return {
        isMaintenanceMode: true,
        message: config.maintenanceMessage || undefined
      };
    }
  }
  
  return {
    isMaintenanceMode: false
  };
}

export default getMaintenanceConfig;

