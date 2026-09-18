# Statistics

Paquete de la feature **Estadísticas**: la pestaña de métricas y progreso de Moldea.

De momento contiene la infraestructura de textos localizados y la pantalla raíz
`StatisticsView`, todavía sin contenido. Las capas `Data` y `Domain` están vacías.

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
Sources/Statistics/
├── Data/           # repositorios y fuentes de datos (vacía por ahora)
├── Domain/         # modelos y casos de uso (vacía por ahora)
└── Presentation/
    ├── StatisticsView.swift
    ├── Enums/
    │   └── StatisticsTextsEnum.swift
    └── Resources/
        └── Localizable.xcstrings
Tests/StatisticsTests/
```

Es la misma estructura de tres capas que `Core` y que el resto de paquetes de feature
(`Today`, `Habits`, `Settings`). Las vistas y los modelos de vista van en `Presentation`.

## Pantalla

`StatisticsView` es el punto de entrada público del paquete: un `NavigationStack` con un
`ScrollView` vacío y el título de pantalla en grande. Es la misma forma que `TodayView`,
`HabitsView` y `SettingsView`; la compone el target `Moldea` en el caso `.statistics` de
`MainTab`.

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

Para añadir un texto: añade la entrada al `Localizable.xcstrings` (en `en` y `es`, con
`"extractionState": "manual"`) y expón la constante en `StatisticsTextsEnum`. Las claves van en
`snake_case` con el prefijo `statistics_`; las constantes, en `camelCase`.

Los textos que acaben usándose desde más de un módulo se mueven a `CoreTextsEnum`. Ojo: el
título de la pestaña ya vive en `Core` como `statistics_title` —lo consume `MainTab`—;
`statistics_screen_title` es el título de la pantalla, no el de la pestaña.

Al formatear números, porcentajes o rangos de fechas, usa `.formatted(...)` con los estilos de
`Foundation` en vez de construir los strings a mano: así se localizan solos.

## Tests

Swift Testing (`import Testing`, `@Test`). `Tests/StatisticsTests/StatisticsTests.swift` es
todavía la plantilla generada.
