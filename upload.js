var publishRelease = require('publish-release')
var commandLineArgs = require('command-line-args');
var path = require('path')

var optionDefinitions = [
  { name: 'files', type: String, multiple: true },
  { name: 'tag', type: String },
  { name: 'version', type: String},
  { name: 'repo', type: String}
];

var options = commandLineArgs(optionDefinitions);

console.log('Uploading Files:', options.files);

publishRelease({
  token: process.env['GITHUB_TOKEN'],
  owner: 'AdoptOpenJDK',
  repo: 'openjdk-' + options.repo,
  tag:  options.tag,
  name: options.tag,
  notes: 'Nightly Build of ' + options.version,
  draft: false,
  prerelease: false,
  reuseRelease: true,
  reuseDraftOnly: true,
  assets: options.files,
}, function (err, release) {
  if (err) {
    console.error(err);
  } else {
    console.error(release)
  }
})
