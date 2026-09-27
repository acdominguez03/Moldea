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

- `swift-tools-version: 6.4`
- Plataforma mínima: `.iOS(.v26)`
- `swiftSettings`: `.enableUpcomingFeature("ApproachableConcurrency")` en target y test target

## Estructura

```
Sources/Core/
├── DI/
│   ├── CoreDependencies.swift           # contenedor + @Entry \.coreDependencies
│   ├── MissingDependenciesView.swift    # lo que pinta una vista raíz sin inyección
│   └── MoldeaPreviewModifier.swift      # trait .moldea para previews
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
│   │   ├── DeleteHabitUseCase.swift      # protocolo + DefaultDeleteHabitUseCase
│   │   └── CompleteHabitsUseCase.swift   # protocolo + DefaultCompleteHabitsUseCase
│   └── HabitCommandParsing.swift
├── Data/
│   ├── Preview/
│   │   └── PreviewRepositories.swift     # implementaciones de CoreDependencies.preview
│   ├── Model/
│   │   ├── HabitEntity.swift
│   │   ├── HabitScheduleEntity.swift
│   │   ├── HabitCompletionEntity.swift
│   │   └── FrequencyTypeEnum.swift
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
│   │   ├── FoundationModelsDeviceEligibility.swift  # público: ¿el hardware admite Apple Intelligence?
│   │   └── HabitCommandSamples.swift        # #if DEBUG, incluye HabitCommandKindEnum
│   ├── HabitsQuery.swift
│   ├── MoldeaSchema.swift
│   ├── SwiftDataHabitRepository.swift
│   ├── PreferenceKeyEnum.swift
│   ├── UserDefaultsRepositoryImpl.swift
│   ├── UNUserNotificationCenterPermissionRepository.swift
│   └── AVAudioApplicationMicrophonePermissionRepository.swift
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
  `.delete(habitID:)` o `.complete(habitIDs:)`—. No importa `FoundationModels`. `.complete` solo
  lleva los hábitos mencionados: cuáles ya estaban completos lo decide `CompleteHabitsUseCase`.
- `NewHabitDraft`: `name`, `frequency` y `repetitionsPerDay`. **No lleva color ni icono**,
  porque al hablar no se dicen: los pone `HabitAppearanceDefaultsEnum`.
- `HabitAppearanceDefaultsEnum`: `colorHex` (`#5B6470`) e `icon` (`drop`) con los que nace un hábito
  creado por voz. Están duplicados respecto a `HabitPaletteColorEnum`/`HabitPaletteIconEnum`, que viven
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

### Progreso: `CalculateHabitsProgressUseCase`

El porcentaje de hábitos completados de la pestaña **Hoy** —y, cuando llegue, el de
`Statistics`—. Es el único caso de uso **síncrono y sin repositorio** del paquete:
`execute(habits: [TodayHabit], scope: HabitProgressScopeEnum) -> HabitsProgress`. No hay I/O, así
que `async`/`throws` serían ruido; el protocolo se llama `CalculateHabitsProgressUseCaseProtocol`
porque el nombre sin sufijo se lo lleva la implementación.

Recibe los `TodayHabit` que ya publican `@TodayHabitsQuery` / `@WeeklyHabitsQuery` en vez de leer
de la base de datos: así el porcentaje se recalcula solo al marcar una completion, sin recargas
a mano, y se testea sin SwiftData. **No recibe una fecha**: el día ya viaja dentro de cada
`TodayHabit` como `referenceDay`, que es contra el que están calculados `completedToday` y
`completedDaysThisWeek`; pedirla otra vez permitiría pasar una distinta de la que filtró las
completions.

La fórmula es **ponderada por repeticiones**, no un recuento de hábitos hechos:

| Alcance   | Numerador                                    | Denominador                          |
| --------- | -------------------------------------------- | ------------------------------------ |
| `.daily`  | `Σ min(completedToday, repetitionsPerDay)`   | `Σ repetitionsPerDay`                |
| `.weekly` | `Σ completedRepetitionsThisWeek`             | `Σ timesPerWeek × repetitionsPerDay` |

Así un hábito 3/4 aporta lo que ha hecho, que es lo que ya pintan las barras de `TodayCardView`.

**La unidad del alcance semanal son repeticiones, no días.** `completedDaysThisWeek` solo cuenta
los días con **todas** sus repeticiones hechas, así que con él un día a medias (1 de 2) aportaba
0 a la semana aunque `TodayCardView` ya lo pintase como barra parcial. Por eso el numerador es
`TodayHabit.completedRepetitionsThisWeek` —suma `min(hechas ese día, repetitionsPerDay)` de cada
día y topa el total en `timesPerWeek × repetitionsPerDay`— y el denominador se multiplica por las
repeticiones. Un `weeklyCount(3)` con `repetitionsPerDay: 2`, dos días completos y una repetición
de hoy da 5/6, no 2/3. `completedDaysThisWeek` sigue existiendo: es lo que necesitan el texto «X
de Y esta semana» y las barras de la tarjeta.
`HabitsProgress` (`Domain/Model`) lleva los dos pares —`completedHabits`/`totalHabits` para el
texto «X de Y hábitos» y `completedUnits`/`totalUnits` para la barra— y deriva `fraction`
(0 cuando `totalUnits == 0`, que es lo que quita el `max(count, 1)` que había en la vista) y
`percentage`.

Dos detalles que no son casuales:

- **En `.weekly`, un hábito que no sea `.weeklyCount` se descarta** (`compactMap` a `nil`), no
  cae a la fórmula diaria: no tiene objetivo semanal, así que no debe sumar ni al numerador ni al
  denominador ni a `totalHabits`. `WeeklyHabitsQuery` ya filtra, pero el caso de uso no depende de
  que quien le llame acierte.
- **Los `min(…)`** existen aunque `completedDaysThisWeek` ya venga topado y el toggle nunca pase
  de `repetitionsPerDay`: un dato viejo en base de datos no puede dar más de un 100 %.

