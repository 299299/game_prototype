#!/usr/bin/env bash
rm -rf Release
mkdir Release
cp -rf CoreData Release/
cp -rf Data Release/
cp -rf MyData Release/
cp Urho3DPlayer Release/
cp Test.sh Release/Game.sh
tool/ScriptCompiler Release/MyData/Scripts/Test.as
rm Release/MyData/Scripts/*.as
tool/PackageTool Release/CoreData ./Release/CoreData.pak -c -q
tool/PackageTool Release/Data ./Release/Data.pak -c -q
tool/PackageTool Release/MyData ./Release/MyData.pak -c -q
rm -rf Release/CoreData
rm -rf Release/Data
rm -rf Release/MyData