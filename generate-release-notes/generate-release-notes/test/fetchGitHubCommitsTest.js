import assert from 'node:assert/strict';
import { test } from 'node:test';
import { fetchCommits } from '../lib/fetchGitHubCommits.js';
import mockAPIResponse from './mock/mockAPIResponse.json' with { type: 'json' };

const repository = 'adoptium/jdk17u'
const baseTag = 'jdk-17.0.5-ga';
const tag = 'jdk-17.0.6+9';

test('fetchGithubCommits', async (t) => {
  const commits = await fetchCommits({ repository, baseTag, tag });

  await t.test('returns correct number of commits', (t) => {
    assert.strictEqual(commits.length, mockAPIResponse.total_commits);
  });

  await t.test('first commit extracts expected values', (t) => {
    assert.strictEqual(commits[0].sha, mockAPIResponse.commits[0].sha);
    assert.strictEqual(commits[0].commit.message, mockAPIResponse.commits[0].commit.message);
  });
});

test('fetchGithubCommits sends Authorization header when GITHUB_TOKEN is set', async () => {
  const originalFetch = globalThis.fetch;
  let capturedHeaders;

  globalThis.fetch = async (url, init) => {
    capturedHeaders = init?.headers ?? {};
    return {
      ok: true,
      headers: { get: () => null },
      json: async () => ({ commits: [mockAPIResponse.commits[0]] }),
    };
  };

  process.env.GITHUB_TOKEN = 'test-token';

  try {
    await fetchCommits({ repository, baseTag, tag });
    assert.strictEqual(capturedHeaders.Authorization, 'Bearer test-token');
  } finally {
    globalThis.fetch = originalFetch;
    delete process.env.GITHUB_TOKEN;
  }
});

test('fetchGithubCommits omits Authorization header when GITHUB_TOKEN is not set', async () => {
  const originalFetch = globalThis.fetch;
  let capturedHeaders;

  globalThis.fetch = async (url, init) => {
    capturedHeaders = init?.headers ?? {};
    return {
      ok: true,
      headers: { get: () => null },
      json: async () => ({ commits: [mockAPIResponse.commits[0]] }),
    };
  };

  delete process.env.GITHUB_TOKEN;

  try {
    await fetchCommits({ repository, baseTag, tag });
    assert.strictEqual(capturedHeaders.Authorization, undefined);
  } finally {
    globalThis.fetch = originalFetch;
  }
});