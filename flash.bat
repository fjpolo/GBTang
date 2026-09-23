@echo off
rem ============================================================================
rem GBTang - Flash to Tang Nano 20K
rem
rem Usage:
rem   flash.bat              - Flash bitstream to SPI Flash (persistent)
rem   flash.bat --sram       - Load to SRAM only (fast, volatile)
rem   flash.bat --firmware   - Flash OSTang firmware.bin to SPI Flash @ 0x500000
rem   flash.bat --all        - Flash bitstream + firmware
rem   flash.bat --build      - Build first, then flash everything
rem
rem Requires: Gowin Programmer installed at C:\Gowin\Gowin_V1.9.9_x64\
rem ============================================================================

setlocal enabledelayedexpansion
set PROGRAMMER=C:\Gowin\Gowin_V1.9.9_x64\Programmer\bin\programmer_cli.exe
set PROJECT_DIR=%~dp0
set FIRMWARE_BIN=%PROJECT_DIR%OSTang\firmware\firmware.bin
set BITSTREAM=

rem Kill any leftover programmer processes holding USB handles
taskkill /f /im programmer_cli.exe >nul 2>&1

rem Find the latest .fs bitstream
for /f %%f in ('dir /b /o-d "%PROJECT_DIR%impl\pnr\*.fs" 2^>nul') do (
    if not defined BITSTREAM set BITSTREAM=%PROJECT_DIR%impl\pnr\%%f
)

set FLASH_MODE=flash
set FLASH_FW=0
set FLASH_FPGA=1

if /i "%~1"=="--sram" (
    set FLASH_MODE=sram
)
if /i "%~1"=="--firmware" (
    set FLASH_FPGA=0
    set FLASH_FW=1
)
if /i "%~1"=="--all" (
    set FLASH_FW=1
)
if /i "%~1"=="--build" (
    echo [*] Building first...
    call "%PROJECT_DIR%build.bat" --all
    if errorlevel 1 (
        echo [ERROR] Build failed. Aborting flash.
        exit /b 1
    )
    rem Re-discover bitstream after build
    for /f %%f in ('dir /b /o-d "%PROJECT_DIR%impl\pnr\*.fs" 2^>nul') do (
        if not defined BITSTREAM set BITSTREAM=%PROJECT_DIR%impl\pnr\%%f
    )
    set FLASH_FW=1
)

echo ============================================================
echo   GBTang Flash - Tang Nano 20K
echo ============================================================

if not exist "%PROGRAMMER%" (
    echo [ERROR] Gowin Programmer not found at: %PROGRAMMER%
    exit /b 1
)

set CABLE_OPT=--cable-index 4 --channel 1
echo [*] Using Tang Nano 20K JTAG (USB Debugger A, Channel 1)...

rem When flashing persistent SPI flash, silence running FPGA logic first
if not "%FLASH_MODE%"=="sram" (
    echo [*] Silencing FPGA core ^(SRAM erase to prevent bus contention^)...
    "%PROGRAMMER%" !CABLE_OPT! --device GW2AR-18C --run 24 >nul 2>&1
    python -c "import time; time.sleep(1)"
)

rem Flash firmware first if requested
if "%FLASH_FW%"=="1" (
    if not exist "%FIRMWARE_BIN%" (
        echo [ERROR] Firmware not found: %FIRMWARE_BIN%
        echo         Run: build.bat --firmware  to build it.
        exit /b 1
    )
    echo [*] Flashing OSTang firmware @ 0x500000 via GAO-Bridge...
    "%PROGRAMMER%" !CABLE_OPT! --device GW2AR-18C --spiaddr 0x500000 --fsFile "%FIRMWARE_BIN%" --run 36
    if errorlevel 1 (
        echo [ERROR] Firmware flash failed.
        exit /b 1
    )
    echo [OK] Firmware flashed.
    rem Re-silence before bitstream flash
    if "%FLASH_FPGA%"=="1" (
        "%PROGRAMMER%" !CABLE_OPT! --device GW2AR-18C --run 24 >nul 2>&1
        python -c "import time; time.sleep(1)"
    )
)

rem Flash FPGA bitstream
if "%FLASH_FPGA%"=="1" (
    if not defined BITSTREAM (
        echo [ERROR] No .fs bitstream found in impl\pnr\
        echo         Run: build.bat  to build first.
        exit /b 1
    )
    echo [*] Bitstream : %BITSTREAM%
    if "%FLASH_MODE%"=="sram" (
        echo [*] Loading to SRAM ^(volatile^)...
        "%PROGRAMMER%" !CABLE_OPT! --device GW2AR-18C --fsFile "%BITSTREAM%" --run 2
    ) else (
        echo [*] Programming SPI Flash @ 0x000000 via GAO-Bridge ^(persistent^)...
        "%PROGRAMMER%" !CABLE_OPT! --device GW2AR-18C --spiaddr 0x000000 --fsFile "%BITSTREAM%" --run 36
    )
    if errorlevel 1 (
        echo [ERROR] Bitstream flash failed.
        exit /b 1
    )
    echo [OK] Bitstream flashed.
)

echo.
echo Done!
exit /b 0