Esto sustituye al `habits.filter(\.isCompletedToday).count` que hacía `TodayView`, que además
medía mal la pestaña semanal: `isCompletedToday` es el objetivo **del día**, así que un hábito de
3 veces por semana con 2 días hechos contaba 0 mientras no se marcase hoy.

### Periodos de inactividad

Un hábito se puede desactivar y reactivar tantas veces como se quiera, y las estadísticas tienen
que respetar lo que estaba activo cada día. Por eso `Habit` lleva `inactivePeriods:
[HabitInactivePeriod]` (`start`, `end?`; `end == nil` = sigue desactivado). En `HabitEntity` es un
atributo `Codable` compuesto con valor por defecto `[]`, no una tabla: nunca se consulta por
separado y la migración ligera lo cubre.

- **Quién los escribe:** `SwiftDataHabitRepository.setActive`. Desactivar abre un periodo (solo
  si no hay ya uno abierto); activar cierra el último abierto con `updatedAt`.
- **Regla del día** (`Habit.isActive(on:calendar:)`): D es inactivo si
  `startOfDay(start) ≤ D < startOfDay(end)`. El día de la desactivación no cuenta (por eso el
  hábito desaparece de Hoy al momento), el de la reactivación sí, y desactivar y reactivar el
  mismo día deja el día intacto.
- **Datos anteriores al campo:** un hábito con `isActive == false` sin periodo abierto se trata
  como inactivo desde `updatedAt`. Sus días pasados cuentan como activos.
- `Habit.activeDays(in:)` cuenta los días activos de un intervalo; lo usa `Statistics` para
  prorratear los `weeklyCount`.
- `ScheduledHabitsBuilder` descarta los hábitos inactivos en `referenceDay`
  (`onlyActiveOnReferenceDay`, `true` por defecto: Hoy, widget, recordatorios).
  `AllHabitsInPeriodQuery` pasa `false`: las estadísticas reciben todos los hábitos y filtran día
  a día en `HabitOccurrencesBuilder`.

## Data

Todo lo de `Model/` y `Mappers/` es `internal`: los `@Model` no salen de `Core`.

- **Entidades de SwiftData**: `HabitEntity` (`id` único, `active`, fechas, relaciones en
  cascada con el schedule y las completions), `HabitScheduleEntity` (guarda `frequencyType`,
  `timesPerWeek?`, `fixedWeekdays: [Int]?` y `repetitionsPerDay`) y `HabitCompletionEntity`
  (`id` único, `day` con `#Index`). `FrequencyTypeEnum` es la etiqueta de persistencia de la
  frecuencia; el dominio usa `HabitFrequency`.
