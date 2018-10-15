const GitHub = require('github-api');
const fs = require('fs')
const mkdirp = require('mkdirp');
const _ = require('underscore');

// basic auth
const gh = new GitHub({
  token: process.env['GITHUB_TOKEN']
});

const repo = gh.getRepo('AdoptOpenJDK', 'open' + process.env['VERSION'] + '-binaries');

mkdirp(process.env['VERSION'], function (err) {
  if (err) console.error(err)
});

repo.listReleases(function (err, result) {

  const release = process.env['RELEASE'] === "true";
  console.log("Release: " + release + " " + process.env['RELEASE']);

  const filteredResult = _.where(result, {prerelease: !release});

  //TODO: Remove these files as they should not be needed, if you want release info use the API
  if (release) {
    fs.writeFileSync(process.env['VERSION'] + '/releases.json', JSON.stringify(filteredResult, null, 2));
    fs.writeFileSync(process.env['VERSION'] + '/latest_release.json', JSON.stringify(filteredResult[0], null, 2));
  } else {
    fs.writeFileSync(process.env['VERSION'] + '/nightly.json', JSON.stringify(filteredResult, null, 2))
    fs.writeFileSync(process.env['VERSION'] + '/latest_nightly.json', JSON.stringify(filteredResult[0], null, 2))
  }
});
