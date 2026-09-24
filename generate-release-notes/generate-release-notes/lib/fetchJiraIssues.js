// Description: Fetches the JIRA issues from bugs.openjdk.org

const delay = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

async function fetchJiraJson(url, maxRetries = 5) {
  const headers = {
    Accept: 'application/json',
    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
  };

  for (let attempt = 1; attempt <= maxRetries; attempt += 1) {
    try {
      const response = await fetch(url, { headers, signal: AbortSignal.timeout(60000) });
      if (!response.ok) {
        if (response.status === 429 || response.status >= 500) {
          if (attempt < maxRetries) {
            const backoff = Math.min(attempt * 10000, 60000);
            console.warn(`Jira API HTTP ${response.status}. Retrying in ${backoff / 1000}s (attempt ${attempt}/${maxRetries})...`);
            await delay(backoff);
            continue;
          }
        }
        throw new Error(`Jira API request failed: HTTP ${response.status} for ${url}`);
      }
      const contentType = response.headers.get('content-type') || '';
      if (!contentType.includes('application/json')) {
        const body = await response.text();
        if (attempt < maxRetries) {
          const backoff = Math.min(attempt * 10000, 60000);
          console.warn(`Jira API returned non-JSON response (content-type: ${contentType}). Retrying in ${backoff / 1000}s (attempt ${attempt}/${maxRetries})...`);
          await delay(backoff);
          continue;
        }
        throw new Error(`Jira API returned non-JSON response (content-type: ${contentType}) for ${url}. Body starts with: ${body.slice(0, 200)}`);
      }
      return await response.json();
    } catch (err) {
      if (attempt < maxRetries && (err.name === 'TimeoutError' || err.name === 'AbortError' || err.code === 'UND_ERR_CONNECT_TIMEOUT')) {
        const backoff = Math.min(attempt * 10000, 60000);
        console.warn(`Jira API request timed out. Retrying in ${backoff / 1000}s (attempt ${attempt}/${maxRetries})...`);
        await delay(backoff);
        continue;
      }
      throw err;
    }
  }
}

export default async function fetchReleaseNotes(version, maxRetries = 5) {
  // fetch the release notes from the bugs.openjdk.org
  const baseUrl = 'https://bugs.openjdk.org/rest/api/2/search?jql=';
  const jql = `project=JDK AND (status in (Closed, Resolved))
    AND (resolution not in ("Won't Fix", "Duplicate", "Cannot Reproduce", "Not an Issue", "Withdrawn"))
    AND (labels not in (release-note, openjdk-na) OR labels is EMPTY)
    AND (summary !~ "release note") AND (issuetype != CSR) AND (fixVersion in (${version}))`;
  const encodedJql = encodeURIComponent(jql);
  const fields = 'summary,priority,components,customfield_10008,issuetype,issuelinks';
  const pageSize = 100;
  const pageDelayMs = 2500;

  // execute the initial fetch to get the total number of issues
  const initialRes = await fetchJiraJson(`${baseUrl + encodedJql}&startAt=0&maxResults=1&fields=summary`, maxRetries);
  const { total } = initialRes;

  console.log(`Found ${total} JIRA issues for JDK ${version}. Fetching in pages of ${pageSize}...`);

  const JIRA_ISSUES = [];

  // fetch all the issues by page
  for (let startAt = 0; startAt < total; startAt += pageSize) {
    if (startAt > 0 && pageDelayMs > 0) {
      await delay(pageDelayMs);
    }
    console.log(`Fetching JIRA issues ${startAt + 1}-${Math.min(startAt + pageSize, total)} of ${total}...`);
    const pageRes = await fetchJiraJson(`${baseUrl + encodedJql}&startAt=${startAt}&maxResults=${pageSize}&fields=${fields}`, maxRetries);

    pageRes.issues.forEach((issue) => {
      let parent = '';

      // if the issue is a backport, get the parent issue JDK number
      if (issue.fields.issuetype.name === 'Backport') {
        const linkedIssues = issue.fields.issuelinks;

        linkedIssues.forEach((linkedIssue) => {
          if (linkedIssue.type.name === 'Backport') {
            parent = linkedIssue.inwardIssue.key;
          }
        });
      }

      JIRA_ISSUES.push({
        id: issue.key,
        title: issue.fields.summary,
        priority: issue.fields.priority.id,
        component: issue.fields.components[0].name,
        subcomponent: `${issue.fields.components[0].name}${issue.fields.customfield_10008?.name ? `/${issue.fields.customfield_10008?.name}` : ''}`,
        link: `https://bugs.openjdk.org/browse/${issue.key}`,
        type: issue.fields.issuetype.name,
        backportOf: parent || null,
      });
    });
  }
  return JIRA_ISSUES;
}
