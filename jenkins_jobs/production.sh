#!/bin/bash

export PATH="/home/jenkins/.jenkins/.nvm/versions/node/v6.10.2/bin:$PATH"

cd openjdk-website
git checkout master

sed -i -e 's/localize-key/vWKzIgeZa4D3c/g' src/handlebars/partials/header.handlebars

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
    git add -f src/handlebars/partials/header.handlebars
    # Revert the handlebars file as we now have the build html file
    # Commit these files to Master, then retrieve the entire repo
    # (including build output) in the gh-pages branch:
    git commit -m "Add built files"
	git checkout gh-pages
    git reset --hard master
    # Delete every file except for .html files, then every dir except for /dist:
    # (Both of these act only on the root dir - not recursively searching dirs)
    find . -type f ! -name '*.html' ! -name '*.pdf' -maxdepth 1 -mindepth 1  -delete
    find . -type d -not -name 'dist' -not -name '.git' -maxdepth 1 -mindepth 1 -exec rm -rf {} \;
	# After this bulk-delete, copy across some other necessary files from the master branch:

   	git checkout master -- NOTICE
    git checkout master -- LICENSE
    git checkout master -- sitemap.xml
    git checkout master -- robots.txt
    git checkout master -- CNAME

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

    # Add and commit everything in the gh-pages branch, then force push to make it live:
    git add .
	git commit -m "Remove development files"
	git push -f origin gh-pages
else
	echo "Build or lint failed."
fi
