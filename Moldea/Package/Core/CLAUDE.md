# Core

Paquete transversal de Moldea. Contiene lo que comparten el resto de módulos: de momento, los
textos localizados comunes a toda la app (títulos de la tab bar y del accesorio de la tab bar)
y `LoadableViewModel`, el protocolo de estado de carga y error de los view models.

No depende de ningún otro paquete. Es la base de la cadena de dependencias: cualquier módulo
puede importar `Core`, pero `Core` no importa a nadie.

La arquitectura que sigue (entidades de dominio puras, `@Model` internos, repositorio como
`@ModelActor`) y su porqué están en el `CLAUDE.md` raíz, en _Persistencia y dominio_. Léelo
antes de tocar `Domain` o `Data`.

## Configuración

- `swift-tools-version: 6.2`
- Plataforma mínima: `.iOS(.v26)`
- `swiftSettings`: `.enableUpcomingFeature("ApproachableConcurrency")` en target y test target

## Estructura

```
Sources/Core/
├── Domain/
│   ├── Entities/
│   │   ├── Habit.swift
│   │   ├── HabitSchedule.swift
│   │   └── HabitFrequency.swift
│   ├── Enums/
│   │   ├── LanguageModelAvailabilityEnum.swift
│   │   ├── LanguageModelErrorEnum.swift
│   │   ├── HabitCommandEnum.swift
│   │   ├── HabitCommandErrorEnum.swift
│   │   ├── CreateHabitErrorEnum.swift
│   │   └── HabitAppearanceDefaultsEnum.swift
│   ├── Model/
│   │   └── NewHabitDraft.swift
│   ├── Repository/
│   │   └── HabitRepository.swift
│   ├── UseCases/
│   │   ├── CreateHabitUseCase.swift      # protocolo + DefaultCreateHabitUseCase
│   │   └── DeleteHabitUseCase.swift      # protocolo + DefaultDeleteHabitUseCase
│   ├── HabitCompletionRecognizing.swift
│   └── HabitCommandParsing.swift
├── Data/
│   ├── Model/
│   │   ├── HabitEntity.swift
│   │   ├── HabitScheduleEntity.swift
│   │   ├── HabitCompletionEntity.swift
│   │   └── FrequencyType.swift
│   ├── Mappers/
│   │   └── HabitMapper.swift
│   ├── AI/
│   │   ├── Model/
│   │   │   ├── GenerableHabitCommand.swift
│   │   │   └── HabitNameSchema.swift
│   │   ├── Mappers/
│   │   │   └── GenerableHabitMapper.swift
│   │   ├── Prompts/
│   │   │   └── HabitCommandInstructions.swift
│   │   ├── FoundationModelsHabitCommandParser.swift
│   │   ├── FoundationModelsErrorMapper.swift
│   │   └── HabitCommandSamples.swift        # #if DEBUG, incluye HabitCommandKindEnum
│   ├── FoundationModelsHabitCompletionRecognizer.swift
│   ├── HabitsQuery.swift
│   ├── MoldeaSchema.swift
│   ├── SwiftDataHabitRepository.swift
│   ├── PreferencesKey.swift
│   ├── UserDefaultsRepositoryImpl.swift
│   └── UNUserNotificationCenterPermissionRepository.swift
└── Presentation/
    ├── Components/
    │   ├── HabitCardView.swift
    │   └── HabitIconBadge.swift
    ├── Converters/
    │   └── HexColorConverter.swift
    ├── Enums/
    │   ├── CoreTextsEnum.swift
    │   ├── HabitCommandPhaseEnum.swift
    │   ├── HabitCommandOutcomeEnum.swift
    │   ├── HabitScheduleSummaryEnum.swift
    │   ├── StageEnum.swift
    │   ├── TranscriberEnum.swift
    │   ├── TranscriptionErrorEnum.swift
    │   └── TranscriptionPhaseEnum.swift
    ├── HabitCommandView/
    │   ├── HabitCommandView.swift
    │   └── HabitCommandViewModel.swift
    ├── SpeechToTextCore/
    │   └── LiveTranscriptionModel.swift
    ├── SpeechToTextView/
    │   ├── SpeechToTextView.swift
    │   └── SpeechToTextViewModel.swift
    ├── Animations/
    │   ├── WaveAnimation.swift
    │   └── WaveItemAnimation.swift
    ├── ViewModel/
    │   └── BaseViewModel.swift
    └── Resources/
        └── Localizable.xcstrings
Tests/CoreTests/
```

Las tres capas (`Data`, `Domain`, `Presentation`) son la convención que siguen todos los
paquetes del proyecto.

Aún no hay contenedores de UI genéricos compartidos: las pantallas raíz de las features usan
`ScrollView` de SwiftUI directamente. Cuando un contenedor se repita de verdad en dos
features, es aquí —en `Presentation/Components/`— donde baja.

## Domain

**Entidades** (`Domain/Entities`): structs `public`, inmutables (`let`), `Sendable`, con `init`
explícito, que solo importan `Foundation`. Sin validación: solo transportan datos; las reglas
las valida el caso de uso.

- `Habit`: `id`, `name`, `color` (hex `#RRGGBB`), `icon` (SF Symbol), `isActive`, `createdAt`,
  `updatedAt` y `schedule`. No lleva las completions: se consultarán por separado.
- `HabitSchedule`: `frequency` y `repetitionsPerDay`.
- `HabitFrequency`: `.daily`, `.weeklyCount(timesPerWeek:)` o `.fixedDays(weekdays:)`, con los
  días como `Set<Int>` de `Calendar.weekday` (1 = domingo … 7 = sábado).

- `HabitCommandEnum`: lo que el usuario ha pedido por voz, ya interpretado —`.create(NewHabitDraft)`,
  `.delete(habitID:)` o `.listCompleted`—. No importa `FoundationModels`.
- `NewHabitDraft`: `name`, `frequency` y `repetitionsPerDay`. **No lleva color ni icono**,
  porque al hablar no se dicen: los pone `HabitAppearanceDefaultsEnum`.
- `HabitAppearanceDefaultsEnum`: `colorHex` (`#5B6470`) e `icon` (`drop`) con los que nace un hábito
  creado por voz. Están duplicados respecto a `HabitPaletteColor`/`HabitPaletteIcon`, que viven
  en `Habits` y `Core` no puede importar; `HabitAppearanceDefaultsTests` (en `HabitsTests`) es lo
  que impide que se separen en silencio.

**Repositorio** (`Domain/Repository`): `HabitRepository` es un protocolo `public` y `Sendable`.
Recibe y devuelve solo tipos de dominio. Hoy tiene `create(_:)` y `delete(id:)`; `fetch` se
añadirá cuando `Today` y `Statistics` lo necesiten, y con él habrá que decidir qué hacer con una
fila corrupta al listar (saltarla y registrarla, o propagar el error).

**Casos de uso** (`Domain/UseCases`): `CreateHabitUseCase` y `DeleteHabitUseCase` viven aquí —y
no en `Habits`— porque los necesitan dos módulos: la pantalla de creación de `Habits` y la capa
de comandos de voz de `Core`. Son `public`, reciben el repositorio por `init` y, en el caso de
crear, también el generador de `UUID` y el reloj como closures para poder testearse.
`CreateHabitUseCase` es el **único** sitio con reglas de negocio: valida nombre, hex del color,
rango de `timesPerWeek` y de los `weekdays`, y lanza `CreateHabitErrorEnum`.

## Data

Todo lo de `Model/` y `Mappers/` es `internal`: los `@Model` no salen de `Core`.

