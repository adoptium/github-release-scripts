git clone git@github.com:AdoptOpenJDK/openjdk-releases.git
git clone git@github.com:AdoptOpenJDK/openjdk-nightly.git
rm -rf openjdk-releases/release.json
rm -rf openjdk-nightly/nightly.json
mv releases.json openjdk-releases/
mv nightly.json openjdk-nightly/
cd $WORKSPACE/openjdk-releases
git add releases.json
git commit -m "updated releases.json" || echo "nothing to commit"
if [ `git diff origin/master | wc -l` > 0 ]; then
	git push
else
	echo "releases already up to date"
fi
cd $WORKSPACE/openjdk-nightly
git add nightly.json
git commit -m "updated nightly.json" || echo "nothing to commit"
if [ `git diff origin/master | wc -l` > 0 ]; then
	git push
else
	echo "nightly already up to date"
fi
