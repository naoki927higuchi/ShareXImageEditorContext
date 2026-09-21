$ErrorActionPreference = 'Stop'
dotnet publish (Join-Path $PSScriptRoot 'ShareXImageEditorContext.csproj') -c Release -r win-x64 --self-contained false
Copy-Item (Join-Path $PSScriptRoot 'bin\Release\net8.0-windows\win-x64\publish\ShareXImageEditorContext.exe') $PSScriptRoot -Force
Write-Host '発行完了: ShareXImageEditorContext.exe'
