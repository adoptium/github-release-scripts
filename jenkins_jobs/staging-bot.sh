#!/bin/bash

# Check PR's already on staging
for d in */ ; do
	number=${d%/}
    echo checking "$number"
    STATUS=$(curl "https://api.github.com/repos/AdoptOpenJDK/openjdk-website/pulls/$number" | grep "\"state\":" | awk '{print $2}')
    if [ "$STATUS" == '"closed",' ]; then
    	echo "removing $number"
        rm -rf "$number"
        git add .
        git commit -m "remove $number from staging"
    fi
done
git push origin HEAD:gh-pages
