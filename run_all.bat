@echo off
echo.
echo ====================================================
echo    MuMuDVB Kompletna instalacija i pokretanje
echo ====================================================
echo.

echo 1. Kompajliranje MuMuDVB-a...
echo.

REM Idi u MuMuDVB direktorijum
cd /d "%~dp0\MuMuDVB"

REM Pokušaj da skines pthread biblioteku
echo Skidanje pthread-win32 biblioteke...
if not exist "pthread\lib" (
    mkdir "pthread\lib"
    echo NAPOMENA: Trebate ručno da preuzmete pthread-win32 biblioteku
    echo sa https://sourceforge.net/projects/pthreads-win32/
    echo i raspakujete u pthread\lib direktorijum
    echo.
)

REM Kompajliraj MuMuDVB sa Visual Studio
echo Kompajliranje MuMuDVB-a...
"C:\Program Files\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe" MuMuDVB.sln /p:Configuration=Release /p:Platform=x64

if %errorlevel% neq 0 (
    echo.
    echo UPOZORENJE: MuMuDVB kompajliranje možda nije uspešno
    echo Možete nastaviti sa web panel-om za konfiguraciju
    echo.
)

echo.
echo 2. Pokretanje web panel-a...
echo.

REM Idi u web_panel direktorijum
cd /d "%~dp0\web_panel"

REM Proveri da li su paketi instalirani
if not exist "node_modules" (
    echo Instaliranje npm paketa...
    call npm install
)

echo.
echo 3. Pokretanje servera...
echo.

REM Pokreni web panel server
start "MuMuDVB Web Panel" cmd /k "echo MuMuDVB Web Panel Server && echo Dostupan na: http://localhost:8080 && node server.js"

REM Sačekaj malo da se server pokrene
timeout /t 3 /nobreak >nul

REM Otvori web browser
start http://localhost:8080

echo.
echo ====================================================
echo               POKRETANJE ZAVRŠENO!
echo ====================================================
echo.
echo Web panel je dostupan na: http://localhost:8080
echo.
echo Možete koristiti panel za:
echo - Skeniranje DVB kanala
echo - Konfiguraciju MuMuDVB-a
echo - Integraciju sa OSCam-om
echo - Monitoring stream-ova
echo.
echo Za zatvaranje servera zatvorite terminal prozor
echo.
pause