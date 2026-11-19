# Environment for D'arky builds and tests.
# Usage: . .\tools\env.ps1

$jdk = 'D:\distrib\devel\java\jdk-21.0.13+9'
$sdk = 'C:\Users\kir\AppData\Local\Android\Sdk'
$flutter = 'D:\distrib\devel\flutter'

if (-not (Test-Path "$jdk\bin\java.exe")) { Write-Warning "JDK not found: $jdk" }
if (-not (Test-Path "$sdk\platform-tools\adb.exe")) { Write-Warning "Android SDK not found: $sdk" }
if (-not (Test-Path "$flutter\bin\flutter.bat")) { Write-Warning "Flutter not found: $flutter" }

$env:JAVA_HOME = $jdk
$env:ANDROID_HOME = $sdk
$env:ANDROID_SDK_ROOT = $sdk
$env:GRADLE_USER_HOME = 'J:\.gradle'

$env:Path = "$jdk\bin;$sdk\platform-tools;$sdk\cmdline-tools\latest\bin;$flutter\bin;$env:Path"

Write-Host "JAVA_HOME=$env:JAVA_HOME"
Write-Host "ANDROID_HOME=$env:ANDROID_HOME"
Write-Host "GRADLE_USER_HOME=$env:GRADLE_USER_HOME"
Write-Host "Flutter=$flutter"
