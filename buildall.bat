@echo off
rem ============================================================================
rem GBTang - Batch Build All (for TangCore distribution or automated builds)
rem
rem Usage:
rem   buildall.bat              - Builds default target (console60k)
rem   buildall.bat console60k   - Builds console60k bitstream (.fs and .bin)
rem   buildall.bat nano20k      - Builds nano20k bitstream
rem   buildall.bat all          - Builds both console60k and nano20k
rem ============================================================================

setlocal
set PROJECT_DIR=%~dp0
cd /d "%PROJECT_DIR%"

set TARGET=%~1
if "%TARGET%"=="" set TARGET=console60k

if /i "%TARGET%"=="all" (
    echo [*] Building Tang Console 60K...
    call "%PROJECT_DIR%build_console60k.bat"
    if errorlevel 1 exit /b 1

    echo [*] Building Tang Nano 20K...
    call "%PROJECT_DIR%build_nano20k.bat"
    if errorlevel 1 exit /b 1

    exit /b 0
)

if /i "%TARGET%"=="console60k" (
    call "%PROJECT_DIR%build_console60k.bat" bl616
    exit /b %errorlevel%
)

if /i "%TARGET%"=="console60k_standalone" (
    call "%PROJECT_DIR%build_console60k.bat"
    exit /b %errorlevel%
)

if /i "%TARGET%"=="nano20k" (
    call "%PROJECT_DIR%build_nano20k.bat"
    exit /b %errorlevel%
)

echo [ERROR] Unknown target: %TARGET%
exit /b 1
