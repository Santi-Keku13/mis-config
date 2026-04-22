@echo off
echo Iniciando tunel de Cloudflare...

:: 1. Limpiar el log anterior
if exist tunnel.log del tunnel.log

:: 2. Iniciar cloudflared (Asegurate de que cloudflared.exe esté en esta carpeta)
start /b cloudflared tunnel --url http://localhost:3001 > tunnel.log 2>&1

echo Esperando 10 segundos...
timeout /t 10 /nobreak > nul

:: 3. Extraer la URL
for /f "tokens=*" %%i in ('powershell -Command "Select-String -Path 'tunnel.log' -Pattern 'https://[a-z0-9-]+\.trycloudflare\.com' | ForEach-Object { $_.Matches.Value } | Select-Object -First 1"') do set NUEVA_URL=%%i

if "%NUEVA_URL%"=="" (
    echo [ERROR] No se detecto la URL. Revisa si cloudflared se esta ejecutando bien.
    pause
    exit /b
)

echo URL detectada: %NUEVA_URL%

:: 4. Crear el archivo JSON
echo {"API_BASE_URL": "%NUEVA_URL%"} > config.json

echo Subiendo a Netlify...
:: Usamos --build para que Netlify piense que ya se "construyó" localmente y no busque a Hugo
:: Usamos -m para evitar que intente sincronizar el archivo de configuración
call netlify deploy --dir=. --prod --build --message "Forzando subida directa"

echo.
echo ¡Hecho! Tu APK ya tiene la nueva direccion en:
echo https://config-manual-apk.netlify.app/config.json
echo.
pause