var GitHub = require('github-api');
var fs = require('fs')

// basic auth
var gh = new GitHub({
  token: process.env['GITHUB_TOKEN']
});

//var AdoptOpenJDK = gh.getOrganization('AdoptOpenJDK');
var releases = gh.getRepo('AdoptOpenJDK', 'openjdk-releases');
var nightly = gh.getRepo('AdoptOpenJDK', 'openjdk-nightly');

releases.listReleases(function(err, result) {
  fs.writeFileSync('releases.json', JSON.stringify(result, null, 2))
  fs.writeFileSync('latest_release.json', JSON.stringify(result[0], null, 2))
});

nightly.listReleases(function(err, result) {
  fs.writeFileSync('nightly.json', JSON.stringify(result, null, 2))
  fs.writeFileSync('latest_nightly.json', JSON.stringify(result[0], null, 2))
});
