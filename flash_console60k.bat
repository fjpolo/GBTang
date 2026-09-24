@echo off
rem ============================================================================
rem GBTang - Flash to Tang Console 60K (GW5AT-LV60PG484AC1/I0)
rem
rem Usage:
rem   flash_console60k.bat              - Flash bitstream to SPI Flash (persistent)
rem   flash_console60k.bat --sram       - Load to SRAM only (fast, volatile)
rem   flash_console60k.bat --firmware   - Flash OSTang firmware.bin to SPI Flash @ 0x500000
rem   flash_console60k.bat --all        - Flash bitstream + firmware
rem   flash_console60k.bat --build      - Build first, then flash everything
rem ============================================================================

setlocal enabledelayedexpansion
set PROGRAMMER=C:\Gowin\Gowin_V1.9.12_x64\Programmer\bin\programmer_cli.exe
if not exist "%PROGRAMMER%" set PROGRAMMER=C:\Gowin\Gowin_V1.9.9_x64\Programmer\bin\programmer_cli.exe
set PROJECT_DIR=%~dp0
set FIRMWARE_BIN=%PROJECT_DIR%OSTang\firmware\firmware.bin
set BITSTREAM=%PROJECT_DIR%impl\pnr\gbtang_console60k.fs

rem Kill any leftover programmer processes holding USB handles
taskkill /f /im programmer_cli.exe >nul 2>&1

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
    call "%PROJECT_DIR%build_console60k.bat" --all
    if errorlevel 1 (
        echo [ERROR] Build failed. Aborting flash.
        exit /b 1
    )
    set FLASH_FW=1
)

echo ============================================================
echo   GBTang Flash - Tang Console 60K (GW5AT-60B)
echo ============================================================

if not exist "%PROGRAMMER%" (
    echo [ERROR] Gowin Programmer not found at: %PROGRAMMER%
    exit /b 1
)

set CABLE_OPT=--device GW5AT-60B

rem Flash firmware first if requested
if "%FLASH_FW%"=="1" (
    if not exist "%FIRMWARE_BIN%" (
        echo [ERROR] Firmware not found: %FIRMWARE_BIN%
        echo         Run: build_console60k.bat --firmware  to build it.
        exit /b 1
    )
    echo [*] Flashing OSTang firmware @ 0x500000 via SPI...
    "%PROGRAMMER%" !CABLE_OPT! --spiaddr 0x500000 --fsFile "%FIRMWARE_BIN%" --run 36
    if errorlevel 1 (
        echo [ERROR] Firmware flash failed.
        exit /b 1
    )
    echo [OK] Firmware flashed.
)

rem Flash FPGA bitstream
if "%FLASH_FPGA%"=="1" (
    if not exist "%BITSTREAM%" (
        echo [ERROR] No bitstream found at: %BITSTREAM%
        echo         Run: build_console60k.bat  to build first.
        exit /b 1
    )
    echo [*] Bitstream : %BITSTREAM%
    if "%FLASH_MODE%"=="sram" (
        echo [*] Loading to SRAM ^(volatile^)...
        "%PROGRAMMER%" !CABLE_OPT! --fsFile "%BITSTREAM%" --run 2
    ) else (
        echo [*] Programming SPI Flash @ 0x000000 ^(persistent^)...
        "%PROGRAMMER%" !CABLE_OPT! --spiaddr 0x000000 --fsFile "%BITSTREAM%" --run 36
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
