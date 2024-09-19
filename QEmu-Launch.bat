:: QEmu Batch Installer

:: DO NOT MOVE OR UPDATE THIS SECTION: START
@echo off
setlocal enabledelayedexpansion

:: QEmu Batch Installer
:: DO NOT MOVE OR UPDATE THIS SECTION: START
echo Initialization Complete.
timeout /t 1 >nul
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo Error: Admin Required!
    echo Right Click, then Run As Administrator.
    timeout /t 3 >nul
    goto :end_of_script
)
echo Status: Administrator
timeout /t 1 >nul
set "ScriptDirectory=%~dp0"
set "ScriptDirectory=%ScriptDirectory:~0,-1%"
cd /d "%ScriptDirectory%"
echo Dp0'd to Script.
goto check_virtualization
timeout /t 1 >nul
:: DO NOT MOVE OR UPDATE THIS SECTION: END

:: Globals
set "persistence_file=.\data\persistence.txt"
set "config_file=.\data\config.txt"

:check_virtualization
echo Checking virtualization support...
systeminfo | findstr /C:"Virtualization Enabled In Firmware" | findstr /C:"Yes" >nul
if %errorlevel% EQU 0 (
    set "accel_option=accel=whpx"
    echo Using WHPX hardware acceleration.
    timeout /t 2 >nul
) else (
    set "accel_option=accel=tcg"
    echo Virtualization not enabled/detected.
    echo Using software emulation TCG.
    timeout /t 2 >nul
)
timeout /t 1 >nul
goto initialize_files

:initialize_files
if not exist ".\data" mkdir ".\data"

if not exist "%persistence_file%" (
    echo E:\QEmuDisk\ubuntu_24_04_1.img>"%persistence_file%"
    echo Default disk image added to persistence file.
)

if not exist "%config_file%" (
    echo 4>"%config_file%"
    echo 8192>>"%config_file%"
    echo G:>>"%config_file%"
    echo Default configuration created.
)

goto load_config

:load_config
< "%config_file%" (
    set /p cpus=
    set /p memory_mb=
    set /p cd_drive=
)
goto menu

:menu
cls
echo ========================================================================================================================
echo     QEmu Batch Installer
echo ========================================================================================================================
echo.
echo     1. Run QEmu with Image (WHPX)
echo     2. Run QEmu with Image (TCG)
echo     3. Create 20GB Drive Image
echo     4. Configure Settings
echo     5. Run Diagnostic Commands
echo.
echo ========================================================================================================================
set /p choice=Selection; Menu Option = 1-5, Exit Program = X: 
if "%choice%"=="1" set "accel_option=accel=whpx" & goto run_qemu_advanced
if "%choice%"=="2" set "accel_option=accel=tcg" & goto run_qemu_advanced
if "%choice%"=="3" goto run_diagnostics
if "%choice%"=="4" goto create_image
if "%choice%"=="5" goto configure_settings
if /i "%choice%"=="x" goto end_of_script
echo Invalid choice. Please try again.
timeout /t 2 >nul
goto menu

:run_qemu_advanced
echo Run QEmu...
timeout /t 1 >nul

echo Available disk images:
set /a count=0
for /f "tokens=*" %%a in (%persistence_file%) do (
    set /a count+=1
    echo !count!. %%a
)

set /p image_choice=Enter the number of the disk image you want to use: 
set /a image_choice-=1
for /f "tokens=* skip=%image_choice%" %%a in (%persistence_file%) do (
    set "image_path=%%a"
    goto :run_qemu
)

:run_qemu
echo Running QEmu...
@echo on
.\qemu-system-x86_64.exe ^
    -machine type=q35,%accel_option% ^
    -cpu max ^
    -m %memory_mb% ^
    -smp %cpus% ^
    -drive file=%image_path%,media=disk,if=virtio ^
    -cdrom %cd_drive% ^
    -boot order=dc ^
    -net nic,model=virtio ^
    -net user ^
    -display sdl
@echo off
pause
goto menu

:create_image
echo Create Disk Image...
timeout /t 1 >nul
set /p image_path=Enter full path for new disk image (e.g., E:\QEmuDisk\ubuntu_24_04_1.img): 
echo Creating 20GB Drive Image...
@echo on
.\qemu-img.exe create -f qcow2 %image_path% 20G
.\qemu-img.exe info %image_path%
@echo off
echo %image_path%>>"%persistence_file%"
echo Image path added to persistence file.
pause
goto menu

:run_diagnostics
echo Running Diagnostic Commands...
echo.
echo Checking system information...
systeminfo | findstr /i "OS Name OS Version System Type Processor(s) BIOS Version"
echo.
echo Checking virtualization status...
systeminfo | findstr /i "Virtualization"
wmic cpu get virtualizationfirmwareenabled
echo.
echo Checking Hyper-V status...
systeminfo | findstr /i "Hyper-V"
bcdedit | findstr hypervisorlaunchtype
echo.
echo Checking Windows features...
dism /online /get-features | findstr /i "Hyper-V VirtualMachinePlatform"
echo.
echo Checking WSL status...
wsl --status
echo.
echo Checking disk space...
wmic logicaldisk get deviceid, freespace, size
echo.
echo Checking QEMU version...
.\qemu-system-x86_64.exe --version
echo.
pause
goto menu

:configure_settings
echo Configure Settings
echo Current settings:
echo CPUs: %cpus%
echo Memory (MB): %memory_mb%
echo CD Drive: %cd_drive%
echo.
set /p new_cpus=Enter number of CPUs (current: %cpus%): 
set /p new_memory_mb=Enter memory in MB (current: %memory_mb%): 
set /p new_cd_drive=Enter CD drive letter (current: %cd_drive%): 
echo %new_cpus%>"%config_file%"
echo %new_memory_mb%>>"%config_file%"
echo %new_cd_drive%>>"%config_file%"
echo Settings updated.
pause
goto load_config

:end_of_script
echo Shutting down...
endlocal
pause