# Habits

Paquete de la feature **Hábitos**: la pestaña de creación y gestión de los hábitos de Moldea.

Hoy contiene la lista de hábitos (`HabitsView`), la pantalla de creación (`CreateHabitView`),
el catálogo de iconos y la paleta de colores.

Depende de `Core` (`.package(path: "../Core")`), de donde salen las entidades de dominio
(`Habit`, `HabitFrequency`…), el protocolo `HabitRepository`, `BaseViewModel` y
`HexColorConverter`. Los `@Model` de SwiftData son `internal` a `Core` y este paquete no los
ve: solo trabaja con tipos de dominio. La arquitectura completa está en el `CLAUDE.md` raíz.

## Configuración

- `swift-tools-version: 6.4`
- Plataforma mínima: `.iOS(.v26)`
- `swiftSettings`: `.enableUpcomingFeature("ApproachableConcurrency")` en target y test target
- Dependencia: `.package(path: "../Core")`, también en el test target (los tests necesitan
  `HabitRepository` para sus fakes)
- Recurso: `Data/Resources/habit-icon-families.json` (declarado con `.process`)

## Estructura

```
Sources/Habits/
├── DI/HabitsDependencies.swift          # contenedor + @Entry \.habitsDependencies
├── Domain/
│   ├── HabitIconCatalog.swift           # protocolo
│   └── HabitIconFamily.swift
├── Data/
│   ├── BundleHabitIconCatalog.swift     # lee habit-icon-families.json
│   └── Resources/habit-icon-families.json
└── Presentation/
    ├── HabitsView.swift                 # punto de entrada público
    ├── HabitForm/
    │   ├── HabitFormView.swift
    │   ├── HabitFormViewModel.swift
    ├── HabitList/HabitView.swift        # fila de la lista
    ├── CreateHabit/
    │   ├── CreateHabitView.swift
    │   ├── CreateHabitViewModel.swift
    │   ├── ChooseHabitIconView.swift
    │   ├── ChooseHabitIconViewModel.swift
    │   ├── Model/WeekdayItem.swift
    │   └── Components/                  # HabitSummaryView, HabitIconPicker,
    │                                    # HabitColorPicker, HabitFrequencyPicker…
    ├── Enums/                           # HabitsTextsEnum, HabitPaletteColorEnum,
    │                                    # HabitPaletteIconEnum, HabitFrequencyEnum…
    └── Resources/Localizable.xcstrings
Tests/HabitsTests/
```

`Data` de este paquete solo tiene las fuentes propias de la feature (el catálogo de iconos). El
repositorio de hábitos y su persistencia viven en `Core`.

**La tarjeta de hábito tampoco vive aquí.** `HabitCardView`, `HabitIconBadge` y
`HabitScheduleSummaryEnum` bajaron a `Core/Presentation/Components` cuando las pantallas de comandos
de voz las necesitaron, y con ellas los textos del resumen de la frecuencia
(`habits_summary_every_day`, `habits_summary_times_per_day`, `habits_summary_times_per_week` y
`days`), que ahora están en `CoreTextsEnum`. `HabitView` se queda con lo que solo tiene sentido
dentro de un `List`: envuelve `HabitCardView(habit:)` y le añade el chevron y los dos
`swipeActions`.

## Pantalla y composición

`HabitsView` es el punto de entrada público: un `NavigationStack` con la lista de hábitos —que
lee con `@HabitsQuery`, de `Core`, y pinta con `HabitView`—, un `ContentUnavailableView` cuando
no hay ninguno, el título en grande y un botón `+` que presenta `CreateHabitView` en una hoja.
La compone el target `Moldea` en el caso `.habits` de `MainTabEnum`.

`HabitsView` es `public init()`: lee `\.habitsDependencies` y pinta
`HabitsContentView(viewModel: dependencies.makeHabitsViewModel())`, que es la lista (patrón
`XView` / `XContentView` del `CLAUDE.md` raíz). Las dos hojas presentan `HabitFormView()` (crear)
y `HabitFormView(editing: habit)` (editar), que a su vez leen el entorno y pintan
`HabitFormContentView` con un `HabitFormViewModel` **nuevo cada vez que se abre la hoja**.

