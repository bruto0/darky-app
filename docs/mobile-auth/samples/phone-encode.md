# Кодирование телефона в виджете

Виджет не передаёт телефон в открытом виде: перед отправкой он кодируется обратимой
функцией без ключа. Это не шифрование — только запутывание.

## Алгоритм

```
digits   = все цифры номера
n        = int(digits) + 49680531
b36      = n в системе счисления 36 (нижний регистр)
encoded  = base64( reverse(b36) )
```

Обратная операция:

```
b36      = reverse( base64decode(encoded) )
n        = int(b36, 36)
digits   = n - 49680531
```

## Пример

```
телефон:  +79001234567
digits:   79001234567
n:        79050915098
base36:   10bcvggq
reverse:  qggvcb01
base64:   cWdndmNiMDE=
```

Проверка: `cWdndmNiMDE=` → `qggvcb01` → `10bcvggq` → `79050915098` − `49680531` = `79001234567`.

## Реализации

PowerShell:

```powershell
function ToBase36([int64]$n) {
    $c = '0123456789abcdefghijklmnopqrstuvwxyz'; $s = ''
    while ($n -gt 0) { $s = $c[[int]($n % 36)] + $s; $n = [math]::Floor($n / 36) }
    if ($s -eq '') { $s = '0' }; $s
}
function Rev([string]$s) { $a = $s.ToCharArray(); [array]::Reverse($a); -join $a }

$digits  = '79001234567'
$n       = [int64]$digits + 49680531
$encoded = [Convert]::ToBase64String(
    [Text.Encoding]::ASCII.GetBytes((Rev (ToBase36 $n)))
)
```

Kotlin (Android):

```kotlin
fun encodePhone(phone: String): String {
    val n = phone.filter { it.isDigit() }.toLong() + 49_680_531
    val reversed = n.toString(36).reversed()
    return Base64.encodeToString(reversed.toByteArray(Charsets.US_ASCII), Base64.NO_WRAP)
}

fun decodePhone(encoded: String): String {
    val reversed = String(Base64.decode(encoded, Base64.NO_WRAP), Charsets.US_ASCII)
    return (reversed.reversed().toLong(36) - 49_680_531).toString()
}
```

## Замечания

- Постоянная `49680531` одинакова для всех тенантов и зашита в JS-бандл.
- Кодирование не защищает номер: оно восстанавливается одной строкой кода, поэтому
  использовать его как «секрет» нельзя.
- В запросах виджета телефон встречается только в полях `phone` методов
  `widget_schedule/phone_info`, `widget_schedule/check_password`,
  `widget_client_lk/search`, `widget_client_mobile/search`.
