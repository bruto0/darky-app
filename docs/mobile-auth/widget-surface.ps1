param(
    [string]$BaseUrl = 'https://4621c03198bd6735334088.impulsemini.ru',
    [Parameter(Mandatory = $true)][string]$Phone,
    [int]$WidgetId = 2
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function ToBase36([int64]$n) {
    $c = '0123456789abcdefghijklmnopqrstuvwxyz'; $s = ''
    while ($n -gt 0) { $s = $c[[int]($n % 36)] + $s; $n = [math]::Floor($n / 36) }
    if ($s -eq '') { $s = '0' }; $s
}
function Rev([string]$s) { $a = $s.ToCharArray(); [array]::Reverse($a); -join $a }
function PhoneEncode([string]$phone) {
    $d = ($phone -replace '[^0-9]', '')
    $n = [int64]$d + 49680531
    [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes((Rev (ToBase36 $n))))
}
$xorKey = Rev '4Lp9Qm2K7x'
$splitSrc = Rev 'pQDkZ2ZK0gZkdGZmdmCNYGZnR2n'
$sep = $splitSrc.Substring(1) + $splitSrc.Substring(0, 1)

function Decrypt([string]$t) {
    $r = Rev $t
    $sb = New-Object System.Text.StringBuilder
    for ($i = 0; $i -lt $r.Length; $i++) { [void]$sb.Append([char]($r[$i] -bxor $xorKey[$i % $xorKey.Length])) }
    $x = $sb.ToString()
    $p = $x.Split([string[]]@($sep), [StringSplitOptions]::None)
    if ($p.Length -lt 2) { throw 'nosep' }
    $o = Rev ($p[0] + $p[1])
    [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($o))
}

function PostWidget([string]$path, $payload) {
    $inner = $payload | ConvertTo-Json -Compress -Depth 8
    $body = '"' + $inner.Replace('\', '\\').Replace('"', '\"') + '"'
    for ($attempt = 1; $attempt -le 3; $attempt++) {
        $tmp = [IO.Path]::GetTempFileName()
        $code = & curl.exe -s -o $tmp -w '%{http_code}' -X POST "$BaseUrl/api/public/$path" `
            -H 'Content-Type: application/json' -H 'Accept: application/json' `
            -H "Referer: $BaseUrl/widget/$WidgetId" --data-binary $body --max-time 40
        $bytes = [IO.File]::ReadAllBytes($tmp)
        Remove-Item $tmp -Force
        $result = [pscustomobject]@{
            Code = $code
            Text = [Text.Encoding]::GetEncoding(28591).GetString($bytes)
        }
        if ($code -eq '200') { return $result }
        Start-Sleep -Milliseconds 400
    }
    return $result
}

function Describe([string]$text) {
    if ([string]::IsNullOrWhiteSpace($text)) { return '(empty)' }
    $plain = $null
    try { $plain = Decrypt $text } catch { }
    if ($plain) { $kind = 'enc'; $j = $plain } else { $kind = 'plain'; $j = $text }
    $sig = ''
    try {
        $o = $j | ConvertFrom-Json -ErrorAction Stop
        if ($o.PSObject.Properties.Name -contains 'total') { $sig = "total=$($o.total)" }
        elseif ($o -is [array]) { $sig = "array[$($o.Count)]" }
        else { $sig = 'keys=' + (($o.PSObject.Properties.Name | Select-Object -First 8) -join ',') }
    }
    catch {
        $one = ($j -replace '\s+', ' ')
        $sig = $one.Substring(0, [Math]::Min(110, $one.Length))
    }
    "[$kind] $sig"
}

# --- получаем client_id + secret ---
$searchRaw = $null
for ($i = 0; $i -lt 3; $i++) {
    $r = PostWidget 'widget_client_lk/search' @{ phone = PhoneEncode $Phone; socialPage = $null }
    try { $searchRaw = Decrypt $r.Text; break } catch { Start-Sleep -Milliseconds 500 }
}
if (-not $searchRaw) { throw 'не удалось получить профиль клиента (search)' }
$c = ($searchRaw | ConvertFrom-Json).items[0]
$id = $c.id; $sec = $c.secret
Write-Host "client_id=$id secret_len=$($sec.Length) name=$($c.name) $($c.lastName)"
Write-Host ''

$flat = @{ client_id = $id; secret = $sec }
$wrap = @{ filters = @{ client_id = $id; secret = $sec } }

$cases = @(
    @{ ep = 'widget_client_lk/client_summary';  body = $flat; shape = 'flat' }
    @{ ep = 'widget_client_lk/accounts';        body = $wrap; shape = 'filters' }
    @{ ep = 'widget_client_lk/visits';          body = $wrap; shape = 'filters' }
    @{ ep = 'widget_client_lk/deposits';        body = $wrap; shape = 'filters' }
    @{ ep = 'widget_client_lk/reservations';    body = $wrap; shape = 'filters' }
    @{ ep = 'widget_client_lk/bonuses';         body = $wrap; shape = 'filters' }
    @{ ep = 'widget_client_lk/debts';           body = $flat; shape = 'flat' }
    @{ ep = 'widget_client_lk/branch';          body = $flat; shape = 'flat' }
    @{ ep = 'widget_client_lk/barcode';         body = @{ client_id = $id; secret = $sec; type = 2; seconds = 5 }; shape = 'flat' }
    @{ ep = 'widget_client_lk/all_levels';      body = $flat; shape = 'flat' }
    @{ ep = 'widget_client_lk/news';            body = $wrap; shape = 'filters' }
    @{ ep = 'widget_client_lk/stories';         body = $wrap; shape = 'filters' }
    @{ ep = 'widget_client_lk/product_sections'; body = $wrap; shape = 'filters' }
    @{ ep = 'widget_client_lk/product_types';   body = $wrap; shape = 'filters' }
    @{ ep = 'widget_client_lk/template';        body = $flat; shape = 'flat' }
    @{ ep = 'widget_client_lk/account_detail';  body = @{ filters = @{ client_id = $id; secret = $sec; id = 514 } }; shape = 'filters+id' }
    @{ ep = 'widget_schedule/reservations';     body = $wrap; shape = 'filters' }
    @{ ep = 'widget_schedule/waitings';         body = $wrap; shape = 'filters' }
    @{ ep = 'widget_schedule/changes';          body = $wrap; shape = 'filters' }
    @{ ep = 'widget_client_mobile/summary';     body = $flat; shape = 'flat' }
)

foreach ($case in $cases) {
    $r = PostWidget $case.ep $case.body
    $d = Describe $r.Text
    "{0,-42} {1,-12} HTTP {2,-4} {3}" -f $case.ep, $case.shape, $r.Code, $d
}

Write-Host ''
Write-Host '--- контроль: без secret ---'
foreach ($ep in @('widget_client_lk/accounts', 'widget_client_lk/visits', 'widget_client_lk/client_summary')) {
    $r = PostWidget $ep @{ filters = @{ client_id = $id } }
    $t = ($r.Text -replace '[^\x20-\x7E]', '.')
    if ($t.Length -gt 90) { $t = $t.Substring(0, 90) }
    "{0,-42} HTTP {1,-4} {2}" -f $ep, $r.Code, $t
}
