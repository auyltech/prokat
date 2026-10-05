# Локальные кадры OCR

Сюда кладутся обезличенные фото для ручного прогона debug-экрана «OCR spike».

Каталог в git не коммитится, кроме этого файла. Снимки не загружать в backend.

Сейчас в APK подключён только ML Kit Latin. Он не основной OCR марки и модели: кириллицу может подменить похожей латиницей. Большой набор под него не снимать.

Следующий прогон — на компьютере, официальные `PP-OCRv5_mobile_det` и `cyrillic_PP-OCRv5_mobile_rec`, до Android. ML Kit в этом прогоне не сравнивать.

Классы, несколько реальных фото бланков:

- Cyrillic: `ГАЗ 2705`, `КамАЗ …`, `ЗИЛ …`
- Mixed: `АВТОПОГРУЗЧИК TOYOTA 42-7FG15` и ещё одна строка кириллица + латинский model code
- Latin: `XCMG XE215C`, `CAT 320D`
- Identifiers: госномер и VIN отдельно

Рядом с файлом `имя.txt`. На каждый движок свой блок raw.

```text
device: Samsung A125F
os:
engine:
image source: camera | gallery
framing: full | crop
group: cyrillic | mixed | latin | identifier
kind: good | angled | glare | blur | small-text
ground truth:
raw:
identity expected:
identity observed:
result: IDENTITY_EXACT | IDENTITY_NORMALIZED_EXACT | IDENTITY_USABLE_PARTIAL | IDENTITY_WRONG | IDENTITY_MISSING
failure: detection | recognition | none
framing: full | line-crop | identity-crop
elapsedMs:
warnings:
```

Метка ставится по identity-подстроке, не по всему бланку.

`АВТОПОГРУ... TOYOTA 42-7FG15` при ground truth `АВТОПОГРУЗЧИК TOYOTA 42-7FG15` — `IDENTITY_EXACT`, если `TOYOTA 42-7FG15` цело. Порча слова «автопогрузчик» full-line портит, марку и модель нет.

`ГАЗ 2705` → `GA3 2705` — `IDENTITY_WRONG`. `GA3` обратно в `ГАЗ` не превращать. `КАМАЗ` при ground truth `КамАЗ` — `IDENTITY_NORMALIZED_EXACT`. `KamAZ` — нет.

Сюда же кладутся фото для локального прогона Paddle на компьютере, до любого Android. Пока файлов нет, GO/NO-GO не выносится.