`DI/HabitsDependencies.swift` recibe un `CoreDependencies` y construye los view models:
`makeHabitsViewModel()` y `makeHabitFormViewModel(editing:)`, que traduce un `Habit` a los
parámetros del formulario en modo edición. También guarda el `iconCatalog`
(`BundleHabitIconCatalog`); el `init` público solo expone `core` porque `HabitIconCatalog` es
`internal`. Así los view models, el catálogo y los casos de uso siguen siendo `internal`.

## Guardar un hábito

```
Guardar → HabitFormViewModel.save()
  → CreateHabitUseCase.execute(name:color:icon:frequency:repetitionsPerDay:)
  → HabitRepository.create(Habit)          (Core)
```

**`CreateHabitUseCase` y `DeleteHabitUseCase` ya no viven aquí: están en `Core/Domain/UseCases`.**
Bajaron cuando la capa de comandos de voz de `Core` los necesitó, siguiendo la regla de que lo
que usan dos módulos baja a `Core`. `Habits` los resuelve con el `import Core` que ya tenía, y
`CreateHabitErrorEnum` y su tabla de validación están documentados en el `CLAUDE.md` de `Core`.

Lo que sigue siendo cierto aquí: **el caso de uso recibe los datos sueltos y construye él el
`Habit`**, así que el view model no conoce ninguna entidad.

**`HabitFormViewModel`** conforma `BaseViewModel` (`isLoading`, `errorMessage`). Guarda el
estado de la pantalla y traduce `selectedFrequency` + `selectedTimesAWeek` + `selectedWeekdays`
a un `HabitFrequency` (`makeFrequency()`).

- `save()` usa `perform { … }` y, si termina bien, pone `didSave = true`. La vista observa
  `didSave` con `.onChange` y hace `dismiss()`. `didSave` no se reinicia: no hace falta porque
  cada apertura de la hoja crea un view model nuevo.
- `canSave` (comodidad de la UI): nombre no vacío tras recortar, al menos un día si la
  frecuencia es «días fijos», y no estar guardando. El caso de uso valida igualmente.
- Cualquier error, también los de validación, se muestra como el mensaje genérico de `Core`
  (`BaseViewModel.perform`). Como la UI evita las entradas inválidas, no deberían llegar al
  usuario. `HabitFormView` lo pinta como texto rojo bajo el formulario.

## Colores

Contrato y razonamiento en el `CLAUDE.md` raíz, en _Colores de los hábitos_. Resumen de cómo lo
aplica este paquete:

- `HabitPaletteColorEnum`: 13 casos (`red, orange, yellow, green, mint, teal, blue, indigo, purple,
pink, gray, brown, stone`), cada uno con `hex`, `color` (derivado del hex con
  `HexColorConverter`, con `.gray` de red de seguridad) y `name` localizado. El orden de
  `allCases` es el del picker: 7 en la primera fila y los 6 restantes más el `ColorPicker`
  nativo en la segunda, por eso hay un test que exige exactamente 13.
- `HabitFormViewModel` guarda `selectedColorHex` (**gris por defecto**, `#5B6470`) y expone
  `selectedColor: Color`; `selectColor(hex:)` es la única forma de cambiarlo. El resto de vistas
  (`HabitSummaryView`, `HabitIconPicker`, `ChooseHabitIconView`) reciben un `Color`.
- `HabitColorPicker` recibe `selectedHex` y devuelve un hex. Los colores de la paleta devuelven
  su `hex`; el `ColorPicker` nativo convierte con `HexColorConverter.hex(from:in:)` usando
  `@Environment(\.self)`. La selección se compara como `String`; es "personalizado" el hex que
  no está en la paleta.
- `stone` sustituye al antiguo `black` (clave `habits_color_stone`: "Stone" / "Piedra").

## Iconos

`HabitIconCatalog` (protocolo, `Domain`) carga `HabitIconFamily`; `BundleHabitIconCatalog`
(`Data`) lee `habit-icon-families.json` fuera del hilo principal (`@concurrent`).
`ChooseHabitIconViewModel` lo consume y registra los fallos con `Logger`. El icono guardado en el
hábito es el nombre del SF Symbol.