- **Entidades de SwiftData**: `HabitEntity` (`id` único, `active`, fechas, relaciones en
  cascada con el schedule y las completions), `HabitScheduleEntity` (guarda `frequencyType`,
  `timesPerWeek?`, `fixedWeekdays: [Int]?` y `repetitionsPerDay`) y `HabitCompletionEntity`
  (`id` único, `day` con `#Index`). `FrequencyType` es la etiqueta de persistencia de la
  frecuencia; el dominio usa `HabitFrequency`.
- **`HabitMapper`**: `makeEntity(from:)` (dominio → entidad) y `toDomain(_:) throws`, que lanza
  `HabitMappingError` (`missingSchedule`, `missingTimesPerWeek`, `missingFixedWeekdays`, todos
  con el `habitID`) si los datos son incoherentes. No rellena valores por defecto: ocultaría la
  corrupción. `apply(_:to:)` traduce un `HabitSchedule` a los campos de un
  `HabitScheduleEntity` existente o nuevo, con `fixedWeekdays` ordenado para que lo persistido
  sea determinista; es el único sitio que hace esa traducción, y lo usan tanto `makeEntity`
  como `SwiftDataHabitRepository.update`.
- **`MoldeaSchema`** (`public`): lista de modelos, `schema` y
  `makeModelContainer(inMemory:)`. Es el único punto de verdad del esquema; cuando lleguen los
  widgets y el App Group, la configuración compartida se añadirá aquí.
- **`SwiftDataHabitRepository`** (`public`, `@ModelActor`): `@ModelActor` genera un
  `public init(modelContainer:)` cuando el actor es `public`, que es lo que usa `MoldeaApp`.
  Las cuatro operaciones siguen el mismo patrón: si `save()` falla hacen `rollback()` y relanzan
  el error, para que la entidad no quede pendiente en el contexto.
    - `create` inserta y guarda.
    - `delete`, `setActive` y `update` buscan la entidad por `id` con un `FetchDescriptor` de
      `fetchLimit = 1` y no hacen nada si no existe.
    - `update` cambia `name`, `color`, `icon` y `updatedAt`, y delega el `schedule` en
      `HabitMapper.apply(_:to:)`, que también lo usa `create` por dentro. Al cambiar de
      frecuencia deja a `nil` los campos de la anterior (`timesPerWeek` o `fixedWeekdays`), para
      no dejar datos sueltos de una frecuencia que ya no aplica.
- **`PreferenceKey`** (`public enum`, raw `String`): claves de `UserDefaults`. Hoy tiene
  `isNotificationsEnabled` (preferencia de producto: "quiero que mis hábitos avisen", la que
  controla `Settings`) e `isNotificationPermissionAllowed` (espejo del permiso real del
  sistema). Son independientes a propósito: el permiso del sistema puede estar concedido y el
  usuario, aun así, tener los avisos apagados dentro de la app.
- **`UserDefaultsRepositoryImpl`** (`public struct`): implementación directa sobre
  `UserDefaults.standard`.
- **`UNUserNotificationCenterPermissionRepository`** (`public struct`): envuelve
  `UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])`;
  si la llamada lanza, devuelve `false` en vez de propagar el error.

## Colores: `HexColorConverter`

Namespace `public` en `Presentation/Converters` (usa `Color`, así que no puede estar en
`Domain`). El contrato de color de los hábitos es hex `#RRGGBB`; el razonamiento completo está
en el `CLAUDE.md` raíz, en _Colores de los hábitos_.

- `color(fromHex:) -> Color?`: acepta `#RRGGBB` (el `#` es opcional; mayúsculas o minúsculas) y
  devuelve `nil` si no es válido. Comprueba `allSatisfy(\.isHexDigit)` antes de
  `UInt32(_, radix: 16)`, porque este acepta un signo (`+12345` pasaría el `count == 6`).
- `hex(from:in:) -> String`: `#RRGGBB` en mayúsculas, resuelto en el `EnvironmentValues`
  dado (`Color.resolve(in:)`). Recorta a 0...1 porque `Color.Resolved` es sRGB de rango
  extendido.

## Estado de carga: `BaseViewModel`

`BaseViewModel` (`Presentation/ViewModel/BaseViewModel.swift`) es el protocolo `@MainActor` que
comparten los view models que ejecutan trabajo asíncrono. Expone `isLoading` y `errorMessage`
**de solo lectura** —la regla del proyecto es que el estado publicado sea `private(set)`— y la
mutación pasa por `setLoading(_:)` y `setError(_:)`, que implementa cada conformer.

La extensión aporta `perform(_:)`, que envuelve la operación: limpia el error, enciende y
apaga el `isLoading` con un `defer`, ignora las cancelaciones (`CancellationError` y
`Task.isCancelled`) y traduce **cualquier otro error** a `CoreTextsEnum.genericError`.

`errorMessage` es un `LocalizedStringResource`, no un `String`: nunca se publica
`error.localizedDescription`, que no está traducido y lleva dentro el nombre del módulo. Hoy no
hay mensajes propios por tipo de error: todo cae en el genérico. Si hicieran falta, habría que
introducir un protocolo para que un error aporte su propio texto.

## Entrada de voz: `SpeechToTextView`

`SpeechToTextView` es la pantalla que se presenta en la hoja inferior de la tab bar cuando se
pulsa el tab destacado `.microphone`. Vive en `Core` —y no en una feature— porque el objetivo
es que desde ella se puedan registrar hábitos de cualquier módulo: si viviera en `Habits` o en
`Today`, `Navigation` o el punto de composición acabarían acoplados a una feature concreta.

Composición de la pantalla:

- El texto transcrito, el estado de la sesión, la `WaveAnimation` y el botón _Terminar_
  (`.buttonStyle(.glass)` + `.buttonSizing(.flexible)`, para que ocupe el ancho disponible).
- Un pie explicativo (`speech_to_text_description`) que enseña que se pueden nombrar varios
  hábitos en una sola frase.
- `navigationTitle(CoreTextsEnum.listening)` con `.inline` y un botón de cierre en
  `ToolbarItem(placement: .cancellationAction)`. El `NavigationStack` que hace de contenedor
  lo pone `MainTabsView`, no esta vista.

La escucha arranca en un `.task` al presentarse la hoja. El botón de cierre para la sesión
**antes** de llamar a `@Environment(\.dismiss)`: si solo se descartara la vista, el micrófono
se quedaría abierto.

_Terminar_ no descarta la hoja: hace `await model.finishTranscribing()` y solo entonces
navega a `HabitCommandView` con `model.transcript`. La espera no es opcional —
`stopTranscribing()` cierra el grifo de audio, pero el último tramo de texto todavía tiene que
salir de `finalizeAndFinish(through:)` y pasar por `observeResults`—, así que navegar en el
mismo ciclo mandaría a la IA una transcripción a medias o vacía. En simulador no se notaba
porque la frase de ejemplo ya está en `finalizedText` desde el principio. Mientras se espera,
ambos botones quedan deshabilitados (`isFinishing`), y el texto se congela en
`transcriptForAI` para que un reinicio posterior de la escucha no lo borre.

La vista **no** fija `presentationDetents`: los decide quien la presenta (hoy `MoldeaApp`, con
`[.medium, .large]`).

### `SpeechToTextViewModel`

Todo el estado de la pantalla vive aquí y la vista se queda solo con `@Environment(\.dismiss)`
y el `@State` del view model, como el resto de pantallas del proyecto. El view model **posee**
el `LiveTranscriptionModel` —la vista ya no lo ve— y republica lo que se pinta (`phase`,
`downloadProgress`, `styledTranscript`, `hasTranscript`, `isTranscribing`) como propiedades
derivadas; leerlas desde `body` sigue registrando la observación en el modelo de transcripción,
así que la vista se repinta igual.

