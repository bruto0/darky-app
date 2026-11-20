# Окружение сборки D'arky

Зафиксировано и проверено 19.11.2026. Использовать на всех этапах: локальная сборка, тесты, эмулятор, release.

## Пути

| Компонент | Путь / версия |
|---|---|
| JDK | `D:\distrib\devel\java\jdk-21.0.13+9` — OpenJDK 21.0.13 LTS (Temurin) |
| Android SDK | `C:\Users\kir\AppData\Local\Android\Sdk` |
| Android platforms | `android-35` (Android 15), `android-36` (появился при smoke build), `android-37.0` |
| Build-tools | `35.0.0`, `34.0.0`, `36.0.0` |
| Platform-tools | `adb.exe` |
| Эмулятор | `emulator.exe`; AVD `DARKY_API_35` (Android 15) и `Medium_Phone_API_37.0` |
| Flutter | `D:\distrib\devel\flutter` — stable 3.50.0, Dart 3.14.0 |
| Gradle cache | `J:\.gradle` (`GRADLE_USER_HOME`) |
| Package id | `ru.darky.dance` |
| minSdk / targetSdk / compileSdk | 35 / 35 / 36 |

`flutter doctor` использует **JDK 21** (привязан через `flutter config --jdk-dir`), Android toolchain — OK, лицензии приняты. Visual Studio отмечен крестом — для Android он не нужен. Есть предупреждение о двух `adb.exe`; скрипт окружения ставит в PATH adb из Android SDK.

**Smoke build 19.11.2026:** временный Flutter-проект прошёл `flutter test`; `flutter build apk --debug` собрал APK (158 МБ, debug) на JDK 21 и Android SDK. Gradle скачал NDK 28.2 и platform 36 и закэшировал их в `J:\.gradle` / SDK.

**Foundation (реальный `app/`) 19.11.2026:** `flutter analyze` — 0, `flutter test` — 30 тестов, `flutter build apk --debug` — успешно. APK: `app/build/app/outputs/flutter-apk/app-debug.apk`. `compileSdk = 36` требуется плагинами `flutter_secure_storage` и `shared_preferences_android`; `targetSdk = minSdk = 35`, поэтому поведение Android 15 сохраняется.

**MVP-разделы (20.11.2026):** реализованы профиль/абонементы, расписание
(stickers/changes, фильтры, FAB), посещения, покупки, записи. `flutter analyze` — 0,
`flutter test` — **188 тестов**, debug APK собран. Живой прогон на **AVD API 37**
(эмулятор `Medium_Phone_API_37.0`, сеть через NAT): нативный вход → home;
2 абонемента, 20 занятий дня, 90 посещений, 9 операций, 1 запись, QR-баркод.
На AVD API 35 в этом окружении сеть/System UI нестабильны (эмулятор), поэтому
фичи проверялись на API 37.

**Native Auth (20.11.2026):** `webview_flutter` удалён из зависимостей; вход —
нативные `TextField` + `AutofillGroup`, `phone_info` → `check_password` →
`widget_client_lk/search`, восстановление — `url_launcher` во внешний браузер.
Все ограничения/варианты WebView — [design/WEBVIEW-NOTES.md](design/WEBVIEW-NOTES.md).

## Скрипт окружения

```powershell
. .\tools\env.ps1
```

Он выставляет `JAVA_HOME`, `ANDROID_HOME`, `ANDROID_SDK_ROOT`, `GRADLE_USER_HOME` и добавляет в `PATH` JDK, platform-tools, cmdline-tools и Flutter.

На Windows в `C:\Windows\adb.exe` может быть старый adb (server 26), конфликтующий с SDK adb (41). Для телефона использовать SDK adb по абсолютному пути:

```powershell
$adb = Join-Path $env:ANDROID_HOME 'platform-tools\adb.exe'
& $adb devices
```

Для AVD в этом окружении надёжнее **не смешивать клиенты**: emulator поднимает
старый `C:\Windows\adb.exe` (multidisplay), из-за чего SDK adb 41 и server 26
по очереди убивают друг друга. Если `adb install` пишет `device offline`:

