param(
    [string]$BaseUrl = 'https://4621c03198bd6735334088.impulsemini.ru',
    [Parameter(Mandatory = $true)][string]$Phone,
    [Parameter(Mandatory = $true)][string]$Password,
    [int]$WidgetId = 2
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function ToBase36([int64]$n) {
    $chars = '0123456789abcdefghijklmnopqrstuvwxyz'
    $s = ''
    while ($n -gt 0) { $s = $chars[[int]($n % 36)] + $s; $n = [math]::Floor($n / 36) }
    if ($s -eq '') { $s = '0' }
    $s
}
function Rev([string]$s) { $a = $s.ToCharArray(); [array]::Reverse($a); -join $a }

function PhoneEncode([string]$phone) {
    $digits = ($phone -replace '[^0-9]', '')
    $n = [int64]$digits + 49680531
    $b36 = ToBase36 $n
    [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes((Rev $b36)))
}

$xorKey = Rev '4Lp9Qm2K7x'
$splitSrc = Rev 'pQDkZ2ZK0gZkdGZmdmCNYGZnR2n'
$sep = $splitSrc.Substring(1) + $splitSrc.Substring(0, 1)

function Decrypt([string]$t) {
    $r = Rev $t
    $sb = New-Object System.Text.StringBuilder
    for ($i = 0; $i -lt $r.Length; $i++) {
        [void]$sb.Append([char]($r[$i] -bxor $xorKey[$i % $xorKey.Length]))
    }
    $x = $sb.ToString()
    $parts = $x.Split([string[]]@($sep), [System.StringSplitOptions]::None)
    if ($parts.Length -lt 2) { throw "decrypt: separator not found; raw=$($x.Substring(0,[Math]::Min(80,$x.Length)))" }
    $o = Rev ($parts[0] + $parts[1])
    [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($o))
}

function PostWidget([string]$path, [hashtable]$payload) {
    $inner = $payload | ConvertTo-Json -Compress
    $body = '"' + $inner.Replace('\', '\\').Replace('"', '\"') + '"'
    $tmp = [IO.Path]::GetTempFileName()
    & curl.exe -s -o $tmp -X POST "$BaseUrl/api/public/$path" `
        -H 'Content-Type: application/json' -H 'Accept: application/json' `
        -H "Referer: $BaseUrl/widget/$WidgetId" `
        --data-binary $body --max-time 30
    $bytes = [IO.File]::ReadAllBytes($tmp)
    Remove-Item $tmp -Force
    [Text.Encoding]::GetEncoding(28591).GetString($bytes)
}

$enc = PhoneEncode $Phone
"phone            : $Phone"
"phone encoded    : $enc"
""
"--- phone_info ---"
$r1 = PostWidget 'widget_schedule/phone_info' @{ phone = $enc }
"raw len: $($r1.Length)"
try { $d1 = Decrypt $r1; "decrypted: $d1" } catch { "decrypt failed: $_" }
""
"--- check_password ---"
$r2 = PostWidget 'widget_schedule/check_password' @{ phone = $enc; password = $Password }
"raw len: $($r2.Length)"
try { $d2 = Decrypt $r2; "decrypted: $d2" } catch { "decrypt failed: $_" }
