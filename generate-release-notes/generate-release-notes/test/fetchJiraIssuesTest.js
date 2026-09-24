import assert from 'node:assert/strict';
import { test } from 'node:test';
import fetchJiraIssues from '../lib/fetchJiraIssues.js';

const mockIssue = {
  key: 'JDK-8280124',
  fields: {
    summary: 'Reduce branches decoding latin-1 chars',
    priority: { id: '3' },
    components: [{ name: 'core-libs' }],
    customfield_10008: { name: 'java.lang' },
    issuetype: { name: 'Backport' },
    issuelinks: [
      {
        type: { name: 'Backport' },
        inwardIssue: { key: 'JDK-8280123' },
      },
    ],
  },
};

test('fetchReleaseNotes', async (t) => {
  const originalFetch = globalThis.fetch;

  globalThis.fetch = async (url) => ({
    ok: true,
    status: 200,
    headers: { get: () => 'application/json;charset=UTF-8' },
    json: async () => {
      if (url.includes('startAt=0') && url.includes('maxResults=1&')) {
        return { total: 1 };
      }
      if (url.includes('startAt=0')) {
        return { total: 1, issues: [mockIssue] };
      }
      return { total: 1, issues: [] };
    },
  });

  try {
    const version = '17.0.6';
    const issues = await fetchJiraIssues(version);

    await t.test('returns an array', () => {
      assert.ok(Array.isArray(issues), 'should return an array');
      assert.strictEqual(issues.length, 1);
    });

    await t.test('first issue extracts expected values', () => {
      const firstIssue = issues[0];

      assert.strictEqual(firstIssue.id, 'JDK-8280124');
      assert.strictEqual(firstIssue.title, 'Reduce branches decoding latin-1 chars');
      assert.strictEqual(firstIssue.priority, '3');
      assert.strictEqual(firstIssue.component, 'core-libs');
      assert.strictEqual(firstIssue.subcomponent, 'core-libs/java.lang');
      assert.strictEqual(firstIssue.link, 'https://bugs.openjdk.org/browse/JDK-8280124');
      assert.strictEqual(firstIssue.type, 'Backport');
      assert.strictEqual(firstIssue.backportOf, 'JDK-8280123');
    });
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test('fetchJiraIssues throws a clear error on HTTP error response', async () => {
  const originalFetch = globalThis.fetch;

  globalThis.fetch = async () => ({
    ok: false,
    status: 400,
    headers: { get: () => 'text/html' },
  });

  try {
    await assert.rejects(
      () => fetchJiraIssues('17.0.6'),
      (err) => {
        assert.ok(err.message.includes('400'), `Expected 400 in error message, got: ${err.message}`);
        return true;
      },
    );
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test('fetchJiraIssues throws a clear error when response is HTML not JSON', async () => {
  const originalFetch = globalThis.fetch;

  globalThis.fetch = async () => ({
    ok: true,
    status: 200,
    headers: { get: () => 'text/html; charset=utf-8' },
    text: async () => '<html><body>Service Unavailable</body></html>',
    json: async () => { throw new SyntaxError('Unexpected token <'); },
  });

  try {
    await assert.rejects(
      () => fetchJiraIssues('17.0.6', 1),
      (err) => {
        assert.ok(err.message.includes('non-JSON'), `Expected "non-JSON" in error message, got: ${err.message}`);
        assert.ok(err.message.includes('text/html'), `Expected content-type in error message, got: ${err.message}`);
        return true;
      },
    );
  } finally {
    globalThis.fetch = originalFetch;
  }
});
