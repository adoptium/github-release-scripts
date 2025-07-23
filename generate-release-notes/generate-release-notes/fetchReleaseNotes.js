#!/usr/bin/env node

/* This script is used to fetch OpenJDK release notes from the bugs.openjdk.org */

import {
  parseArgs,
} from 'node:util';

import fs from 'node:fs';
import path from 'node:path';
import fetchJiraIssues from './lib/fetchJiraIssues.js';

// parseArgs is used to parse command line arguments
const options = {
  commitList: { type: 'string', alias: 'c' },
  filename: { type: 'string', alias: 'f', default: 'jdk-release-notes.json' },
  version: { type: 'string', alias: 'v' },
};

const { commitList, filename, version } = parseArgs({ options }).values;

// error if required arguments are missing
if (!commitList || !version) {
  console.error('Missing required arguments');
  process.exit(1);
}

const commits = JSON.parse(fs.readFileSync(commitList));

const output = [];

console.log(`Fetching release notes for ${version} from JIRA`);
const JIRA_ISSUES = await fetchJiraIssues(version);

// loop through the commits and add the release notes to the output
for (const commit of commits) {
console.log(`COMMIT ${commit}`)
  let releaseNote = JIRA_ISSUES
    .find((issue) => issue.id === commit.id || issue.backportOf === commit.id);

  if (!releaseNote) {
    const title = commit.title.replace(/^(\d+: )/, '');

    releaseNote = {
      id: commit.id,
      title,
      priority: null,
      component: null,
      subcomponent: null,
      link: `https://bugs.openjdk.java.net/browse/${commit.id}`,
      type: null,
      backportOf: null,
    };
  }

  output.push(releaseNote);
}

try {
  console.log(`Writing release notes to ${filename}`);
  fs.writeFileSync(path.resolve(process.cwd(), `${filename}`), JSON.stringify(output, null, 2));
} catch (error) {
  console.error(`Error writing file ${filename}: ${error.message}`);
}
