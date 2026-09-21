$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'build-native.cmd')
if ($LASTEXITCODE) { throw 'Native build failed' }
dotnet publish (Join-Path $PSScriptRoot 'ShareXImageEditorContext.csproj') -c Release -r win-x64 --self-contained true -o (Join-Path $PSScriptRoot 'dist')
if ($LASTEXITCODE) { throw 'Launcher publish failed' }
Copy-Item (Join-Path $PSScriptRoot 'AppxManifest.xml') (Join-Path $PSScriptRoot 'dist') -Force
Add-Type -AssemblyName System.Drawing
$assets = New-Item -ItemType Directory -Path (Join-Path $PSScriptRoot 'dist\Assets') -Force
$bitmap = [System.Drawing.Bitmap]::new(150,150)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
try {
 $graphics.Clear([System.Drawing.Color]::SteelBlue)
 $bitmap.Save((Join-Path $assets.FullName 'Logo.png'),[System.Drawing.Imaging.ImageFormat]::Png)
} finally { $graphics.Dispose(); $bitmap.Dispose() }
& 'C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\makeappx.exe' pack /d (Join-Path $PSScriptRoot 'dist') /p (Join-Path $PSScriptRoot 'ShareXImageEditorContext.msix') /o
if ($LASTEXITCODE) { throw 'Package validation failed' }
