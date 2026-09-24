# Statistics

Paquete de la feature **Estadísticas**: la pestaña de métricas y progreso de Moldea.

La pantalla raíz `StatisticsView` tiene cuatro pestañas (Día, Semana, Mes y Año), cada una con
su vista y su view model. `Data` está vacía: los datos llegan con las queries de `Core`.

Depende de `Core` (`.package(path: "../Core")`): `@HabitsQuery`, `@AllHabitsInPeriodQuery`,
`TodayHabit`, `CalculateHabitsProgressUseCase` y `HexColorConverter`.

## Configuración

- `swift-tools-version: 6.2`
- Plataforma mínima: `.iOS(.v26)`
- `swiftSettings`: `.enableUpcomingFeature("ApproachableConcurrency")` en target y test target
- Dependencia: `.package(path: "../Core")`

## Estructura

```
Sources/Statistics/
├── Data/           # vacía por ahora
├── Domain/
│   └── HabitOccurrencesBuilder.swift
└── Presentation/
    ├── StatisticsView.swift
    ├── Components/
    │   ├── DayCalendarCard.swift
    │   ├── HabitProgressCard.swift
    │   ├── HabitProgressList.swift       # lista "Por hábito", común a las 4 pestañas
    │   ├── ProgressBarChart.swift        # barras de Semana, Mes y Año
    │   └── ProgressSummaryHeader.swift   # "% cumplido este …"
    ├── DayChartView/    WeekChartView/    MonthChartView/    YearChartView/
    ├── Enums/
    │   ├── StatisticsFilterEnum.swift
    │   └── StatisticsTextsEnum.swift
    ├── Model/
    │   ├── HabitStatistic.swift
    │   └── StatisticsDay.swift
    └── Resources/
        └── Localizable.xcstrings
Tests/StatisticsTests/
```

Es la misma estructura de tres capas que `Core` y que el resto de paquetes de feature
(`Today`, `Habits`, `Settings`). Las vistas y los modelos de vista van en `Presentation`.

## Pantalla

`StatisticsView` es el punto de entrada público del paquete: un `NavigationStack` con el título en
grande, un `Picker` segmentado (`StatisticsFilterEnum`) y la vista de la pestaña elegida. La
compone el target `Moldea` en el caso `.statistics` de `MainTab`.

**Estado vacío:** si no hay ningún hábito (`@HabitsQuery`), en vez del picker se pinta el
`ContentUnavailableView` nativo con `statistics_empty_state`, igual que `HabitsView`. Sin hábitos
todas las pestañas saldrían al 0 % con la lista vacía, que no le dice nada al usuario.

Las cuatro pestañas comparten piezas de `Components/`: `ProgressSummaryHeader` (el % total),
`HabitProgressList` (la lista "Por hábito", que recibe los hábitos y un closure con el % de cada
uno) y, salvo Día, `ProgressBarChart` (las barras con Swift Charts; la barra `.weekly` de la
semana va con el color de acento). Cada view model solo calcula números.

## Textos y localización

Un único catálogo por paquete —`Presentation/Resources/Localizable.xcstrings`— y un único
punto de acceso —`StatisticsTextsEnum`—, que expone constantes `LocalizedStringResource`:

```swift
private static func resource(_ key: String) -> LocalizedStringResource {
    LocalizedStringResource(
        String.LocalizationValue(key),
        bundle: .atURL(Bundle.module.bundleURL)
    )
}
```

`bundle: .atURL(Bundle.module.bundleURL)` es obligatorio: sin él el string se buscaría en el
bundle principal de la app y no en el del paquete. Xcode genera el bundle de recursos
(`Statistics_Statistics`) automáticamente al detectar el catálogo; no hace falta declarar
`resources:` en `Package.swift`.

Claves actuales:

| Clave | en | es |
|---|---|---|
| `statistics_screen_title` | Statistics | Estadísticas |
| `statistics_empty_state` | There is no data to display yet | Todavía no hay datos que mostrar |
| `statistics_habits_header` | By habit | Por hábito |
| `statistics_day_chart_summary` | completed this day | cumplido este día |

Para añadir un texto: añade la entrada al `Localizable.xcstrings` (en `en` y `es`, con
`"extractionState": "manual"`) y expón la constante en `StatisticsTextsEnum`. Las claves van en
`snake_case` con el prefijo `statistics_`; las constantes, en `camelCase`.

