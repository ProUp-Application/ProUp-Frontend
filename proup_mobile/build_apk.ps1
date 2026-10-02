# ============================================================
#  ProUp - Script de compilacion del APK (Windows)
#  Uso:  .\build_apk.ps1            (apunta al backend de Railway)
#        .\build_apk.ps1 -ApiUrl "http://10.0.2.2:3000/api/v1"   (backend local/emulador)
#
#  Incluye el workaround del bug de Flutter en Windows:
#  - .flutter-plugins-dependencies queda con rutas doble-escapadas que Gradle no resuelve
#  - un daemon de Gradle "viejo" cachea la evaluacion rota
# ============================================================
param(
  [string]$ApiUrl = "https://proup-backend-production.up.railway.app/api/v1"
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

Write-Host "1/4 flutter pub get..." -ForegroundColor Cyan
flutter pub get | Out-Null

Write-Host "2/4 corrigiendo rutas de .flutter-plugins-dependencies..." -ForegroundColor Cyan
$f = ".flutter-plugins-dependencies"
if (Test-Path $f) {
  $raw = Get-Content $f -Raw
  $fixed = $raw -replace '\\\\\\\\', '/'   # doble backslash escapado en JSON -> forward slash
  # UTF-8 SIN BOM: con BOM, el plugin-loader de Gradle no puede leer el JSON y el build falla
  [System.IO.File]::WriteAllText((Resolve-Path $f), $fixed, (New-Object System.Text.UTF8Encoding $false))
}

Write-Host "3/4 deteniendo daemons de Gradle..." -ForegroundColor Cyan
Get-CimInstance Win32_Process -Filter "Name='java.exe'" |
  Where-Object { $_.CommandLine -like '*GradleDaemon*' } |
  ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

Write-Host "4/4 compilando APK (API: $ApiUrl)..." -ForegroundColor Cyan
flutter build apk --release --no-pub --dart-define "API_BASE_URL=$ApiUrl"

$apk = "build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path $apk) {
  Copy-Item $apk "..\..\ProUp.apk" -Force
  Write-Host "APK listo: C:\Users\EYP\OneDrive\Documentos\Proup\ProUp.apk" -ForegroundColor Green
} else {
  Write-Host "No se genero el APK; revisa la salida de arriba." -ForegroundColor Red
}
