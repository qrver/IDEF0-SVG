# Branching Fix for Shared Concepts

## Problem Description / Описание проблемы

**EN:** When a control or mechanism arrow (or any concept) had one name but entered multiple boxes, the system created 2 separate arrow elements instead of one arrow with branching. This resulted in duplicate labels and separate lines for what should be a single shared concept.

**RU:** Когда стрелка управления или механизма (или любой концепт) имела одно название, но входила в несколько блоков, система создавала 2 отдельных элемента стрелок вместо одной стрелки с ветвлениями. Это приводило к дублированию меток и отдельным линиям для того, что должно быть единым общим концептом.

## Solution / Решение

**EN:** The fix modifies how external lines (inputs, outputs, controls, mechanisms) are created. Instead of creating one line per box, the system now:

1. Groups all boxes that expect the same concept name
2. Creates a single line that branches to multiple targets
3. Draws a branching structure with:
   - A main line from the external source
   - A horizontal/vertical branch line
   - Individual lines to each target with arrows

**RU:** Исправление модифицирует способ создания внешних линий (входы, выходы, управления, механизмы). Вместо создания одной линии на каждый блок, система теперь:

1. Группирует все блоки, которые ожидают один и тот же концепт
2. Создает одну линию с ветвлениями к нескольким целям
3. Рисует структуру ветвления с:
   - Основной линией от внешнего источника
   - Горизонтальной/вертикальной линией ветвления
   - Отдельными линиями к каждой цели со стрелками

## Example / Пример

**Before / До:**
```
Control-X → Function
Control-X → Function2
```
(Two separate lines with two separate labels)

**After / После:**
```
        Control-X
            |
      ------+------
      |           |
      ↓           ↓
  Function2   Function
```
(One line with branching to both functions)

## Modified Files / Измененные файлы

1. **`lib/idef0/diagram.rb`**
   - Changed external line creation to use `make_lines_grouped` method
   - Groups targets by concept name before creating lines

2. **`lib/idef0/external_line.rb`**
   - Added `make_lines_grouped` class method (default implementation)
   - Allows subclasses to override for custom grouping logic

3. **`lib/idef0/external_guidance_line.rb`**
   - Modified to support multiple targets
   - Implements branching SVG drawing logic
   - Groups boxes by concept name in `make_lines_grouped`

4. **`lib/idef0/external_mechanism_line.rb`**
   - Same modifications as guidance line for bottom-side connections

5. **`lib/idef0/external_input_line.rb`**
   - Modified to support multiple targets
   - Implements horizontal branching for left-side inputs

6. **`lib/idef0/external_output_line.rb`**
   - Modified to support multiple sources (collecting outputs)
   - Implements horizontal branching for right-side outputs

7. **`lib/idef0/unsatisfied_input_line.rb`**
   - Added `make_lines_grouped` for unattached inputs

8. **`lib/idef0/unsatisfied_output_line.rb`**
   - Added `make_lines_grouped` for unattached outputs

9. **`lib/idef0/unsatisfied_guidance_line.rb`**
   - Added `make_lines_grouped` for unattached controls

10. **`lib/idef0/unsatisfied_mechanism_line.rb`**
    - Added `make_lines_grouped` for unattached mechanisms

## Testing / Тестирование

Test the fix with:
```bash
bin/schematic < samples/bug.idef0 > output.svg
bin/schematic < samples/branching-test.idef0 > output2.svg
```

The bug.idef0 example demonstrates Control-X being shared between Function and Function2.

The branching-test.idef0 example demonstrates:
- Control-Shared: branches to Function A and Function B
- Mechanism-Shared: branches to Function A and Function B  
- Input-Shared: branches to Function B and Function C
- Output-Shared: collects from Function C and Function D

## Backward Compatibility / Обратная совместимость

**EN:** The fix maintains backward compatibility:
- Single target lines still work as before
- Existing diagrams render correctly
- The branching logic only activates when multiple boxes share the same concept name

**RU:** Исправление сохраняет обратную совместимость:
- Линии с одной целью работают как раньше
- Существующие диаграммы отображаются корректно
- Логика ветвления активируется только когда несколько блоков используют один концепт

## Technical Details / Технические детали

**EN:** Each external line class now:
1. Stores multiple targets (or sources for outputs) in an array
2. Creates multiple target_anchors when attaching
3. Calculates center point for label placement
4. Generates branching SVG with proper geometry
5. Handles both ArraySet and Array target collections

**RU:** Каждый класс внешней линии теперь:
1. Хранит несколько целей (или источников для выходов) в массиве
2. Создает несколько target_anchors при присоединении
3. Вычисляет центральную точку для размещения метки
4. Генерирует SVG ветвления с правильной геометрией
5. Обрабатывает коллекции целей как ArraySet, так и Array