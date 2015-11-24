RMDIR /S /Q .\Release\
md .\Release\
xcopy /s /e /h .\CoreData .\Release\CoreData\
xcopy /s /e /h .\Data .\Release\Data\
xcopy /s /e /h .\MyData .\Release\MyData\
copy .\Test.bat .\Release\Game.bat
copy /f .\Test.sh .\Release\Game.sh
copy /f .\Urho3DPlayer.exe .\Release\
.\tool\ScriptCompiler.exe .\Release\MyData\Scripts\Test.as
del .\Release\MyData\Scripts\*.as
.\tool\PackageTool .\Release\CoreData .\Release\CoreData.pak -c -q
.\tool\PackageTool .\Release\Data .\Release\Data.pak -c -q
.\tool\PackageTool .\Release\MyData .\Release\MyData.pak -c -q
RMDIR /S /Q .\Release\CoreData
RMDIR /S /Q .\Release\Data
RMDIR /S /Q .\Release\MyData