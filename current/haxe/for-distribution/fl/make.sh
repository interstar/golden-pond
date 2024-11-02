# Build the final FL Studio script by grabbing latest python library build, and the concatenating FL Studio specific pre-script and post-script with it

cp ../../out/python/goldenpond.py generated.py

cat pre.py generated.py post.py > final_output.py


