// Description: Fetches the JIRA issues from bugs.openjdk.org
export default async function fetchReleaseNotes(version) {
  // fetch the release notes from the bugs.openjdk.org
  const baseUrl = 'https://bugs.openjdk.java.net/rest/api/2/search?jql=';
  const jql = `project=JDK AND (status in (Closed, Resolved))
    AND (resolution not in ("Won't Fix", "Duplicate", "Cannot Reproduce", "Not an Issue", "Withdrawn"))
    AND (labels not in (release-note, openjdk-na) OR labels is EMPTY)
    AND (summary !~ "release note") AND (issuetype != CSR) AND fixVersion=${version}`;
  // execute the initial fetch to get the total number of issues
  const totalQuery = await fetch(`${baseUrl + jql}&startAt=1&maxResults=1`);
  const initialRes = await totalQuery.json();
  const { total } = initialRes;

  const JIRA_ISSUES = [];

  // fetch all the issues by page
  for (let startAt = 0; startAt <= total + 50; startAt += 50) {
    const query = await fetch(`${baseUrl + jql}&startAt=${startAt}&maxResults=50`);
    const pageRes = await query.json();

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

console.log(`ISSUE: ${issue.key}`)
      JIRA_ISSUES.push({
        id: issue.key,
        title: issue.fields.summary,
        priority: issue.fields.priority.id,
        component: issue.fields.components[0].name,
        subcomponent: `${issue.fields.components[0].name}${issue.fields.customfield_10008?.name ? `/${issue.fields.customfield_10008?.name}` : ''}`,
        link: `https://bugs.openjdk.java.net/browse/${issue.key}`,
        type: issue.fields.issuetype.name,
        backportOf: parent || null,
      });
    });
  }
  return JIRA_ISSUES;
}
