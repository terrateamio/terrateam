import assert from 'node:assert/strict';
import { test } from 'node:test';
import { dirspaceOfQuery, latestPlanQuery, runDirspacePath } from './planLink.ts';

test('latestPlanQuery: quotes each dirspace term', () => {
  assert.equal(
    latestPlanQuery(42, 'infra', 'envs/data-prod/us-east-1/eks/eks1', 'default'),
    'pr:42 and "repo:infra" and "dir:envs/data-prod/us-east-1/eks/eks1" and "workspace:default" and type:plan'
  );
});

test('latestPlanQuery: escapes quotes and backslashes in values', () => {
  assert.equal(
    latestPlanQuery(1, 'r', 'a "b"\\c', 'w s'),
    'pr:1 and "repo:r" and "dir:a \\"b\\"\\\\c" and "workspace:w s" and type:plan'
  );
});

test('runDirspacePath and dirspaceOfQuery round-trip', () => {
  const path = runDirspacePath('abc', 'envs/a b&c', 'default');
  assert.equal(path, '/runs/abc?dir=envs%2Fa+b%26c&workspace=default');
  assert.deepEqual(dirspaceOfQuery(path.split('?')[1]), { dir: 'envs/a b&c', workspace: 'default' });
});

test('dirspaceOfQuery: null without both parameters', () => {
  assert.equal(dirspaceOfQuery(undefined), null);
  assert.equal(dirspaceOfQuery('dir=a'), null);
});
