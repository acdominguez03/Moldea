# Core

Paquete transversal de Moldea. Contiene lo que comparten el resto de módulos: de momento,
los textos localizados comunes a toda la app (títulos de la tab bar y del accesorio de la tab bar).

No depende de ningún otro paquete. Es la base de la cadena de dependencias: cualquier módulo
puede importar `Core`, pero `Core` no importa a nadie.

## Configuración

- `swift-tools-version: 6.4`
- Plataforma mínima: `.iOS(.v26)`
- `swiftSettings`: `.enableUpcomingFeature("ApproachableConcurrency")` en target y test target

## Estructura

```
Sources/Core/
├── Data/           # capa de datos (vacía por ahora)
├── Domain/         # modelos y casos de uso (vacía por ahora)
└── Presentation/
    ├── Enums/
    │   └── CoreTextsEnum.swift
    └── Resources/
        └── Localizable.xcstrings
Tests/CoreTests/
```

Las tres capas (`Data`, `Domain`, `Presentation`) son la convención que siguen todos los
paquetes de feature del proyecto.

## Textos y localización

`CoreTexts` es el único punto de acceso a los strings del paquete. Expone constantes
`LocalizedStringResource` resueltas contra el catálogo del propio módulo:

```swift
private static func resource(_ key: String) -> LocalizedStringResource {
    LocalizedStringResource(
        String.LocalizationValue(key),
        bundle: .atURL(Bundle.module.bundleURL)
    )
}
```

`bundle: .atURL(Bundle.module.bundleURL)` es obligatorio: sin él el string se buscaría en el
bundle principal de la app y no en el del paquete.

Claves actuales:

| Clave | en | es |
|---|---|---|
| `today_title` | Today | Hoy |
| `statistics_title` | Statistics | Estadísticas |
| `habits_title` | Habits | Hábitos |
| `settings_title` | Settings | Configuración |
| `voice_input_button` | Voice input | Entrada de voz |

Para añadir un texto: añade la entrada al `Localizable.xcstrings` (en `en` y `es`, con
`"extractionState": "manual"`) y expón la constante en `CoreTexts`. Las claves van en
`snake_case`; las constantes, en `camelCase`.

Aquí solo deben vivir los textos usados por más de un módulo. Los específicos de una feature
van en el `Texts` de su propio paquete.

## Tests

Swift Testing (`import Testing`, `@Test`). `Tests/CoreTests/CoreTests.swift` es todavía la
plantilla generada.
