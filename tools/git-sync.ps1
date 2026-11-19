param(
  [Parameter(Mandatory = $true)]
  [string]$Message
)

$ErrorActionPreference = 'Stop'
Set-Location (Split-Path -Parent $PSScriptRoot)

git add -A
if (git diff --cached --quiet) {
  Write-Output 'No changes to commit.'
} else {
  git commit -m $Message
}
git push origin main
