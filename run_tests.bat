@echo off
REM Run all headless GDScript tests in scripts\tests\.
REM
REM Each test is an `extends SceneTree` script that quit(0) on pass / quit(1) on fail.
REM Resolve the Godot binary from (in order):
REM   1. first argument:        run_tests.bat "C:\path\to\Godot.exe"
REM   2. %GODOT% env variable
REM   3. a bare `godot` on PATH
REM
REM Exit code is 0 only if every test passes.

setlocal enabledelayedexpansion

REM %GODOT% may already be set in the environment; only override it with the arg
REM when an arg was actually passed. Fall back to a bare `godot` if neither is set.
if not "%~1"=="" set "GODOT=%~1"
if "%GODOT%"=="" set "GODOT=godot"

REM Run from this script's directory so res:// paths resolve.
pushd "%~dp0"

set "TESTS=scripts\tests\test_ship_movement.gd scripts\tests\test_health.gd scripts\tests\test_weapon.gd scripts\tests\test_feedback.gd"

set /a failed=0
set /a total=0
for %%t in (%TESTS%) do (
  set /a total+=1
  echo === %%t ===
  "%GODOT%" --headless --script "%%t"
  if errorlevel 1 (
    echo   -^> FAIL
    set /a failed+=1
  ) else (
    echo   -^> PASS
  )
  echo.
)

popd

if %failed%==0 (
  echo All %total% test file^(s^) passed.
  exit /b 0
) else (
  echo %failed% of %total% test file^(s^) FAILED.
  exit /b 1
)
