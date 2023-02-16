// Description: Fetches commits from GitHub API
export const hasNextPage = (linkHeader) => (linkHeader || '').includes('rel="next"');

export const fetchCommits = async ({
  repository, baseTag, tag,
}) => {
  const pageSize = 100;
  let page = 1;
  let nextPage = true;
  let commits = [];

  console.log(`Fetching commits for ${repository} between ${baseTag} and ${tag}...`);
  while (nextPage) {
    const githubQuery = `https://api.github.com/repos/${repository}/compare/${baseTag}...${tag}?per_page=${pageSize}&page=${page}`;
    console.log(`Fetching commits from ${githubQuery}`);
    const githubResponse = await fetch(githubQuery);
    if (!githubResponse.ok) {
      throw new Error(`Failed to fetch commits from ${githubQuery}, status: ${githubResponse.status}`);
    }

    const githubResponseJson = await githubResponse.json();
    console.log(`Fetched total ${githubResponseJson.commits.length} commits`);
    commits = [...commits, ...githubResponseJson.commits];
    nextPage = hasNextPage(githubResponse.headers.get('link'));
    page += 1;
  }
  return commits;
};

export default fetchCommits;
