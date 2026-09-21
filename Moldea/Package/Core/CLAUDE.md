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
│   └── Repository/
│       └── HabitRepository.swift
├── Data/
│   ├── Model/
│   │   ├── HabitEntity.swift
│   │   ├── HabitScheduleEntity.swift
│   │   ├── HabitCompletionEntity.swift
│   │   └── FrequencyType.swift
│   ├── Mappers/
│   │   └── HabitMapper.swift
│   ├── MoldeaSchema.swift
│   └── SwiftDataHabitRepository.swift
└── Presentation/
    ├── Enums/
    │   ├── CoreTextsEnum.swift
    │   ├── StageEnum.swift
    │   ├── TranscriberEnum.swift
    │   ├── TranscriptionErrorEnum.swift
    │   └── TranscriptionPhaseEnum.swift
    ├── SpeechToTextCore/
    │   └── LiveTranscriptionModel.swift
    ├── SpeechToTextView/
    │   └── SpeechToTextView.swift
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

**Repositorio** (`Domain/Repository`): `HabitRepository` es un protocolo `public` y `Sendable`.
Recibe y devuelve solo tipos de dominio. Hoy solo tiene `create(_:)`; `fetch` se añadirá cuando
`Today` y `Statistics` lo necesiten, y con él habrá que decidir qué hacer con una fila corrupta
al listar (saltarla y registrarla, o propagar el error).

## Data

Todo lo de `Model/` y `Mappers/` es `internal`: los `@Model` no salen de `Core`.

- **Entidades de SwiftData**: `HabitEntity` (`id` único, `active`, fechas, relaciones en
  cascada con el schedule y las completions), `HabitScheduleEntity` (guarda `frequencyType`,
  `timesPerWeek?`, `fixedWeekdays: [Int]?` y `repetitionsPerDay`) y `HabitCompletionEntity`
  (`id` único, `day` con `#Index`). `FrequencyType` es la etiqueta de persistencia de la
  frecuencia; el dominio usa `HabitFrequency`.
- **`HabitMapper`**: `makeEntity(from:)` (dominio → entidad, con `fixedWeekdays` ordenado para
  que lo persistido sea determinista) y `toDomain(_:) throws`, que lanza `HabitMappingError`
  (`missingSchedule`, `missingTimesPerWeek`, `missingFixedWeekdays`, todos con el `habitID`) si
  los datos son incoherentes. No rellena valores por defecto: ocultaría la corrupción.
- **`MoldeaSchema`** (`public`): lista de modelos, `schema` y
  `makeModelContainer(inMemory:)`. Es el único punto de verdad del esquema; cuando lleguen los
  widgets y el App Group, la configuración compartida se añadirá aquí.
- **`SwiftDataHabitRepository`** (`public`, `@ModelActor`): `@ModelActor` genera un
  `public init(modelContainer:)` cuando el actor es `public`, que es lo que usa `MoldeaApp`.
  `create` inserta y guarda; si `save()` falla hace `rollback()` y relanza el error, para que la
  entidad no quede pendiente y se guarde con el siguiente `create`.

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

(El comentario de cabecera del fichero dice `LoadableViewModel.swift`; es un resto de un nombre
anterior.)

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

| Clave                | en                                      | es                                      |
| -------------------- | --------------------------------------- | --------------------------------------- |
| `today_title`        | Today                                   | Hoy                                     |
| `statistics_title`   | Statistics                              | Datos                                   |
| `habits_title`       | Habits                                  | Hábitos                                 |
| `settings_title`     | Settings                                | Ajustes                                 |
| `voice_input_button` | Voice input                             | Entrada de voz                          |
| `generic_error`      | Something went wrong. Please try again. | Algo ha salido mal. Inténtalo de nuevo. |

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
  dejan dos hábitos. No cubre el `rollback()` de un `save()` fallido.
- `HexColorConverterTests`: parseo, entradas inválidas, ida y vuelta con los 13 hex de la
  paleta, mayúsculas y recorte de rango.

`CoreTests.swift` es todavía la plantilla generada.
