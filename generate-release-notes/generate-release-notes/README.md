# OpenJDK Release Notes Tool

This repository contains two scripts that can be used to generate OpenJDK release notes. Typical usage will be to first generate the list of commits for the release using the `fetchCommitList.js` script and then run the `fetchReleaseNotes.js` script, supplying the commit list from `fetchCommitList.js` as an input.

## Prerequisites

* Node.js 18+

## fetchCommitList.js

Uses the GitHub API to output the commits between two tags on a given repository. The output includes the JDK bug IDs where they can be determined. Output is written to a JSON file.

### Parameters

* `repository`
  * GitHub repository in the form `org/repo` such as `adoptium/jd19u`.
* `baseTag`
  * Base Git tag or SHA to use for the comparison. Typically, this should be the GA tag of the previous version.
* `tag`
  * New Git tag or SHA to use for the comparison. Typically, this should be the GA tag of the version to generate release notes.
* `filename`
  * The output filename.

### Usage

```console
node fetchCommitList.js --repository <repository> --baseTag <baseTag> --tag <tag> --filename <filename>
```

### Output

JSON array of commits and JDK issue IDs in the following format:

```JSON
[
  {
    "id": "JDK-8287017",
    "commit": "25ac222aa2e04f934ffd989e3ee355157f497fde",
    "title": "8287017: Bump update version for OpenJDK: jdk-11.0.17"
  },
  ...
]
```

*NOTE:* The same commit may reference multiple JDK issues.

##  fetchReleaseNotes.js

Uses the commit list to gather information from https://bugs.openjdk.org/ for the supplied fix version.

### Parameters

* `commitList`
  * The JSON list of commits generated from `fetchCommitList.js`.
* `version`
  * The OpenJDK fix version in the form used by Jira. Example: `17.0.5`.
* `filename`
  * The output filename.

### Usage

```console
node ./fetchReleaseNotes.js --commitList <filename> --version <fixVersion> --filename <filename>
```

### Output

JSON array of commits and JDK issue IDs in the following format:

```JSON
[
  {
    "id": "JDK-8294333",
    "title": "(tz) Update Timezone Data to 2022c",
    "priority": "3",
    "component": "core-libs",
    "subcomponent": "core-libs/java.time",
    "link": "https://bugs.openjdk.java.net/browse/JDK-8294333",
    "type": "Backport",
    "backportOf": "JDK-8292579"
  },
  ...
]
```
