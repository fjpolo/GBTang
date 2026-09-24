@echo off
rem ============================================================================
rem GBTang - Multi-Target Flash Dispatcher
rem
rem Usage:
rem   flash.bat nano20k       - Flash to Tang Nano 20K (default)
rem   flash.bat console60k    - Flash to Tang Console 60K
rem   flash.bat               - Defaults to nano20k
rem ============================================================================

set TARGET=%~1
if "%TARGET%"=="" set TARGET=nano20k

if /i "%TARGET%"=="nano20k" (
    shift
    call "%~dp0flash_nano20k.bat" %1 %2 %3 %4
    exit /b %errorlevel%
)

if /i "%TARGET%"=="console60k" (
    shift
    call "%~dp0flash_console60k.bat" %1 %2 %3 %4
    exit /b %errorlevel%
)

echo [ERROR] Unknown target: %TARGET%
echo Usage: flash.bat [nano20k^|console60k] [options]
exit /b 1
