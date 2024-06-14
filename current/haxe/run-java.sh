cd out/java/src

# Compile Java files with the hxjava dependencies
javac -d ../obj -cp "../obj:$(haxelib path hxjava | sed -n 2p)" haxe/root/*.java

cd ../obj
java -cp ".:../src:$(haxelib path hxjava | sed -n 2p)" haxe.root.TestGoldenPond