- **`HabitMapper`**: `makeEntity(from:)` (dominio → entidad) y `toDomain(_:) throws`, que lanza
  `HabitMappingErrorEnum` (`missingSchedule`, `missingTimesPerWeek`, `missingFixedWeekdays`, todos
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
- **`@AllHabitsInPeriodQuery`** (`public`, `Data/Query`): todos los hábitos con sus completions
  de un periodo. Tiene dos `init`: `init(_ component: Calendar.Component, date:)` (semana, mes,
  año de `Calendar.current`) e `init(_ interval: DateInterval, date:)` para rangos que no son un
  componente del calendario, como los 10 últimos días de la vista diaria de `Statistics`. El
  primero calcula su intervalo y delega en el segundo.
- **`DebugHistorySeeder`** (`#if DEBUG`, `@ModelActor`): siembra ~1 año de historial (8 hábitos,
  unas 3.000 completions, con tendencias distintas y uno en pausa) para ver las gráficas de
  `Statistics` con datos. Se lanza desde un `.task` de `MoldeaApp`, en su propio contexto y fuera
  del hilo principal, **una sola vez por instalación** (marca `debug.yearHistorySeeded` en
  `UserDefaults`) y **solo si no hay ningún hábito**, así que no toca datos que ya tengas. No corre
  con `-inMemoryStore` (tests de UI). Es determinista (semilla fija) y los hábitos no llevan
  recordatorio. Escribe en consola cuánto ha tardado. Para volver a sembrar: borra la app. No lo
  usan los previews: esos siguen con `SampleDataSeeder`. Ya que vive en `Core`, en Release ni se compila.
- **`PreferenceKeyEnum`** (`public enum`, raw `String`): claves de `UserDefaults`. Hoy tiene
  `isNotificationsEnabled` (preferencia de producto: "quiero que mis hábitos avisen", la que
  controla `Settings`), `isNotificationPermissionAllowed` (espejo del permiso real del
  sistema) e `isMicrophonePermissionAllowed` (ídem para el micrófono). Son independientes a propósito: el permiso del sistema puede estar concedido y el
  usuario, aun así, tener los avisos apagados dentro de la app.
- **`UserDefaultsRepositoryImpl`** (`public struct`): implementación directa sobre
  `UserDefaults.standard`.
- **`UNUserNotificationCenterPermissionRepository`** (`public struct`): envuelve
  `UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])`;
  si la llamada lanza, devuelve `false` en vez de propagar el error.
- **`AVAudioApplicationMicrophonePermissionRepository`** (`public struct`): el mismo patrón
  para el micrófono, sobre `AVAudioApplication.requestRecordPermission()` (no lanza).
  `DefaultRequestMicrophoneAuthorizationUseCase` guarda el resultado en
  `isMicrophonePermissionAllowed`, como su equivalente de notificaciones. Además expone
  `authorizationStatus() -> MicrophonePermissionStatusEnum` (`notDetermined` / `denied` /
  `granted`), que lee `AVAudioApplication.shared.recordPermission` **sin mostrar alerta**; lo
  usa `Settings` para saber si pintar la fila de micrófono denegado.
- **Cuándo se pide cada permiso.** El de notificaciones, al arrancar, en el `.task` de
  `MoldeaApp`. El de micrófono, **solo si la IA está disponible y justo antes de abrir el sheet de
  voz**: `MoldeaApp` pasa `requestMicrophoneAuthorization.execute()` como `prepareSheet` de
  `MainTabsView`, que lo espera antes de presentar la hoja. Como la pestaña del micrófono solo
  existe si `FoundationModelsDeviceEligibility.isDeviceEligible`, en un dispositivo no compatible
  nunca se pide. Si el usuario ya respondió, `requestRecordPermission()` devuelve al instante sin
  alerta. `LiveTranscriptionModel` no pide el permiso: solo comprueba
  `AVAudioApplication.shared.recordPermission == .granted` y, si no lo está, lanza
  `microphoneNotAuthorized`, que el sheet muestra como aviso.

## Dependencias: `DI/`

- **`CoreDependencies`** (`public struct`, `Sendable`): el contenedor que reciben todas las
  features. Guarda una instancia de cada repositorio compartido (`habitRepository`,
  `todayHabitsRepository`, `userDefaultsRepository`, `notificationScheduler`, los dos de
  permisos y `todayProgressStore`) y expone los casos de uso de `Core` como propiedades
  calculadas. `modelContainer` es `internal`: solo lo necesita el trait de previews.
  - `live(container:)` monta las implementaciones reales; la llama `AppDependencies`.
  - `preview` es un `static let` solo para previews, sobre
    `MoldeaSchema.makeModelContainer(inMemory: true)`. **No** es `live(...)`: usa
    `NoOpHabitNotificationScheduler` y los tipos de `Data/Preview/PreviewRepositories.swift`
    (`InMemoryUserDefaultsRepository`, que arranca con permiso y avisos activados;
    `NoOpTodayProgressStore`; y permisos de notificaciones y micrófono siempre concedidos), así que
    no toca disco, notificaciones ni el App Group.
  - `@Entry var coreDependencies: CoreDependencies? = nil`: sin default real. Quien lo lee
    (`SpeechToTextView`) pinta `MissingDependenciesView` si falta la inyección (ver _Composición_
    en el `CLAUDE.md` raíz).
  - `makeSpeechToTextViewModel()` crea **un** `FoundationModelsHabitCommandParser` y se lo pasa
    al view model de voz junto con una factoría que llama a `makeHabitCommandViewModel(parser:)`
    con ese mismo parser: el que se precalienta en `start()` es el que recibe la primera petición.
- **`MissingDependenciesView(_:)`** (público): lo pinta una vista raíz cuando su `@Entry` es
  `nil`. `assertionFailure` con el nombre del tipo en Debug; en Release no pinta nada.
- **`UNUserNotificationCenterHabitNotificationScheduler.init` es `nonisolated`.** El tipo es
  `@MainActor`, pero `live(container:)` no lo es. El `init` solo guarda el
  `UserDefaultsRepository`; los métodos siguen en el main actor.
- **Recordatorios: una notificación puntual por hábito y día** (`HabitNotificationScheduler`).
  - **Por qué no repetitivos:** un `UNCalendarNotificationTrigger` con `repeats: true` no puede
    saltarse una sola ocurrencia, y completar un hábito tiene que quitar solo la de hoy. Los
    identificadores son `habit-reminder-<id>-<yyyyMMdd>`.
  - **`syncReminders()` es la única operación de fondo.** Lee los hábitos y lo completado hoy
    (`ReminderPlanSource`), calcula con `ReminderPlanner` (puro, con tests) qué tendría que haber
    pendiente y aplica la diferencia: quita lo que sobra o cambió de hora o texto, añade lo que
    falta y limpia del Centro de Notificaciones el aviso de hoy si el hábito ya está completado.
    Es idempotente y se serializa. `scheduleReminder(for:)` y `cancelReminders(for:)` solo la
    llaman: como todos los casos de uso escriben primero y llaman después, el estado guardado manda.
  - **Quién sincroniza:** los casos de uso de crear, actualizar, borrar, pausar y los de
    recordatorio; `DefaultToggleHabitCompletionUseCase` y `DefaultCompleteHabitsUseCase` **solo
    al completar del todo o al deshacer** (un progreso parcial no cambia qué avisar hoy); y
    `MoldeaApp` cada vez que la escena pasa a activa.
  - **Reglas de `ReminderPlanner`:** hábito pausado, sin recordatorio o con el aviso apagado no
    planifica; si hoy ya está completado se salta solo hoy; si la hora de hoy ya pasó, tampoco;
    horizonte máximo de 28 días.
  - **Presupuesto:** 64 pendientes por app medido en un iPhone con iOS 26, cada una cuenta como
    una. No está en la documentación de Apple. `add` no falla al pasarse: el sistema conserva en
    silencio las **últimas 64 añadidas**. El scheduler usa 60 y reparte por fecha: se quedan las
    60 más próximas de todos los hábitos, así que todos tienen el mismo horizonte (con 12 hábitos
    diarios, unos 5 días). Sin abrir la app en ese tiempo se acaban los avisos.
  - **`cancelAllReminders()`** quita todas las pendientes de la app. Lo usa el interruptor
    "Permitir avisos", que limpia siempre y después sincroniza.
  - `scheduleReminder` ignora los hábitos **pausados**, así que quien programa pasa el `isActive`
    real. El borrado de pendientes es asíncrono, y se espera (máximo 1 s) a verlo aplicado.
  - **Aviso de la noche** (`DailySummaryReminder`, 21:30 fijo, no configurable): un aviso extra con
    texto fijo ("Tienes hábitos pendientes por completar") que invita a entrar a revisarlos.
    Se planifica con `includesDailySummary`, que sale de `PreferenceKeyEnum.isDailySummaryEnabled`, y
    solo hay uno por día con hábitos programados. Cuenta como pendiente lo mismo que la pestaña
    Diario de Today: hábitos activos que tocan ese día (`isScheduled(on:)`), así que los de "X
    veces por semana" no cuentan, y el aviso propio de cada hábito no influye. Hoy solo se
    programa si queda alguno sin completar y la hora no ha pasado; al completar el último se quita,
    y si ya había salido, se limpia del Centro de Notificaciones. Su identificador es
    `habit-reminder-summary-<yyyyMMdd>`, con el mismo prefijo que los de los hábitos, y comparte
    el presupuesto de 60. Solo llega si "Permitir avisos" también está activo.
  - **El widget no sincroniza.** Su intent (`QuickHabitCheckWidget/ToggleHabitIntent`) corre por
    defecto en el proceso de la extensión, y la documentación de Apple no dice si allí se
    comparten las notificaciones pendientes con la app. Usa `NoOpHabitNotificationScheduler`: lo
    que complete el widget se refleja en las notificaciones en la siguiente sincronización desde
    la app. Hasta entonces, el aviso de ese día puede sonar aunque ya esté completado.
- **`.moldea`** (`MoldeaPreviewModifier`, `PreviewModifier`): `makeSharedContext()` siembra
  `CoreDependencies.preview` con `SampleDataSeeder` **solo si no hay hábitos**
  (`fetchCount == 0`), porque el seeder no comprueba si ya ha sembrado; `body` aplica
  `.modelContainer` y `\.coreDependencies`.

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
`.fittingSheetDetents()`). En tamaños de accesibilidad el contenido va en un `ScrollView`, así
que `FittingSheetModifier` quita el `fixedSize` vertical y deja solo `.large` (más los
`extraDetents`): con el `fixedSize` el `ScrollView` crecería hasta su contenido y no se podría
desplazar.

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

