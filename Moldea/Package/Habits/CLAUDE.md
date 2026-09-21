# Habits

Paquete de la feature **Hábitos**: la pestaña de creación y gestión de los hábitos de Moldea.

Hoy contiene la pantalla de creación de hábitos (`CreateHabitView`) con su caso de uso, el
catálogo de iconos y la paleta de colores. `HabitsView` todavía no lista los hábitos: no hay
`fetch` en el repositorio, así que tras guardar un hábito no se ve en ninguna pantalla.

Depende de `Core` (`.package(path: "../Core")`), de donde salen las entidades de dominio
(`Habit`, `HabitFrequency`…), el protocolo `HabitRepository`, `BaseViewModel` y
`HexColorConverter`. Los `@Model` de SwiftData son `internal` a `Core` y este paquete no los
ve: solo trabaja con tipos de dominio. La arquitectura completa está en el `CLAUDE.md` raíz.

## Configuración

- `swift-tools-version: 6.2`
- Plataforma mínima: `.iOS(.v26)`
- `swiftSettings`: `.enableUpcomingFeature("ApproachableConcurrency")` en target y test target
- Dependencia: `.package(path: "../Core")`, también en el test target (los tests necesitan
  `HabitRepository` para sus fakes)
- Recurso: `Data/Resources/habit-icon-families.json` (declarado con `.process`)

## Estructura

```
Sources/Habits/
├── Domain/
│   ├── UseCases/
│   │   ├── CreateHabitUseCase.swift     # protocolo + DefaultCreateHabitUseCase
│   │   └── CreateHabitError.swift
│   ├── HabitIconCatalog.swift           # protocolo
│   └── HabitIconFamily.swift
├── Data/
│   ├── BundleHabitIconCatalog.swift     # lee habit-icon-families.json
│   └── Resources/habit-icon-families.json
└── Presentation/
    ├── HabitsView.swift                 # punto de entrada público
    ├── CreateHabit/
    │   ├── CreateHabitView.swift
    │   ├── CreateHabitViewModel.swift
    │   ├── ChooseHabitIconView.swift
    │   ├── ChooseHabitIconViewModel.swift
    │   ├── Model/WeekdayItem.swift
    │   └── Components/                  # HabitSummaryView, HabitIconPicker,
    │                                    # HabitColorPicker, HabitFrequencyPicker…
    ├── Enums/                           # HabitsTextsEnum, HabitPaletteColor,
    │                                    # HabitPaletteIcon, HabitFrequencyEnum…
    └── Resources/Localizable.xcstrings
Tests/HabitsTests/
```

`Data` de este paquete solo tiene las fuentes propias de la feature (el catálogo de iconos). El
repositorio de hábitos y su persistencia viven en `Core`.

## Pantalla y composición

`HabitsView` es el punto de entrada público: un `NavigationStack` con un `ScrollView` vacío, el
título en grande y un botón `+` que presenta `CreateHabitView` en una hoja. La compone el target
`Moldea` en el caso `.habits` de `MainTab`.

Su `init` público recibe `habitRepository: any HabitRepository`. Construye por dentro
`DefaultCreateHabitUseCase(repository:)` y crea un `CreateHabitViewModel` **nuevo cada vez que se
abre la hoja**. Así el caso de uso, el view model y `BundleHabitIconCatalog` siguen siendo
`internal`.

## Guardar un hábito

```
Guardar → CreateHabitViewModel.save()
  → CreateHabitUseCase.execute(name:color:icon:frequency:repetitionsPerDay:)
  → HabitRepository.create(Habit)          (Core)
```

**`CreateHabitUseCase`** recibe los datos sueltos y construye él el `Habit`: el view model no
conoce ninguna entidad. `DefaultCreateHabitUseCase` recibe el repositorio y, para poder
testearse, `makeID` y `now` como closures (con `UUID()` y `.now` por defecto). Recorta el nombre
y crea el hábito con `isActive = true` y `createdAt == updatedAt`.

