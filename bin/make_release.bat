RMDIR /S /Q .\Release\
md Release\
xcopy /s CoreData\ Release\CoreData\
xcopy /s Data\ Release\Data\
xcopy /s MyData\ Release\MyData\
cp Test.bat Release\Game.bat
cp Test.sh Release\Game.sh
tool\ScriptCompiler.exe Release\MyData\Scripts\Test.as
del Release\MyData\Scripts\*.as
tool\PackageTool Release\CoreData Release\CoreData.pak -c -q
tool\PackageTool Release\Data Release\Data.pak -c -q
tool\PackageTool Release\MyData Release\MyData.pak -c -q
RMDIR /S /Q Release\CoreData
RMDIR /S /Q Release\Data
RMDIR /S /Q Release\MyData