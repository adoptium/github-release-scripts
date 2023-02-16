// Description: Extracts JDK issues from commit messages
export const extractJDKIssues = (commits) => {
  const JDK_ISSUES = [];

  function isJDKIssue(line) {
    return (/^[0-9]+:/).test(line);
  }

  for (const commit of commits) {
    const commitLines = commit.commit.message.split('\n');
    commitLines.forEach((line) => {
      if (isJDKIssue(line)) {
        JDK_ISSUES.push({
          id: `JDK-${line.split(':')[0]}`,
          commit: commit.sha,
          title: line,
        });
      }
    });
  }

  return JDK_ISSUES;
};

export default extractJDKIssues;
