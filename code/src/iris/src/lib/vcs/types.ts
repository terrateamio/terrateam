// VCS Provider Types and Interfaces
export type VCSProvider = 'github' | 'gitlab';

export interface VCSConfig {
  provider: VCSProvider;
  apiBasePath: string;
  oauthClientIdEndpoint: string;
  displayName: string;
  icon: string;
  terminology: {
    repository: string;
    repositories: string;
    organization: string;
    organizations: string;
  };
}

export interface VCSContext {
  provider: VCSProvider;
  config: VCSConfig;
}