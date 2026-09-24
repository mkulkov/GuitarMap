# Донаты «Формулы грифа»

Покупка доната — единственная монетизация «Формулы грифа». Донат не открывает функции,
не выдаёт игровую валюту и не отключает ограничения: приложение остаётся
бесплатным, без подписок и рекламы.

## Архитектура

UI обращается только к `DonationService`. Сервис выбирает один адаптер по feature
экспорта, загружает три товара и передаёт в UI готовые `button_text`, сформированные
из метаданных SDK площадки. Первая кнопка показывает SDK-название и цену, вторая
и третья — SDK-цену. UI не содержит цену или название production-товара.

```text
About / donation prompt -> DonationService -> DebugDonationAdapter
                                         -> RuStoreDonationAdapter -> RuStore Pay
                                         -> WebDonationAdapter -> Yandex Games SDK
                                                              -> VK bridge (disabled)
```

После успешной покупки идентификатор транзакции сначала атомарно записывается в
`user://fret_formula_monetization.json`. Только после этого сервис вызывает
`consumePurchase` в Yandex или подтверждение покупки в RuStore. Повторный callback
с тем же ID не увеличивает локальный счётчик поддержки.

Счётчик запусков хранится в том же документе. До первой подтверждённой поддержки
предложение показывается после загрузки основного окна на запусках 5, 10, 15 и
далее через каждые пять запусков. После покупки автоматическое предложение больше
не появляется, кнопки остаются в разделе «О программе», а рядом с названием
«Формула грифа» показывается сердечко сторонника.

## Профили

| Экспорт | Feature | Состояние |
| --- | --- | --- |
| Editor/debug | `debug` | Детерминированный тестовый товар, не production-платёж |
| Android - RuStore | `android,rustore` | Pay SDK 11.1.0 подключён; нужен товар в кабинете и sandbox/device тест |
| Yandex Games Web | `web,yandex_games` | Каталог, покупка, восстановление и consume подключены через Web SDK; нужен товар в кабинете и hosted draft тест |
| VK Mini Apps Web | `web,vk_mini_apps` | Экспортная граница есть, донат отключён: клиентский SDK-каталог с текстом/ценой товара не подтверждён |
| Windows release | — | Production-платёж не настроен; кнопка остаётся недоступной |

## Действия владельца

1. Создать три потребляемых товара `fret_formula_donation_99`,
   `fret_formula_donation_199` и `fret_formula_donation_499` в RuStore и Yandex Games
   либо заменить публичные ID в `config/monetization.json` на уже созданные товары.
   Название первого товара задаётся в кабинете, например «Угостить разработчика
   кофе»; цены всех трёх товаров также задаются площадкой.
2. Для RuStore зарегистрировать и проверить пакет `ru.mkulkov.fretformula`, подпись сборки, доступность
   Pay SDK, тестового пользователя и одностадийную покупку consumable. Проверить
   получение `title` и `amountLabel`, повторную покупку после acknowledgement и
   восстановление незавершённой транзакции на реальном Android-устройстве.
3. Для Yandex включить инап-покупки, создать consumable, опубликовать черновик и
   проверить `getCatalog`, цену/валюту, отмену, успех, `getPurchases` и
   `consumePurchase` в размещённой draft-сборке.
4. Не включать VK-профиль, пока в конкретном кабинете и актуальной официальной
   документации не подтверждены тип приложения, платёжный продукт, тестовый режим
   и способ получить SDK-текст/цену до открытия формы оплаты.

## Проверенные официальные источники (2026-09-19)

- RuStore Pay SDK overview: <https://www.rustore.ru/help/en/sdk/pay>
- RuStore Pay SDK for Godot, current 11.1.0: <https://www.rustore.ru/help/en/sdk/pay/godot>
- Yandex Games in-app purchases: <https://yandex.ru/dev/games/doc/ru/sdk/sdk-purchases>
- Yandex purchase requirements: <https://yandex.ru/dev/games/doc/ru/requirements/1/13>

Статическая и desktop-проверка не подтверждает настоящую оплату, sandbox,
кабинет, подпись Android, hosted Web callbacks или модерацию.
