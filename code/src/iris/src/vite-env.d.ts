/// <reference types="vite/client" />

interface ImportMetaEnv {
  // Analytics configuration
  readonly VITE_TERRATEAM_UI_ANALYTICS?: 'enabled' | 'disabled';
  
  // Subscription UI mode
  readonly VITE_TERRATEAM_UI_SUBSCRIPTION?: 'disabled' | 'oss' | 'saas';
  
  // Maintenance mode
  readonly VITE_TERRATEAM_MAINTENANCE?: string;
  readonly VITE_TERRATEAM_MAINTENANCE_MESSAGE?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}