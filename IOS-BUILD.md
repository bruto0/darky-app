# Локальная сборка D'arky на macOS

Эта инструкция покрывает iOS-сборку на Mac. Android-сборка на macOS не
настроена: `codemagic.yaml` и Podfile относятся только к iOS.

## Требования

- macOS с Xcode (проект проверялся под iOS 15.0; используйте актуальный Xcode).
- Flutter `3.50.0` и Dart `3.14.0`.
- CocoaPods (`sudo gem install cocoapods`).
- Apple Developer team с bundle ID `ru.darky.dance` — для установки на
  устройство или сборки IPA. Для запуска в симуляторе Apple-подпись не нужна.

## Первичная настройка

```bash
cd app
flutter pub get
cd ios
pod install --repo-update
cd ..
```

После `pod install` всегда открывайте **workspace**, а не `.xcodeproj`:

```bash
open ios/Runner.xcworkspace
```

Или одной командой:

```bash
./tools/ios-setup.sh
```

## Подпись в Xcode

1. Откройте `Runner.xcworkspace`.
2. Выберите target **Runner** → **Signing & Capabilities**.
3. Укажите свою **Team**.
4. Bundle Identifier уже задан: `ru.darky.dance`; не меняйте его без
   соответствующего профиля.
5. Для локальной сборки включите **Automatically manage signing**.

Сертификат и provisioning profile должны соответствовать bundle ID и Team.
Если используется ручная подпись, установите `.p12` в связку ключей macOS и
`.mobileprovision` в `~/Library/MobileDevice/Provisioning Profiles`, затем
выберите профиль в Xcode.

Keychain Sharing уже добавлен в `Runner/Runner.entitlements` — он нужен
`flutter_secure_storage` для хранения сессии. В Apple Developer у App ID
`ru.darky.dance` должна быть включена capability **Keychain Sharing**; без
неё provisioning profile не совпадёт с entitlements, и сборка на устройство
завершится ошибкой подписи.

## Запуск и сборка

```bash
# Debug на подключённом iPhone
cd app
flutter run -d <device-id>

# Release IPA (подпись берётся из Xcode)
./tools/ios-build.sh

# Либо напрямую
flutter build ipa --release
```

IPA появится в `app/build/ios/ipa/`, архив — в
`app/build/ios/archive/`.

## Проверка без подписи

Для проверки компиляции можно собрать unsigned-артефакт:

```bash
flutter build ios --release --no-codesign
```

Такой `.app` нельзя установить на iPhone как обычный IPA; для устройства нужна
подпись.

## Codemagic

В репозитории есть [codemagic.yaml](../codemagic.yaml) с ручным workflow
`ios-release`. Для него нужны загруженные в Codemagic:

- App Store distribution `.p12`;
- App Store provisioning profile для `ru.darky.dance`.

Workflow собирает только `.ipa` и не публикует его в TestFlight/App Store.

## Частые проблемы

| Симптом | Что проверить |
|---|---|
| `No Podfile found` | Убедитесь, что `app/ios/Podfile` существует и выполнен `pod install`. |
| `No such module` / плагин не найден | Откройте `Runner.xcworkspace`, а не `Runner.xcodeproj`; повторите `pod install`. |
| Ошибка подписи | Team, bundle ID `ru.darky.dance`, срок действия профиля и соответствие сертификата. |
| Изменения Podfile не применяются | `cd app/ios && pod install`, затем Clean Build Folder в Xcode. |
| `flutter_secure_storage` не сохраняет сессию | Проверьте, что target использует `Runner/Runner.entitlements` и Keychain Sharing включён. |

`Podfile.lock` и папка `Pods/` появляются после первого `pod install`.
`Pods/` не коммитится; `Podfile.lock` рекомендуется закоммитить после
проверенной сборки, чтобы зафиксировать версии pod-зависимостей.
