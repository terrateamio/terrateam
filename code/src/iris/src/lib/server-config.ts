import type { ServerConfig } from './types';
import type { VCSProvider } from './vcs/types';

export function getWebBaseUrl(vcsProvider: VCSProvider, serverConfig: ServerConfig): string {
  if (vcsProvider == 'github') {
    return serverConfig.github?.web_base_url || 'https://github.com';
  }
  else if (vcsProvider == 'gitlab') {
    return serverConfig.gitlab?.web_base_url || 'https://gitlab.com';
  }
  else {
    return 'https://github.com';
  }
}
