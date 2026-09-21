param([switch]$Uninstall,[string]$ShareXPath = 'C:\Program Files\ShareX\ShareX.exe')
$ErrorActionPreference = 'Stop'
$name = 'Local.ShareXImageEditorContext'
if ($Uninstall) {
 Get-AppxPackage -Name $name | Remove-AppxPackage
 Write-Host 'Package removed.'
 exit
}
if (!(Test-Path -LiteralPath $ShareXPath -PathType Leaf)) { throw 'Specify the actual ShareX.exe path using -ShareXPath.' }
$manifest = Join-Path $PSScriptRoot 'dist\AppxManifest.xml'
if (!(Test-Path -LiteralPath $manifest)) { throw 'Run publish-modern.ps1 first.' }
Add-AppxPackage -Register $manifest
$key = 'HKCU:\Software\ShareXImageEditorContext'
New-Item $key -Force | Out-Null
New-ItemProperty $key -Name ShareXPath -Value (Resolve-Path -LiteralPath $ShareXPath).Path -PropertyType String -Force | Out-Null
Get-AppxPackage -Name $name | Select-Object Name,Status,InstallLocation
Write-Host 'Registered. Sign out and back in if the menu is not visible.'
