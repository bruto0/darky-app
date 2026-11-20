# Релизная сборка D'arky

## APK

```powershell
. .\tools\env.ps1
cd app
flutter build apk --release
```

Результат: `app/build/app/outputs/flutter-apk/app-release.apk` (universal APK,
`ru.darky.dance`, version `1.0.9+10`, targetSdk 35).

## Подпись

Release подписывается ключом из `app/android/key.properties` (файл в
`.gitignore`, в репозиторий не попадает). Сам keystore лежит **вне workspace**:

- keystore: `J:\__git__\android-keys\darky-release.jks`
- alias: `darky`
- пароль и параметры: `J:\__git__\android-keys\credentials.txt` (не коммитить)
- SHA-256 сертификата: `99b87f636bf8268570c324c8b08a066dcffbcb018ef0b334756067129fa5f021`

`app/android/app/build.gradle.kts` читает `key.properties`; если файла нет,
release собирается с debug-подписью (для локальной проверки, не для публикации).
Перед публикацией keystore и пароль нужно хранить в защищённом месте и сделать
резервную копию: без него обновления приложения невозможны.

Проверка подписи:

```powershell
& "$env:ANDROID_HOME\build-tools\<version>\apksigner.bat" verify --print-certs `
  app\build\app\outputs\flutter-apk\app-release.apk
```

## Что внутри

Нативный вход, профиль/абонементы, заморозка через кабинет клуба, QR, темы,
расписание, посещения, покупки, записи. WebView в auth отсутствует.

## Проверка на HONOR (20.11.2026)

- Устройство: **HONOR BVL-AN16**, Android 17.
- Debug-сборка удалена (у неё другая подпись), release установлен через
  wireless adb: `versionName=1.0.9`, `versionCode=10`.
- Приложение запускается на экране нативного входа; телефон подставился
  Android Password Manager (autofill).
- Release использует `FLAG_SECURE`, поэтому системные скриншоты экрана
  приложения заблокированы.