El view model también posee las dependencias que `HabitCommandView` necesita (`parser` y los
casos de uso de crear, borrar y completar) y las expone como `let`, que es el motivo por el que
el `init` sigue recibiendo solo el `habitRepository`. El parser entra por el `init` con la
implementación real por defecto, así que la pantalla se puede previsualizar con dobles.

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
  tarda. El provider vive dentro de `CaptureSessionRunner`, un `actor` privado del mismo
  fichero, porque `startRunning()` y `stopRunning()` de `AVCaptureSession` son síncronos y
  bloquean hasta que la sesión arranca o se para: Apple pide no llamarlos en el hilo principal
  (el runtime avisa con _"should be called from background thread"_), y su sample _Recognizing
  speech in live audio_ guarda la sesión en un actor. `analyzerInputs` se saca antes de pasar el
  provider al actor (es `Sendable`). El runner se guarda como `AnyObject?` (una propiedad
  almacenada no admite `@available`); `stopCaptureSession()` lanza `stopRunning()` en un `Task`.
- **El análisis se termina cancelando, no soltando el provider.** La secuencia de
  `analyzerInputs` solo acaba cuando se desasigna el provider, y basta una referencia olvidada
  (la variable local `runner` de `analyzeCaptureSession`, viva mientras se espera a `analyze`)
  para que `analyzeSequence(_:)` no vuelva nunca: _Terminar_ se quedaba esperando con los botones
  deshabilitados. Por eso `analyze(_:with:)` consume la secuencia en su propio `Task`
  (`analysisTask`) y `stopTranscribing()` lo cancela; según la documentación, cancelado,
  `analyzeSequence(_:)` devuelve el último instante consumido sin lanzar `CancellationError`, y
  con él se llama a `finalizeAndFinish(through:)` **fuera** del `Task` cancelado. Es lo que
  recomienda el sample _Recognizing speech in live audio_. Vale para las dos rutas; en la de
  iOS 26 el `finish()` del `AsyncStream` ya bastaba.
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

La pantalla a la que se llega desde _Terminar_. Interpreta el transcrito como **un comando**;
crear y borrar piden confirmación antes de tocar nada:

```
SpeechToTextView ──Terminar──► HabitCommandView            (única pantalla)
                                 ├─ .create        → Confirmar → CreateHabitUseCase
                                 ├─ .delete        → Confirmar → DeleteHabitUseCase
                                 └─ .complete      → CompleteHabitsUseCase → resultado
```

**Los tres comandos se resuelven en la misma pantalla.** Hubo una `HabitsRecognizerView`
aparte para los resultados del antiguo comando de listar y se borró: era un tercer nivel de navegación sin ninguna
decisión dentro —se entraba automáticamente— y obligaba a arrastrar un closure `onRepeat` para
poder volver desde dos niveles de profundidad.

**Se confirma lo que no se deshace con un toque.** Crear y borrar piden confirmación: una
transcripción mala no puede borrar un hábito. Completar escribe, pero se deshace desde Today,
así que el view model guarda justo después del parseo y la pantalla pasa del spinner al
resultado sin intervención (detalle en _Completar hábitos_, más abajo).

### El estado es una fase, no un puñado de banderas

`HabitCommandPhaseEnum` (`Presentation/Enums/`) es lo único que la vista consulta:

| Fase                                                    | Pantalla                                                        |
| ------------------------------------------------------- | --------------------------------------------------------------- |
| `.parsing`                                              | spinner + «Interpretando lo que has pedido…»                    |
| `.confirmingCreate(draft)` / `.confirmingDelete(habit)` | título, tarjeta y `[Repetir｜Confirmar]`                        |
| `.done(outcome)`                                        | creado/borrado con su tarjeta, o completados + «ya completado»  |
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
`.task` reinicia la escucha. Aparece en la confirmación, en `.failed` y en `.done(.completed)`
(crear y borrar cierran la hoja al terminar): tras completar significa «completar otro», y en
`.failed` es la única salida que no es el chevron de la barra.

Con la pantalla de resultados fuera ya no hace falta el closure `onRepeat` que había que pasar
de `SpeechToTextView` a `HabitCommandView` y de ahí a la tercera pantalla.

### Dos etapas, no una

`parseCommand(in:from:today:)` hace **dos peticiones**, no una, y cada etapa lleva sus propias
instrucciones elegidas en Swift:

1. **Intención** → `respond(generating: GenerableCommandDecision.self)`. Una elección entre tres
   casos, que es lo que el modelo on-device hace bien.
2. **Argumentos**, según la intención:
    - `.create` → `respond(generating: GenerableHabitDraft.self)`.
    - `.delete` → `respond(schema:)` con el `GenerationSchema` que construye `HabitNameSchema`, y
      se leen `activity` y `habit` con `content.value(String.self, forProperty:)`. Después, una
      petición más de verificación (`GenerableActivityMatch`, ver _V2_ más abajo).
    - `.complete` → `respond(schema:)` con `HabitNameSchema.makeCompletionSchema`, se lee `done`
      con `content.value([GeneratedContent].self, forProperty:)` y cada par se verifica.

