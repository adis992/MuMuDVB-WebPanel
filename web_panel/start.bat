@echo off
echo.
echo ====================================================
echo         MuMuDVB Web Panel - Pokretanje
echo ====================================================
echo.

REM Proveri da li su instalirati paketi
if not exist "node_modules" (
    echo GREŠKA: node_modules ne postoji!
    echo Molimo pokrenite setup.bat pre pokretanja
    echo.
    pause
    exit /b 1
)

echo Pokretanje MuMuDVB Web Panel servera...
echo.
echo Web panel će biti dostupan na: http://localhost:8080
echo WebSocket server će biti na: ws://localhost:8081
echo.
echo Za zaustavljanje pritisnite Ctrl+C
echo.

REM Pokreni server
node server.js

pause