#!/usr/bin/env node

import { parseArgs } from 'node:util';
import fs from 'node:fs';
import path from 'node:path';
import { fetchCommits } from './lib/fetchGitHubCommits.js';
import { extractJDKIssues } from './lib/extractJDKIssues.js';

// parse CLI arguments
const options = {
  repository: {
    type: 'string',
  },
  baseTag: {
    type: 'string',
  },
  tag: {
    type: 'string',
  },
  filename: {
    type: 'string',
    default: 'jdk-commits.json',
  },
};

const {
  repository,
  baseTag,
  tag,
  filename,
} = parseArgs({
  options,
}).values;

// error if required arguments are missing
if (!repository || !baseTag || !tag) {
  console.error('Missing required arguments');
  process.exit(1);
}

const commitsJson = await fetchCommits({
  repository,
  baseTag,
  tag,
});
console.log(`Fetched ${commitsJson.length} commits`);
const JDK_ISSUES = await extractJDKIssues(commitsJson);

try {
  console.log(`Writing JDK issues to ${filename}`);
  fs.writeFileSync(path.resolve(process.cwd(), `${filename}`), JSON.stringify(JDK_ISSUES, null, 2));
} catch (error) {
  console.error(`Error writing file ${filename}: ${error.message}`);
}
