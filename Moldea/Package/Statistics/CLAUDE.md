# Statistics

Paquete de la feature **Estadísticas**: la pestaña de métricas y progreso de Moldea.

Recién creado: de momento solo contiene la infraestructura de textos localizados. Las capas
`Data` y `Domain` están vacías, y aún no hay vistas.

No depende de ningún otro paquete. Si necesita textos o utilidades compartidas, la dependencia
a añadir es `Core` (`.package(path: "../Core")`), como hace `Navigation`.

## Configuración

- `swift-tools-version: 6.4`
- Plataforma mínima: `.iOS(.v26)`
- `swiftSettings`: `.enableUpcomingFeature("ApproachableConcurrency")` en target y test target

## Estructura

```
Sources/Statistics/
├── Data/           # repositorios y fuentes de datos (vacía por ahora)
├── Domain/         # modelos y casos de uso (vacía por ahora)
└── Presentation/
    ├── Enums/
    │   └── StatisticsTextsEnum.swift
    └── Resources/
        └── Localizable.xcstrings
Tests/StatisticsTests/
```

Es la misma estructura de tres capas que `Core` y que el resto de paquetes de feature
(`Today`, `Habits`, `Settings`). Las vistas y los modelos de vista van en `Presentation`.

## Textos y localización

Un único catálogo por paquete —`Presentation/Resources/Localizable.xcstrings`— y un único
punto de acceso —`StatisticsTexts`—, que expone constantes `LocalizedStringResource`:

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
`"extractionState": "manual"`) y expón la constante en `StatisticsTexts`. Las claves van en
`snake_case` con el prefijo `statistics_`; las constantes, en `camelCase`.

Los textos que acaben usándose desde más de un módulo se mueven a `CoreTexts`. Ojo: el título
de la pestaña ya vive en `Core` como `statistics_title` —lo consume `MainTab`—;
`statistics_screen_title` es el título de la pantalla, no el de la pestaña.

Al formatear números, porcentajes o rangos de fechas, usa `.formatted(...)` con los estilos de
`Foundation` en vez de construir los strings a mano: así se localizan solos.

## Tests

Swift Testing (`import Testing`, `@Test`). `Tests/StatisticsTests/StatisticsTests.swift` es
todavía la plantilla generada.
