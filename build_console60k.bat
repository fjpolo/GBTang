@echo off
rem ============================================================================
rem GBTang - Build bitstream for Tang Console 60K (GW5AT-LV60PG484AC1/I0)
rem
rem Usage:
rem   build_console60k.bat              - Build FPGA bitstream
rem   build_console60k.bat --firmware   - Build OSTang PicoRV32 firmware only
rem   build_console60k.bat --all        - Build firmware + FPGA bitstream
rem ============================================================================

setlocal
set GWSH=C:\Gowin\Gowin_V1.9.12_x64\IDE\bin\gw_sh.exe
if not exist "%GWSH%" set GWSH=C:\Gowin\Gowin_V1.9.9_x64\IDE\bin\gw_sh.exe
set PROJECT_DIR=%~dp0
set BUILD_TCL=%PROJECT_DIR%build.tcl

set BUILD_FW=0
set BUILD_FPGA=1

if /i "%~1"=="--firmware" (
    set BUILD_FW=1
    set BUILD_FPGA=0
)
if /i "%~1"=="--all" (
    set BUILD_FW=1
    set BUILD_FPGA=1
)

set TARGET_MODE=standalone
if /i "%~1"=="bl616" set TARGET_MODE=bl616
if /i "%~1"=="--bl616" set TARGET_MODE=bl616
if /i "%~2"=="bl616" set TARGET_MODE=bl616
if /i "%~2"=="--bl616" set TARGET_MODE=bl616

echo ============================================================
echo   GBTang Build - Tang Console 60K (GW5AT-60B) [%TARGET_MODE%]
echo ============================================================

if "%BUILD_FW%"=="1" (
    echo [*] Building OSTang PicoRV32 firmware via WSL...
    wsl -d Ubuntu-22.04 -- bash -c "cd /mnt/c/Workspace/FPGA/GBTang/OSTang/firmware && bash build.sh"
    if errorlevel 1 (
        echo [ERROR] Firmware build failed.
        exit /b 1
    )
    echo [OK] Firmware built: OSTang\firmware\firmware.bin
)

if "%BUILD_FPGA%"=="1" (
    echo [*] Building FPGA bitstream for Tang Console 60K [%TARGET_MODE%]...
    if not exist "%GWSH%" (
        echo [ERROR] Gowin IDE not found at: %GWSH%
        exit /b 1
    )
    if "%TARGET_MODE%"=="bl616" (
        "%GWSH%" "%BUILD_TCL%" console60k bl616
    ) else (
        "%GWSH%" "%BUILD_TCL%" gbtang_console60k
    )
    if errorlevel 1 (
        echo [ERROR] FPGA synthesis/PnR failed.
        exit /b 1
    )
    echo [OK] Bitstream built.
    if exist impl\pnr\gbtang_console60k.fs (
        echo [OK] Output bitstream:
        dir /b impl\pnr\gbtang_console60k.fs
    )
)

echo.
echo Done!
exit /b 0