Valida en este orden y lanza el primer error (`CreateHabitError`):

| Error | Cuándo |
|---|---|
| `emptyName` | el nombre recortado está vacío |
| `invalidColor` | no es `#` más 6 dígitos hexadecimales **ASCII** |
| `invalidRepetitionsPerDay` | `repetitionsPerDay < 1` (el rango 1...20 es cosa de la UI) |
| `invalidTimesPerWeek` | `weeklyCount` fuera de 1...7 |
| `emptyWeekdays` | `fixedDays` sin ningún día |
| `invalidWeekdays` | algún día de `fixedDays` fuera de 1...7 |

No se valida el icono: no tiene formato comprobable sin UIKit y el selector no da uno vacío.

**`CreateHabitViewModel`** conforma `BaseViewModel` (`isLoading`, `errorMessage`). Guarda el
estado de la pantalla y traduce `selectedFrequency` + `selectedTimesAWeek` + `selectedWeekdays`
a un `HabitFrequency` (`makeFrequency()`).

- `save()` usa `perform { … }` y, si termina bien, pone `didSave = true`. La vista observa
  `didSave` con `.onChange` y hace `dismiss()`. `didSave` no se reinicia: no hace falta porque
  cada apertura de la hoja crea un view model nuevo.
- `canSave` (comodidad de la UI): nombre no vacío tras recortar, al menos un día si la
  frecuencia es «días fijos», y no estar guardando. El caso de uso valida igualmente.
- Cualquier error, también los de validación, se muestra como el mensaje genérico de `Core`
  (`BaseViewModel.perform`). Como la UI evita las entradas inválidas, no deberían llegar al
  usuario. `CreateHabitView` lo pinta como texto rojo bajo el formulario.

## Colores

Contrato y razonamiento en el `CLAUDE.md` raíz, en *Colores de los hábitos*. Resumen de cómo lo
aplica este paquete:

- `HabitPaletteColor`: 13 casos (`red, orange, yellow, green, mint, teal, blue, indigo, purple,
  pink, gray, brown, stone`), cada uno con `hex`, `color` (derivado del hex con
  `HexColorConverter`, con `.gray` de red de seguridad) y `name` localizado. El orden de
  `allCases` es el del picker: 7 en la primera fila y los 6 restantes más el `ColorPicker`
  nativo en la segunda, por eso hay un test que exige exactamente 13.
- `CreateHabitViewModel` guarda `selectedColorHex` (**gris por defecto**, `#5B6470`) y expone
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
título de la pestaña ya vive en `Core` como `habits_title` —lo consume `MainTab`—;
`habits_screen_title` es el título de la pantalla, no el de la pestaña. `Guardar` y `Cancelar`
también vienen de `Core` (`CoreTextsEnum.save`, `.cancel`).

Para los textos con cantidad variable ("3 hábitos", "1 racha"), usa una variación de plural en
el catálogo en vez de concatenar.

## Tests

Swift Testing. Los repositorios y casos de uso falsos son `actor` (los protocolos son
`Sendable`).

- `CreateHabitUseCaseTests`: el `Habit` que recibe el repositorio para las tres frecuencias (con
  `id` y fecha fijados), nombre recortado, 13 entradas inválidas (cada una lanza su error y no
  toca el repositorio; incluye un hex de ancho completo) y propagación del error del
  repositorio.
- `CreateHabitViewModelTests`: color por defecto y selección (paleta, personalizado, hex
  ilegible → gris), `canSave`, traducción de cada frecuencia al caso de uso, `didSave` y error
  genérico cuando el caso de uso falla.
- `HabitPaletteColorTests`: los 13 hex parsean (garantiza que el fallback no se usa), formato
  `#RRGGBB` en mayúsculas, sin repetidos y exactamente 13 casos.

No hay tests de vista ni de la cadena completa por la interfaz. `HabitsTests.swift` es todavía
la plantilla generada.