Los textos que acaben usándose desde más de un módulo se mueven a `CoreTextsEnum`. Ojo: el
título de la pestaña ya vive en `Core` como `statistics_title` —lo consume `MainTab`—;
`statistics_screen_title` es el título de la pantalla, no el de la pestaña.

Al formatear números, porcentajes o rangos de fechas, usa `.formatted(...)` con los estilos de
`Foundation` en vez de construir los strings a mano: así se localizan solos.

## Gráfica semanal

`WeekChartView` lee con `@AllHabitsInPeriodQuery(.weekOfYear)`. Hay 7 barras diarias, que usan
`HabitOccurrencesBuilder.occurrences(of:on:)`, igual que la vista diaria, y una barra "Sem" para
los `.weeklyCount` con `scope: .weekly`. Antes había una `AllWeeklyHabitsQuery` en `Core` que hacía
lo mismo que `.weekOfYear`; se borró.

## Gráficas mensual y anual

`MonthChartView` y `YearChartView` (cada una con su view model) repiten la forma de
`WeekChartView`: % total del periodo, barras con Swift Charts y la lista "Por hábito" con
`HabitProgressCard`. Leen los datos con `@AllHabitsInPeriodQuery(.month / .year)` de `Core`,
que trae todos los hábitos y las completions del periodo.

- **Mes:** 4 barras `S1…S4` (`W1…W4` en inglés) con tramos fijos: días 1–7, 8–14, 15–21 y
  22–fin de mes. La última dura entre 7 y 10 días.
- **Año:** 12 barras, una por mes, con `veryShortStandaloneMonthSymbols`. Cada mes es la suma de
  sus 4 tramos.
- **Solo hasta hoy:** los días futuros no cuentan en el denominador; los tramos y meses que aún
  no han empezado salen al 0 %. Así el % anual no se hunde por los meses que faltan.
- No hay barra "Sem" aparte: los hábitos `.weeklyCount` entran en cada tramo con su objetivo
  semanal (`timesPerWeek × repeticiones`) y solo con las completions de ese tramo.

La lógica está en `Domain/HabitOccurrencesBuilder`: convierte hábitos + tramo en la lista de
`TodayHabit` esperados (uno por día programado, con las completions de ese día, y uno por tramo
para los semanales). Esa lista se puntúa con `CalculateHabitsProgressUseCase` y `scope: .all`,
que aplica `dailyTarget` o `weeklyTarget` según la frecuencia. El % total, el de cada barra y el
de cada hábito salen de la misma llamada sobre subconjuntos distintos.

## Vista diaria

`DayChartView` (pestaña **Día**) enseña un carrusel horizontal (`ScrollView` + `LazyHStack`) con
los **10 últimos días** en `DayCalendarCard`: el de la derecha es hoy y los anteriores van hacia la
izquierda. `.defaultScrollAnchor(.trailing)` hace que el carrusel arranque mostrando hoy. La carta
seleccionada (por defecto hoy) lleva el fondo `.tertiary`; las demás, ninguno. Cada carta es un
`Button` con `.buttonStyle(.plain)` para que VoiceOver la trate como control, con el rasgo
`.isSelected` en la marcada.

Debajo, el % total del día seleccionado y la lista "Por hábito" con `HabitProgressCard`, igual que
en Semana/Mes/Año.

- **Datos:** `@AllHabitsInPeriodQuery(DayChartViewModel.period())`, que usa el `init` por
  `DateInterval` de `Core`. Hace falta porque los 10 días pueden caer en dos meses y `.month` no
  basta.
- **Qué hábitos cuentan:** los mismos que en la pestaña `Today`, es decir, los que tienen
  `HabitFrequency.isScheduled(on: weekday)` ese día, con sus completions de ese día y puntuados con
  `scope: .daily`. **Los `.weeklyCount` no salen**: su objetivo es semanal y no tienen un día
  concreto (`isScheduled` devuelve `false` para ellos).
- La lógica está en `HabitOccurrencesBuilder.lastDays(_:until:)` y `occurrences(of:on:)`;
  `StatisticsDay` (`Presentation/Model`) es lo que pinta cada carta (letra con
  `veryShortStandaloneWeekdaySymbols` y número del día).

## Tests

Swift Testing (`import Testing`, `@Test`). `StatisticsTests.swift` cubre `HabitOccurrencesBuilder`
(tramos de febrero y de un mes de 31 días, días futuros, objetivo de los semanales, los 10 últimos
días cruzando de mes y los hábitos programados en un día) y los view models diario, mensual y
anual, con un `Calendar` gregoriano en UTC.
