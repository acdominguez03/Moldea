# Habits

Paquete de la feature **Hábitos**: la pestaña de creación y gestión de los hábitos de Moldea.

De momento contiene la infraestructura de textos localizados y la pantalla raíz `HabitsView`,
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
Sources/Habits/
├── Data/           # repositorios y fuentes de datos (vacía por ahora)
├── Domain/         # modelos y casos de uso (vacía por ahora)
└── Presentation/
    ├── HabitsView.swift
    ├── Enums/
    │   └── HabitsTextsEnum.swift
    └── Resources/
        └── Localizable.xcstrings
Tests/HabitsTests/
```

Es la misma estructura de tres capas que `Core` y que el resto de paquetes de feature
(`Today`, `Statistics`, `Settings`). Las vistas y los modelos de vista van en `Presentation`.

Este es el paquete donde vivirá el modelo de hábito y su persistencia, así que es previsible
que `Domain` y `Data` crezcan antes que en el resto de features.

## Pantalla

`HabitsView` es el punto de entrada público del paquete: un `NavigationStack` con un
`ScrollView` vacío y el título de pantalla en grande. Es la misma forma que `TodayView`,
`StatisticsView` y `SettingsView`; la compone el target `Moldea` en el caso `.habits` de
`MainTab`.

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
(`Habits_Habits`) automáticamente al detectar el catálogo; no hace falta declarar `resources:`
en `Package.swift`.

Claves actuales:

| Clave | en | es |
|---|---|---|
| `habits_screen_title` | Habits | Hábitos |
| `habits_empty_state` | You have not created any habits yet | Todavía no has creado ningún hábito |

Para añadir un texto: añade la entrada al `Localizable.xcstrings` (en `en` y `es`, con
`"extractionState": "manual"`) y expón la constante en `HabitsTextsEnum`. Las claves van en
`snake_case` con el prefijo `habits_`; las constantes, en `camelCase`.

Los textos que acaben usándose desde más de un módulo se mueven a `CoreTextsEnum`. Ojo: el
título de la pestaña ya vive en `Core` como `habits_title` —lo consume `MainTab`—;
`habits_screen_title` es el título de la pantalla, no el de la pestaña.

Para los textos con cantidad variable ("3 hábitos", "1 racha"), usa una variación de plural en
el catálogo en vez de concatenar.

## Tests

Swift Testing (`import Testing`, `@Test`). `Tests/HabitsTests/HabitsTests.swift` es todavía la
plantilla generada.
