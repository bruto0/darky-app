# Локальный Git-сервер D'arky

Сервер: **Gitea 28.4.0**, только localhost.

| Параметр | Значение |
|---|---|
| UI | http://127.0.0.1:3000/ |
| Репозиторий | http://127.0.0.1:3000/darky/darky |
| Данные/рабочий каталог | `J:\__git__\gitea` |
| Конфиг | `J:\__git__\gitea\custom\conf\app.ini` |
| Администратор | `darky` |
| Пароль администратора | `J:\__git__\gitea\admin-password.txt` (вне репозитория) |
| Токен и git-credentials | `J:\__git__\gitea\token.txt`, `J:\__git__\git-credentials` (вне репозитория) |
| Запуск | `J:\__git__\start-gitea.cmd` |
| Остановка | `Stop-Process -Name gitea` |

Сервер запущен detached-процессом. После перезагрузки машины запустить
`start-gitea.cmd`; данные и репозитории сохраняются в `J:\__git__\gitea`.

## Работа с репозиторием

Remote уже настроен:

```powershell
cd J:\work\__dsh__\darky
git status
git add -A
git commit -m "Meaningful change"
git push origin main
```

Или одной командой:

```powershell
.\tools\git-sync.ps1 "Meaningful change"
```

`git-sync.ps1` делает `git add -A`, коммит (если есть изменения) и push.
Пароль/токен хранится вне репозитория; в `.git/config` push-URL содержит
локальный токен, поэтому не копируйте `.git` в публичные места.

## Что исключено

`.gitignore` исключает `**/build`, `.dart_tool`, `.gradle`, `.idea`,
`.vscode`, `local.properties`, APK/AAB/keystore, логи и временные каталоги.
Проверка:

```powershell
git status --short
git check-ignore -v app/build/app/outputs/flutter-apk/app-debug.apk
```
