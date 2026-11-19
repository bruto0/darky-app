# Сводная таблица эндпойнтов

[← Оглавление](README.md) · [Индекс сущностей](03-entities/README.md)

Все HTTP-запросы API: метод, путь, назначение. Префикс `$IMPULSE_BASE_URL` — адрес вашей CRM (например, `https://demo.impulsecrm.ru`).

Всего эндпойнтов: **103**, сущностей: **23**.

## Клиент — `client`

| Действие | Метод | Путь | Описание |
|---|---|---|---|
| [Получить по идентификатору](03-entities/client.md#get) | `GET` | `/api/public/client/load/{id}` | Получить клиента по идентификатору |
| [Список (выборка)](03-entities/client.md#list) | `POST` | `/api/public/client/list` | Получить список клиентов |
| [Создать](03-entities/client.md#create) | `POST` | `/api/public/client/update` | Создать клиента |
| [Обновить](03-entities/client.md#update) | `POST` | `/api/public/client/update` | Обновить клиента |
| [Удалить](03-entities/client.md#delete) | `POST` | `/api/public/client/delete` | Удалить клиентов |

## Родитель — `ancestor`

| Действие | Метод | Путь | Описание |
|---|---|---|---|
| [Получить по идентификатору](03-entities/ancestor.md#get) | `GET` | `/api/public/ancestor/load/{id}` | Получить родителя по идентификатору |
| [Список (выборка)](03-entities/ancestor.md#list) | `POST` | `/api/public/ancestor/list` | Получить список родителей |
| [Создать](03-entities/ancestor.md#create) | `POST` | `/api/public/ancestor/update` | Создать родителя |
| [Обновить](03-entities/ancestor.md#update) | `POST` | `/api/public/ancestor/update` | Обновить родителя |
| [Удалить](03-entities/ancestor.md#delete) | `POST` | `/api/public/ancestor/delete` | Удалить родителей |

## Источник — `informer`

| Действие | Метод | Путь | Описание |
|---|---|---|---|
| [Список (выборка)](03-entities/informer.md#list) | `POST` | `/api/public/informer/list` | Получить список источников |

## Воронка — `pipeline`

| Действие | Метод | Путь | Описание |
|---|---|---|---|
| [Список (выборка)](03-entities/pipeline.md#list) | `POST` | `/api/public/pipeline/list` | Получить список воронок |

## Депозит — `deposit`

| Действие | Метод | Путь | Описание |
|---|---|---|---|
| [Список (выборка)](03-entities/deposit.md#list) | `POST` | `/api/public/deposit/list` | Получить список операций по депозиту |
| [Пополнить депозит](03-entities/deposit.md#input) | `POST` | `/api/public/deposit/input` | Пополнение депозита |
| [Списать с депозита](03-entities/deposit.md#output) | `POST` | `/api/public/deposit/output` | Вывод с депозита |
| [Удалить](03-entities/deposit.md#delete) | `POST` | `/api/public/deposit/delete` | Удалить записи операций по депозиту |

## Филиал — `branch`

| Действие | Метод | Путь | Описание |
|---|---|---|---|
| [Получить по идентификатору](03-entities/branch.md#get) | `GET` | `/api/public/branch/load/{id}` | Получить филиал по идентификатору |
| [Список (выборка)](03-entities/branch.md#list) | `POST` | `/api/public/branch/list` | Получить список филиалов |
| [Создать](03-entities/branch.md#create) | `POST` | `/api/public/branch/update` | Создать филиал |
| [Обновить](03-entities/branch.md#update) | `POST` | `/api/public/branch/update` | Обновить филиал |
| [Удалить](03-entities/branch.md#delete) | `POST` | `/api/public/branch/delete` | Удалить филиалы |

## Зал — `hall`

| Действие | Метод | Путь | Описание |
|---|---|---|---|
| [Получить по идентификатору](03-entities/hall.md#get) | `GET` | `/api/public/hall/load/{id}` | Получить зал по идентификатору |
| [Список (выборка)](03-entities/hall.md#list) | `POST` | `/api/public/hall/list` | Получить список залов |
| [Создать](03-entities/hall.md#create) | `POST` | `/api/public/hall/update` | Создать зал |
| [Обновить](03-entities/hall.md#update) | `POST` | `/api/public/hall/update` | Обновить зал |
| [Удалить](03-entities/hall.md#delete) | `POST` | `/api/public/hall/delete` | Удалить залы |

## Товар — `product`

| Действие | Метод | Путь | Описание |
|---|---|---|---|
| [Получить по идентификатору](03-entities/product.md#get) | `GET` | `/api/public/product/load/{id}` | Получить продажу товара по идентификатору |
| [Список (выборка)](03-entities/product.md#list) | `POST` | `/api/public/product/list` | Получить список продаж товаров |
| [Создать](03-entities/product.md#create) | `POST` | `/api/public/product/update` | Создать запись продажи товара |
| [Обновить](03-entities/product.md#update) | `POST` | `/api/public/product/update` | Обновить запись продажи товара |
| [Удалить](03-entities/product.md#delete) | `POST` | `/api/public/product/delete` | Удалить записи продажи товаров |

## Преподаватель — `teacher`

| Действие | Метод | Путь | Описание |
|---|---|---|---|
| [Получить по идентификатору](03-entities/teacher.md#get) | `GET` | `/api/public/teacher/load/{id}` | Получить преподавателя по идентификатору |
| [Список (выборка)](03-entities/teacher.md#list) | `POST` | `/api/public/teacher/list` | Получить список преподавателей |
| [Создать](03-entities/teacher.md#create) | `POST` | `/api/public/teacher/update` | Создать преподавателя |
| [Обновить](03-entities/teacher.md#update) | `POST` | `/api/public/teacher/update` | Обновить преподавателя |
| [Удалить](03-entities/teacher.md#delete) | `POST` | `/api/public/teacher/delete` | Удалить преподавателей |

## Пользователь — `user`

| Действие | Метод | Путь | Описание |
|---|---|---|---|
| [Получить по идентификатору](03-entities/user.md#get) | `GET` | `/api/public/user/load/{id}` | Получить пользователя по идентификатору |
| [Список (выборка)](03-entities/user.md#list) | `POST` | `/api/public/user/list` | Получить список пользователей |
| [Создать](03-entities/user.md#create) | `POST` | `/api/public/user/update` | Создать пользователя |
| [Обновить](03-entities/user.md#update) | `POST` | `/api/public/user/update` | Обновить пользователя |
| [Удалить](03-entities/user.md#delete) | `POST` | `/api/public/user/delete` | Удалить пользователей |

## Направление — `style`

| Действие | Метод | Путь | Описание |
|---|---|---|---|
| [Получить по идентификатору](03-entities/style.md#get) | `GET` | `/api/public/style/load/{id}` | Получить направление по идентификатору |
| [Список (выборка)](03-entities/style.md#list) | `POST` | `/api/public/style/list` | Получить список направлений |
| [Создать](03-entities/style.md#create) | `POST` | `/api/public/style/update` | Создать направление |
| [Обновить](03-entities/style.md#update) | `POST` | `/api/public/style/update` | Обновить направление |
| [Удалить](03-entities/style.md#delete) | `POST` | `/api/public/style/delete` | Удалить направления |

## Группа — `group`

| Действие | Метод | Путь | Описание |
|---|---|---|---|
| [Получить по идентификатору](03-entities/group.md#get) | `GET` | `/api/public/group/load/{id}` | Получить группу по идентификатору |
| [Список (выборка)](03-entities/group.md#list) | `POST` | `/api/public/group/list` | Получить список групп |
| [Создать](03-entities/group.md#create) | `POST` | `/api/public/group/update` | Создать группу |
| [Обновить](03-entities/group.md#update) | `POST` | `/api/public/group/update` | Обновить группу |
| [Удалить](03-entities/group.md#delete) | `POST` | `/api/public/group/delete` | Удалить группы |

## Расписание — `schedule`

| Действие | Метод | Путь | Описание |
|---|---|---|---|
| [Получить по идентификатору](03-entities/schedule.md#get) | `GET` | `/api/public/schedule/load/{id}` | Получить занятие из расписания по идентификатору |
| [Список (выборка)](03-entities/schedule.md#list) | `POST` | `/api/public/schedule/list` | Получить список занятий в расписании |
| [Создать](03-entities/schedule.md#create) | `POST` | `/api/public/schedule/update` | Создать занятие в расписании |
| [Обновить](03-entities/schedule.md#update) | `POST` | `/api/public/schedule/update` | Обновить занятие в расписании |
| [Удалить](03-entities/schedule.md#delete) | `POST` | `/api/public/schedule/delete` | Удалить занятие из расписания |

## Групповой абонемент — `group_account`

| Действие | Метод | Путь | Описание |
|---|---|---|---|
| [Получить по идентификатору](03-entities/group_account.md#get) | `GET` | `/api/public/group_account/load/{id}` | Получить групповой абонемент по идентификатору |
| [Список (выборка)](03-entities/group_account.md#list) | `POST` | `/api/public/group_account/list` | Получить список групповых абонементов |
| [Создать](03-entities/group_account.md#create) | `POST` | `/api/public/group_account/update` | Создать групповой абонемент |
| [Обновить](03-entities/group_account.md#update) | `POST` | `/api/public/group_account/update` | Обновить групповой абонемент |
| [Удалить](03-entities/group_account.md#delete) | `POST` | `/api/public/group_account/delete` | Удалить групповые абонементы |

## Разовое групповое занятие — `group_single`

| Действие | Метод | Путь | Описание |
|---|---|---|---|
| [Получить по идентификатору](03-entities/group_single.md#get) | `GET` | `/api/public/group_single/load/{id}` | Получить разовое групповое занятие по идентификатору |
| [Список (выборка)](03-entities/group_single.md#list) | `POST` | `/api/public/group_single/list` | Получить список разовых групповых занятий |
| [Создать](03-entities/group_single.md#create) | `POST` | `/api/public/group_single/update` | Создать разовое групповое занятие |
| [Обновить](03-entities/group_single.md#update) | `POST` | `/api/public/group_single/update` | Обновить разовое групповое занятие |
| [Удалить](03-entities/group_single.md#delete) | `POST` | `/api/public/group_single/delete` | Удалить разовые групповые занятия |

## Индивидуальный абонемент — `individual_account`

| Действие | Метод | Путь | Описание |
|---|---|---|---|
| [Получить по идентификатору](03-entities/individual_account.md#get) | `GET` | `/api/public/individual_account/load/{id}` | Получить индивидуальный абонемент по идентификатору |
| [Список (выборка)](03-entities/individual_account.md#list) | `POST` | `/api/public/individual_account/list` | Получить список индивидуальных абонементов |
| [Создать](03-entities/individual_account.md#create) | `POST` | `/api/public/individual_account/update` | Создать индивидуальный абонемент |
| [Обновить](03-entities/individual_account.md#update) | `POST` | `/api/public/individual_account/update` | Обновить индивидуальный абонемент |
| [Удалить](03-entities/individual_account.md#delete) | `POST` | `/api/public/individual_account/delete` | Удалить индивидуальные абонементы |

## Разовое индивидуальное занятие — `individual_single`

| Действие | Метод | Путь | Описание |
|---|---|---|---|
| [Получить по идентификатору](03-entities/individual_single.md#get) | `GET` | `/api/public/individual_single/load/{id}` | Получить разовое индивидуальное занятие по идентификатору |
| [Список (выборка)](03-entities/individual_single.md#list) | `POST` | `/api/public/individual_single/list` | Получить список разовых индивидуальных занятий |
| [Создать](03-entities/individual_single.md#create) | `POST` | `/api/public/individual_single/update` | Создать разовое индивидуальное занятие |
| [Обновить](03-entities/individual_single.md#update) | `POST` | `/api/public/individual_single/update` | Обновить разовое индивидуальное занятие |
| [Удалить](03-entities/individual_single.md#delete) | `POST` | `/api/public/individual_single/delete` | Удалить разовые индивидуальные занятия |

## Самостоятельный абонемент — `self_account`

| Действие | Метод | Путь | Описание |
|---|---|---|---|
| [Получить по идентификатору](03-entities/self_account.md#get) | `GET` | `/api/public/self_account/load/{id}` | Получить самостоятельный абонемент по идентификатору |
| [Список (выборка)](03-entities/self_account.md#list) | `POST` | `/api/public/self_account/list` | Получить список самостоятельных абонементов |
| [Создать](03-entities/self_account.md#create) | `POST` | `/api/public/self_account/update` | Создать самостоятельный абонемент |
| [Обновить](03-entities/self_account.md#update) | `POST` | `/api/public/self_account/update` | Обновить самостоятельный абонемент |
| [Удалить](03-entities/self_account.md#delete) | `POST` | `/api/public/self_account/delete` | Удалить самостоятельные абонементы |

## Разовое самостоятельное занятие — `self_single`

| Действие | Метод | Путь | Описание |
|---|---|---|---|
| [Получить по идентификатору](03-entities/self_single.md#get) | `GET` | `/api/public/self_single/load/{id}` | Получить разовое самостоятельное занятие по идентификатору |
| [Список (выборка)](03-entities/self_single.md#list) | `POST` | `/api/public/self_single/list` | Получить список разовых самостоятельных занятий |
| [Создать](03-entities/self_single.md#create) | `POST` | `/api/public/self_single/update` | Создать разовое самостоятельное занятие |
| [Обновить](03-entities/self_single.md#update) | `POST` | `/api/public/self_single/update` | Обновить разовое самостоятельное занятие |
| [Удалить](03-entities/self_single.md#delete) | `POST` | `/api/public/self_single/delete` | Удалить разовые самостоятельные занятия |

## Абонемент на аренду — `rent_account`

| Действие | Метод | Путь | Описание |
|---|---|---|---|
| [Получить по идентификатору](03-entities/rent_account.md#get) | `GET` | `/api/public/rent_account/load/{id}` | Получить абонемент на аренду по идентификатору |
| [Список (выборка)](03-entities/rent_account.md#list) | `POST` | `/api/public/rent_account/list` | Получить список абонементов на аренду |
| [Создать](03-entities/rent_account.md#create) | `POST` | `/api/public/rent_account/update` | Создать абонемент на аренду |
| [Обновить](03-entities/rent_account.md#update) | `POST` | `/api/public/rent_account/update` | Обновить абонемент на аренду |
| [Удалить](03-entities/rent_account.md#delete) | `POST` | `/api/public/rent_account/delete` | Удалить абонементы на аренду |

## Разовая аренда — `rent_single`

| Действие | Метод | Путь | Описание |
|---|---|---|---|
| [Получить по идентификатору](03-entities/rent_single.md#get) | `GET` | `/api/public/rent_single/load/{id}` | Получить разовую аренду по идентификатору |
| [Список (выборка)](03-entities/rent_single.md#list) | `POST` | `/api/public/rent_single/list` | Получить список разовых аренд |
| [Создать](03-entities/rent_single.md#create) | `POST` | `/api/public/rent_single/update` | Создать разовую аренду |
| [Обновить](03-entities/rent_single.md#update) | `POST` | `/api/public/rent_single/update` | Обновить разовую аренду |
| [Удалить](03-entities/rent_single.md#delete) | `POST` | `/api/public/rent_single/delete` | Удалить разовые аренды |

## Посещение по абонементу — `visit`

| Действие | Метод | Путь | Описание |
|---|---|---|---|
| [Список (выборка)](03-entities/visit.md#list) | `POST` | `/api/public/visit/list` | Получить список посещений по абонементу |
| [Удалить](03-entities/visit.md#delete) | `POST` | `/api/public/visit/delete` | Удалить посещения |

## Запись на занятие — `reservation`

| Действие | Метод | Путь | Описание |
|---|---|---|---|
| [Получить по идентификатору](03-entities/reservation.md#get) | `GET` | `/api/public/reservation/load/{id}` | Получить запись на занятие по идентификатору |
| [Список (выборка)](03-entities/reservation.md#list) | `POST` | `/api/public/reservation/list` | Получить список записей на занятия |
| [Создать](03-entities/reservation.md#create) | `POST` | `/api/public/reservation/update` | Создать запись на занятие |
| [Обновить](03-entities/reservation.md#update) | `POST` | `/api/public/reservation/update` | Обновить запись на занятие |
| [Удалить](03-entities/reservation.md#delete) | `POST` | `/api/public/reservation/delete` | Удалить записи на занятия |