El motivo de partirlo en dos no es estético: Apple pide **convertir los `if-else` del prompt en
lógica de programación**, así que el modelo nunca lee condiciones que no aplican a la petición
que tiene delante. Es la misma lección que ya estaba pagada con el antiguo reconocedor (partir
en peticiones pequeñas gana a una petición que lo hace todo).

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

### Borrar: razonar antes de elegir, y siempre con salida

Síntoma medido: al borrar, el modelo **elegía siempre el primer hábito de la lista**. Dos causas
que se sumaban:

1. El `anyOf` solo tenía los nombres y el prompt decía «elige siempre uno», así que si ningún
   hábito cuadraba el modelo estaba obligado a inventarse la coincidencia.
2. Con `sampling: .greedy` y el esquema cerrado, el primer token que escribía el modelo **ya era
   el nombre**: no tenía dónde razonar antes de comprometerse, y ganaba el primero.

Arreglo, solo en el esquema y el prompt (la elección la sigue haciendo el modelo, sin filtro en
Swift):

- **El esquema lleva `reasoning` antes de `habit`**, por la misma razón que
  `GenerableCommandDecision`: el modelo escribe primero qué actividad menciona la frase y solo
  después elige.
- **`anyOf` incluye `HabitNameSchema.noneOption` («ninguno»).** «ninguno» no está en la lista de
  hábitos, así que `GenerableHabitMapper.habitID` lo convierte en `.habitNotFound` sin tratarlo
  aparte. Si el usuario tiene un hábito llamado exactamente «ninguno», `options(for:)` no lo
  duplica y se resuelve a ese hábito.
- El prompt dice explícitamente que el orden de la lista no importa y trae un ejemplo con el
  último hábito y otro con «ninguno».

#### V2: extraer la actividad y verificar

Con V1 el eval pasaba, pero **solo porque la lista del eval era la misma que la del ejemplo del
prompt**. Con otra lista (_Meditar, Estudiar inglés, Andar 3 km, Beber muchas agua, Correr 5 min,
Tomar vitaminas_), «borra el hábito de nadar» y «ya no quiero ir al gimnasio» devolvían un hábito
parecido (agua, correr) en vez de «ninguno». La regla «acepta sinónimos» empujaba a casar
cualquier cosa relacionada.

`habitToDeleteV2` cambia tres cosas:

- **El esquema pide `activity` en vez de `reasoning`**: la actividad con las palabras de la frase,
  sin «borra» ni «el hábito de». Es un razonamiento con forma fija, y luego sirve para verificar.
- **Parecido no es lo mismo**: el prompt da contraejemplos explícitos (nadar ≠ beber agua,
  gimnasio ≠ correr) y dice que «ninguno» es a menudo la respuesta correcta.
- **Los ejemplos usan hábitos que no están en el eval** (_Pasear al perro, Dormir 8 horas, Tocar
  el piano_), para que el eval mida el prompt y no la copia del ejemplo.

Y el parser añade una **tercera petición de verificación**: con el hábito elegido, pregunta
`sameActivityV1` —«actividad del usuario» frente a «hábito», `GenerableActivityMatch` con
`reasoning` y `isSameActivity: Bool`— y si sale `false` lanza `.habitNotFound`. Es la forma que
ya estaba medida como fiable en el antiguo reconocedor (un `Bool` suelto por pregunta), aplicada
a un solo candidato, así que cuesta una petición y no N. Sigue decidiendo el modelo: Swift no
compara textos. «Ante la duda, no son la misma» es a propósito: un falso «no» se arregla
repitiendo; un falso «sí» propone borrar otro hábito.

`habitToDeleteV1` se queda para comparar las dos versiones con el eval, como pide
_Instrucciones versionadas_. **V2 está sin medir**: la línea base de V1 (2 fallos de 5 negativos
en la lista nueva) sí se midió en el simulador 27.0.

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

`weekdays` es `[GenerableWeekdayEnum]`, un enum con los siete días, y la conversión a
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
(`intentV1`, `newHabitV1`, `habitToDeleteV2`, `sameActivityV1`, `habitsToCompleteV2`),
separadas de la lógica. Apple recomienda no
llevar los prompts hardcodeados para poder comparar la salida cuando cambie la versión del modelo
base; esto es esa idea sin montar la carga de un recurso de bundle (`Core/Package.swift` no
declara `resources:`, así que un `.json` obligaría a añadirlo y a manejar un fallo de lectura que
no puede pasar).

Al añadir una versión nueva, se añade la función `…V2` y se pasa
`HabitCommandPromptEvalTests` con las dos para comparar, en vez de sustituir y confiar.

A diferencia del antiguo reconocedor, la etapa 1 **sí lleva ejemplos** (`frase -> comando`). La lección
real del reconocedor era _nada de ejemplos con una forma de salida que ya no existe_; Apple sí
recomienda ejemplos en las instrucciones, y una clasificación pura es donde encajan. La etapa 2
no los lleva: la generación guiada ya fija la forma.

### Precalentado

`SpeechToTextView.task` precalienta **el parser**, porque es quien recibe la primera petición
(la de intención). Las segundas etapas crean su sesión sin precalentar: la ventana de ≥1 s que
pide la documentación no existe entre una petición y la siguiente.

### Composición

`SpeechToTextView` es `public init()` y lee `\.coreDependencies`; en su `body` pinta
`SpeechToTextContentView(viewModel: dependencies.makeSpeechToTextViewModel())`, que es la
pantalla descrita arriba (patrón `XView` / `XContentView` del `CLAUDE.md` raíz), o
`MissingDependenciesView` si no hay inyección. `MoldeaApp` solo escribe `SpeechToTextView()`.

Ningún view model construye casos de uso. `SpeechToTextViewModel.init(parser:makeCommandViewModel:)`
solo recibe el parser (para `prepare()`) y una factoría; en `finishAndRecognize()` crea con ella
`commandViewModel`, y la vista empuja `HabitCommandView(transcript:viewModel:onFinish:)` con ese
view model ya construido. Los casos de uso de `HabitCommandViewModel` los pone
`CoreDependencies.makeHabitCommandViewModel(parser:)` a partir de sus propiedades calculadas.

