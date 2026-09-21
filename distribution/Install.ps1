param([switch]$Uninstall,[string]$ShareXPath)
$ErrorActionPreference = 'Stop'
try {
 $name = 'Local.ShareXImageEditorContext'
 if ($Uninstall) {
  Get-AppxPackage -Name $name | Remove-AppxPackage
  Write-Host 'Uninstalled. ShareX itself and the signing certificate were retained.'
  exit 0
 }
 if ([Environment]::OSVersion.Version.Build -lt 22000) { throw 'Windows 11 is required.' }
 $arch = [Environment]::GetEnvironmentVariable('PROCESSOR_ARCHITEW6432')
 if (!$arch) { $arch = $env:PROCESSOR_ARCHITECTURE }
 if ($arch -ne 'AMD64') { throw 'This package requires an Intel/AMD x64 Windows PC (not ARM64).' }
 $info = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'package-info.json') -Raw | ConvertFrom-Json
 $package = Join-Path $PSScriptRoot 'ShareXImageEditorContext.msix'
 $certificate = Join-Path $PSScriptRoot 'ShareXImageEditorContext.cer'
 if ((Get-FileHash -LiteralPath $package -Algorithm SHA256).Hash -ne $info.PackageSHA256) { throw 'Package checksum mismatch.' }
 if ((Get-FileHash -LiteralPath $certificate -Algorithm SHA256).Hash -ne $info.CertificateSHA256) { throw 'Certificate checksum mismatch.' }
 if (!$ShareXPath) {
  $candidates = @((Get-ItemProperty 'HKCU:\Software\ShareXImageEditorContext' -ErrorAction SilentlyContinue).ShareXPath)
  $candidates += @("$env:ProgramFiles\ShareX\ShareX.exe", "${env:ProgramFiles(x86)}\ShareX\ShareX.exe", "$env:LOCALAPPDATA\ShareX\ShareX.exe")
  foreach ($hive in @('HKCU:', 'HKLM:')) {
   foreach ($subkey in @('Software\Microsoft\Windows\CurrentVersion\Uninstall', 'Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall')) {
    Get-ItemProperty "$hive\$subkey\*" -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like 'ShareX*' -and $_.InstallLocation } | ForEach-Object { $candidates += Join-Path $_.InstallLocation 'ShareX.exe' }
   }
  }
  $ShareXPath = $candidates | Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Leaf) } | Select-Object -First 1
 }
 if (!$ShareXPath) {
  Add-Type -AssemblyName System.Windows.Forms
  $dialog = New-Object System.Windows.Forms.OpenFileDialog
  $dialog.Title = 'Select ShareX.exe'
  $dialog.Filter = 'ShareX executable|ShareX.exe'
  try { if ($dialog.ShowDialog() -eq 'OK') { $ShareXPath = $dialog.FileName } } finally { $dialog.Dispose() }
 }
 if (!$ShareXPath -or !(Test-Path -LiteralPath $ShareXPath -PathType Leaf) -or [IO.Path]::GetFileName($ShareXPath) -ine 'ShareX.exe') { throw 'ShareX.exe was not selected. Install ShareX first.' }
 $ShareXPath = (Resolve-Path -LiteralPath $ShareXPath).Path
 $cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($certificate)
 if ($cert.NotAfter -lt (Get-Date)) { throw 'Signing certificate has expired. Obtain a new package.' }
 if (!(Test-Path "Cert:\LocalMachine\TrustedPeople\$($cert.Thumbprint)")) {
  Write-Host 'Administrator approval is needed ONLY to trust this package signing certificate.'
  Write-Host "Certificate: $($cert.Subject) / $($cert.Thumbprint)"
  $helper = Join-Path $PSScriptRoot 'Trust-Certificate.ps1'
  $params = '-NoProfile -ExecutionPolicy Bypass -File "' + $helper + '" -ExpectedHash ' + $info.CertificateSHA256
  $process = Start-Process -FilePath "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -ArgumentList $params -Verb RunAs -Wait -PassThru -WindowStyle Hidden
  if ($process.ExitCode -ne 0) { throw 'Certificate registration failed or was cancelled.' }
 }
 $signature = Get-AuthenticodeSignature -FilePath $package
 if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Thumbprint -ne $cert.Thumbprint) { throw "Package signature is not valid: $($signature.Status)" }
 $existing = Get-AppxPackage -Name $name
 if ($existing -and $existing.IsDevelopmentMode) { throw 'A development registration exists. Run the old install-modern.ps1 -Uninstall first, then retry.' }
 Add-AppxPackage -Path $package
 $key = 'HKCU:\Software\ShareXImageEditorContext'
 New-Item $key -Force | Out-Null
 New-ItemProperty $key -Name ShareXPath -Value $ShareXPath -PropertyType String -Force | Out-Null
 Get-AppxPackage -Name $name | Select-Object Name,Version,Status
 Write-Host 'Installed. Right-click an image. Sign out and back in if the command is not visible.'
 exit 0
} catch { Write-Error $_; exit 1 }
