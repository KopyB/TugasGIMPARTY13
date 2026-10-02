@echo off
setlocal
set "RW_GODOT=%~1"
if not defined RW_GODOT set /p "RW_GODOT=Paste the path to your Godot 4.5.1 editor executable and press Enter "
set "RW_GODOT=%RW_GODOT:"=%"
if not exist "%RW_GODOT%" (
    echo The Godot editor executable could not be found.
    pause
    exit /b 1
)
pushd "%~dp0"
if not exist "build" mkdir "build"
echo Importing the project with Godot 4.5.1...
"%RW_GODOT%" --headless --path "%CD%" --editor --import
if errorlevel 1 goto failed
echo Creating the Windows debug build...
"%RW_GODOT%" --headless --path "%CD%" --export-debug "Windows Desktop" "%CD%\build\Rogue Waves.exe"
if errorlevel 1 goto failed
echo Export complete. Keep Rogue Waves.exe and Rogue Waves.pck together.
echo They are in the build folder beside this script.
popd
pause
exit /b 0
:failed
echo Godot reported an error. Review the output above.
popd
pause
exit /b 1
