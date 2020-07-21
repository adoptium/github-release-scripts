#!/bin/bash
set -x

# Check PR's already on staging
cd staging
for d in */ ; do
    regx='^[0-9]+$'
    number=${d%/}
    if [[ $number =~ $regx ]]; then 
      echo checking "$number"
      echo "https://api.github.com/repos/AdoptOpenJDK/openjdk-website/pulls/$number"
      STATUS=$(curl "https://api.github.com/repos/AdoptOpenJDK/openjdk-website/pulls/$number" | grep "\"state\":" | head -n 1 | awk '{print $2}')
      if [[ "$STATUS" == '"closed",' ]]; then
        echo "removing $number"
          rm -rf "$number"
          git add .
          git commit -m "remove $number from staging"
      fi
      unset STATUS
    fi
done
git push origin HEAD:gh-pages

# Check for new PR's
cd $WORKSPACE
rm -rf openPR.txt
curl https://api.github.com/repos/AdoptOpenJDK/openjdk-website/pulls\?state\=open | grep "\"diff_url\":" | awk '{print $2}' |  sed 's/[^0-9]*//g' > openPR.txt
rm -rf *.properties
cat openPR.txt | while read line
do
  	echo "Checking PR: $line"
    if [ -d "$WORKSPACE/staging/$line" ]; then
		echo "already staged"
    else
    	echo "staging PR: $line"
        echo "PR_NUMBER=$line" > $line.properties
	fi
done
