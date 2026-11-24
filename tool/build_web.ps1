# Builds Bloxie for the browser and packages it for itch.io.
#
# Usage:  powershell -File tool\build_web.ps1
# Output: dist/bloxie-web.zip  (upload to itch.io as an HTML project)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

Set-Location $root
flutter build web --release --pwa-strategy=none
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# itch.io serves the game from a subpath, so the base href must be relative.
# flutter build web does not accept "./" as --base-href, so patch after build.
$index = Join-Path $root 'build\web\index.html'
(Get-Content $index -Raw) -replace '<base href="/">', '<base href="./">' |
    Set-Content $index -Encoding utf8 -NoNewline

$dist = Join-Path $root 'dist'
New-Item -ItemType Directory -Force $dist | Out-Null
$zip = Join-Path $dist 'bloxie-web.zip'
if (Test-Path $zip) { Remove-Item $zip }

Compress-Archive -Path (Join-Path $root 'build\web\*') -DestinationPath $zip
Write-Host "Packaged: $zip"
Write-Host ''
Write-Host 'itch.io setup:'
Write-Host '  1. Upload bloxie-web.zip to your itch.io project'
Write-Host '  2. "Kind of project" = HTML, tick "played in the browser"'
Write-Host '  3. Viewport ~480x854 (portrait) or 960x640 (landscape), enable fullscreen'
