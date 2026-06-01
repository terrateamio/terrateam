import { get } from 'svelte/store';
import { api, isApiError } from './api';
import {
  installations,
  selectedInstallation,
  installationsLoading,
  installationsError,
  installationsInitialized,
  defaultInstallationId,
  currentVCSProvider,
  cacheInstallations,
  clearInstallationsCache
} from './stores';
import type { Installation } from './types';

/**
 * Reconcile the selected installation against a freshly-fetched list.
 *
 * Preference order: keep the currently-selected installation if it still
 * exists (so a refresh updates its metadata without changing the selection),
 * otherwise the user's default, otherwise the first available.
 */
function reconcileSelectedInstallation(list: Installation[]): void {
  if (list.length === 0) {
    selectedInstallation.set(null);
    return;
  }

  const current = get(selectedInstallation);
  if (current) {
    const stillPresent = list.find((i) => i.id === current.id);
    if (stillPresent) {
      selectedInstallation.set(stillPresent);
      return;
    }
  }

  const defaultId = get(defaultInstallationId);
  const next = (defaultId && list.find((i) => i.id === defaultId)) || list[0];
  selectedInstallation.set(next);
}

/**
 * Load the user's installations.
 *
 * Key invariant: only a *successful* response is authoritative. A success
 * (even an empty list — e.g. the app was genuinely uninstalled) overwrites the
 * in-memory list and the last-known-good cache. Any error leaves the existing
 * (cached) installations in place and only sets installationsError, so a
 * transient failure can never masquerade as "no installations" / demo mode.
 *
 * Pass force=true to retry after a failure (bypasses the once-per-session guard).
 */
export async function loadInstallations(force = false): Promise<void> {
  if (get(installationsLoading)) return;
  if (get(installationsInitialized) && !force) return;

  installationsInitialized.set(true);
  installationsLoading.set(true);
  installationsError.set(null);

  try {
    const provider = get(currentVCSProvider);
    const response = await api.getUserInstallations(provider);

    if (response && response.installations && response.installations.length > 0) {
      // Authoritative, non-empty result — update the list and the cache.
      installations.set(response.installations);
      cacheInstallations(response.installations);
      reconcileSelectedInstallation(response.installations);
    } else {
      // Authoritative empty result — the user genuinely has no installations.
      // Clear the cache so demo mode is shown now and on the next visit.
      installations.set([]);
      clearInstallationsCache();
      selectedInstallation.set(null);
    }
  } catch (err) {
    console.error('Error loading installations:', err);

    if (get(currentVCSProvider) === 'gitlab' && isApiError(err) && err.status === 404) {
      // The GitLab installations endpoint isn't implemented yet — treat a 404
      // as a definitive "no installations" rather than an error.
      installations.set([]);
      clearInstallationsCache();
      selectedInstallation.set(null);
      installationsError.set(null);
    } else {
      // Transient/real error: keep the last-known-good installations in place
      // (do NOT clear the list) so we never fall back to demo mode on a blip.
      installationsError.set('Failed to load installations');
    }
  } finally {
    installationsLoading.set(false);
  }
}
