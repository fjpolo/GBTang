@echo off
rem ============================================================================
rem GBTang - Build bitstream for Tang Nano 20K
rem
rem Usage:
rem   build.bat              - Build FPGA bitstream (nano20k)
rem   build.bat --firmware   - Build OSTang PicoRV32 firmware only
rem   build.bat --all        - Build firmware + FPGA bitstream
rem
rem Requires: Gowin IDE installed at C:\Gowin\Gowin_V1.9.9_x64\
rem ============================================================================

setlocal
set GWSH=C:\Gowin\Gowin_V1.9.9_x64\IDE\bin\gw_sh.exe
set PROJECT_DIR=%~dp0
set BUILD_TCL=%PROJECT_DIR%build.tcl
set FIRMWARE_DIR=%PROJECT_DIR%OSTang\firmware

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

echo ============================================================
echo   GBTang Build - Tang Nano 20K
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
    echo [*] Building FPGA bitstream for Tang Nano 20K [GBTang target]...
    if not exist "%GWSH%" (
        echo [ERROR] Gowin IDE not found at: %GWSH%
        echo         Install Gowin V1.9.9 or update GWSH path in build.bat
        exit /b 1
    )
    "%GWSH%" "%BUILD_TCL%" gbtang_nano20k
    if errorlevel 1 (
        echo [ERROR] FPGA synthesis/PnR failed.
        exit /b 1
    )
    echo [OK] Bitstream built.
    if exist impl\pnr\*.fs (
        echo [OK] Output bitstream:
        dir /b impl\pnr\*.fs
    )
)

echo.
echo Done!
exit /b 0
