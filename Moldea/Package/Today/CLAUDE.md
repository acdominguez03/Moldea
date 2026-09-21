# Today

Paquete de la feature **Hoy**: la pestaña de inicio de Moldea, la vista del día en curso.

De momento contiene la infraestructura de textos localizados y la pantalla raíz `TodayView`,
todavía sin contenido. Las capas `Data` y `Domain` están vacías.

Depende de `Core` (`.package(path: "../Core")`), de donde saldrán los modelos y utilidades
compartidas (`LoadableViewModel`, los `@Model` de SwiftData). Hoy la vista todavía no consume
nada de `Core`.

## Configuración

- `swift-tools-version: 6.2`
- Plataforma mínima: `.iOS(.v26)`
- `swiftSettings`: `.enableUpcomingFeature("ApproachableConcurrency")` en target y test target
- Dependencia: `.package(path: "../Core")`

## Estructura

```
Sources/Today/
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

`TodayView` es el punto de entrada público del paquete: un `NavigationStack` con un
`ScrollView` vacío y el título de pantalla en grande. Es la misma forma que `HabitsView`,
`StatisticsView` y `SettingsView`; la compone el target `Moldea` en el caso `.today` de
`MainTab`.

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
título de la pestaña ya vive en `Core` como `today_title` —lo consume `MainTab`—;
`today_screen_title` es el título de la pantalla, no el de la pestaña.

## Tests

Swift Testing (`import Testing`, `@Test`). `Tests/TodayTests/TodayTests.swift` es todavía la
plantilla generada.
