# Build the final FL Studio script by grabbing latest python library build, and the concatenating FL Studio specific pre-script and post-script with it

cp ../../out/python/goldenpond.py generated.py

cat pre.py generated.py post.py > goldenpond.pyscript

cat pre.py generated.py post-live.py > goldenpond-livecoding.pyscript

cat pre.py generated.py post-fpc.py > goldenpond-fpc.pyscript

cat pre-vfx.py generated.py post-vfx.py > goldenpond-vfx-harmonizer.pyscript

cp goldenpond.pyscript  ../../../published/
cp goldenpond-livecoding.pyscript  ../../../published/
cp goldenpond-fpc.pyscript  ../../../published/
cp goldenpond-vfx-harmonizer.pyscript ../../../published/

echo "--- FL Studio Python Scripts Build Complete ---"
echo "Piano roll scripts (e.g., goldenpond-livecoding.pyscript) go in: <Documents>/Image-Line/FL Studio/Settings/Piano roll scripts/"
echo "VFX scripts (e.g., goldenpond-vfx-harmonizer.pyscript) go in: <Documents>/Image-Line/FL Studio/Presets/Patcher/ (then load in a VFX Script node)"
