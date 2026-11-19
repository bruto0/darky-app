<#
.SYNOPSIS
    Проверка авторизации impulseCRM так, чтобы пароль не покидал ваш компьютер.

.DESCRIPTION
    Скрипт логинится в контур, прогоняет проверки из чек-листа и пишет отчёт,
    в котором нет ни пароля, ни полного идентификатора сессии: только HTTP-статусы,
    имена полей ответа и длина сессии.

    Пароль спрашивается интерактивно и в отчёт не попадает. Для автоматизации можно
    заранее положить его в переменную окружения CHECK_AUTH_PASSWORD.

    Работает и в Windows PowerShell 5.1, и в PowerShell 7.

.PARAMETER BaseUrl
    Адрес контура, например https://4621c03198bd6735334088.impulsemini.ru

.PARAMETER Username
    Логин (телефон) тестового пользователя.

.PARAMETER ApiKey
    Необязательно. Ключ API — чтобы проверить, отдаёт ли user/load поля apiToken и password.

.PARAMETER UserId
    Необязательно. Чей профиль читать ключом API (по умолчанию — id залогиненного пользователя).

.EXAMPLE
    powershell -File .\check-auth.ps1 -BaseUrl https://4621c03198bd6735334088.impulsemini.ru -Username +79990000000

.EXAMPLE
    powershell -File .\check-auth.ps1 -BaseUrl https://<tenant>.impulsemini.ru -Username +7... -ApiKey <ключ>
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$BaseUrl,
    [Parameter(Mandatory = $true)][string]$Username,
    [string]$ApiKey,
    [int]$UserId = 0,
    [string]$OutFile = (Join-Path $PSScriptRoot 'check-report.json')
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
if (-not $ApiKey -and $env:CHECK_AUTH_API_KEY) { $ApiKey = $env:CHECK_AUTH_API_KEY }
$BaseUrl = $BaseUrl.TrimEnd('/')

Add-Type -AssemblyName System.Net.Http -ErrorAction SilentlyContinue
$script:Http = New-Object System.Net.Http.HttpClient
$script:Http.Timeout = [TimeSpan]::FromSeconds(40)

function Write-Step([string]$Text) { Write-Host "== $Text" -ForegroundColor Cyan }

function Invoke-Api {
    param(
        [string]$Path,
        [string]$Method = 'GET',
        $Body,
        [hashtable]$Headers = @{},
        [string]$ContentType = 'application/json'
    )
    $req = New-Object System.Net.Http.HttpRequestMessage
    $req.Method = New-Object System.Net.Http.HttpMethod($Method)
    $req.RequestUri = New-Object System.Uri($BaseUrl + $Path)
    foreach ($k in $Headers.Keys) {
        [void]$req.Headers.TryAddWithoutValidation($k, [string]$Headers[$k])
    }
    if ($null -ne $Body) {
        if ($Body -is [hashtable]) {
            $pairs = foreach ($k in $Body.Keys) {
                '{0}={1}' -f [Uri]::EscapeDataString([string]$k), [Uri]::EscapeDataString([string]$Body[$k])
            }
            $payload = $pairs -join '&'
        }
        else {
            $payload = [string]$Body
        }
        $req.Content = New-Object System.Net.Http.StringContent($payload, [Text.Encoding]::UTF8, $ContentType)
    }
    try {
        $resp = $script:Http.SendAsync($req).GetAwaiter().GetResult()
        $text = $resp.Content.ReadAsStringAsync().GetAwaiter().GetResult()
        $cookie = ''
        $vals = $null
        if ($resp.Headers.TryGetValues('Set-Cookie', [ref]$vals)) { $cookie = (@($vals) -join '; ') }
        [pscustomobject]@{ Status = [int]$resp.StatusCode; Body = [string]$text; Cookie = $cookie }
    }
    catch {
        [pscustomobject]@{
            Status = -1
            Body   = 'REQUEST_FAILED: ' + $_.Exception.GetBaseException().Message
            Cookie = ''
        }
    }
}

function Convert-JsonOrNull([string]$Text) {
    if ([string]::IsNullOrWhiteSpace($Text)) { return $null }
    try { return $Text | ConvertFrom-Json -ErrorAction Stop } catch { return $null }
}

function Mask([string]$Value) {
    if ([string]::IsNullOrEmpty($Value)) { return $null }
    $head = if ($Value.Length -ge 4) { $Value.Substring(0, 4) } else { $Value }
    return ('{0}...(len={1})' -f $head, $Value.Length)
}

# ---------- 1. Логин ----------
Write-Step '1. Логин (пароль запрашивается локально, в отчёт не попадает)'
if ($env:CHECK_AUTH_PASSWORD) {
    $plain = $env:CHECK_AUTH_PASSWORD
}
else {
    $secure = Read-Host -Prompt "Пароль для $Username" -AsSecureString
    $plain = [System.Net.NetworkCredential]::new('', $secure).Password
    $secure = $null
}

