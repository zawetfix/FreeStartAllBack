@echo off
mode con: cols=50 lines=22
setlocal EnableDelayedExpansion
chcp 65001 >nul
title TrialRefresh StartAllBack

openfiles >nul 2>&1
if %errorlevel% NEQ 0 (
    mode con: cols=50 lines=5
    echo.
    echo  Run as Administrator required!
    pause
    exit /b
)

:: Colors
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (set "ESC=%%b")
set "R=%ESC%[0m"
set "Bold=%ESC%[1m"
set "Green=%ESC%[32m"
set "Red=%ESC%[31m"
set "Cyan=%ESC%[36m"
set "Yellow=%ESC%[33m"
set "Gray=%ESC%[90m"

:: Load language
set "LANG=EN"
for /f "tokens=3" %%i in ('reg query "HKCU\Software\TrialRefresh" /v "Lang" 2^>nul') do set "LANG=%%i"

call :SetLang

:menu
cls
call :CheckStatus

echo.
echo  %Bold%%Cyan%TrialRefresh%R%  %Gray%by zawetfix%R%
echo  %Gray%-------------------------------%R%

if "!_Auto!"=="1" (set "s=%Green%On%R%") else (set "s=%Red%Off%R%")
echo  %Bold%!L_Autoreset!%R%  !s!
echo  %Bold%!L_Interval!%R%  !_Days! !L_Days!
echo  %Bold%!L_LastReset!%R%  !_LastReset!

echo  %Gray%-------------------------------%R%
echo  %Bold%[1]%R%  !L_M1!
echo  %Bold%[2]%R%  !L_M2!
echo  %Bold%[3]%R%  %Green%!L_M3!%R%
echo  %Bold%[4]%R%  %Red%!L_M4!%R%
echo  %Bold%[5]%R%  %Yellow%!L_M5!%R%
echo  %Bold%[6]%R%  %Yellow%!L_M6!%R%
echo  %Bold%[7]%R%  %Gray%!L_M7!%R%
echo  %Bold%[8]%R%  !L_M8!
echo  %Gray%-------------------------------%R%
echo  %Gray%!L_Author!%R%
echo.

set /p "c= !L_Choose! "

if "%c%"=="1" goto reset
if "%c%"=="2" goto setdays
if "%c%"=="3" goto enable
if "%c%"=="4" goto disable
if "%c%"=="5" goto github
if "%c%"=="6" goto githubauthor
if "%c%"=="7" goto changelang
if "%c%"=="8" exit
goto menu

:reset
cls
echo.
echo  %Cyan%!L_Resetting!%R%
echo.

set "BASE=HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\CLSID"
set "DELETED=0"

for /f "tokens=*" %%k in ('reg query "%BASE%" 2^>nul') do (
    reg query "%%k" >nul 2>&1
    if !errorlevel!==0 (
        for /f %%s in ('reg query "%%k" 2^>nul ^| find /c /v ""') do (
            if %%s LEQ 1 (
                reg delete "%%k" /f >nul 2>&1
                set "DELETED=1"
            )
        )
    )
)

reg add "HKCU\Software\TrialRefresh" /v "LastReset" /t REG_SZ /d "%date%" /f >nul

if "!DELETED!"=="1" (
    echo  %Green%!L_ResetOK!%R%
) else (
    echo  %Gray%!L_ResetSkip!%R%
)

echo.
pause
goto menu

:setdays
cls
echo.
echo  %Cyan%!L_ChooseInterval!%R%
echo.
echo  %Bold%[1]%R%  7  !L_Days!
echo  %Bold%[2]%R%  14 !L_Days!
echo  %Bold%[3]%R%  31 !L_Days!
echo  %Bold%[4]%R%  98 !L_Days!
echo.
set /p "d= !L_Choose! "

if "%d%"=="1" set "NEW_DAYS=7"
if "%d%"=="2" set "NEW_DAYS=14"
if "%d%"=="3" set "NEW_DAYS=31"
if "%d%"=="4" set "NEW_DAYS=98"

if not defined NEW_DAYS goto menu

reg add "HKCU\Software\TrialRefresh" /v "Interval" /t REG_SZ /d "%NEW_DAYS%" /f >nul

schtasks /query /tn "TrialRefresh" >nul 2>&1
if %errorlevel%==0 (
    schtasks /delete /tn "TrialRefresh" /f >nul
    schtasks /create /tn "TrialRefresh" /tr "\"%~f0\" auto" /sc daily /mo %NEW_DAYS% /ru SYSTEM /f >nul
    echo.
    echo  %Green%!L_IntervalUpdated! %NEW_DAYS% !L_Days!!%R%
) else (
    echo.
    echo  %Yellow%!L_IntervalSaved! %NEW_DAYS% !L_Days!!%R%
    echo  %Gray%!L_AutoOffHint!%R%
)

echo.
pause
goto menu

:enable
cls
set "EN_DAYS=7"
for /f "tokens=3" %%i in ('reg query "HKCU\Software\TrialRefresh" /v "Interval" 2^>nul') do set "EN_DAYS=%%i"

schtasks /delete /tn "TrialRefresh" /f >nul 2>&1
schtasks /create /tn "TrialRefresh" /tr "\"%~f0\" auto" /sc daily /mo %EN_DAYS% /ru SYSTEM /f >nul

