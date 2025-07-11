import type { VCSProvider, VCSConfig } from './types';

export const VCS_PROVIDERS: Record<VCSProvider, VCSConfig> = {
  github: {
    provider: 'github',
    apiBasePath: '/api/v1/github',
    oauthClientIdEndpoint: '/github/client_id',
    displayName: 'GitHub',
    icon: 'mdi:github',
    terminology: {
      repository: 'repository',
      repositories: 'repositories',
      organization: 'organization',
      organizations: 'organizations'
    }
  },
  gitlab: {
    provider: 'gitlab',
    apiBasePath: '/api/v1/gitlab',
    oauthClientIdEndpoint: '/gitlab/client_id',
    displayName: 'GitLab',
    icon: 'mdi:gitlab',
    terminology: {
      repository: 'project',
      repositories: 'projects',
      organization: 'group',
      organizations: 'groups'
    }
  }
};

// Helper to get current provider config
export function getProviderConfig(provider: VCSProvider): VCSConfig {
  return VCS_PROVIDERS[provider];
}

// Helper to get API base path for a provider
export function getProviderApiPath(provider: VCSProvider): string {
  return VCS_PROVIDERS[provider].apiBasePath;
}