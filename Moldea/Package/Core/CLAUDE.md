# Core

Paquete transversal de Moldea. Contiene lo que comparten el resto de módulos: de momento, los
textos localizados comunes a toda la app (títulos de la tab bar y del accesorio de la tab bar)
y `LoadableViewModel`, el protocolo de estado de carga y error de los view models.

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
    ├── ViewModel/
    │   └── LoadableViewModel.swift
    └── Resources/
        └── Localizable.xcstrings
Tests/CoreTests/
```

Las tres capas (`Data`, `Domain`, `Presentation`) son la convención que siguen todos los
paquetes de feature del proyecto.

Todavía no hay componentes de UI compartidos: las pantallas raíz de las features usan
`ScrollView` de SwiftUI directamente. Cuando un contenedor se repita de verdad en dos
features, es aquí —en `Presentation/Components/`— donde baja.

## Estado de carga: `LoadableViewModel`

`LoadableViewModel` es el protocolo que comparten los view models que ejecutan trabajo
asíncrono. Expone `isLoading` y `errorMessage` **de solo lectura** —la regla del proyecto es
que el estado publicado sea `private(set)`— y la mutación pasa por `setLoading(_:)` y
`setError(_:)`, que implementa cada conformer.

La extensión aporta `perform(_:)`, que envuelve la operación: limpia el error, enciende y
apaga el `isLoading` con un `defer`, ignora las cancelaciones (`CancellationError` y
`Task.isCancelled`) y traduce el resto de errores a texto de usuario.

`errorMessage` es un `LocalizedStringResource`, no un `String`: nunca se publica
`error.localizedDescription`, que no está traducido y lleva dentro el nombre del módulo. Un
error que quiera un mensaje propio conforma `UserFacingError`; el resto caen en
`CoreTextsEnum.genericError`.

```swift
struct HabitNotFound: UserFacingError {
    var userMessage: LocalizedStringResource { HabitsTextsEnum.habitNotFound }
}
```

## Textos y localización

`CoreTextsEnum` es el único punto de acceso a los strings del paquete. Expone constantes
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
| `statistics_title` | Statistics | Datos |
| `habits_title` | Habits | Hábitos |
| `settings_title` | Settings | Ajustes |
| `voice_input_button` | Voice input | Entrada de voz |
| `generic_error` | Something went wrong. Please try again. | Algo ha salido mal. Inténtalo de nuevo. |

Para añadir un texto: añade la entrada al `Localizable.xcstrings` (en `en` y `es`, con
`"extractionState": "manual"`) y expón la constante en `CoreTextsEnum`. Las claves van en
`snake_case`; las constantes, en `camelCase`.

Aquí solo deben vivir los textos usados por más de un módulo. Los específicos de una feature
van en el `<Feature>TextsEnum` de su propio paquete.

## Tests

Swift Testing (`import Testing`, `@Test`). `Tests/CoreTests/CoreTests.swift` es todavía la
plantilla generada.
