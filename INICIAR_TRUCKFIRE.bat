@echo off
setlocal EnableExtensions
cd /d "%~dp0"

if not exist "%~dp0project.godot" (
    echo ERROR: No encuentro project.godot.
    echo Extrae el ZIP completo y deja este BAT junto a project.godot.
    pause
    exit /b 1
)

set "GODOT_EXE="

REM Busca Godot en el PATH.
for %%G in (godot.exe godot4.exe) do (
    for /f "delims=" %%P in ('where %%G 2^>nul') do (
        set "GODOT_EXE=%%P"
        goto found
    )
)

REM Busca instalaciones habituales de Godot 4.7.
for %%G in (
    "%ProgramFiles%\Godot\Godot_v4.7-stable_win64.exe"
    "%ProgramFiles%\Godot\godot.exe"
    "%LOCALAPPDATA%\Programs\Godot\Godot_v4.7-stable_win64.exe"
    "%LOCALAPPDATA%\Programs\Godot\godot.exe"
    "%USERPROFILE%\Downloads\Godot_v4.7-stable_win64.exe"
    "%USERPROFILE%\Downloads\Godot_v4.7-stable_win64_console.exe"
) do (
    if exist "%%~G" (
        set "GODOT_EXE=%%~G"
        goto found
    )
)

echo No encuentro Godot 4.7.
echo Instala Godot 4.7 para Windows o anade godot.exe al PATH.
echo Descarga oficial: https://godotengine.org/download/windows/
pause
exit /b 1

:found
echo Preparando Truckfire: importando recursos por primera vez...
"%GODOT_EXE%" --headless --editor --path "%~dp0" --quit
if errorlevel 1 (
    echo.
    echo ERROR al importar el proyecto. Revisa que tengas Godot 4.7.
    pause
    exit /b 1
)

echo Abriendo Truckfire...
start "Truckfire" "%GODOT_EXE%" --path "%~dp0"
exit /b 0
