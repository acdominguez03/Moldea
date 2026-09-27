# Today

Paquete de la feature **Hoy**: la pestaña de inicio de Moldea, la vista del día en curso.

De momento contiene la infraestructura de textos localizados y la pantalla raíz `TodayView`,
todavía sin contenido. Las capas `Data` y `Domain` están vacías.

Depende de `Core` (`.package(path: "../Core")`), de donde saldrán los modelos y utilidades
compartidas (`LoadableViewModel`, los `@Model` de SwiftData). Hoy la vista todavía no consume
nada de `Core`.

## Configuración

- `swift-tools-version: 6.4`
- Plataforma mínima: `.iOS(.v26)`
- `swiftSettings`: `.enableUpcomingFeature("ApproachableConcurrency")` en target y test target
- Dependencia: `.package(path: "../Core")`

## Estructura

```
Sources/Today/
├── DI/TodayDependencies.swift   # contenedor + @Entry \.todayDependencies
├── Data/           # repositorios y fuentes de datos (vacía por ahora)
├── Domain/         # modelos y casos de uso (vacía por ahora)
└── Presentation/
    ├── TodayView.swift
    ├── Enums/
    │   └── TodayTextsEnum.swift
    └── Resources/
        └── Localizable.xcstrings
Tests/TodayTests/
```

Es la misma estructura de tres capas que `Core` y que el resto de paquetes de feature
(`Statistics`, `Habits`, `Settings`). Las vistas y los modelos de vista van en `Presentation`.

## Pantalla

`TodayView` es el punto de entrada público del paquete: un `NavigationStack` con una `List`
cuya cabecera lleva el selector de pestaña (`TodayTabEnum`: diaria / semanal) y el progreso, y
cuyas filas son `TodayCardView`. La compone el target `Moldea` en el caso `.today` de `MainTabEnum`.

Los hábitos no los carga el view model: entran por `@TodayHabitsQuery` y `@WeeklyHabitsQuery`
(de `Core`), que son `@Query` de SwiftData envueltos en un `propertyWrapper`. Por eso marcar una
completion no necesita recarga: SwiftData republica y la vista se repinta sola.

### Progreso de la cabecera

El porcentaje **no se calcula en la vista**: lo da `CalculateHabitsProgressUseCase`, de `Core`
(la fórmula y su porqué están en el `CLAUDE.md` de `Core`). `TodayDependencies.makeTodayViewModel()` se lo
pasa al view model (con `core.calculateHabitsProgress`, `core.toggleHabitCompletion` y
`core.todayProgressStore`); `TodayView` es `public init()`, lee `\.todayDependencies` y pinta
`TodayContentView(viewModel:)`, que lo consulta con `todayViewModel.progress(for: habits)`, donde `habits` es la lista de la
pestaña activa.

El único trabajo de `TodayViewModel` aquí es traducir su estado de UI al parámetro del caso de
uso: `TodayTabEnum → HabitProgressScopeEnum`. Ese mapeo vive en el view model y en ningún otro
sitio; `TodayTabEnum` se queda en `Today` porque es estado de pantalla, y el enum de alcance está
en `Core` porque es del caso de uso.

`progress(for:)` es un método y no estado publicado porque la lista la tiene la vista, no el view
model: es un valor derivado, como `unavailableMessage` en `HabitCommandViewModel`.

Lo que había antes era `habits.filter(\.isCompletedToday).count` dentro de `TodayView`, que
además daba 0 en la pestaña semanal hasta que marcabas el día de hoy, porque `isCompletedToday`
mide el objetivo del día y no el de la semana.

## Textos y localización

Un único catálogo por paquete —`Presentation/Resources/Localizable.xcstrings`— y un único
punto de acceso —`TodayTextsEnum`—, que expone constantes `LocalizedStringResource`:

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
(`Today_Today`) automáticamente al detectar el catálogo; no hace falta declarar `resources:`
en `Package.swift`.

Claves actuales:

| Clave | en | es |
|---|---|---|
| `today_screen_title` | Today | Hoy |
| `today_empty_state` | Nothing planned for today yet | Aún no hay nada planificado para hoy |

Para añadir un texto: añade la entrada al `Localizable.xcstrings` (en `en` y `es`, con
`"extractionState": "manual"`) y expón la constante en `TodayTextsEnum`. Las claves van en
`snake_case` con el prefijo `today_`; las constantes, en `camelCase`.

Los textos que acaben usándose desde más de un módulo se mueven a `CoreTextsEnum`. Ojo: el
título de la pestaña ya vive en `Core` como `today_title` —lo consume `MainTabEnum`—;
`today_screen_title` es el título de la pantalla, no el de la pestaña.

## Tests

Swift Testing (`import Testing`, `@Test`). `Tests/TodayTests/TodayTests.swift` es todavía la
plantilla generada.

`TodayViewModelTests` cubre el toggle (los datos que recibe el caso de uso y el error genérico
cuando falla) y el alcance que se le pasa al de progreso según la pestaña seleccionada.

`FakeCalculateHabitsProgressUseCase` es una `final class @unchecked Sendable`, **no un `actor`**:
`execute(habits:scope:)` es síncrono y un `actor` no puede satisfacer una conformidad síncrona
sin volverse `nonisolated`. Es el mismo motivo que documenta `Core` para
`FakeUserDefaultsRepository`; `FakeToggleHabitCompletionUseCase`, que sí es `actor`, puede serlo
porque su método es `async`.

Los tests de los paquetes **no están en el test plan de Xcode** (`Moldea` solo trae
`MoldeaTests` y `MoldeaUITests`), así que se pasan con `xcodebuild test -scheme Today
-destination 'id=<simulador iOS 26/27>'`.

## Accesibilidad

`TodayCompletionCheck` nombra el hábito en su etiqueta (`completionLabel(_:)`), expone
«Completado» + `.isSelected` y escala con `@ScaledMetric`. `TodayCardView` usa el patrón
`AnyLayout` en tamaños de accesibilidad.

Las reglas comunes están en el `CLAUDE.md` raíz, en _Accesibilidad_.
