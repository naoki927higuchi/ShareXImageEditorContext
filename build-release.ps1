$ErrorActionPreference = 'Stop'
$sdk = 'C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64'
$payload = New-Item -ItemType Directory -Path (Join-Path $PSScriptRoot ('release-payload-' + [guid]::NewGuid().ToString('N'))) 
$out = New-Item -ItemType Directory -Path (Join-Path $PSScriptRoot 'release\ShareXImageEditorContext-1.0.1-x64') -Force
# Copy only runtime files, never debug symbols, tests, or compiler outputs.
foreach ($file in @('ShareXImageEditorContext.exe','ShareXCommand.dll','D3DCompiler_47_cor3.dll','PresentationNative_cor3.dll','vcruntime140_cor3.dll','PenImc_cor3.dll','wpfgfx_cor3.dll')) {
 Copy-Item -LiteralPath (Join-Path $PSScriptRoot "dist\$file") -Destination $payload.FullName
}
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'dist\Assets') -Destination $payload.FullName -Recurse
[xml]$manifest = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'AppxManifest.xml') -Raw
$manifest.Package.Identity.Version = '1.0.1.0'
$manifest.Save((Join-Path $payload.FullName 'AppxManifest.xml'))
$package = Join-Path $out.FullName 'ShareXImageEditorContext.msix'
& "$sdk\makeappx.exe" pack /d $payload.FullName /p $package /o
if ($LASTEXITCODE) { throw 'Package creation failed.' }
$cert = Get-ChildItem Cert:\CurrentUser\My | Where-Object { $_.Subject -eq 'CN=ShareXImageEditorContext' -and $_.FriendlyName -eq 'ShareX context menu local distribution' -and $_.HasPrivateKey -and $_.NotAfter -gt (Get-Date).AddMonths(1) } | Sort-Object NotAfter -Descending | Select-Object -First 1
if (!$cert) {
 $cert = New-SelfSignedCertificate -Type CodeSigningCert -Subject 'CN=ShareXImageEditorContext' -FriendlyName 'ShareX context menu local distribution' -CertStoreLocation Cert:\CurrentUser\My -KeyAlgorithm RSA -KeyLength 3072 -HashAlgorithm SHA256 -KeyExportPolicy NonExportable -NotAfter (Get-Date).AddYears(5)
}
$cer = Join-Path $out.FullName 'ShareXImageEditorContext.cer'
Export-Certificate -Cert $cert -FilePath $cer -Force | Out-Null
& "$sdk\signtool.exe" sign /fd SHA256 /s My /sha1 $cert.Thumbprint $package
if ($LASTEXITCODE) { throw 'Signing failed.' }
$signature = Get-AuthenticodeSignature -FilePath $package
if ($signature.SignerCertificate.Thumbprint -ne $cert.Thumbprint -or $signature.Status -eq 'HashMismatch' -or $signature.Status -eq 'NotSigned') { throw 'Signature verification failed.' }
Copy-Item -Path (Join-Path $PSScriptRoot 'distribution\*') -Destination $out.FullName -Force
[ordered]@{
 Version = '1.0.1.0'
 Architecture = 'x64'
 PackageSHA256 = (Get-FileHash -LiteralPath $package -Algorithm SHA256).Hash
 CertificateSHA256 = (Get-FileHash -LiteralPath $cer -Algorithm SHA256).Hash
 CertificateThumbprint = $cert.Thumbprint
 CertificateExpires = $cert.NotAfter.ToString('o')
} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $out.FullName 'package-info.json') -Encoding UTF8
$zip = Join-Path $PSScriptRoot 'release\ShareXImageEditorContext-1.0.1-x64.zip'
Compress-Archive -Path $out.FullName -DestinationPath $zip -Force
Get-Item -LiteralPath $zip | Select-Object FullName,Length
