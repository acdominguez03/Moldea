# Core

Paquete transversal de Moldea. Contiene lo que comparten el resto de módulos: los textos
localizados comunes a toda la app (títulos de la tab bar, accesorio de la tab bar y pantalla
de voz), `BaseViewModel` —el protocolo de estado de carga y error de los view models— y la
pantalla de entrada de voz (`SpeechToTextView`) con su animación de onda.

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
    ├── Animations/
    │   ├── WaveAnimation.swift
    │   └── WaveItemAnimation.swift
    ├── Enums/
    │   └── CoreTextsEnum.swift
    ├── SpeechToTextViews/
    │   └── SpeechToTextView.swift
    ├── ViewModel/
    │   └── BaseViewModel.swift
    └── Resources/
        └── Localizable.xcstrings
Tests/CoreTests/
```

Las tres capas (`Data`, `Domain`, `Presentation`) son la convención que siguen todos los
paquetes de feature del proyecto.

Aún no hay contenedores de UI genéricos compartidos: las pantallas raíz de las features usan
`ScrollView` de SwiftUI directamente. Cuando un contenedor se repita de verdad en dos
features, es aquí —en `Presentation/Components/`— donde baja.

## Estado de carga: `BaseViewModel`

`BaseViewModel` es el protocolo que comparten los view models que ejecutan trabajo
asíncrono. Expone `isLoading` y `errorMessage` **de solo lectura** —la regla del proyecto es
que el estado publicado sea `private(set)`— y la mutación pasa por `setLoading(_:)` y
`setError(_:)`, que implementa cada conformer.

La extensión aporta `perform(_:)`, que envuelve la operación: limpia el error, enciende y
apaga el `isLoading` con un `defer`, ignora las cancelaciones (`CancellationError` y
`Task.isCancelled`) y traduce el resto de errores a texto de usuario.

`errorMessage` es un `LocalizedStringResource`, no un `String`: nunca se publica
`error.localizedDescription`, que no está traducido y lleva dentro el nombre del módulo. Hoy
todos los errores que atrapa `perform(_:)` caen en `CoreTextsEnum.genericError`; si un error
necesita mensaje propio, el view model lo distingue antes y llama a `setError(_:)` con el
texto de su `<Feature>TextsEnum`.

## Entrada de voz: `SpeechToTextView`

`SpeechToTextView` es la pantalla que se presenta en la hoja inferior de la tab bar cuando se
pulsa el tab destacado `.microphone`. Vive en `Core` —y no en una feature— porque el objetivo
es que desde ella se puedan registrar hábitos de cualquier módulo: si viviera en `Habits` o en
`Today`, `Navigation` o el punto de composición acabarían acoplados a una feature concreta.

Estado actual: **maqueta**. Todavía no hay reconocimiento de voz; el texto transcrito es un
`@State` con un valor de ejemplo y el botón *Terminar* no hace nada. La integración real con
`SpeechAnalyzer`/`SpeechTranscriber` es el siguiente paso.

Composición de la pantalla:

- El texto transcrito, la `WaveAnimation` y el botón *Terminar* (`.buttonStyle(.glass)` +
  `.buttonSizing(.flexible)`, para que ocupe el ancho disponible).
- Un pie explicativo (`speech_to_text_description`) que enseña que se pueden nombrar varios
  hábitos en una sola frase.
- `navigationTitle(CoreTextsEnum.listening)` con `.inline` y un botón de cierre en
  `ToolbarItem(placement: .cancellationAction)` que llama a `@Environment(\.dismiss)`. El
  `NavigationStack` que hace de contenedor lo pone `MainTabsView`, no esta vista.

La vista **no** fija `presentationDetents`: los decide quien la presenta (hoy `MoldeaApp`, con
`[.medium, .large]`). El `#Preview` sí la envuelve en un `.sheet` para poder comprobar cómo se
ve presentada.

### `WaveAnimation` / `WaveItemAnimation`

`WaveAnimation` es la barra de nivel de audio: un `HStack` con `barCount` (11)
`WaveItemAnimation`. Las dos son `internal` —solo las usa `SpeechToTextView`, dentro del
propio paquete—; se abrirán a `public` el día que alguien de fuera las necesite.

`WaveItemAnimation` anima una `RoundedRectangle` cuya altura cambia cada 200 ms a un valor
aleatorio del rango `20...60`, con `.animation(.spring(...), value: height)` y un color que se
aclara según la altura. El bucle vive en un `.task(id:) { while !Task.isCancelled { try await
Task.sleep(...) } }`, no en un `Timer` ni en Combine: así se cancela solo cuando la vista
desaparece.

Respeta *Reducir movimiento*: con `accessibilityReduceMotion` activo la barra se queda a
`restingHeight` y el bucle ni arranca, y la animación pasa a `nil` para que tampoco haya
transición al cambiar el ajuste. El `id:` del `.task` es el propio `reduceMotion`, así que
activar o desactivar el ajuste con la pantalla abierta reinicia el bucle en vez de dejarlo en
el estado anterior.

Es una animación decorativa y sintética —marcada con `.accessibilityHidden(true)` en la
pantalla, porque el estado de escucha ya lo comunica el título—. Cuando entre el audio real,
la altura debe venir del nivel de la señal en vez de `CGFloat.random(in:)`.

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
| `close` | Close | Cerrar |
| `listening` | Listening | Escuchando |
| `finish` | Finish | Terminar |
| `speech_to_text_description` | You can list several habits in a single sentence: … | Puedes nombrar varios hábitos en una sola frase: … |

Para añadir un texto: añade la entrada al `Localizable.xcstrings` (en `en` y `es`, con
`"extractionState": "manual"`) y expón la constante en `CoreTextsEnum`. Las claves van en
`snake_case`; las constantes, en `camelCase`.

Aquí solo deben vivir los textos usados por más de un módulo. Los específicos de una feature
van en el `<Feature>TextsEnum` de su propio paquete.

## Tests

Swift Testing (`import Testing`, `@Test`). `Tests/CoreTests/CoreTests.swift` es todavía la
plantilla generada.