if %errorlevel%==0 (
    echo.
    echo  %Green%!L_AutoOn! %EN_DAYS% !L_Days!!%R%
) else (
    echo.
    echo  %Red%!L_AutoErr!%R%
)
echo.
pause
goto menu

:disable
cls
schtasks /delete /tn "TrialRefresh" /f >nul 2>&1

if %errorlevel%==0 (
    echo.
    echo  %Red%!L_AutoOff!%R%
) else (
    echo.
    echo  %Gray%!L_AutoNotFound!%R%
)
echo.
pause
goto menu

:changelang
if "!LANG!"=="EN" (
    set "LANG=RU"
) else (
    set "LANG=EN"
)
reg add "HKCU\Software\TrialRefresh" /v "Lang" /t REG_SZ /d "!LANG!" /f >nul
call :SetLang
goto menu

:github
start https://github.com/zawetfix/FreeStartAllBack
goto menu

:githubauthor
start https://github.com/zawetfix
goto menu

:CheckStatus
set "_Auto=0"
set "_Days=—"
set "_LastReset=—"
schtasks /query /tn "TrialRefresh" >nul 2>&1
if %errorlevel%==0 set "_Auto=1"
for /f "tokens=3" %%i in ('reg query "HKCU\Software\TrialRefresh" /v "Interval" 2^>nul') do set "_Days=%%i"
for /f "tokens=3*" %%i in ('reg query "HKCU\Software\TrialRefresh" /v "LastReset" 2^>nul') do set "_LastReset=%%i %%j"
exit /b

:SetLang
if "!LANG!"=="RU" (
    set "L_Autoreset=Auto-reset Trial:"
    set "L_Interval=Интервал:       "
    set "L_LastReset=Последний сброс:"
    set "L_Days=дней"
    set "L_M1=Сбросить пробник сейчас"
    set "L_M2=Настроить интервал (7/14/31/98 дней)"
    set "L_M3=Включить автозапуск"
    set "L_M4=Выключить автозапуск"
    set "L_M5=Открыть GitHub проекта"
    set "L_M6=Открыть GitHub автора"
    set "L_M7=Сменить язык (EN)"
    set "L_M8=Выход"
    set "L_Choose=Выберите действие:"
    set "L_Author=Автор: zawetfix  |  github.com/zawetfix"
    set "L_Resetting=Сбрасываем пробный период..."
    set "L_ResetOK=  Готово! Пробный период сброшен."
    set "L_ResetSkip=  Ключ не найден или уже сброшен."
    set "L_ChooseInterval=Выберите интервал автосброса:"
    set "L_IntervalUpdated=Интервал обновлён: каждые"
    set "L_IntervalSaved=Интервал сохранён:"
    set "L_AutoOffHint=Автозапуск выключен. Включите в пункте 3."
    set "L_AutoOn=Автозапуск ВКЛЮЧЕН! Каждые"
    set "L_AutoOff=Автозапуск ВЫКЛЮЧЕН!"
    set "L_AutoErr=Ошибка при создании задачи!"
    set "L_AutoNotFound=Задача не найдена или уже удалена."
) else (
    set "L_Autoreset=Auto-reset Trial:"
    set "L_Interval=Interval:      "
    set "L_LastReset=Last reset:    "
    set "L_Days=days"
    set "L_M1=Reset trial now"
    set "L_M2=Set interval (7/14/31/98 days)"
    set "L_M3=Enable auto-reset"
    set "L_M4=Disable auto-reset"
    set "L_M5=Open project GitHub"
    set "L_M6=Open author GitHub"
    set "L_M7=Change language (RU)"
    set "L_M8=Exit"
    set "L_Choose=Choose action:"
    set "L_Author=Author: zawetfix  |  github.com/zawetfix"
    set "L_Resetting=Resetting trial period..."
    set "L_ResetOK=  Done! Trial period has been reset."
    set "L_ResetSkip=  Key not found or already reset."
    set "L_ChooseInterval=Choose auto-reset interval:"
    set "L_IntervalUpdated=Interval updated: every"
    set "L_IntervalSaved=Interval saved:"
    set "L_AutoOffHint=Auto-reset is off. Enable it in option 3."
    set "L_AutoOn=Auto-reset ENABLED! Every"
    set "L_AutoOff=Auto-reset DISABLED!"
    set "L_AutoErr=Error creating scheduled task!"
    set "L_AutoNotFound=Task not found or already removed."
)
exit /b

:auto
powershell -NoProfile -Command ^
  "$basePath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\CLSID';" ^
  "$keys = Get-ChildItem -Path $basePath -ErrorAction SilentlyContinue;" ^
  "foreach ($key in $keys) {" ^
  "  $children = Get-ChildItem -Path $key.PSPath -ErrorAction SilentlyContinue;" ^
  "  $values = Get-ItemProperty -Path $key.PSPath -ErrorAction SilentlyContinue;" ^
  "  $valueCount = ($values.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' } | Measure-Object).Count;" ^
  "  $defaultVal = $values.'(default)';" ^
  "  if (-not $children -and $valueCount -eq 1 -and -not $defaultVal) {" ^
  "    Remove-Item -Path $key.PSPath -Recurse -Force -ErrorAction SilentlyContinue;" ^
  "  }" ^
  "}"
reg add "HKCU\Software\TrialRefresh" /v "LastReset" /t REG_SZ /d "%date:~4%" /f >nul
exit