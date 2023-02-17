import assert from 'assert';
import { test } from 'node:test';
import extractJDKIssues from '../lib/extractJDKIssues.js';
import mockAPIResponse from './mock/mockAPIResponse.json' assert { type: 'json' };


test('extractJDKIssues', async (t) => {

 await t.test('extracts correct values from first commit', (t) => {
    const JDK_ISSUES = extractJDKIssues(mockAPIResponse.commits);
    let firstCommit = mockAPIResponse.commits[0];
    assert.strictEqual(JDK_ISSUES[0].id, `JDK-${firstCommit.commit.message.split('\n')[0].split(':')[0]}`);
    assert.strictEqual(JDK_ISSUES[0].commit, firstCommit.sha);
    assert.strictEqual(JDK_ISSUES[0].title, firstCommit.commit.message.split('\n')[0]);
 });

 await t.test('extracts correct values from multi issue commit', (t) => {
    const JDK_ISSUES = extractJDKIssues(mockAPIResponse.commits);
    let firstCommit = mockAPIResponse.commits[0];
    assert.strictEqual(JDK_ISSUES[0].id, `JDK-${firstCommit.commit.message.split('\n')[0].split(':')[0]}`);
    assert.strictEqual(JDK_ISSUES[0].commit, firstCommit.sha);
    assert.strictEqual(JDK_ISSUES[0].title, firstCommit.commit.message.split('\n')[0]);
 });
});
