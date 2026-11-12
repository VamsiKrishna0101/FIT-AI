param([string]$ApiBaseUrl = '')

$ErrorActionPreference = 'Stop'
$mobileRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$configPath = Join-Path $mobileRoot 'android\app\google-services.json'
$config = Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json
$androidClient = @($config.client | Where-Object {
    $_.client_info.android_client_info.package_name -eq 'com.setcraft.app'
})
if ($androidClient.Count -ne 1) {
    throw 'Download google-services.json for the Setcraft Android app with package com.setcraft.app.'
}
$webClients = @($androidClient[0].oauth_client | Where-Object {
    $_.client_type -eq 3
} | ForEach-Object { $_.client_id } | Select-Object -Unique)
if ($webClients.Count -ne 1 -or $webClients[0] -notmatch '^[0-9]+-[A-Za-z0-9_-]+\.apps\.googleusercontent\.com$') {
    throw 'Google sign-in is not configured in this file. Save the Google provider in Firebase, then download a fresh google-services.json.'
}
$source = @'
/// Public OAuth configuration verified against Setcraft's Firebase Android app.
/// Regenerate with tool/prepare_google_sign_in.ps1 when Firebase config changes.
abstract final class GoogleAuthConfig {
  static const androidEnabled = true;

  /// iOS OAuth client from ios/Runner/GoogleService-Info.plist (CLIENT_ID).
  static const iosClientId =
      '__IOS_CLIENT_ID__';
  static const serverClientId =
      '__WEB_CLIENT_ID__';
}
'@
$iosClientId = ''
$iosPlistPath = Join-Path $mobileRoot 'ios\Runner\GoogleService-Info.plist'
if (Test-Path -LiteralPath $iosPlistPath) {
    $iosMatch = [regex]::Match((Get-Content -Raw -LiteralPath $iosPlistPath),
        '<key>CLIENT_ID</key>\s*<string>([^<]+)</string>')
    if ($iosMatch.Success) { $iosClientId = $iosMatch.Groups[1].Value }
}
$sourcePath = Join-Path $mobileRoot 'lib\core\config\google_auth_config.dart'
$source = $source.Replace('__WEB_CLIENT_ID__', $webClients[0]).Replace('__IOS_CLIENT_ID__', $iosClientId) + "`n"
[System.IO.File]::WriteAllText($sourcePath, $source, [System.Text.UTF8Encoding]::new($false))
$defines = [ordered]@{
    SETCRAFT_GOOGLE_SIGN_IN = $true
    SETCRAFT_GOOGLE_SERVER_CLIENT_ID = $webClients[0]
}
if ($ApiBaseUrl) {
    $apiUri = $null
    if (-not [Uri]::TryCreate($ApiBaseUrl, [UriKind]::Absolute, [ref]$apiUri) -or
        $apiUri.Scheme -ne 'https' -or $apiUri.UserInfo -or $apiUri.Query -or $apiUri.Fragment) {
        throw 'Provide a public HTTPS API base URL without credentials, query parameters, or a fragment.'
    }
    $defines.SETCRAFT_API_BASE_URL = $ApiBaseUrl.TrimEnd('/')
}
$outputPath = Join-Path $mobileRoot 'build\setcraft-google-sign-in.json'
[System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($outputPath)) | Out-Null
[System.IO.File]::WriteAllText($outputPath, ($defines | ConvertTo-Json), [System.Text.UTF8Encoding]::new($false))
Write-Output 'Prepared build/setcraft-google-sign-in.json with public client configuration.'
Write-Output 'Updated the default Android Google configuration for ordinary Flutter builds.'
Write-Output 'From mobile/: flutter build appbundle --release --dart-define-from-file=build/setcraft-google-sign-in.json'
