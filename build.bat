@echo off
rem ============================================================================
rem GBTang - Multi-Target Build Dispatcher
rem
rem Usage:
rem   build.bat nano20k       - Build for Tang Nano 20K (default)
rem   build.bat console60k    - Build for Tang Console 60K
rem   build.bat               - Defaults to nano20k
rem ============================================================================

set TARGET=%~1
if "%TARGET%"=="" set TARGET=nano20k

if /i "%TARGET%"=="nano20k" (
    shift
    call "%~dp0build_nano20k.bat" %1 %2 %3 %4
    exit /b %errorlevel%
)

if /i "%TARGET%"=="console60k" (
    shift
    call "%~dp0build_console60k.bat" %1 %2 %3 %4
    exit /b %errorlevel%
)

echo [ERROR] Unknown target: %TARGET%
echo Usage: build.bat [nano20k^|console60k] [options]
exit /b 1