$login = Invoke-Api -Path '/api/public/user/login' -Method 'POST' `
    -Body @{ username = $Username; password = $plain } `
    -ContentType 'application/x-www-form-urlencoded' `
    -Headers @{ Accept = 'application/json' }
$plain = $null    # больше не нужен

$loginJson = Convert-JsonOrNull $login.Body
$session = $null
if ($loginJson -and ($loginJson.PSObject.Properties.Name -contains 'session')) { $session = [string]$loginJson.session }

$shortBody = if ($login.Body.Length -gt 200) { $login.Body.Substring(0, 200) } else { $login.Body }

$report = [ordered]@{
    baseUrl   = $BaseUrl
    username  = $Username
    checkedAt = (Get-Date).ToString('s')
    login     = [ordered]@{
        httpStatus   = $login.Status
        success      = if ($loginJson) { $loginJson.success } else { $null }
        message      = if ($loginJson) { $loginJson.message } else { $shortBody }
        responseKeys = if ($loginJson) { @($loginJson.PSObject.Properties.Name) } else { @() }
        hasSession   = [bool]$session
        sessionMask  = Mask $session
        setCookie    = if ($login.Cookie) { ($login.Cookie -replace '=[^;]+', '=***') } else { $null }
    }
}

if (-not $session) {
    Write-Host ("Логин не удался: HTTP {0}; тело: {1}" -f $login.Status, $shortBody) -ForegroundColor Yellow
    $report | ConvertTo-Json -Depth 6 | Set-Content -Path $OutFile -Encoding UTF8
    Write-Host "Отчёт: $OutFile"
    return
}

Write-Host ("Сессия получена: {0}" -f (Mask $session)) -ForegroundColor Green

# ---------- 2. Проверки с сессией ----------
Write-Step '2. Проверки с сессией'

$currentQ = Invoke-Api -Path "/api/public/user/current?PHPSESSID=$session" -Headers @{ Accept = 'application/json' }
$currentJson = Convert-JsonOrNull $currentQ.Body
$myId = $null
if ($currentJson -and ($currentJson.PSObject.Properties.Name -contains 'id')) { $myId = [int]$currentJson.id }

$cookieQ = Invoke-Api -Path '/api/public/user/current' -Headers @{ Accept = 'application/json'; Cookie = "PHPSESSID=$session" }

$branchQ = Invoke-Api -Path "/api/public/branch/load/1?PHPSESSID=$session" -Headers @{ Accept = 'application/json' }

$listQ = Invoke-Api -Path "/api/public/user/list?PHPSESSID=$session" -Method 'POST' `
    -Body '{"limit":1,"fields":["id","username"]}' -Headers @{ Accept = 'application/json' }

$refreshQ = Invoke-Api -Path "/api/public/user/refresh_token?PHPSESSID=$session" -Method 'POST' `
    -Body '{}' -Headers @{ Accept = 'application/json' }
$refreshJson = Convert-JsonOrNull $refreshQ.Body
$refreshSession = $null
if ($refreshJson -and ($refreshJson.PSObject.Properties.Name -contains 'session')) { $refreshSession = [string]$refreshJson.session }

$listJson = Convert-JsonOrNull $listQ.Body

$report['session'] = [ordered]@{
    currentViaQuery  = [ordered]@{
        httpStatus = $currentQ.Status
        userId     = $myId
        username   = if ($currentJson) { $currentJson.username } else { $null }
        keys       = if ($currentJson) { @($currentJson.PSObject.Properties.Name) } else { @() }
    }
    currentViaCookie = [ordered]@{ httpStatus = $cookieQ.Status }
    branchLoad       = [ordered]@{
        httpStatus = $branchQ.Status
        isJson     = [bool](Convert-JsonOrNull $branchQ.Body)
    }
    userList         = [ordered]@{
        httpStatus = $listQ.Status
        total      = if ($listJson) { $listJson.total } else { $null }
    }
    refreshToken     = [ordered]@{
        httpStatus     = $refreshQ.Status
        newSession     = [bool]$refreshSession
        sessionRotated = [bool]($refreshSession -and $refreshSession -ne $session)
        sessionMask    = Mask $refreshSession
    }
}

# ---------- 3. Проверки с ключом API ----------
if ($ApiKey) {
    Write-Step '3. Проверки с ключом API (только имена полей, без значений)'
    $targetId = if ($UserId -gt 0) { $UserId } elseif ($myId) { $myId } else { 1 }

    $loadQ = Invoke-Api -Path "/api/public/user/load/$targetId" -Headers @{
        Accept        = 'application/json'
        Authorization = 'Basic ' + $ApiKey
    }
    $loadJson = Convert-JsonOrNull $loadQ.Body
    $names = if ($loadJson) { @($loadJson.PSObject.Properties.Name) } else { @() }

    $report['apiKey'] = [ordered]@{
        userId           = $targetId
        httpStatus       = $loadQ.Status
        fieldCount       = $names.Count
        hasPasswordField = $names -contains 'password'
        passwordLength   = if ($names -contains 'password') { ([string]$loadJson.password).Length } else { $null }
        hasApiTokenField = $names -contains 'apiToken'
        apiTokenNonEmpty = if ($names -contains 'apiToken') { -not [string]::IsNullOrWhiteSpace([string]$loadJson.apiToken) } else { $null }
        apiTokenMask     = if ($names -contains 'apiToken') { Mask ([string]$loadJson.apiToken) } else { $null }
        username         = if ($loadJson) { $loadJson.username } else { $null }
    }
}

# ---------- 4. Отчёт ----------
Write-Step '4. Отчёт'
$json = $report | ConvertTo-Json -Depth 8
$json | Set-Content -Path $OutFile -Encoding UTF8
Write-Host $json
Write-Host ''
Write-Host "Сохранено: $OutFile" -ForegroundColor Green
Write-Host 'Пароль в отчёт не попал, сессия замаскирована — файл можно присылать как есть.' -ForegroundColor Green
