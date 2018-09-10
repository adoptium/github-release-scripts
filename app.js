const GitHub = require('github-api');
const fs = require('fs')
const mkdirp = require('mkdirp');
const _ = require('underscore');

// basic auth
const gh = new GitHub({
  token: process.env['GITHUB_TOKEN']
});

//var AdoptOpenJDK = gh.getOrganization('AdoptOpenJDK');
const repo = gh.getRepo('AdoptOpenJDK', 'open' + process.env['VERSION'] + '-binaries');

mkdirp(process.env['VERSION'], function (err) {
  if (err) console.error(err)
});

repo.listReleases(function (err, result) {

  const release = process.env['RELEASE'] === "true";
  console.log("Release: " + release + " " + process.env['RELEASE']);

  const filteredResult = _.where(result, {prerelease: !release});

  if (release) {
    fs.writeFileSync(process.env['VERSION'] + '/releases.json', JSON.stringify(filteredResult, null, 2));
    fs.writeFileSync(process.env['VERSION'] + '/latest_release.json', JSON.stringify(filteredResult[0], null, 2));
  } else {
    fs.writeFileSync(process.env['VERSION'] + '/nightly.json', JSON.stringify(filteredResult, null, 2))
    fs.writeFileSync(process.env['VERSION'] + '/latest_nightly.json', JSON.stringify(filteredResult[0], null, 2))
  }
});
