param([switch]$Uninstall)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$exe = Join-Path $root 'ShareXImageEditorContext.exe'
$key = 'HKCU:\Software\Classes\SystemFileAssociations\image\shell\OpenWithShareXImageEditor'
if ($Uninstall) { Remove-Item $key -Recurse -Force -ErrorAction SilentlyContinue; Write-Host 'アンインストールしました。'; exit }
if (!(Test-Path $exe)) { throw "実行ファイルがありません: $exe`n先に publish.ps1 を実行してください。" }
New-Item $key -Force | Out-Null
Set-ItemProperty $key -Name '(default)' -Value 'ShareXイメージエディタで開く'
Set-ItemProperty $key -Name 'Icon' -Value "$exe,0"
New-Item "$key\command" -Force | Out-Null
Set-ItemProperty "$key\command" -Name '(default)' -Value "`"$exe`" %*"
Write-Host '登録しました。エクスプローラーを再起動すると反映されます。'