Las dos banderas que eran de la vista pasan a métodos con intención: `start()` (precalentar el
parser y arrancar la escucha), `stop()`, `finishAndRecognize()` —el que congela
`transcriptForAI` y enciende `isPresentingCommand`— y `dismissCommand()`. `canFinish` y
`canClose` sustituyen a los `disabled` calculados en la vista.

El view model también posee las dependencias que `HabitCommandView` necesita (`recognizer`,
`parser` y los dos casos de uso) y las expone como `let`, que es el motivo por el que el `init`
sigue recibiendo solo el `habitRepository`. El reconocedor y el parser entran por el `init` con
la implementación real por defecto, así que la pantalla se puede previsualizar con dobles.

`isPresentingCommand` es `private(set)`, como todo el estado publicado del proyecto, así que la
vista construye a mano el `Binding` de `navigationDestination(isPresented:)`: el `get` lee la
propiedad y el `set` solo llama a `dismissCommand()` cuando el sistema cierra el destino.

### Transcripción: `LiveTranscriptionModel`

`LiveTranscriptionModel` es la clase `@Observable @MainActor` que posee la sesión de voz.
Publica `finalizedText`/`volatileText`, la `phase` y el `downloadProgress` de la descarga del
modelo.

**El texto transcrito se guarda como `String`, no como `AttributedString`.** Los transcriptores
entregan `AttributedString` con los runs de tiempo de audio, pero `apply(text:isFinal:)` los
descarta en la frontera con `String(text.characters)` y a partir de ahí todo el paquete
maneja texto plano. El motivo es la IA: lo que se manda al modelo tiene que ser exactamente lo
que se ve, sin metadatos y sin depender de cómo `AttributedString` se convierta a texto. Nada
de la app necesita esos atributos.

`transcript` es lo que se le pasa a la IA: `finalizedText + volatileText` con los espacios
normalizados (`split(whereSeparator: \.isWhitespace).joined(separator: " ")`), así que no
llegan saltos de línea, espacios repetidos ni espacios sobrantes al principio o al final.

El atenuado del tramo volátil es cosa de la vista: `SpeechToTextView.styledTranscript` compone
un `AttributedString` **solo para pintar**, a partir de los dos `String`. No se usa
`Text + Text` porque el operador está deprecado desde iOS 26 (hardcodea el orden de la frase y
rompe la localización en idiomas RTL).

`runSession()` es común a todas las versiones —permiso, transcriptor, assets, analizador,
`prepareToAnalyze(in:)` y consumo de `results`— salvo por un atajo al principio: si
`isSimulator`, escribe una frase de ejemplo en `finalizedText` y sale sin tocar el micrófono,
porque en el simulador no funciona ninguna API de voz (ver la tabla de abajo). La comprobación
es un `let` resuelto con `#if targetEnvironment(simulator)`, no un `#if` alrededor del código,
para que la ruta real siga compilando en el simulador.

Solo la **fuente de audio** se bifurca:

- **iOS 27+** → `CaptureInputSequenceProvider.providerWithSession(from:compatibleWith:)`. Monta
  la sesión de captura, la conversión y la `AsyncSequence<AnalyzerInput>`, así que no hay motor
  de audio, ni tap, ni `AVAudioConverter`, ni configuración manual de `AVAudioSession`. Se crea
  en una función `@concurrent` porque `AVCaptureDevice` no es `Sendable` y montar la sesión
  tarda. El provider se guarda como `AnyObject?` (una propiedad almacenada no admite
  `@available`) y soltarlo es lo que termina la secuencia y devuelve el control a
  `analyzeSequence(_:)`.
- **iOS 26** → `AVAudioEngine` + `installTap` + `AVAudioConverter` a mano.

`startEngine(...)` es **`nonisolated static` a propósito, no por casualidad**:
`AVAudioNodeTapBlock` está importado como no `Sendable`, así que un closure escrito dentro de
un contexto `@MainActor` heredaría ese aislamiento y Swift 6 le insertaría una comprobación
dinámica de aislamiento; el motor de audio lo invoca desde su hilo de render y la comprobación
revienta con `EXC_BREAKPOINT`. Escribiéndolo en contexto `nonisolated` el closure no hereda
nada. Si algún día se vuelve a mover ese código dentro del actor, el crash vuelve.

Los errores viven en `TranscriptionErrorEnum`, que expone `message: LocalizedStringResource`
—no conforma `LocalizedError`— y `StageEnum`, que da el nombre traducido de la etapa que ha
fallado. El error subyacente nunca se publica: se queda en el `print` de `run(_:_:)`.

### Qué funciona en el simulador y qué no

Comprobado ejecutando en los runtimes 26.5 y 27.0, sobre un Mac con Apple Intelligence activo:

| API                    | Simulador                 | Notas                                                                                                                                                             |
| ---------------------- | ------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Foundation Models      | ✅ `available`            | usa el Apple Intelligence del Mac anfitrión                                                                                                                       |
| `SpeechTranscriber`    | ❌ `isAvailable == false` |                                                                                                                                                                   |
| `DictationTranscriber` | ❌                        | el idioma se soporta y los assets llegan a instalarse, pero `bestAvailableAudioFormat` es `nil`                                                                   |
| `SFSpeechRecognizer`   | ❌                        | `isAvailable == true`, pero `recognitionTask` falla con `kLSRErrorDomain 300`, «Failed to create recognizer»: el asset `Siri_Understanding` del runtime está roto |
| Micrófono              | ✅ 48 kHz                 | hace falta _I/O → Audio Input_ en Simulator y el permiso de micrófono de Simulator en macOS                                                                       |

Es decir: **la transcripción no se puede probar en el simulador con ninguna API.** Hay que hacerlo
en un dispositivo real, donde `DictationTranscriber` funciona incluso sin Apple Intelligence.

Dos trampas que costaron tiempo y conviene no repetir:

- `AVAudioSession.activate()`, la alternativa asíncrona que sugiere el warning de hilo principal de
  `setActive(_:)`, **deja el nodo de entrada a 0 Hz en el simulador** y el motor no arranca. Es de
  iOS 27 y el paquete es iOS 26, así que de momento no se usa.
- Que los assets de `DictationTranscriber` lleguen a `installed` **no** implica que el analizador
  pueda transcribir: `bestAvailableAudioFormat` sigue devolviendo `nil`. El síntoma es un
  `noCompatibleAudioFormat` que parece un problema del micrófono y no lo es.

Por eso el atajo de `runSession()`: en el simulador la pantalla aparece con una de las frases
de `HabitCommandSamples` ya transcrita —van rotando, ver _Frases de ejemplo_ más abajo—, que es lo que permite iterar `SpeechToTextView` —y la pantalla de IA que cuelga
de ella, que sí funciona en el simulador— sin dispositivo conectado. No hay simulación de
resultados parciales ni se abre el micrófono; es solo el texto puesto a mano.

## Comandos de voz: `HabitCommandView`

La pantalla a la que se llega desde _Terminar_. Interpreta el transcrito como **un comando** y
pide confirmación antes de tocar nada:

```
SpeechToTextView ──Terminar──► HabitCommandView            (única pantalla)
                                 ├─ .create        → Confirmar → CreateHabitUseCase
                                 ├─ .delete        → Confirmar → DeleteHabitUseCase
                                 └─ .listCompleted → HabitCompletionRecognizing → tarjetas
```

**Los tres comandos se resuelven en la misma pantalla.** Hubo una `HabitsRecognizerView`
aparte para los resultados de listar y se borró: era un tercer nivel de navegación sin ninguna
decisión dentro —se entraba automáticamente— y obligaba a arrastrar un closure `onRepeat` para
poder volver desde dos niveles de profundidad.

**Se confirma lo que escribe en la base de datos, y solo eso.** Crear y borrar piden
confirmación: una transcripción mala no puede borrar un hábito. Listar no escribe nada, así que
el view model encadena el reconocimiento justo después del parseo y la pantalla pasa del spinner
a las tarjetas sin intervención.

