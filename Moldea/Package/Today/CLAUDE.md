# Today

Paquete de la feature **Hoy**: la pestaña de inicio de Moldea, la vista del día en curso.

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
Sources/Today/
├── Data/           # repositorios y fuentes de datos (vacía por ahora)
├── Domain/         # modelos y casos de uso (vacía por ahora)
└── Presentation/
    ├── Enums/
    │   └── TodayTextsEnum.swift
    └── Resources/
        └── Localizable.xcstrings
Tests/TodayTests/
```

Es la misma estructura de tres capas que `Core` y que el resto de paquetes de feature
(`Statistics`, `Habits`, `Settings`). Las vistas y los modelos de vista van en `Presentation`.

## Textos y localización

Un único catálogo por paquete —`Presentation/Resources/Localizable.xcstrings`— y un único
punto de acceso —`TodayTexts`—, que expone constantes `LocalizedStringResource`:

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
`"extractionState": "manual"`) y expón la constante en `TodayTexts`. Las claves van en
`snake_case` con el prefijo `today_`; las constantes, en `camelCase`.

Los textos que acaben usándose desde más de un módulo se mueven a `CoreTexts`. Ojo: el título
de la pestaña ya vive en `Core` como `today_title` —lo consume `MainTab`—; `today_screen_title`
es el título de la pantalla, no el de la pestaña.

## Tests

Swift Testing (`import Testing`, `@Test`). `Tests/TodayTests/TodayTests.swift` es todavía la
plantilla generada.
