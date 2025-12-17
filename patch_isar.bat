@echo off
echo Patching Isar plugin for Android compatibility...

set ISAR_PATH=%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\isar_flutter_libs-3.1.0+1\android

echo 1. Fixing AndroidManifest.xml...
powershell -Command "(Get-Content '%ISAR_PATH%\src\main\AndroidManifest.xml') -replace 'package=\"dev\.isar\.isar_flutter_libs\"', '' | Set-Content '%ISAR_PATH%\src\main\AndroidManifest.xml'"

echo 2. Fixing build.gradle...
powershell -Command "(Get-Content '%ISAR_PATH%\build.gradle') -replace 'android \{', 'android {\n    namespace \"dev.isar.isar_flutter_libs\"' | Set-Content '%ISAR_PATH%\build.gradle'"

echo Done! Run 'flutter run' again.