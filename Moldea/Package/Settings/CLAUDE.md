# Settings

Paquete de la feature **Configuración**: la pestaña de ajustes y preferencias de Moldea.

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
Sources/Settings/
├── Data/           # persistencia de preferencias (vacía por ahora)
├── Domain/         # modelos y casos de uso (vacía por ahora)
└── Presentation/
    ├── Enums/
    │   └── SettingsTextsEnum.swift
    └── Resources/
        └── Localizable.xcstrings
Tests/SettingsTests/
```

Es la misma estructura de tres capas que `Core` y que el resto de paquetes de feature
(`Today`, `Statistics`, `Habits`). Las vistas y los modelos de vista van en `Presentation`.

## Textos y localización

Un único catálogo por paquete —`Presentation/Resources/Localizable.xcstrings`— y un único
punto de acceso —`SettingsTexts`—, que expone constantes `LocalizedStringResource`:

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
(`Settings_Settings`) automáticamente al detectar el catálogo; no hace falta declarar
`resources:` en `Package.swift`.

Claves actuales:

| Clave | en | es |
|---|---|---|
| `settings_screen_title` | Settings | Configuración |
| `settings_general_section` | General | General |

Para añadir un texto: añade la entrada al `Localizable.xcstrings` (en `en` y `es`, con
`"extractionState": "manual"`) y expón la constante en `SettingsTexts`. Las claves van en
`snake_case` con el prefijo `settings_`; las constantes, en `camelCase`.

Los textos que acaben usándose desde más de un módulo se mueven a `CoreTexts`. Ojo: el título
de la pestaña ya vive en `Core` como `settings_title` —lo consume `MainTab`—;
`settings_screen_title` es el título de la pantalla, no el de la pestaña.

Este paquete acumulará muchas etiquetas cortas (secciones, filas, pies de ayuda). Mantén el
prefijo por sección al nombrar claves —`settings_general_…`, `settings_about_…`— para que el
catálogo siga siendo legible.

## Tests

Swift Testing (`import Testing`, `@Test`). `Tests/SettingsTests/SettingsTests.swift` es todavía
la plantilla generada.
