@echo off
if exist "%~dp0Urho3DPlayer.exe" (set "DEBUG=") else (set "DEBUG=_d")
start "" "%~dp0Urho3DPlayer%DEBUG%" Scripts/BatchProcessAsset.as  -p CoreData;Data;MyData -headless