**`ChooseHabitIconView`: una fila de la `List` por línea de iconos, nunca un `LazyVGrid` por fila.**
Cada familia es una `Section` y cada fila es un `HStack` con los iconos de una línea. Una `List` es
un `UICollectionView` que autodimensiona sus celdas y necesita alturas exactas. Un `LazyVGrid`
«only calculates the geometry for subviews as they become visible» (_Creating performant
scrollable stacks_), así que su altura es una estimación. Con la versión anterior (un `LazyVGrid`
con toda la familia en una sola fila, hasta 923 iconos), el iPhone 15 Pro Max con iOS 26.6.2
abortaba al abrir la pantalla con «stuck in a recursive layout loop». En los simuladores 26.x y en
iOS 27 no fallaba.

- Columnas con la misma regla que `GridItem(.adaptive(minimum:))`, a partir del ancho de una
  línea medido con `onGeometryChange` (`lineWidth`). Hasta medirlo se usan 6.
- Cada icono se limita a `maximumItemSize`, como el máximo de `.adaptive`.
- La última línea se rellena con huecos (`Color.clear`) para que sus iconos no se estiren.
- Márgenes: `listRowInsets(.top/.bottom, 5)` entre líneas, para que el espacio vertical sea el
  mismo que el horizontal (10). En los bordes de la sección se deja el margen por defecto (`nil`)
  más 4 pt de `padding`.

`HabitIconPicker` (el del formulario) sí usa un `LazyVGrid` dentro de una fila del `Form`. Con 14
iconos, todos visibles, su altura es exacta y no ha dado problemas.

## Textos y localización

Un único catálogo por paquete —`Presentation/Resources/Localizable.xcstrings`— y un único
punto de acceso —`HabitsTextsEnum`—, que expone constantes `LocalizedStringResource`:

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
(`Habits_Habits`) automáticamente al detectar el catálogo.

El catálogo tiene hoy unas 58 claves: título de pantalla, formulario (nombre, frecuencia, veces
al día/semana), los 13 colores (`habits_color_*` más `habits_color_custom` y
`habits_color_title`), y los iconos y sus familias (`habits_icon_*`). Las claves nuevas van en
`snake_case` con el prefijo `habits_`; algunas antiguas no lo llevan (`new_habit`, `frequency`,
`times_a_day`…).

Para añadir un texto: añade la entrada al `Localizable.xcstrings` (en `en` y `es`, con
`"extractionState": "manual"`) y expón la constante en `HabitsTextsEnum`.

Los textos que acaben usándose desde más de un módulo se mueven a `CoreTextsEnum`. Ojo: el
título de la pestaña ya vive en `Core` como `habits_title` —lo consume `MainTabEnum`—;
`habits_screen_title` es el título de la pantalla, no el de la pestaña. `Guardar` y `Cancelar`
también vienen de `Core` (`CoreTextsEnum.save`, `.cancel`).

Para los textos con cantidad variable ("3 hábitos", "1 racha"), usa una variación de plural en
el catálogo en vez de concatenar.

## Tests

Swift Testing. Los repositorios y casos de uso falsos son `actor` (los protocolos son
`Sendable`).

`CreateHabitUseCaseTests` se fue a `CoreTests` con el caso de uso, y
`HabitScheduleSummaryTests` con el resumen.

- `HabitAppearanceDefaultsTests`: ata `HabitAppearanceDefaultsEnum` (en `Core`) a
  `HabitPaletteColorEnum.gray.hex` y a `HabitPaletteIconEnum.drop.systemName`. Existe porque `Core` no
  puede importar `Habits`, así que los valores por defecto de un hábito creado por voz están
  duplicados; este test es lo único que impide que se separen en silencio.
- `CreateHabitViewModelTests`: color por defecto y selección (paleta, personalizado, hex
  ilegible → gris), `canSave`, traducción de cada frecuencia al caso de uso, `didSave` y error
  genérico cuando el caso de uso falla.
- `HabitPaletteColorTests`: los 13 hex parsean (garantiza que el fallback no se usa), formato
  `#RRGGBB` en mayúsculas, sin repetidos y exactamente 13 casos.

No hay tests de vista ni de la cadena completa por la interfaz. `HabitsTests.swift` es todavía
la plantilla generada.

## Accesibilidad

`HabitView` expone pausar/eliminar como acciones de VoiceOver y lee los días completos. El
selector de días, la paleta y el de frecuencia cambian de disposición en tamaños de
accesibilidad; los errores del formulario se anuncian.

Las reglas comunes están en el `CLAUDE.md` raíz, en _Accesibilidad_.
