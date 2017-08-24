var GitHub = require('github-api');
var fs = require('fs')
var mkdirp = require('mkdirp');

// basic auth
var gh = new GitHub({
  token: process.env['GITHUB_TOKEN']
});

//var AdoptOpenJDK = gh.getOrganization('AdoptOpenJDK');
var releases = gh.getRepo('AdoptOpenJDK', 'open' + process.env['VERSION'] + '-releases');
var nightly = gh.getRepo('AdoptOpenJDK', 'open' + process.env['VERSION'] + '-nightly');

mkdirp(process.env['VERSION'], function (err) {
    if (err) console.error(err)
});

releases.listReleases(function(err, result) {
  fs.writeFileSync(process.env['VERSION'] + '/releases.json', JSON.stringify(result, null, 2))
  fs.writeFileSync(process.env['VERSION'] + '/latest_release.json', JSON.stringify(result[0], null, 2))
});

nightly.listReleases(function(err, result) {
  fs.writeFileSync(process.env['VERSION'] + '/nightly.json', JSON.stringify(result, null, 2))
  fs.writeFileSync(process.env['VERSION'] + '/latest_nightly.json', JSON.stringify(result[0], null, 2))
});