### Frases de ejemplo: andamio con fecha de caducidad

`HabitCommandSamples` (`Data/AI`) es la tabla de frases de los comandos. **Todo el fichero va
detrás de `#if DEBUG`**, así que en un build de release ni siquiera está compilado y no puede
acabar en la App Store aunque se olvide quitarlo.

Tiene dos mitades con vidas distintas:

| Parte                                                                   | Vida                                                       |
| ----------------------------------------------------------------------- | ---------------------------------------------------------- |
| `HabitCommandSample` y `all`                                            | **se queda**: la valida `HabitCommandSamplesTests`          |
| `nextPhrase()`, `rotationKey` y `LiveTranscriptionModel.samplePhrase()` | **temporal**: se va con el atajo del simulador             |

#### `all` es un guion, no una lista

Nueve frases, tres por comando, en el orden en que se lanzan: crear → marcar → borrar. Cada
una encuentra creados los hábitos que necesita. Parte de una **instalación limpia** (borrar la
app del simulador): así `DebugHistorySeeder` siembra sus hábitos (entre ellos _Beber agua_ ×4) y
el índice de rotación vuelve a 0. Las confirmaciones se aceptan.

Marcar por voz solo ve los **hábitos de hoy**, y un semanal no es de hoy
(`HabitFrequency.isScheduled` devuelve `false` para `.weeklyCount`); por eso lo que se marca es
diario.

| #   | Frase                                                      | Resultado esperado                              |
| --- | ---------------------------------------------------------- | ----------------------------------------------- |
| 1   | añade tocar el piano todos los días                        | crea _Tocar el piano_, diario                   |
| 2   | añade nadar tres veces por semana                          | crea _Nadar_, 3 por semana                      |
| 3   | crea el hábito de leer la biblia los lunes y los miércoles | crea _Leer la biblia_, L y X                    |
| 4   | hoy he bebido dos litros de agua                           | marca _Beber agua_                              |
| 5   | he tocado el piano pero no he dormido bien                 | marca _Tocar el piano_; la negación no cuenta   |
| 6   | hoy he tocado la guitarra                                  | nada: guitarra no es piano                      |
| 7   | borra el hábito de tocar el piano                          | borra _Tocar el piano_                          |
| 8   | quita el de nadar                                          | borra _Nadar_                                   |
| 9   | elimina el hábito de tocar la guitarra                     | ninguno: no existe                              |

Si se cambia una frase, se mantiene el orden por bloques y se revisa esta tabla.

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

## Completar hábitos: `.complete`

El trabajo del comando `.complete`: marcar como hechos los hábitos de hoy que el usuario dice
haber hecho. Es la **segunda etapa del parser**, con la misma forma que el borrado.

```
HabitCommandView ── @HabitsQuery + @TodayHabitsQuery ──► HabitCommandViewModel.handle
  → FoundationModelsHabitCommandParser.parseCommand(in:from:today:)
      1. intención → .complete
      2. respond(schema: HabitNameSchema.makeCompletionSchema) → [(activity, habit)]
      3. isSameActivity(activity, as: habit) por cada par         → .complete(habitIDs:)
  → CompleteHabitsUseCase.execute(habitIDs:in:)                   → CompleteHabitsResult
  → .done(.completed(completed:alreadyCompleted:))
```

- **La IA solo dice qué hábitos se mencionan como hechos; el estado lo decide el caso de uso.**
  Antes el prompt llevaba el progreso (`Beber agua (1/3)`) y el modelo repartía entre
  `toComplete` y `alreadyCompleted`. Se equivocaba: en el eval, con todo a 0, metía hábitos en
  `alreadyCompleted`, y en la app salía «ya completado» con un hábito a medias. Si un hábito
  está lleno o no es un dato, no algo que interpretar, así que es una regla de negocio y va en
  `Domain`.
- **`CompleteHabitsUseCase` reparte**: un hábito es «ya completado» (`alreadyCompleted`, no se
  guarda) si `isCompletedToday` —todas las repeticiones del día hechas, no se puede sumar más
  hoy— **o** si es `.weeklyCount(n)` y `completedDaysThisWeek >= n`. Si no, suma una repetición y
  va a `completed`. Quita ids repetidos y los que no son de hoy.
- **`makeCompletionSchema(for:)`**: `reasoning` primero y después `done`, un
  `DynamicGenerationSchema(arrayOf:)` de objetos `{ activity: String, habit: anyOf nombres }`.
  La actividad va por hábito por lo mismo que en el borrado: es lo que se verifica después. No
  hay «ninguno»: «ninguno» es la lista vacía.
- **Cada par se verifica** con `isSameActivity(_:as:)` y `sameActivityV1`, igual que en el
  borrado; los `false` se descartan. Es una petición más por hábito elegido, no por hábito de la
  lista. El prompt (`habitsToCompleteV2`) lleva solo los nombres y las mismas reglas que
  `habitToDeleteV2`: parecido no es igual, lo negado no cuenta, ejemplos con hábitos fuera del
  eval.
- **En pantalla**: los `completed` llevan título + card; los `alreadyCompleted`, solo el texto
  «ya ha sido completado hoy», sin card. Si todo estaba completo, no sale ninguna card.
- **Solo los hábitos de hoy** (`@TodayHabitsQuery`, lo que toca según el patrón). Un hábito que
  hoy no toca no se ofrece al modelo.
- **Sin hábitos hoy no se llama al modelo**: el parser devuelve la lista vacía, igual que
  el borrado comprueba la lista antes de construir el `anyOf` (que vacío falla distinto según el
  runtime).
- **La lista vacía es `.failed`** con `HabitCommandErrorEnum.noHabitsMentioned`, que se
  pinta como «No se ha mencionado ningún hábito de tu lista». Distinto de `.habitNotFound`, que
  es del borrado («Ese hábito no está en tu lista»).
