@echo off
setlocal EnableExtensions

rem Pack the root of this shader folder into a zip without the VCS files.
set "ROOT=%~dp0"
set "ZIP_NAME=AtmosphericShaders_0.zip"
set "SCRIPT_NAME=%~nx0"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$root = $env:ROOT; " ^
  "$zip = Join-Path $root $env:ZIP_NAME; " ^
  "$items = Get-ChildItem -Force -LiteralPath $root | Where-Object { " ^
  "    $_.Name -ne '.git' -and " ^
  "    $_.Name -ne '.gitignore' -and " ^
  "    $_.Name -ne 'changes.md' -and " ^
  "    $_.Name -ne $env:ZIP_NAME -and " ^
  "    $_.Name -ne $env:SCRIPT_NAME -and " ^
  "    $_.Extension -ne '.zip' " ^
  "}; " ^
  "if (-not $items) { throw 'Nothing to archive.' }; " ^
  "if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }; " ^
  "$args = @('-a','-c','-f',$zip,'-C',$root) + @($items.Name); " ^
  "& tar @args"

if errorlevel 1 (
    echo Failed to build zip.
    exit /b 1
)

echo Created "%ZIP_NAME%"
endlocal
