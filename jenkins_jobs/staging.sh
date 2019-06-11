#!/bin/bash

export PATH="/home/jenkins/.jenkins/.nvm/versions/node/v10.16.0/bin:$PATH"

GIT_REMOTE_REF=refs/pull/$PR_NUMBER/head
git clone https://github.com/AdoptOpenJDK/openjdk-website.git
mv openjdk-website $PR_NUMBER
cd $PR_NUMBER
git fetch origin $GIT_REMOTE_REF:testBranch
git checkout testBranch

cat >>"src/handlebars/partials/header.handlebars" <<-EOF
<div class="alert align-center">
 <span class="closebtn" onclick="this.parentElement.style.display='none';">&times;</span>
 This is a staging server, currently hosting <a class="light-link" href="https://github.com/AdoptOpenJDK/openjdk-website/pull/$PR_NUMBER"><var>PR $PR_NUMBER</var></a>
</div>
EOF

# Install the build tools, then run the build:
npm install --global gulp-cli
npm install
gulp build
# If the build is successful...
if [ $0 != 0 ]; then
	git add src/handlebars/partials/header.handlebars
	# Force-add the ignored build output files:
	git add -f dist
    git add -f *.html
    git add -f sitemap.xml
    git add -f robots.txt
    # Commit these files to Master, then retrieve the entire repo
    # (including build output) in the gh-pages branch:
    git commit -m "Add built files"
	git checkout gh-pages
    git reset --hard testBranch
    # Delete every file except for .html files, then every dir except for /dist:
    # (Both of these act only on the root dir - not recursively searching dirs)
    find . -type f ! -name '*.html' ! -name '*.pdf' -maxdepth 1 -mindepth 1  -delete
    find . -type d -not -name 'dist' -not -name '.git' -maxdepth 1 -mindepth 1 -exec rm -rf {} \;
# After this bulk-delete, copy across some other necessary files from the master branch:
cat >"CNAME" <<-EOF
staging.adoptopenjdk.net
EOF

cat >"robots.txt" <<-EOF
User-agent: *
Disallow: /
EOF
   	git checkout testBranch -- NOTICE
    git checkout testBranch -- LICENSE
    git checkout testBranch -- sitemap.xml
    #git checkout testBranch -- robots.txt

    echo "These files are ready to be moved onto the production web server:"
	ls

    # Check that the essential files (/dist and .html) exist before pushing:
    if [ ! -d dist ]; then
    	echo "/dist does not exist. Exiting."
		exit 1
    fi
    if [ ! -f index.html ]; then
   		echo ".html files do not exist. Exiting."
		exit 1
    fi
    rm -rf .git
    cd $WORKSPACE
    git clone git@github.com:AdoptOpenJDK/openjdk-website-staging.git
    cp -R $WORKSPACE/$PR_NUMBER openjdk-website-staging/
    cd openjdk-website-staging
    # Add and commit everything in the gh-pages branch, then force push to make it live:
    git add .
	git commit -m "Remove development files"
	git push origin gh-pages
  message="Now on staging server [here](https://staging.adoptopenjdk.net/$PR_NUMBER)."
  curl -u adoptopenjdk-github-bot:$TOKEN --data '{"body": "'"$message"'"}' https://api.github.com/repos/AdoptOpenJDK/openjdk-website/issues/$PR_NUMBER/comments
else
	echo "Build or lint failed."
fi
