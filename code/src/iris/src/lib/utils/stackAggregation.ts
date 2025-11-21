import type { Stacks, StackOuter, StackState } from '../types';

/**
 * Determines the severity priority of a stack state.
 * Higher numbers indicate more severe states.
 */
function getStateSeverity(state: StackState): number {
  const severityMap: Record<StackState, number> = {
    apply_failed: 7,
    plan_failed: 6,
    apply_pending: 5,
    plan_pending: 4,
    apply_ready: 3,
    apply_success: 2,
    no_changes: 1,
  };
  return severityMap[state] || 0;
}

/**
 * Determines the most severe state from an array of states.
 */
function getMostSevereState(states: StackState[]): StackState {
  if (states.length === 0) return 'no_changes';

  return states.reduce((mostSevere, current) => {
    return getStateSeverity(current) > getStateSeverity(mostSevere)
      ? current
      : mostSevere;
  });
}

/**
 * Aggregates StackOuter objects with the same name into a single layer.
 *
 * - Groups stacks by their `name` property
 * - Merges all children from duplicate names
 * - Determines aggregated state using severity priority
 * - Preserves the first occurrence's position (earliest layer)
 *
 * @param stacks - The stacks data from the API
 * @returns Aggregated stacks with deduplicated StackOuter array
 */
export function aggregateStacks(stacks: Stacks | null): Stacks | null {
  if (!stacks || !stacks.stacks || stacks.stacks.length === 0) {
    return stacks;
  }

  // Group stacks by name
  const stackGroups = new Map<string, StackOuter[]>();

  for (const stack of stacks.stacks) {
    const existing = stackGroups.get(stack.name) || [];
    existing.push(stack);
    stackGroups.set(stack.name, existing);
  }

  // Aggregate groups with the same name
  const aggregatedStacks: StackOuter[] = [];
  const processedNames = new Set<string>();

  for (const stack of stacks.stacks) {
    // Skip if we've already processed this name
    if (processedNames.has(stack.name)) {
      continue;
    }
    processedNames.add(stack.name);

    const group = stackGroups.get(stack.name) || [];

    if (group.length === 1) {
      // No duplicates, use as-is
      aggregatedStacks.push(stack);
    } else {
      // Aggregate duplicates
      const allChildren = group.flatMap(s => s.stacks);
      const allStates = group.map(s => s.state);
      const aggregatedState = getMostSevereState(allStates);

      aggregatedStacks.push({
        name: stack.name,
        stacks: allChildren,
        state: aggregatedState,
      });
    }
  }

  return {
    stacks: aggregatedStacks,
  };
}