1. не запускать параллельно SDK adb и `C:\Windows\adb.exe`;
2. использовать один клиент последовательно; при `adb server is out of date`
   повторить `install -r` после `adb devices` (device должен быть `device`);
3. при необходимости `adb kill-server`, снова `adb start-server`, дождаться
   `emulator-5554 device`, затем повторить установку.
4. Это лечится переименованием старого adb, но системный файл не трогаем.

## Проверка

```powershell
. .\tools\env.ps1
java -version
flutter --version
flutter doctor -v
adb devices
flutter emulators
```

Первичная привязка Flutter к SDK и JDK (уже выполнена):

```powershell
flutter config --android-sdk "C:\Users\kir\AppData\Local\Android\Sdk"
flutter config --jdk-dir "D:\distrib\devel\java\jdk-21.0.13+9"
```

## Сборка и тесты (после появления `app/`)

```powershell
. .\tools\env.ps1
cd app

flutter pub get
flutter analyze
flutter test
flutter build apk --debug
flutter build appbundle --release
```

Интеграционные тесты на эмуляторе:

```powershell
# Запустить AVD (window или headless). На software-эмуляторе debug собирается со Skia.
& "$env:ANDROID_HOME\emulator\emulator.exe" -avd DARKY_API_35 -no-snapshot -gpu host -cores 4 -memory 4096

# Дождаться device и прогнать
adb wait-for-device
flutter test integration_test -d emulator-5554
```

## Android 15 (API 35)

Платформа `android-35` и системный образ `system-images;android-35;google_apis;x86_64` установлены. AVD **`DARKY_API_35`** создан и проверен: загружается, `ro.build.version.sdk=35`, `ro.build.version.release=15`.

На этом AVD установлены **Chrome 124.0.6367.219** и WebView 124.0.6367.219. Приложение реально определяет `Chrome 124 (chrome)` (проверено по `DARKY browser` в logcat) и собирает профиль под actual-версию; low-entropy hints для 124 не отправляются, пока GREASE-бренд этой версии не занесён в таблицу. На телефоне клиента с Chrome 156 будет `Chrome/156.0.0.0`.

**Native Auth на AVD (20.11.2026):**

- Установлен debug APK; нативный экран входа открывается без WebView.
- Тестовый клиент: телефон + пароль → `phone_info`/`check_password` → home.
- «Восстановить пароль» → внешний Chrome (`topResumedActivity=com.android.chrome/...FirstRunActivity` на чистом AVD; на телефоне — обычная вкладка с `/widget/2`).
- После теста `pm clear`; приложение оставлено на входе.

## Реальное устройство (историческая проверка 20.11.2026)

- **HONOR BVL-AN16**, Android 17 (API 37), WebView 145+.
- Установка по **wireless debugging**: `adb pair`, `adb connect`, `adb install -r app-debug.apk` — успешно.
- WebView-вход работал, но медленно; auth переведён на нативный (D15), после чего
  проверка продолжена на AVD.
- IP/порт/код сопряжения в документацию не переносятся.

```powershell
. .\tools\env.ps1
& "$env:ANDROID_HOME\emulator\emulator.exe" -avd DARKY_API_35 -no-window -no-audio -no-boot-anim -gpu swiftshader_indirect -no-snapshot
adb wait-for-device
adb shell getprop ro.build.version.sdk   # 35
```

Проверять на API 35 и на `Medium_Phone_API_37.0`; физическое устройство — если подключено.

## Правила

- Не коммитить `local.properties` с машинными путями; он генерируется Flutter/Gradle.
- Не коммитить ключи подписи и `key.properties`.
- Секреты тестового клиента — только через переменные окружения, не в файлах.
- Кэш Gradle — на `J:\.gradle`, чтобы не забивать системный диск.
- Перед релизом: `flutter build appbundle --release --obfuscate --split-debug-info=build/symbols`.
