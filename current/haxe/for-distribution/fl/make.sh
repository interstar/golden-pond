# Build the final FL Studio script by grabbing latest python library build, and the concatenating FL Studio specific pre-script and post-script with it

cp ../../out/python/goldenpond.py generated.py

cat pre.py generated.py post.py > goldenpond.pyscript

cp goldenpond.pyscript  ../../../published/

echo "Now put the goldenpond.pyscript wherever FL Studio can find it. Probably  <User>/YOURNAME/Documents/Image-Line/FL Studio/Settings/Piano roll scripts/goldenpond.pyscript"


