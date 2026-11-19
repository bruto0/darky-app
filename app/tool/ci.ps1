$ErrorActionPreference = 'Stop'
$app = Split-Path $PSScriptRoot -Parent
$repo = Split-Path $app -Parent

. (Join-Path $repo 'tools\env.ps1')

Push-Location $app
try {
  flutter pub get
  if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed' }

  flutter analyze
  if ($LASTEXITCODE -ne 0) { throw 'flutter analyze failed' }

  flutter test
  if ($LASTEXITCODE -ne 0) { throw 'flutter test failed' }

  $forbidden = @(
    $env:DARKY_PII_PHONE,
    $env:DARKY_PII_PASSWORD,
    $env:DARKY_PII_SECRET
  ) | Where-Object { $_ -and $_.Trim().Length -gt 0 }
  if ($forbidden.Count -eq 0) {
    Write-Output 'PII scan skipped: set DARKY_PII_PHONE/PASSWORD/SECRET to scan for real values'
  } else {
    $pattern = ($forbidden | ForEach-Object { [regex]::Escape($_) }) -join '|'
    $leaks = Get-ChildItem -Path lib,test -Recurse -File |
      Select-String -Pattern $pattern -AllMatches
    if ($leaks) {
      $leaks | ForEach-Object { Write-Output "$($_.Path):$($_.LineNumber)" }
      throw 'secret/PII pattern found'
    }
  }

  flutter build apk --debug
  if ($LASTEXITCODE -ne 0) { throw 'flutter build apk failed' }

  Write-Output 'CI OK'
} finally {
  Pop-Location
}
