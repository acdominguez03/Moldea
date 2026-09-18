# Habits

Paquete de la feature **Hábitos**: la pestaña de creación y gestión de los hábitos de Moldea.

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
Sources/Habits/
├── Data/           # repositorios y fuentes de datos (vacía por ahora)
├── Domain/         # modelos y casos de uso (vacía por ahora)
└── Presentation/
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

## Textos y localización

Un único catálogo por paquete —`Presentation/Resources/Localizable.xcstrings`— y un único
punto de acceso —`HabitsTexts`—, que expone constantes `LocalizedStringResource`:

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
`"extractionState": "manual"`) y expón la constante en `HabitsTexts`. Las claves van en
`snake_case` con el prefijo `habits_`; las constantes, en `camelCase`.

Los textos que acaben usándose desde más de un módulo se mueven a `CoreTexts`. Ojo: el título
de la pestaña ya vive en `Core` como `habits_title` —lo consume `MainTab`—; `habits_screen_title`
es el título de la pantalla, no el de la pestaña.

Para los textos con cantidad variable ("3 hábitos", "1 racha"), usa una variación de plural en
el catálogo en vez de concatenar.

## Tests

Swift Testing (`import Testing`, `@Test`). `Tests/HabitsTests/HabitsTests.swift` es todavía la
plantilla generada.