### El estado es una fase, no un puñado de banderas

`HabitCommandPhaseEnum` (`Presentation/Enums/`) es lo único que la vista consulta:

| Fase                                                    | Pantalla                                                        |
| ------------------------------------------------------- | --------------------------------------------------------------- |
| `.parsing`                                              | spinner + «Interpretando lo que has pedido…»                    |
| `.confirmingCreate(draft)` / `.confirmingDelete(habit)` | título, tarjeta y `[Repetir｜Confirmar]`                        |
| `.recognizing`                                          | spinner + «Comprobando qué hábitos has mencionado…»             |
| `.recognized([Habit])`                                  | una tarjeta por hábito, o el mensaje de vacío si no hay ninguno |
| `.done(outcome)`                                        | mensaje de creado/borrado y su tarjeta                          |
| `.failed`                                               | el mensaje de error                                             |

El view model tenía antes `command`, `outcome` e `isParsing` sueltos, y al absorber el
reconocimiento habría sumado `habitsCompleted` y otra fase. **Esa forma ya produjo un bug en
este paquete**: inferir el estado de un booleano más un array vacío hacía que el spinner y el
mensaje de «no se ha mencionado ningún hábito» se pintasen a la vez.

Tres detalles que no son casuales:

- **La confirmación son dos casos, no un `HabitCommandEnum`.** Con `confirmingCreate` /
  `confirmingDelete` el caso imposible desaparece: antes la vista tenía un
  `if command != .listCompleted`, un `case .listCompleted: EmptyView()` y un `title(for:)` que
  para listar devolvía el texto de «interpretando» como relleno. Además la fase lleva el
  `Habit` ya resuelto, así que la búsqueda por `id` se hace una vez al parsear y no en cada
  repintado.
- **Un borrado de un hábito que no está en la lista es `.failed`**, con `.habitNotFound`. Antes
  pintaba una pantalla vacía en silencio.
- **El estado inicial es `.parsing`**, así que hay spinner desde el primer frame, antes de que
  corra el `.task`. Una cancelación se queda en `.parsing` —la vista se está yendo— en vez de
  marcar un final que enseñaría el mensaje de vacío en el último frame.

`errorMessage` sigue aparte porque lo exige `BaseViewModel.perform`; `.failed` es solo lo que
apaga el spinner. Si el caso de uso falla al confirmar, la fase **se queda en la confirmación**:
no se anuncia un éxito que no ha pasado.

### Volver a hablar

`Repetir` hace `dismiss()`, que saca la pantalla empujada y deja `SpeechToTextView`, cuyo
`.task` reinicia la escucha. Aparece en **todas las fases terminales** (`.recognized`, `.done` y
`.failed`, además de la confirmación): tras crear un hábito significa «crear otro», y en
`.failed` es la única salida que no es el chevron de la barra.

Con la pantalla de resultados fuera ya no hace falta el closure `onRepeat` que había que pasar
de `SpeechToTextView` a `HabitCommandView` y de ahí a la tercera pantalla.

### Dos etapas, no una

`parseCommand(in:from:)` hace **dos peticiones**, no una, y cada etapa lleva sus propias
instrucciones elegidas en Swift:

1. **Intención** → `respond(generating: GenerableCommandDecision.self)`. Una elección entre tres
   casos, que es lo que el modelo on-device hace bien.
2. **Argumentos**, según la intención:
    - `.create` → `respond(generating: GenerableHabitDraft.self)`.
    - `.delete` → `respond(schema:)` con el `GenerationSchema` que construye `HabitNameSchema`, y
      se lee con `content.value(String.self, forProperty: "habit")`.
    - `.listCompleted` → no hay segunda petición; el comando no lleva carga.

El motivo de partirlo en dos no es estético: Apple pide **convertir los `if-else` del prompt en
lógica de programación**, así que el modelo nunca lee condiciones que no aplican a la petición
que tiene delante. Es la misma lección que ya estaba pagada con el reconocedor (partir en
peticiones pequeñas gana a una petición que lo hace todo).

Como en el reconocedor, **una sesión nueva por petición**: `LanguageModelSession` acumula
historial y reutilizarla arrastra la respuesta anterior hasta `contextSizeExceeded`.

### `DynamicGenerationSchema`: el único esquema que no se puede escribir a mano

`HabitNameSchema.makeSchema(for:)` construye en tiempo de ejecución un `anyOf` con los nombres
de los hábitos que el usuario tiene **ahora mismo**. Es el sitio donde `DynamicGenerationSchema`
se gana el sueldo: con el `anyOf` cerrado, un nombre inventado deja de ser _posible_ en vez de
solo improbable.

Tres cosas medidas que conviene no volver a pagar:

- **`anyOf` no admite nombres repetidos**, así que `uniqueNames(of:)` deduplica conservando el
  orden. Con dos hábitos con el mismo nombre no hay forma de desambiguar y gana el primero; hay
  un test que lo fija.
- **Un `anyOf` vacío se comporta distinto según el runtime**: lanza `emptyTypeChoices` en iOS 27
  pero **no** en iOS 26.5. Por eso el parser comprueba la lista _antes_ de construir el esquema y
  lanza `.habitNotFound`, en vez de confiar en que el esquema falle.
- **La lista de hábitos va también en el prompt**, no solo en el `anyOf`: es un dato que el
  usuario ha dicho, no metadato de formato.

### `@Generable`: campos obligatorios y campo de razonamiento

`GenerableCommandDecision` lleva `reasoning: String` **como primera propiedad a propósito**: es
la forma documentada de darle al modelo un sitio donde razonar sin que ese texto acabe dentro de
`kind`. El modelo genera las propiedades en orden de declaración, así que tiene que ir primero.

`GenerableHabitDraft` tiene `timesPerWeek` y `weekdays` **no opcionales a propósito**. Con
`timesPerWeek: Int?` el modelo elegía `.timesPerWeek` y dejaba el número a `nil`: un opcional es
permiso para omitirlo. Obligándolos (`.range(1...7)` y `.minimumCount(1)`) el hueco desaparece, y
`GenerableHabitMapper` se queda solo con el campo de la frecuencia elegida e ignora el ruido de los
otros dos. **Lo encontró `HabitCommandPromptEvalTests`, no una revisión a ojo.**

### Los días se piden por nombre, nunca por número

`weekdays` es `[GenerableWeekday]`, un enum con los siete días, y la conversión a
`Calendar.weekday` la hace `GenerableHabitMapper.calendarWeekday(_:)` en Swift.

Antes era `[Int]` con `@Guide(description: "1 domingo hasta 7 sábado", .element(.range(1...7)))`,
y **salía un día corrido**: «lunes y miércoles» se guardaba como domingo y martes. El modelo usa
**ISO-8601** (1 = lunes … 7 = domingo), que es lo que domina sus datos de entrenamiento, y el
texto del `@Guide` no le gana a ese sesgo. No era un problema de idioma ni de traducción: se le
estaba pidiendo un número habiendo **dos convenciones numéricas plausibles**.

Regla general que deja este caso: **si un valor tiene más de una convención de codificación
razonable, no se pide codificado — se pide por nombre y se codifica en Swift.** Es la misma
jugada que el `timesPerWeek: Int?`: quitar la posibilidad en vez de pedirla por favor.

De regalo, un día fuera de rango deja de ser representable, así que el mapper ya no filtra:
`.missingFrequencyData` para `fixedWeekdays` solo puede saltar con la lista vacía.
`GenerableHabitMapperTests` fija la tabla día a día y el eval lo comprueba contra el modelo real
(«los lunes y los miércoles» → `[2, 4]`).

