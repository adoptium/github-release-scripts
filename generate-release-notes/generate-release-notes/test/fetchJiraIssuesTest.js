import assert from 'node:assert/strict';
import { test } from 'node:test';
import fetchJiraIssues from '../lib/fetchJiraIssues.js';

test('fetchReleaseNotes', async (t) => {
  const version = '17.0.6';

  const issues = await fetchJiraIssues(version);

  await t.test('returns an array', () => {
    assert.ok(Array.isArray(issues), 'should return an array');
  });

  await t.test('first issue extracts expected values', () => {
    if (issues.length > 0) {
      const firstIssue = issues[0];

      assert.ok(typeof firstIssue.id === 'string', 'issue should have an id');
      assert.ok(typeof firstIssue.title === 'string', 'issue should have a title');
      assert.ok(typeof firstIssue.priority === 'string', 'issue should have a priority');
      assert.ok(typeof firstIssue.component === 'string', 'issue should have a component');
      assert.ok(typeof firstIssue.subcomponent === 'string', 'issue should have a subcomponent');
      assert.ok(typeof firstIssue.link === 'string', 'issue should have a link');
      assert.ok(typeof firstIssue.type === 'string', 'issue should have a type');
      assert.ok(typeof firstIssue.backportOf === 'string' || firstIssue.backportOf === null, 'issue should have a backportOf value');
    } else {
      assert.fail('no issues were returned');
    }
  });
});
