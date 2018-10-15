var publishRelease = require('publish-release')
var commandLineArgs = require('command-line-args');
var path = require('path')

var optionDefinitions = [{
    name: 'files',
    type: String,
    multiple: true
  },
  {
    name: 'tag',
    type: String
  },
  {
    name: 'description',
    type: String
  },
  {
    name: 'release',
    type: String
  }
];

var options = commandLineArgs(optionDefinitions);

release = (options.release === "true");
console.log('Uploading Files:', options.files);
console.log('Release:', options.release);

publishRelease({
  token: process.env['GITHUB_TOKEN'],
  owner: 'AdoptOpenJDK',
  repo: 'open' + process.env['VERSION'] + '-binaries',
  tag: options.tag,
  name: options.tag,
  notes: options.description,
  draft: false,
  prerelease: !release,
  reuseRelease: true,
  reuseDraftOnly: false,
  assets: options.files,
}, function(err, release) {
  if (err) {
    console.error(err);
  } else {
    console.error(release)
  }
})