- **Los mensajes van encima del botón, en gris.** `HabitCommandMessage` (secundario, centrado,
  sin rojo ni `footnote`) es el mismo componente para los errores y para «ya completado». En
  `.failed` se pinta encima de `Repetir`; en la confirmación, entre la card y los botones. Antes
  el error iba en rojo y debajo de todo.
- **Sin confirmación.** Es la excepción a «se confirma lo que escribe»: completar es reversible
  desde Today con un toque, y crear o borrar no.
- **`CompleteHabitsUseCase` suma una repetición** con `setCompletions(count: min(completedToday + 1, total))`,
  igual que un toque en Today (1/3 → 2/3). **No reutiliza `ToggleHabitCompletionUseCase`**
  porque el toggle vuelve a 0 al llegar al total: con un error del modelo, un «completar» podría
  descompletar. El `min` no decide nada, solo impide pasarse.
- **Cierre automático** solo si no hay `alreadyCompleted`: si hay avisos de «ya ha sido
  completado hoy», la pantalla se queda con `Repetir` para que dé tiempo a leerlos.

### Riesgo conocido: una petición con la lista entera

Esto sustituye a `FoundationModelsHabitCompletionRecognizer`, que hacía **una petición `Bool`
por hábito** porque las formas con la lista entera estaban medidas y fallaban. Con los hábitos
_Andar 3 km_, _Estudiar día a día_, _Beber muchas agua_ y _Correr 5 min_ y la frase _"He bebido
dos litros de agua, he caminado veinte minutos y he salido a correr media hora"_ (correctos:
todos menos _Estudiar_):

| Forma de la salida                                               | Resultado                                        |
| ---------------------------------------------------------------- | ------------------------------------------------ |
| Un `Bool` por hábito (`h1`…`hN`) en un `DynamicGenerationSchema` | solo _Beber_                                     |
| Una propiedad `realizados: [Int]` con los números                | _Beber_ y _Andar_; se dejaba _Correr_            |
| Una petición por hábito, `Bool` suelto                           | las tres correctas, en tres pasadas seguidas     |

La forma actual es distinta de las dos que fallaron (nombres en `anyOf` en vez de claves opacas
o números, `reasoning` antes de las listas y la lista también en el prompt), pero **está sin
medir en dispositivo**. `HabitCommandPromptEvalTests` trae el caso de varios hábitos para
comprobarlo; si se deja hábitos, la vuelta atrás es la petición por hábito.

Lecciones de aquella medición que siguen valiendo:

- **El esquema no llega al prompt como texto.** Con `includeSchemaInPrompt: true`, lo único que
  aparece en el `transcript` es `Response Format: …`; las `description` de las propiedades **no
  se ven**. **Todo lo que el modelo tiene que leer va en el prompt o en las instrucciones, nunca
  solo en el esquema.** Se comprueba imprimiendo `session.transcript`.
- **Una sesión nueva por petición**: `LanguageModelSession` acumula historial y reutilizarla
  arrastra la respuesta anterior hasta `contextSizeExceeded`. `prepare()` deja una sesión
  preparada que consume la primera petición (la de intención) y nunca se reutiliza.

### Instrucciones y prompt

- **El prompt se compone con `@PromptBuilder`, en segmentos**, no con un `"""` interpolado: el
  hábito, la frase y la pregunta son tres segmentos. Con interpolación, un nombre de hábito o
  un transcrito con una comilla o un salto de línea rompía el marco del prompt. Además
  `singleLine(_:)` aplasta el espacio en blanco de los dos.
