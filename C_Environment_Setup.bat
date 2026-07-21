@echo off

REM>Exit /B 2>NUL & GOTO :START
:: ============================================================================
::! @file       C_Program_Environment.bat
::! @brief      Automates build and deployment tasks for the project.
::! @details    This batch script handles setting up environment, downloading notes, removing unnecessary files and folder0 and running test.
::!
::! @author     Bamboo Grass
::! @version    3.2.0
::! @date       2026-07-21
::! @copyright  (c) 2026 Bamboo Code. All rights reserved.
:: ============================================================================
:START

setlocal EnableDelayedExpansion

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Not running as Administrator.
    echo [+] Requesting elevated window...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath 'cmd.exe' -ArgumentList '/k \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

title MinGW64 Automated Installer (ADMIN) - Bamboo grass
color 0B

set "SCRIPT_DIR=%~dp0"
set "ZIP_PATH=%SCRIPT_DIR%winlibs*.zip"
set "DEST_PATH=%SCRIPT_DIR%"

set "SOURCE_MINGW=%SCRIPT_DIR%mingw64"
set "TARGET_DIR=%ProgramFiles:~0,2%\mingw64"

cd /d "%SCRIPT_DIR%"

echo ========================================================
echo    RUNNING WITH ADMINISTRATOR PRIVILEGES
echo ========================================================
echo.
echo ========================================================
echo    Downloading Compiler
echo ========================================================

curl -L "https://github.com/brechtsanders/winlibs_mingw/releases/download/16.1.0posix-14.0.0-msvcrt-r3/winlibs-x86_64-posix-seh-gcc-16.1.0-mingw-w64msvcrt-14.0.0-r3.zip" -o "winlibs-x86_64-posix-seh-gcc-16.1.0-mingw-w64msvcrt-14.0.0-r3.zip"

if not exist "%ZIP_PATH%" (
    echo Error: Could not find source folder next to this script.
    echo Expected: %SOURCE_MINGW%
    exit
) else (
    echo ZIP folder exists.
)

echo =======================================================
echo    Checking for 7-Zip...
echo =======================================================
echo.

if not exist "%ProgramFiles%\7-Zip\7z.exe" (
    echo 7-Zip not found. Installing...
    winget install -e --id 7zip.7zip --silent --accept-source-agreements
    echo.

    if not exist "%ProgramFiles%\7-Zip\7z.exe" (
        echo Installation failed. Please check your internet connection.
        pause
    )
    echo 7-Zip successfully installed!
) else (
    echo 7-Zip is already installed on this machine.
)

if not exist "%SOURCE_MINGW%" (
    echo.
    echo ========================================================
    echo    Extracting file, please wait...
    echo ========================================================

    "%ProgramFiles%\7-Zip\7z.exe" x "%ZIP_PATH%" -o"%DEST_PATH%" -y

    echo ========================================================
    echo    Extraction complete!
    echo ========================================================
) else (
    echo Source folder verified.
)

echo.
echo ========================================================
echo    Installing Visual Studio Code
echo ========================================================

winget install Microsoft.VisualStudioCode --silent --accept-package-agreements --accept-source-agreements

echo Installation complete

set "VSCODE_PATH1=%LOCALAPPDATA%\Programs\Microsoft VS Code\bin"
set "VSCODE_PATH2=%ProgramFiles%\Microsoft VS Code\bin"
 
if exist "%VSCODE_PATH1%\code.cmd" (
    set "PATH=%VSCODE_PATH1%;%PATH%"
    echo     Found VS Code at: %VSCODE_PATH1%
) else if exist "%VSCODE_PATH2%\code.cmd" (
    set "PATH=%VSCODE_PATH2%;%PATH%"
    echo     Found VS Code at: %VSCODE_PATH2%
) else (
    :: Fallback: read updated PATH from the registry (works for machine-wide installs)
    for /f "tokens=2*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "SYS_PATH=%%B"
    set "PATH=%SYS_PATH%;%PATH%"
    echo     Used registry PATH fallback.
)
echo.

