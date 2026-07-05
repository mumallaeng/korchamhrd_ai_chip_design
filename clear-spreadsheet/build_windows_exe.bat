@echo off
setlocal
cd /d "%~dp0"

set "PYTHON_LAUNCHER="

where py >nul 2>nul
if %errorlevel%==0 (
  set "PYTHON_LAUNCHER=py -3"
)

if not defined PYTHON_LAUNCHER (
  where python >nul 2>nul
  if %errorlevel%==0 (
    set "PYTHON_LAUNCHER=python"
  )
)

if not defined PYTHON_LAUNCHER (
  echo Python 3 is required to build the Windows exe.
  echo Install Python first, then run this script again.
  echo.
  echo Suggested command:
  echo winget install -e --id Python.Python.3.12 --accept-package-agreements --accept-source-agreements
  exit /b 1
)

if not exist .venv (
  call %PYTHON_LAUNCHER% -m venv .venv
  if errorlevel 1 exit /b 1
)

call .venv\Scripts\activate.bat
if errorlevel 1 exit /b 1

python -m pip install --upgrade pip
if errorlevel 1 exit /b 1

python -m pip install -r requirements-build.txt
if errorlevel 1 exit /b 1

python -m PyInstaller ^
  -F ^
  -w ^
  --name clear-spreadsheet ^
  --additional-hooks-dir=. ^
  clear_spreadsheet_gui.py
if errorlevel 1 exit /b 1

echo.
echo Build complete:
echo %CD%\dist\clear-spreadsheet.exe