Corrección a lo que decía antes este fichero: las `description` de `@Guide` **sí** llegan al
modelo. La documentación de `Generable` dice que el framework convierte cada tipo a JSON schema y
se lo pasa al modelo, y recomienda usar `@Guide(description:)` «solo cuando mejora la calidad».
Lo que se veía imprimiendo `session.transcript` (`Response Format: HabitReport`) es el resumen
del transcrito, no lo que viaja. El problema real de aquel diseño eran las **claves opacas**
(`h1`…`hN`), no las descripciones.

### `GenerableHabitMapper` y los errores

`GenerableHabitMapper` es la frontera entre lo generado y el dominio, en paralelo a `HabitMapper`:
valida estructura, **no rellena valores por defecto** y lanza `HabitCommandErrorEnum`
(`.notUnderstood`, `.habitNotFound`, `.missingFrequencyData`, `.schemaFailed`). Comprueba los
rangos aunque el esquema ya los fije, para que un valor fuera de rango sea un error explícito y
no un `CreateHabitErrorEnum` que la UI pintaría como error genérico.

Los fallos del **framework** siguen cayendo en `LanguageModelErrorEnum`, ya completo.
`FoundationModelsErrorMapper` (en `Data/AI`) es la traducción, sacada del reconocedor para que la
compartan los dos tipos de `Data`. **Ahí vive el `#available(iOS 27.0, *)`**: `LanguageModelError`
y `SystemLanguageModel.Error` son de iOS 27 y en iOS 26 lo que se lanza es
`LanguageModelSession.GenerationError`. Sin esa segunda rama todos los fallos caerían en el
mensaje genérico justo en la versión mínima soportada.

Todo lo demás que usa el diseño (`@Generable`, `DynamicGenerationSchema`,
`GenerationSchema(root:dependencies:)`, `respond(schema:)`, `GenerationOptions(samplingMode:)`)
existe en iOS 26, así que no hay más `#available`. Quedan fuera a propósito `Tool`/tool calling,
`GenerationOptions(toolCallingMode:)`, `ContextOptions` y `DynamicProfile`/`DynamicInstructions`:
son de iOS 27 y en un flujo donde el modelo **no debe ejecutar efectos por su cuenta** no aportan
nada.

### Instrucciones versionadas

`HabitCommandInstructions` tiene una función por etapa con la versión en el nombre
(`intentV1`, `newHabitV1`, `habitToDeleteV1`), separadas de la lógica. Apple recomienda no
llevar los prompts hardcodeados para poder comparar la salida cuando cambie la versión del modelo
base; esto es esa idea sin montar la carga de un recurso de bundle (`Core/Package.swift` no
declara `resources:`, así que un `.json` obligaría a añadirlo y a manejar un fallo de lectura que
no puede pasar).

Al añadir una versión nueva, se añade la función `…V2` y se pasa
`HabitCommandPromptEvalTests` con las dos para comparar, en vez de sustituir y confiar.

A diferencia del reconocedor, la etapa 1 **sí lleva ejemplos** (`frase -> comando`). La lección
real del reconocedor era _nada de ejemplos con una forma de salida que ya no existe_; Apple sí
recomienda ejemplos en las instrucciones, y una clasificación pura es donde encajan. La etapa 2
no los lleva: la generación guiada ya fija la forma.

### Precalentado

`SpeechToTextView.task` precalienta **el parser**, porque es quien recibe la primera petición.

El `prepare()` del reconocedor lo dispara `HabitCommandViewModel` **al arrancar el parseo**, no
al saber ya el comando. Antes se hacía al publicar un `.listCompleted`, contando con que el
usuario tardase en leer la confirmación; al quitar esa pantalla (listar ya no se confirma) esa
ventana desapareció y el `prewarm()` habría quedado pegado al `respond`, que es justo el trabajo
tirado que documenta este fichero más abajo. El parseo tarda 1-3 s, así que da la ventana de
≥1 s que pide la documentación.

**El precio, que es real:** en los comandos de crear y borrar ese precalentado se tira. Se
aceptó porque listar es el caso común y un `prewarm()` desperdiciado no rompe nada. Si algún día
la proporción cambia, el sitio donde mirar es `HabitCommandViewModel.parse`.

### Composición

`SpeechToTextView.init(habitRepository:)` recibe el repositorio y construye los casos de uso por
dentro, igual que ya construía `FoundationModelsHabitCompletionRecognizer()` por defecto. `MoldeaApp` le
pasa el `habitRepository` que ya tenía.

### Frases de ejemplo: andamio con fecha de caducidad

`HabitCommandSamples` (`Data/AI`) es la tabla de frases de los comandos. **Todo el fichero va
detrás de `#if DEBUG`**, así que en un build de release ni siquiera está compilado y no puede
acabar en la App Store aunque se olvide quitarlo.

Tiene dos mitades con vidas distintas:

| Parte                                                                   | Vida                                                       |
| ----------------------------------------------------------------------- | ---------------------------------------------------------- |
| `HabitCommandSample` y `all`                                            | **se queda**: es la tabla de `HabitCommandPromptEvalTests` |
| `nextPhrase()`, `rotationKey` y `LiveTranscriptionModel.samplePhrase()` | **temporal**: se va con el atajo del simulador             |

Para retirar el andamio: borrar `nextPhrase()` y `rotationKey`, y en `LiveTranscriptionModel` borrar
`samplePhrase()` y la rama `if Self.isSimulator` de `runSession()`. `all` no se toca.

Dos detalles que no son opcionales:

- **`samplePhrase()` está definido dos veces** (`#if DEBUG` / `#else`), no con un `#if` alrededor
  del código, por el mismo motivo que `isSimulator`: hay dos condicionales cruzadas
  (Debug/Release × simulador/dispositivo) y las cuatro combinaciones tienen que compilar. Están
  las cuatro comprobadas.
- **Rota, no sortea.** Con `randomElement()` puedes abrir la hoja diez veces y no ver nunca el
  caso de borrar. El índice va en `UserDefaults` —no `@AppStorage`, que es un `DynamicProperty`
  para vistas y quien llama es una clase `@Observable`— y el `% all.count` protege de un índice
  guardado mayor que el catálogo si algún día se borran frases.

## Reconocimiento de hábitos: `HabitCompletionRecognizing`

El trabajo del comando `.listCompleted`: coger lo transcrito y preguntar al modelo on-device
cuáles de los hábitos que el usuario ya tiene ha mencionado. Lo consume
`HabitCommandViewModel`; la pantalla es `HabitCommandView`, descrita más arriba.

```
Presentation              HabitCommandViewModel
                            │ any HabitCompletionRecognizing
Domain                 HabitCompletionRecognizing
                            ▲            LanguageModelErrorEnum
Data      FoundationModelsHabitCompletionRecognizer    LanguageModelAvailabilityEnum
```

- `HabitCompletionRecognizing` (`Domain`) es el protocolo `@MainActor` que ve el view model. El
  reconocedor entra por el `init` de la vista con la implementación real por defecto, así que
  se puede previsualizar y testear con un doble sin Apple Intelligence.
- `FoundationModelsHabitCompletionRecognizer` (`Data`) arma el prompt, hace la generación guiada y
  traduce los errores con `FoundationModelsErrorMapper`. `Domain` no importa
  `FoundationModels`: los `@Generable` de la primera versión (`HabitCheck` / `HabitReport`) se
  borraron, y con ellos ese `import`.
- El view model no conoce `SystemLanguageModel`. Expone `unavailableMessage` como valor
  **derivado** de `availability` —no estado— para que la vista pinte el motivo sin esperar al
  `.task`.

La lista de hábitos contra la que casar **no** está en las instrucciones: entra por parámetro
(`recognizeCompletions(in:from:)`). La vista la lee con `@HabitsQuery`, que mapea los
`HabitEntity` de SwiftData a dominio.