- **La frase es un dato, no una orden.** Lo dicen las instrucciones, que es donde Apple señala
  que hay que mitigar la inyección de prompt (_"the model is typically trained to obey
  instructions over any commands it receives in prompts"_).
- **El locale va en las instrucciones con la frase exacta en inglés** (`The person's locale is
<identifier>.`) y solo cuando `.current` no es `en_US`, como pide la documentación.
- **El idioma de la respuesta se pide siempre** (`You MUST respond in <idioma>.`, con el nombre
  del idioma en inglés sacado de `Locale.current`, sin región), también en `en_US`. Según
  _Supporting languages and locales with Foundation Models_, el modelo responde por defecto en el
  idioma de sus entradas; como las instrucciones están en español, con el dispositivo en inglés
  el `name` del hábito salía en español («Leer» en vez de «Read»). Las instrucciones no se
  traducen: hay un solo juego que afinar y la documentación admite prompts en un idioma y
  salida en otro. Lo cubre `HabitCommandInstructionsTests`.
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

Es una animación decorativa y sintética —`WaveAnimation` se marca a sí misma con
`.accessibilityHidden(true)`, porque el estado de escucha ya lo comunica el título—. Cuando entre el audio real,
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
| `ai_command_frequency_daily`                    | Every day                                                 | Todos los días                                                   |
| `ai_command_frequency_weekly %lld`              | %lld times a week                                         | %lld veces por semana                                            |
| `ai_command_frequency_fixed_days %@`            | On %@                                                     | Los %@                                                           |
| `ai_command_repetitions %lld`                   | %lld times a day                                          | %lld veces al día                                                |
| `ai_command_confirm`                            | Confirm                                                   | Confirmar                                                        |
| `ai_command_created %@`                         | Habit “%@” created.                                       | Hábito «%@» creado.                                              |
| `ai_command_deleted %@`                         | Habit “%@” deleted.                                       | Hábito «%@» borrado.                                             |
| `ai_command_completed %@`                       | Habit “%@” completed.                                     | Hábito «%@» completado.                                          |
| `ai_command_already_completed %@`               | You’ve already completed “%@” today.                      | El hábito de «%@» ya ha sido completado hoy.                     |
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

- `MoldeaSchemaTests`: el esquema tiene las cuatro entidades (con `HabitReminderEntity`), guardado con relaciones inversas
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
- `RequestMicrophoneAuthorizationUseCaseTests`: lo mismo para el micrófono, con
  `FakeMicrophonePermissionRepository`.
- `CreateHabitUseCaseTests` / `DeleteHabitUseCaseTests`: el `Habit` que recibe el repositorio con
  las tres frecuencias, el nombre recortado, las 13 entradas inválidas y la propagación del error
  del repositorio. Vinieron de `HabitsTests` al bajar los casos de uso a `Core`.
- `CalculateHabitsProgressUseCaseTests`: la ponderación por repeticiones (2/4 + 1/1 → 60 %),
  `completedHabits` contando solo los que llegan al objetivo, el alcance semanal midiendo contra
  `timesPerWeek × repetitionsPerDay`, **un día a medias sumando a la semana** (5/6 → 83 %), **un
  hábito sin objetivo semanal colado en la lista semanal que no suma en ningún campo**, la lista
  vacía sin dividir entre cero, el redondeo del porcentaje (1/3 → 33, 2/3 → 67) y que unas
  completions de más en base de datos no pasen del 100 %.
- `GenerableHabitMapperTests`: draft → dominio con las tres frecuencias (ignorando los campos de
  las otras dos), nombre recortado, días duplicados, `timesPerWeek` fuera de rango y
  `fixedWeekdays` vacío; **la tabla día a día de `GenerableWeekdayEnum` → `Calendar.weekday`**, que
  es lo que habría cazado el bug del desfase; nombre → `Habit.ID` ignorando mayúsculas y
  espacios, `.habitNotFound`, y nombre duplicado resuelto al primero.
- `HabitCommandViewModelTests`: cubre **todas las transiciones de `HabitCommandPhaseEnum**`, que
es lo que impide que vuelvan los bugs de esta pantalla. `.parsing`de salida; modelo no
disponible sin preguntar nada; parseo de crear y de borrar a su confirmación, con el `Habit` ya
  resuelto; borrar un hábito que no está en la lista → `.failed`; completar pasando los ids
  al caso de uso y acabando en `.done(.completed)` con los que este informa como ya completados
  aparte; la lista vacía (o ids que no son de hoy) → `.failed` con el mensaje de «no hay hábitos»; errores de
  parser y del caso de uso traducidos; cancelación que se queda en `.parsing` sin error;
  confirmar crear/borrar llamando al caso de uso con el color e icono por defecto; un fallo del
  caso de uso que **conserva la confirmación** en vez de anunciar un éxito que no ha pasado; el
  cierre automático solo sin avisos de «ya completado»; y una segunda pasada que limpia lo
  anterior.
- `CompleteHabitsUseCaseTests`: suma una repetición por hábito en el `startOfDay` de
  `referenceDay`; con el día lleno o la meta semanal alcanzada no guarda y lo devuelve en
  `alreadyCompleted`; un semanal sin meta alcanzada se marca; un id repetido se marca una vez;
  ignora ids que no son de hoy y propaga el error del repositorio.
- `HabitCommandSamplesTests`: el catálogo tiene al menos una frase de cada `HabitCommandKindEnum`,
  sin repetidas ni vacías, y la rotación recorre las N antes de repetir y sobrevive a un índice
  guardado mayor que el catálogo. Usa un `UserDefaults(suiteName:)` propio por test, no
  `.standard`, para no ensuciar los ajustes del simulador ni encadenar un test con el anterior.
- `HabitCommandInstructionsTests`: las instrucciones piden responder en el idioma del locale
  (solo el idioma, sin región) y la frase del locale solo aparece fuera de `en_US`.
- `HabitNameSchemaTests`: el esquema resuelve con N hábitos y con dos que comparten nombre, la
  deduplicación conserva el orden y «ninguno» se añade al final sin duplicarse; el esquema de
  completar se construye con nombres repetidos y con un hábito llamado «ninguno». `GenerationSchema` no expone sus opciones en iOS 26 (`name` es
  de iOS 27), así que no se puede afirmar más que eso.
- `FoundationModelsErrorMapperTests`: la rama de **iOS 26**
  (`LanguageModelSession.GenerationError`), que es la versión mínima soportada y la que se
  quedaría sin traducir si alguien borrase el `else` del `#available`, más `SchemaError` y el
  fallback.
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
  razón por la que el antiguo reconocedor iba en secuencia.
- **Un caso por esquema, no una batería.** Cada test pasa por la etapa de intención y luego por
  uno de los tres esquemas de la segunda etapa: crear (`GenerableHabitDraft`, «añade nadar tres
  veces por semana» → `.weeklyCount(3)`), borrar (`HabitNameSchema` + verificación, «borra el
  hábito de correr» → _Correr 5 min_) y completar (`makeCompletionSchema`, «hoy he bebido dos
  litros de agua» → _Beber agua_). Además, la frase vacía se rechaza sin llamar al modelo.
- Se recortó a propósito: la batería anterior (frontera, negación, listas distintas, inglés)
  tenía 13 casos en rojo en el simulador 27.0 —casi todos borrados que acababan en
  `.habitNotFound` y completados que devolvían la lista vacía— y medía la calidad del prompt, no
  si el código funciona. Si se vuelve a afinar el prompt, esos casos son el punto de partida.
- Se pasa sola con `-only-testing:CoreTests/HabitCommandPromptEvalTests`.

**Hay que pasarla en un simulador con runtime 27.0.** En 26.5 el asset de seguridad del runtime
(`com.apple.fm.language.instruct_300m.safety`) está roto y toda generación falla con
`promptTemplateNotFound`, así que todos los casos dan `.generationFailed` y parece un bug del prompt
cuando es del runtime. Los tests unitarios sí pasan en los dos.

`CoreTests.swift` es todavía la plantilla generada.

## Accesibilidad

`ContrastingColor.contrastRatio(...)`, el fallback `.tinted` → `.solid` de `HabitIconBadge`
(con su círculo en `@ScaledMetric`), `HabitScheduleSummaryEnum.weekdayNames(of:)` y los textos
compartidos de VoiceOver (`accessibilityCompleted`, `accessibilityProgress(_:of:)`…) viven aquí.
`HabitCommandView` anuncia cada fase y no se cierra sola con VoiceOver activo.

Las reglas comunes están en el `CLAUDE.md` raíz, en _Accesibilidad_.