timeout /t 3 /nobreak >nul

echo.
echo ========================================================
echo     Installing VS Code Extensions
echo ========================================================

echo Installing C/C++ Extension Pack...
cmd /c "code --install-extension ms-vscode.cpptools-extension-pack --force 2>nul"
echo Installation complete
echo.

echo Installing Code Runner by Jun Han...
cmd /c "code --install-extension formulahendry.code-runner --force 2>nul"
echo Installation complete
echo.

echo Installing Prettier - Code Formatter...
cmd /c "code --install-extension esbenp.prettier-vscode --force 2>nul"
echo Installation complete
echo.

echo Installing Markdown Preview Enhanced by Yiyi Wang...
cmd /c "code --install-extension shd101wyy.markdown-preview-enhanced --force 2>nul"
echo Installation complete
echo.

echo All extensions installed!

if not exist "%TARGET_DIR%" (
    echo Copying MinGW to local disk %ProgramFiles:~0,2%\... This may take a minute...
    xcopy "%SOURCE_MINGW%" "%TARGET_DIR%" /E /I /H /Y >nul
    echo Copy complete!
) else (
    echo Target folder already exists on %ProgramFiles:~0,2%\. Skipping copy.
)
echo.

echo Updating System PATH safely...

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$targetBin = '%ProgramFiles:~0,2%\mingw64\bin';" ^
    "$regPath = 'HKCU:\Environment';" ^
    "$current = (Get-ItemProperty -Path $regPath -Name Path -ErrorAction SilentlyContinue).Path;" ^
    "if (-not $current) { $current = '' };" ^
    "$entries = $current -split ';' | Where-Object { $_ -ne '' };" ^
    "if ($entries -contains $targetBin) {" ^
    "    Write-Host '%ProgramFiles:~0,2%\mingw64\bin is already in your User PATH. No changes made.';" ^
    "} else {" ^
    "    $newPath = ($entries + $targetBin) -join ';';" ^
    "    Set-ItemProperty -Path $regPath -Name Path -Value $newPath -Type ExpandString;" ^
    "    [System.Environment]::SetEnvironmentVariable('Path', $newPath, 'User');" ^
    "    Write-Host 'Successfully added %ProgramFiles:~0,2%\mingw64\bin to your User PATH!';" ^
    "}"
echo.
echo =======================================================
echo     Downloading the latest Git for Windows installer...
echo =======================================================
echo.

if exist ".\git_installer.exe" (
    echo   git is already downloaded.
) else (
    curl -L -o git_installer.exe https://github.com/git-for-windows/git/releases/download/v2.45.2.windows.1/Git-2.45.2-64-bit.exe
)

echo.
echo =======================================================
echo    Download Complete! 
echo =======================================================
echo    Running the installer now...
echo =======================================================

start /wait git_installer.exe /VERYSILENT /NORESTART /NOCANCEL /SP-

echo.
echo =======================================================
echo    Installation Complete! 
echo =======================================================
echo    Downloading Notes and supporting Documents..
echo =======================================================

if not exist "learningC" (
    git clone "https://github.com/bamboograss001-lab/learningC"
)

echo. 
echo =======================================================
echo    Cleaning up the files
echo =======================================================

if exist "%ZIP_PATH%" (
    del /q "%ZIP_PATH%"
)
if exist "%SOURCE_MINGW%" (
    rmdir /s /q "%SOURCE_MINGW%"
)

if exist "git_installer.exe" (
    del /q git_installer.exe
)

echo =======================================================
echo    Creating a test file
echo =======================================================

(
    echo int printf^(const char *__format^, ...^);
    echo.
    echo int main ^(^) {
    echo     printf^("here"^);
    echo     return 0;
    echo }
) > test.c


echo =======================================================
echo    Test file has been created successfully!
echo =======================================================

echo.
echo ========================================================
echo    SETUP COMPLETE! You can close this window now.
echo ========================================================
echo.
chcp 65001 > nul
echo © 2026 bamboo grass
echo.

pause