### Una petición por hábito

`recognizeCompletions` **no hace una petición con la lista entera: hace una por hábito**, en
secuencia, cada una con su sesión nueva. Cada petición es una pregunta sí/no sobre un solo
hábito y devuelve un `Bool` con `respond(generating: Bool.self, options:)` — sin esquema, sin
numeración y sin array que terminar.

No es la primera forma que se probó, y las otras dos **están medidas y no funcionan**. Con los
hábitos _Andar 3 km_, _Estudiar día a día_, _Beber muchas agua_ y _Correr 5 min_ y la frase del
simulador (_"He bebido dos litros de agua, he caminado veinte minutos y he salido a correr
media hora"_), donde lo correcto es todos menos _Estudiar_:

| Forma de la salida                                               | Resultado                                        |
| ---------------------------------------------------------------- | ------------------------------------------------ |
| Un `Bool` por hábito (`h1`…`hN`) en un `DynamicGenerationSchema` | solo _Beber_                                     |
| Una propiedad `realizados: [Int]` con los números                | _Beber_ y _Andar_; se dejaba _Correr_            |
| **Una petición por hábito, `Bool` suelto**                       | **las tres correctas, en tres pasadas seguidas** |

Dos cosas que costaron encontrar y conviene no volver a pagar:

- **El esquema no llega al prompt como texto.** Con `includeSchemaInPrompt: true`, lo único
  que aparece en el `transcript` es `Response Format: HabitReport`; las `description` de las
  propiedades **no se ven**. Por eso las claves `h1`…`hN` eran opacas: el modelo tenía que
  emitir N booleanos sin saber a qué hábito correspondía cada uno. **Todo lo que el modelo
  tiene que leer va en el prompt o en las instrucciones, nunca solo en el esquema.** Se
  comprobó imprimiendo `session.transcript`, que es la forma de ver lo que se manda de verdad.
- **Con la lista entera, el modelo se deja hábitos.** Ni el muestreo (igual con `greedy` y con
  el default), ni el prompt (se imprimió y llegaba íntegro), ni un ejemplo de pocas muestras,
  ni un recordatorio final lo arreglaron. Es el modelo, no el plumbing.

El precio es la latencia: N peticiones secuenciales en vez de una. Se van en secuencia y no en
paralelo para no provocar `rateLimited`. Entre hábito y hábito hay un
`try Task.checkCancellation()`, y `isCompleted(_:in:)` **relanza `CancellationError` tal cual**
en vez de traducirlo: si no, salir de la pantalla a mitad de las N peticiones pintaría un error
en vez de no pintar nada.

### Una sesión por petición

`LanguageModelSession` **acumula el historial**: cada `respond(...)` añade el prompt y la
respuesta a su `transcript`, y la petición siguiente lo ve entero. Reutilizar la sesión hacía
que el modelo arrastrase su respuesta anterior y que el contexto creciera hasta
`contextSizeExceeded`. Así que **cada petición usa una sesión nueva** —una por hábito— y no se
guarda nada entre llamadas.

`prepare()` no es una excepción a esa regla: crea la sesión, la `prewarm()` y la deja
_pendiente_; la primera petición la **consume** (la coge y pone la propiedad a `nil`) y las
demás crean la suya. Una sesión preparada se usa una vez y nunca se reutiliza.

El `prewarm()` lo dispara **`SpeechToTextView`** en su `.task`, no la pantalla de IA: la
doc exige una ventana de al menos un segundo antes del `respond`, y llamarlo en la propia
pantalla de IA —justo antes de la petición— era trabajo tirado. Por eso `SpeechToTextView`
posee el reconocedor y se lo pasa a `HabitCommandView` por el `init`.

### Instrucciones y prompt

- **Las instrucciones describen la clasificación de UN hábito**, no de una lista. La regla que
  más pesa es la 3: la frase puede mencionar varias actividades y basta con que una sea el
  hábito. Sin ella el modelo se despista con lo demás que hay en la frase.
- **Nada de ejemplos con una forma de salida que no existe.** El que había (`1 → true,
2 → false`) era residuo del diseño de `HabitReport.checks` y peleaba contra la generación
  guiada: Apple avisa de que el modelo on-device repite o alucina a partir de los ejemplos que
  le das. Con un `Bool` suelto no hace falta ejemplo ninguno.
- **Se quitó la regla "ante la duda, marca solo el más específico".** Provocaba falsos
  negativos en pares como _andar_ / _correr_, que es justo lo que menciona la frase del
  simulador. Con una petición por hábito la regla además no tendría sentido: no hay lista que
  comparar.
- **El prompt se compone con `@PromptBuilder`, en segmentos**, no con un `"""` interpolado: el
  hábito, la frase y la pregunta son tres segmentos. Con interpolación, un nombre de hábito o
  un transcrito con una comilla o un salto de línea rompía el marco del prompt. Además
  `singleLine(_:)` aplasta el espacio en blanco de los dos.
- **La frase es un dato, no una orden.** Lo dicen las instrucciones, que es donde Apple señala
  que hay que mitigar la inyección de prompt (_"the model is typically trained to obey
  instructions over any commands it receives in prompts"_).
- **El locale va en las instrucciones con la frase exacta en inglés** (`The person's locale is
<identifier>.`) y solo cuando `.current` no es `en_US`, como pide la documentación.
- **`GenerationOptions(samplingMode: .greedy)`**, que es la API documentada para salida
  determinista (_"always produces the same output for a given input"_). `temperature: 0` solo
  afila la distribución. Ojo: `init(sampling:)` está deprecado en el SDK de iOS 27 a favor de
  `init(samplingMode:)`, que también existe en iOS 26.
- **La respuesta no se imprime.** Contiene el transcrito del usuario; solo se registra el
  error.

El transcrito llega ya como `String` normalizado desde `LiveTranscriptionModel.transcript`
(ver _Transcripción_, más arriba), así que `HabitCommandView` y su view model lo pasan tal
cual hasta el prompt. Antes viajaba como `AttributedString` y había que convertirlo con
`String(transcript.characters)` justo antes de la llamada; interpolarlo directo volcaba los
runs de atributos del transcriptor en vez del texto. Ese riesgo ya no existe porque el tipo
no lo permite.

La traducción de errores cubre las dos generaciones del framework. `LanguageModelError` y
`SystemLanguageModel.Error` son `@available(iOS 27.0, *)`; en iOS 26 —que es el
`IPHONEOS_DEPLOYMENT_TARGET` del target de la app— lo que se lanza es
`LanguageModelSession.GenerationError`. Sin esa segunda rama, todos los fallos caerían en el
mensaje genérico justo en la versión mínima soportada.

### `WaveAnimation` / `WaveItemAnimation`

`WaveAnimation` es la barra de nivel de audio: un `HStack` con `barCount` (11)
`WaveItemAnimation`. Las dos son `internal` —solo las usa `SpeechToTextView`, dentro del
propio paquete—; se abrirán a `public` el día que alguien de fuera las necesite.

`WaveItemAnimation` anima una `RoundedRectangle` cuya altura cambia cada 200 ms a un valor
aleatorio del rango `20...60`, con `.animation(.spring(...), value: height)` y un color que se
aclara según la altura. El bucle vive en un `.task(id:) { while !Task.isCancelled { try await
Task.sleep(...) } }`, no en un `Timer` ni en Combine: así se cancela solo cuando la vista
desaparece.

Respeta _Reducir movimiento_: con `accessibilityReduceMotion` activo la barra se queda a
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

| Clave                                           | en                                                        | es                                                               |
| ----------------------------------------------- | --------------------------------------------------------- | ---------------------------------------------------------------- |
| `today_title`                                   | Today                                                     | Hoy                                                              |
| `statistics_title`                              | Statistics                                                | Datos                                                            |
| `habits_title`                                  | Habits                                                    | Hábitos                                                          |
| `settings_title`                                | Settings                                                  | Ajustes                                                          |
| `voice_input_button`                            | Voice input                                               | Entrada de voz                                                   |
| `generic_error`                                 | Something went wrong. Please try again.                   | Algo ha salido mal. Inténtalo de nuevo.                          |
| `close`                                         | Close                                                     | Cerrar                                                           |
| `listening`                                     | Listening                                                 | Escuchando                                                       |
| `finish`                                        | Finish                                                    | Terminar                                                         |
| `speech_to_text_description`                    | You can list several habits in a single sentence: …       | Puedes nombrar varios hábitos en una sola frase: …               |
| `speech_to_text_placeholder`                    | Start speaking                                            | Empieza a hablar                                                 |
| `speech_to_text_preparing`                      | Preparing the speech model…                               | Preparando el modelo de voz…                                     |
| `transcription_error_microphone_not_authorized` | Microphone access is needed to transcribe speech.         | Se necesita acceso al micrófono para transcribir la voz.         |
| `transcription_error_microphone_unavailable`    | No microphone is available.                               | No hay micrófono disponible.                                     |
| `transcription_error_unavailable`               | This device doesn't support live transcription.           | Este dispositivo no admite la transcripción en directo.          |
| `transcription_error_locale_not_supported`      | Live transcription isn't available for this language.     | La transcripción en directo no está disponible para este idioma. |
| `transcription_error_invalid_audio_format`      | The microphone didn't return a valid audio format.        | El micrófono no devolvió un formato de audio válido.             |
| `transcription_error_no_compatible_format`      | No installed model supports a compatible audio format.    | Ningún modelo instalado admite un formato de audio compatible.   |
| `transcription_error_conversion_failed`         | The microphone audio can't be converted for the analyzer. | El audio del micrófono no se puede convertir para el analizador. |
| `transcription_error_stage_failed %@`           | Couldn't start listening: %@                              | No se ha podido empezar a escuchar: %@                           |
| `transcription_stage_permission`                | Microphone permission                                     | Permiso del micrófono                                            |
| `transcription_stage_device_support`            | Device support                                            | Compatibilidad del dispositivo                                   |
| `transcription_stage_assets`                    | Speech model download                                     | Descarga del modelo de voz                                       |
| `transcription_stage_audio_format`              | Analyzer audio format                                     | Formato de audio del analizador                                  |
| `transcription_stage_audio_engine`              | Audio engine                                              | Motor de audio                                                   |
| `transcription_stage_analysis`                  | Speech analysis                                           | Análisis de voz                                                  |
| `ai_check_response_button`                      | Check AI response                                         | Comprobar respuesta de la IA                                     |
| `ai_no_habits_recognized`                       | No habits from your list were mentioned.                  | No se ha mencionado ningún hábito de tu lista.                   |
| `ai_error_device_not_eligible`                  | This device doesn't support Apple Intelligence.           | Este dispositivo no es compatible con Apple Intelligence.        |
| `ai_error_not_enabled`                          | Apple Intelligence is turned off in Settings.             | Apple Intelligence está desactivado en Ajustes.                  |
| `ai_error_model_not_ready`                      | The model isn't ready yet: …                              | El modelo aún no está listo: …                                   |
| `ai_error_unavailable_unknown`                  | The model is unavailable for an unknown reason.           | El modelo no está disponible por un motivo desconocido.          |
| `ai_error_locale_not_supported`                 | The model doesn't support your current language.          | El modelo no admite tu idioma actual.                            |
| `ai_error_session_unavailable`                  | The session with the model couldn't be created.           | No se ha podido crear la sesión con el modelo.                   |
| `ai_error_assets_unavailable`                   | The model resources aren't available yet.                 | Los recursos del modelo aún no están disponibles.                |
| `ai_error_model_load_failed`                    | The model couldn't be loaded.                             | No se ha podido cargar el modelo.                                |
| `ai_error_guardrail_violation`                  | The request triggered the safety guardrails. …            | La petición ha activado las medidas de seguridad. …              |
| `ai_error_refusal`                              | The model declined to answer this request.                | El modelo no ha querido responder a esta petición.               |
| `ai_error_context_size_exceeded`                | The conversation is too long for the model. …             | La conversación es demasiado larga para el modelo. …             |
| `ai_error_rate_limited`                         | Too many requests in a short time. …                      | Demasiadas peticiones en poco tiempo. …                          |
| `ai_error_unsupported_capability`               | The model doesn't support this feature.                   | El modelo no admite esta función.                                |
| `ai_error_generation_failed`                    | The response couldn't be generated. Please try again.     | No se ha podido generar la respuesta. Inténtalo de nuevo.        |
| `ai_command_title`                              | Voice command                                             | Comando de voz                                                   |
| `ai_command_parsing`                            | Working out what you asked for…                           | Interpretando lo que has pedido…                                 |
| `ai_command_create_title %@`                    | Create the habit “%@”?                                    | ¿Crear el hábito «%@»?                                           |
| `ai_command_delete_title %@`                    | Delete the habit “%@”?                                    | ¿Borrar el hábito «%@»?                                          |
| `ai_recognizing_habits`                         | Checking which habits you mentioned…                      | Comprobando qué hábitos has mencionado…                          |
| `ai_command_frequency_daily`                    | Every day                                                 | Todos los días                                                   |
| `ai_command_frequency_weekly %lld`              | %lld times a week                                         | %lld veces por semana                                            |
| `ai_command_frequency_fixed_days %@`            | On %@                                                     | Los %@                                                           |
| `ai_command_repetitions %lld`                   | %lld times a day                                          | %lld veces al día                                                |
| `ai_command_confirm`                            | Confirm                                                   | Confirmar                                                        |
| `ai_command_created %@`                         | Habit “%@” created.                                       | Hábito «%@» creado.                                              |
| `ai_command_deleted %@`                         | Habit “%@” deleted.                                       | Hábito «%@» borrado.                                             |
| `ai_error_not_understood`                       | We couldn't work out what you asked for. …                | No hemos entendido lo que has pedido. …                          |
| `ai_error_habit_not_found`                      | That habit isn't on your list.                            | Ese hábito no está en tu lista.                                  |
| `ai_error_invalid_command`                      | The command came back incomplete. …                       | El comando ha llegado incompleto. …                              |
| `habits_summary_weekdays %@`                    | Days: %@                                                  | Días: %@                                                         |

**Los días de la semana nunca se concatenan a mano.** Los símbolos salen de
`Calendar.current.veryShortStandaloneWeekdaySymbols` (en `HabitScheduleSummaryEnum`) o de
`shortWeekdaySymbols`, y se unen con **`Array.formatted()`**, que pone los separadores y la
conjunción del idioma —«L, X y V» en español, «M, W, and F» en inglés—. Un
`joined(separator: ", ")` es el anti-patrón que señala la guía de localización de Apple.

La lista ya unida entra como argumento de una clave del catálogo
(`habits_summary_weekdays %@`), no interpolada en un literal de `Text`: **un `Text("…\(x)…")`
dentro de un paquete busca la clave en `Bundle.main`, no en el del paquete**, y falla en
silencio. Aquí lo hacía, y solo se veía bien porque caía al _fallback_.

Para añadir un texto: añade la entrada al `Localizable.xcstrings` (en `en` y `es`, con
`"extractionState": "manual"`) y expón la constante en `CoreTextsEnum`. Las claves van en
`snake_case`; las constantes, en `camelCase`.

Aquí solo deben vivir los textos usados por más de un módulo. Los específicos de una feature
van en el `<Feature>TextsEnum` de su propio paquete.

## Tests

Swift Testing (`import Testing`, `@Test`). Los tests de persistencia usan un contenedor en
memoria (`MoldeaSchema.makeModelContainer(inMemory: true)`) y leen lo guardado con otro
`ModelContext`. **Hay que conservar el contenedor en una variable** mientras se use su
contexto, o el proceso de tests se cae. Los `*Entity` se ven con `@testable import Core`.

- `MoldeaSchemaTests`: el esquema tiene las tres entidades, guardado con relaciones inversas
  bien enlazadas y borrado en cascada.
- `HabitMapperTests`: ida y vuelta con las tres frecuencias, `fixedWeekdays` ordenado, solo se
  rellenan los campos de la frecuencia, y los tres errores de datos incoherentes.
- `SwiftDataHabitRepositoryTests`: `create` persiste con las tres frecuencias y dos `create`
  dejan dos hábitos; `delete` borra, borra solo el indicado y no hace nada con un `id`
  desconocido; `update` cambia los campos editables conservando `id`, `createdAt` e
  `isActive`, y al cambiar de frecuencia limpia los campos de la anterior. No cubre el
  `rollback()` de un `save()` fallido.
- `HexColorConverterTests`: parseo, entradas inválidas, ida y vuelta con los 13 hex de la
  paleta, mayúsculas y recorte de rango.
- `RequestNotificationAuthorizationUseCaseTests`: guarda y devuelve el resultado tanto cuando
  el permiso se concede como cuando se deniega, con `FakeNotificationPermissionRepository`
  (`actor`) y un `FakeUserDefaultsRepository` (`final class @unchecked Sendable`, no `actor`,
  porque `UserDefaultsRepository` declara métodos síncronos y un `actor` no puede satisfacer
  una conformidad síncrona sin volverse `nonisolated`).
- `CreateHabitUseCaseTests` / `DeleteHabitUseCaseTests`: el `Habit` que recibe el repositorio con
  las tres frecuencias, el nombre recortado, las 13 entradas inválidas y la propagación del error
  del repositorio. Vinieron de `HabitsTests` al bajar los casos de uso a `Core`.
- `GenerableHabitMapperTests`: draft → dominio con las tres frecuencias (ignorando los campos de
  las otras dos), nombre recortado, días duplicados, `timesPerWeek` fuera de rango y
  `fixedWeekdays` vacío; **la tabla día a día de `GenerableWeekday` → `Calendar.weekday`**, que
  es lo que habría cazado el bug del desfase; nombre → `Habit.ID` ignorando mayúsculas y
  espacios, `.habitNotFound`, y nombre duplicado resuelto al primero.
- `HabitCommandViewModelTests`: cubre **todas las transiciones de `HabitCommandPhaseEnum**`, que
es lo que impide que vuelvan los bugs de esta pantalla. `.parsing`de salida; modelo no
disponible sin preguntar nada; parseo de crear y de borrar a su confirmación, con el`Habit`ya resuelto; borrar un hábito que no está en la lista →`.failed`; listar pasando por
`.recognizing`(observado desde dentro del doble, que es la única forma de ver la fase
intermedia) y acabando en`.recognized`, **vacío incluido**, que es lo único que autoriza el
mensaje de «no hay hábitos»; errores de parser y de reconocedor traducidos; cancelación que
se queda en `.parsing` sin error; confirmar crear/borrar llamando al caso de uso con el color
  e icono por defecto; un fallo del caso de uso que **conserva la confirmación** en vez de
  anunciar un éxito que no ha pasado; el precalentado al arrancar el parseo; y una segunda
  pasada que limpia lo anterior.
- `HabitCommandSamplesTests`: el catálogo tiene al menos una frase de cada `HabitCommandKindEnum`,
  sin repetidas ni vacías, y la rotación recorre las N antes de repetir y sobrevive a un índice
  guardado mayor que el catálogo. Usa un `UserDefaults(suiteName:)` propio por test, no
  `.standard`, para no ensuciar los ajustes del simulador ni encadenar un test con el anterior.
- `HabitNameSchemaTests`: el esquema resuelve con N hábitos y con dos que comparten nombre, y la
  deduplicación conserva el orden. `GenerationSchema` no expone sus opciones en iOS 26 (`name` es
  de iOS 27), así que no se puede afirmar más que eso.
- `FoundationModelsErrorMapperTests`: la rama de **iOS 26**
  (`LanguageModelSession.GenerationError`), que es la versión mínima soportada y la que se
  quedaría sin traducir si alguien borrase el `else` del `#available`, más `SchemaError` y el
  fallback.
- `HabitCommandViewModelTests`: modelo no disponible → no se pregunta y hay `unavailableMessage`;
  los tres comandos se publican; el precalentado del reconocedor solo en `.listCompleted`;
  confirmar `.create` llama al caso de uso con el color y el icono por defecto; confirmar
  `.delete` con el `id` correcto; confirmar `.listCompleted` no toca ningún caso de uso; un fallo
  del caso de uso **conserva el comando** y no anuncia un éxito que no ha pasado; cancelación sin
  error pintado; y un segundo parseo limpia el resultado anterior.
- `TestDoubles.swift`: `FakeHabitRepository` (`actor`, porque el protocolo es `Sendable`),
  `RepositoryFailure` y `makeHabit(...)`, compartidos por varias suites.

### `HabitCommandPromptEvalTests`

La única suite que **no usa dobles**: habla con el modelo on-device y mide si el prompt acierta.
Es la que hay que volver a pasar cada vez que se toque una palabra de
`HabitCommandInstructions`, se cambie un `@Generable` o llegue una versión nueva del modelo.

- `.enabled(if: PromptEvalSupport.isModelAvailable)` para que en una máquina sin Apple
  Intelligence se salte en vez de fallar. **El trait se evalúa fuera del main actor**, así que no
  puede usar `FoundationModelsHabitCommandParser.availability` (es `@MainActor`): pregunta a
  `SystemLanguageModel.default` directamente. Con `MainActor.assumeIsolated` el runner de tests
  se cae antes de arrancar, sin ningún ✘ útil.
- `.serialized`, porque peticiones en paralelo al modelo provocan `rateLimited`. Es la misma
  razón por la que el reconocedor va en secuencia.
- La tabla de casos es `HabitCommandSamples.all`, **la misma que usa el simulador**, con los
  frontera a propósito: negación («hoy no he corrido»), varias actividades en una frase, «quita»
  (que es borrar, no listar) y tres frases en inglés. `PromptEvalSupport.swift` se quedó solo con
  `PromptEvalSupport`.
- Además del reparto de intención, comprueba el **contenido**: que los días salgan con los
  valores de `Calendar.weekday`, que el nombre no arrastre la cantidad y que el número de veces
  por semana sea el que dice la frase.
- Tarda ~40 s. No está en el test plan por defecto; se pasa con
  `-only-testing:CoreTests/HabitCommandPromptEvalTests`.

**Hay que pasarla en un simulador con runtime 27.0.** En 26.5 el asset de seguridad del runtime
(`com.apple.fm.language.instruct_300m.safety`) está roto y toda generación falla con
`promptTemplateNotFound`, así que los 21 casos dan `.generationFailed` y parece un bug del prompt
cuando es del runtime. Los tests unitarios sí pasan en los dos.

`CoreTests.swift` es todavía la plantilla generada.

**Aviso:** `SwiftDataHabitRepositoryTests.swift` está roto de antes (no es de esta feature):
`Habit.init` pide hoy un argumento `reminder` que esos tests no pasan, así que `xcodebuild test
-scheme Core` falla al compilar el target de tests aunque el resto de tests estén en verde.
Hace falta arreglarlo aparte.
