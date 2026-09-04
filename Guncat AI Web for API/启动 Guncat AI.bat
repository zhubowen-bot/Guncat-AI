@echo off
chcp 65001 >nul
cd /d "%~dp0"

setlocal enabledelayedexpansion

echo ==========================================
echo   Starting Guncat AI Local Server
echo ==========================================
echo.

REM Check if Python is available
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python not found. Please install Python and add it to PATH.
    echo Download: https://www.python.org/downloads/
    echo.
    pause
    exit /b 1
)

REM Try candidate ports in order and pick the first available one
set "CANDIDATE_PORTS=8080 8081 8082 8000 8888 5500 7777 9999"
set "FOUND_PORT="

for %%P in (%CANDIDATE_PORTS%) do (
    if "!FOUND_PORT!"=="" (
        netstat -ano | findstr ":%%P " | findstr LISTENING >nul 2>&1
        if !errorlevel! neq 0 (
            set "FOUND_PORT=%%P"
        )
    )
)

if "!FOUND_PORT!"=="" (
    echo [ERROR] All candidate ports are in use: %CANDIDATE_PORTS%
    echo Please close the programs using these ports and try again.
    echo.
    pause
    exit /b 1
)

echo   URL: http://localhost:!FOUND_PORT!
echo ==========================================
echo Tip: Close this window to stop the server.
echo.

start http://localhost:!FOUND_PORT!
python -m http.server !FOUND_PORT!
