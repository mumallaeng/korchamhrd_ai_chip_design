@echo off
setlocal

if not exist .venv (
  py -3 -m venv .venv
)

call .venv\Scripts\activate.bat
python -m pip install --upgrade pip
python -m pip install -r requirements-build.txt

pyinstaller ^
  -F ^
  -w ^
  --name clear-spreadsheet ^
  --additional-hooks-dir=. ^
  clear_spreadsheet_gui.py

echo.
echo Build complete:
echo dist\clear-spreadsheet.exe
