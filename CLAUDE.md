# Contexto del Proyecto: App de Hábitos (Apple Coding Academy Hackathon)

## Datos generales

- **Evento:** Hackathon de Apple Coding Academy
- **Fechas:** 18 al 27 de septiembre
- **Objetivo del proyecto:** Construir una app de seguimiento de hábitos en Swift, con la intención de publicarla en la App Store.

## Criterios y restricciones clave

1. **Cobertura del SDK nativo:** El objetivo de la hackathon es usar la mayor cantidad posible de funciones del SDK nativo de Apple (SwiftUI, frameworks del sistema, APIs de plataforma, etc.), evitando dependencias externas innecesarias.
2. **Comprensión profunda del código:** No basta con que el código funcione; hay que entender bien cómo y por qué funciona cada pieza.
3. **Fuente de información:** Toda consulta técnica debe responderse basándose en la **documentación oficial de Apple** (Apple Developer Documentation, Human Interface Guidelines, WWDC sessions, etc.), no en fuentes de terceros ni en conocimiento general no verificado.
4. **Publicación real:** La app debe quedar en condiciones de subirse a la App Store (cumplir guidelines de revisión, buenas prácticas de UX/UI de Apple, etc.).

## Identidad de la app

**Nombre:** Moldea - Hábitos a tu manera!

**Descripción (App Store):**

Olvídate de las apps de hábitos que te obligan a seguir su ritmo. Moldea se adapta al tuyo.
Elige exactamente qué días quieres repetir cada hábito, durante cuánto tiempo, y deja que la app haga el resto. Con estadísticas claras verás tu progreso real, no promesas vacías. Y con integración de Siri e IA, crear, ajustar o revisar tus hábitos es tan fácil como decirlo en voz alta.
Nada de plantillas rígidas ni "rachas perfectas" imposibles de mantener. Moldea tus hábitos, no al revés.

✨ Flexibilidad total — tú decides días y duración
📊 Estadísticas que sí importan — progreso real, sin adornos
🎙️ Siri + IA — controla tus hábitos hablando
🧩 Se adapta a tu vida — no al revés

Moldea. Porque tus hábitos son tuyos.

**Diseño (Figma):** https://www.figma.com/design/S4UlZp7Ikypg3WRWWxhjIh/Flexible-Habit-Tracker?node-id=15-2&p=f&t=MTJ6fJPO19RDuJV5-0

**Icono de la app:** https://drive.google.com/drive/folders/1m4JJZZGoMo5Rvwd1hlt0_e785OP6PFeE?usp=drive_link

**Prototipo funcional:** https://drive.google.com/file/d/1pTxkfHKvoHlJ3O5KQJaAOtDO70gx70Bb/view?usp=drive_link

### Implicaciones funcionales que se derivan de la descripción

- **Días y duración personalizados por hábito:** cada hábito necesita su propio patrón de repetición (no un esquema global fijo) y una duración/objetivo configurable.
- **Estadísticas de progreso real:** se necesita un sistema de tracking histórico y visualización de datos (Swift Charts es el candidato natural del SDK nativo).
- **Integración con Siri e IA:** implica explorar App Intents / SiriKit para creación y consulta de hábitos por voz, y posiblemente Apple Intelligence / on-device ML donde aplique.
- **Sin "rachas perfectas" forzadas:** el modelo de datos y la UX deben evitar la lógica clásica de streaks rígidos; hay que diseñar métricas de progreso más flexibles y honestas.

## Modelo de datos

Cuatro tablas: `Habit` (datos fijos), `HabitSchedule` (patrón de repetición, 1:1 con `Habit`), `HabitCompletion` (log de cada repetición marcada como hecha, 1:N) y `HabitReminder` (avisos configurados, 1:N, independientes del schedule).

**Estado de implementación:** `Habit`, `HabitSchedule` y `HabitCompletion` están implementadas como entidades de SwiftData (`HabitEntity`, `HabitScheduleEntity`, `HabitCompletionEntity`, en `Core/Data/Model`). Solo `Habit` y `HabitSchedule` tienen además entidad de dominio; la de `HabitCompletion` se creará cuando `Today` y `Statistics` la necesiten. `HabitReminder` está pendiente.

Las tablas describen el modelo lógico. Cómo se materializa en código (entidad de dominio frente a entidad de SwiftData) está en _Persistencia y dominio_, más abajo.

**Habit**

| Campo      | Tipo                                                 |
| ---------- | ---------------------------------------------------- |
| id         | uuid (PK, único)                                     |
| name       | string                                               |
| color      | string — hex `#RRGGBB` en mayúsculas (ver _Colores_) |
| icon       | string — nombre de SF Symbol                         |
| active     | bool                                                 |
| created_at | date                                                 |
| updated_at | date                                                 |

**HabitSchedule**

| Campo               | Tipo                                                                                      |
| ------------------- | ----------------------------------------------------------------------------------------- |
| habit_id            | uuid (FK → Habit)                                                                         |
| frequency_type      | enum (`daily` / `weeklyCount` / `fixedDays`)                                              |
| times_per_week      | int (solo si `weeklyCount`)                                                               |
| fixed_weekdays      | `[Int]` con valores de `Calendar.weekday`: 1 = domingo … 7 = sábado (solo si `fixedDays`) |
| repetitions_per_day | int, siempre presente, mínimo 1                                                           |

`HabitSchedule` no tiene `id` propio: es 1:1 con `Habit` y nunca se referencia por separado.

**HabitCompletion**

| Campo            | Tipo              |
| ---------------- | ----------------- |
| id               | uuid (PK, único)  |
| habit_id         | uuid (FK → Habit) |
| day              | date (con índice) |
| repetition_index | int               |
| completed_at     | datetime          |

**HabitReminder**

| Campo                   | Tipo               |
| ----------------------- | ------------------ |
| id                      | uuid (PK)          |
| habit_id                | uuid (FK → Habit)  |
| time                    | time (hora:minuto) |
| weekday                 | weekday (opcional) |
| enabled                 | bool               |
| notification_identifier | string             |
| created_at              | date               |
| updated_at              | date               |

## SDK nativo a utilizar

- **SwiftData** — framework de persistencia de Apple; guarda y consulta el modelo de datos de la app (hábitos, horarios, registros de completado, recordatorios) sin depender de librerías externas.
- **Swift Charts** — framework de visualización de datos de Apple; se usa para representar gráficamente las estadísticas de progreso de los hábitos.
- **App Intents** — framework que expone acciones de la app al sistema; permite que Siri cree/consulte hábitos por voz, y es el mecanismo que usan los botones interactivos dentro de los widgets para ejecutar acciones sin abrir la app.
- **Foundation Models** — framework de modelos de lenguaje on-device de Apple Intelligence; interpreta lo que el usuario dice en voz alta como un comando (crear un hábito, borrarlo o listar los completados) con `@Generable`, `DynamicGenerationSchema` y `LanguageModelSession`. El detalle está en el `CLAUDE.md` de `Core`, en _Comandos de voz_.
- **UserNotifications** — framework de notificaciones locales del sistema; programa los recordatorios de hábitos para que se disparen aunque la app no esté abierta.
- **BackgroundTasks** — framework de ejecución en segundo plano; despierta la app periódicamente para mantener sincronizados los recordatorios pendientes con lo que hay guardado en la base de datos.
- **WidgetKit** — framework para crear widgets del sistema; se usa para el widget de pantalla de bloqueo (progreso del día) y el widget interactivo de pantalla principal (checklist de hábitos).
- **SwiftUI** — framework de interfaz declarativa de Apple; construye tanto las pantallas de la app como las vistas de los widgets.
- **App Groups** — mecanismo de contenedor compartido entre la app y sus extensiones; permite que la app principal y los widgets lean y escriban los mismos datos.

## Estructura del proyecto

```
Moldea/
├── CLAUDE.md                  # este fichero
├── Moldea.xcodeproj
├── Moldea/                    # target de la app
│   ├── MoldeaApp.swift        # @main: ModelContainer, repositorio y composición de la navegación
│   ├── Assets.xcassets
│   └── Package/               # todos los paquetes locales
│       ├── Core/
│       ├── Navigation/
│       ├── Today/
│       ├── Statistics/
│       ├── Habits/
│       └── Settings/
├── MoldeaTests/
└── MoldeaUITests/
```

Cada paquete tiene su propio `CLAUDE.md` con el detalle del módulo. Antes de tocar un paquete,
léelo.

### Cómo están enganchados los paquetes

`Moldea/` es un _filesystem-synchronized group_ en el `.xcodeproj`. Xcode descubre solo los
paquetes locales que hay dentro de `Package/`; cada uno aparece en el proyecto con dos piezas:

1. una excepción de pertenencia (`membershipExceptions`) para que sus fuentes **no** se
   compilen dentro del target de la app, y
2. una `XCSwiftPackageProductDependency` que enlaza su producto al target `Moldea`.

Si añades un paquete nuevo a mano, necesita las dos cosas o no compilará bien.

### Configuración común de los paquetes

Todos los `Package.swift` son iguales salvo el nombre y las dependencias:

- `swift-tools-version: 6.2`
- `platforms: [.iOS(.v26)]`
- `swiftSettings: [.enableUpcomingFeature("ApproachableConcurrency")]` en target y test target
- un `.library` con el mismo nombre del paquete y un `.testTarget` `<Nombre>Tests`

El target de la app no fija `IPHONEOS_DEPLOYMENT_TARGET`, así que hereda el del SDK (27.0).
Los paquetes declaran iOS 26 como mínimo.

### Crear un paquete nuevo

1. Copia la estructura de un paquete de feature existente (`Today` es el más limpio).
2. Ajusta nombre en `Package.swift`, carpeta `Sources/<Nombre>/`, `Tests/<Nombre>Tests/`.
3. Crea `Presentation/Enums/<Nombre>TextsEnum.swift` y
   `Presentation/Resources/Localizable.xcstrings`.
4. Enlázalo al target `Moldea` (Xcode lo detecta solo; el enlace se hace en _General → Frameworks,
   Libraries, and Embedded Content_).
5. Escribe su `CLAUDE.md`.

## Arquitectura

**Modularización por features + MVVM dentro de cada feature.** La regla de oro: una feature no
conoce a otra feature. Todo lo compartido baja a `Core`; todo lo que compone la app sube al
target `Moldea`.

### Mapa de dependencias

```
        Moldea (app target)
        ├── compone todo y es el único que conoce a todos
        │
   ┌────┴────┬──────────┬────────┬──────────┐
 Today   Statistics   Habits   Settings   Navigation
   └────────┴──────────┴────────┴──────────┘
                      │
                    Core
```

- `Core` no depende de nadie.
- `Navigation` depende de `Core` y de nada más: expone contenedores genéricos sobre
  `Content: View`, así que no conoce las pantallas que pinta.
- Las features dependen como mucho de `Core`. **Nunca entre ellas.** Si dos necesitan lo mismo,
  eso pertenece a `Core`.
- Solo el target `Moldea` importa features. `MoldeaApp` es el punto de composición: crea el
  `ModelContainer` y el repositorio, instancia los routers y decide qué vista va en cada
  `MainTab`.

### Las tres capas de un paquete

```
Sources/<Paquete>/
├── Domain/         # el qué: entidades, casos de uso, protocolos de repositorio
├── Data/           # el cómo: implementaciones de repositorio, SwiftData, recursos, red
└── Presentation/   # la UI: vistas, view models, textos, recursos
```

Dirección de las dependencias: `Presentation → Domain ← Data`. `Domain` es el centro y no
importa a las otras dos. `Presentation` nunca habla con `Data` directamente; habla con los
protocolos que declara `Domain`, y la implementación se inyecta desde fuera. Eso es lo que
permite testear un view model sin base de datos.

`Core` sigue la misma estructura de tres capas: es el sitio donde viven lo compartido por
varias features —entidades de dominio, repositorios y su persistencia— y no solo utilidades.

### Persistencia y dominio (arquitectura estricta)

Decisión: **Clean Architecture estricta**. `Domain` no depende de ningún framework de
persistencia, así que los `@Model` de SwiftData **no** son entidades de dominio. Se ha elegido
esto sobre la alternativa pragmática (usar el `@Model` como entidad y ahorrarse el mapeo)
porque mantiene `Domain` puro y porque los `@Model` no son `Sendable`: el compilador marca su
conformidad como `unavailable` y SwiftData indica usar un `ModelActor` o el
`persistentModelID`. Por la frontera del repositorio solo cruzan valores.

```
Core/
├── Domain/
│   ├── Entities/      Habit, HabitSchedule, HabitFrequency   (structs puros, Sendable)
│   └── Repository/    HabitRepository                        (protocolo)
└── Data/
    ├── Model/         HabitEntity, HabitScheduleEntity,
    │                  HabitCompletionEntity, FrequencyType   (@Model, internal)
    ├── Mappers/       HabitMapper                             (Entity ⇄ dominio)
    ├── MoldeaSchema.swift
    └── SwiftDataHabitRepository.swift                         (@ModelActor)
```

- **Nomenclatura.** "Entity" sin más es lo que persiste SwiftData (`HabitEntity`); el objeto
  de dominio se llama como el concepto (`Habit`). Un `Habit` es un struct inmutable (`let`):
  para editarlo se crea otro con `updatedAt` nuevo.
- **Los `*Entity` son `internal` a `Core`.** Nadie fuera de `Core` los ve. Por eso el
  repositorio también vive en `Core`: es lo que necesitan varias features y los widgets.
  `MoldeaSchema` (público) es el único punto de verdad del esquema y crea el `ModelContainer`
  (`makeModelContainer(inMemory:)`; `inMemory: true` para tests y previews).
- **Frecuencia sin estados imposibles.** `HabitFrequency` es un enum con valores asociados
  (`.daily`, `.weeklyCount(timesPerWeek:)`, `.fixedDays(weekdays:)`), así que no se puede
  representar un `.daily` con `timesPerWeek`. `HabitScheduleEntity` guarda los campos sueltos
  (`FrequencyType`, `timesPerWeek?`, `fixedWeekdays?`) y `HabitMapper` los convierte. Si los
  datos guardados son incoherentes (p. ej. `weeklyCount` sin `timesPerWeek`),
  `HabitMapper.toDomain` lanza `HabitMappingError`; no rellena valores por defecto. El mapper
  solo valida estructura, no reglas de negocio.
- **`id` propio.** `HabitEntity.id` (`UUID`, único) es la identidad de dominio; nada depende
  del `PersistentIdentifier` de SwiftData.
- **El repositorio** (`HabitRepository`, `Sendable`) recibe y devuelve solo tipos de dominio.
  `SwiftDataHabitRepository` es un `@ModelActor` (contexto propio, fuera del hilo principal) y
  hace `rollback()` si el `save()` falla para no dejar la entidad pendiente en el contexto.
  Expone `create`, `delete`, `setActive` y `update`; la lectura se añade cuando `Today` y
  `Statistics` la necesiten.

### Casos de uso

Viven en el `Domain` de la feature que los usa, y **bajan a `Core/Domain/UseCases` en cuanto los
necesita un segundo módulo**, igual que cualquier otra cosa compartida. `CreateHabitUseCase` y
`DeleteHabitUseCase` ya están en `Core`: los usan la pantalla de creación de `Habits` y la capa
de comandos de voz de `Core`. Son un protocolo (`CreateHabitUseCase`) más una implementación
(`DefaultCreateHabitUseCase`) que recibe el repositorio y, para poder testearse, el generador de
`UUID` y el reloj como closures.

**Norma: el caso de uso recibe los datos sueltos y construye él los objetos de dominio; el
view model no conoce `Habit` ni ningún objeto de entrada.**

```swift
func execute(name: String, color: String, icon: String,
             frequency: HabitFrequency, repetitionsPerDay: Int) async throws
```

`CreateHabitUseCase` y `UpdateHabitUseCase` comparten esa forma (`update` añade `id` delante);
`DeleteHabitUseCase` y `SetHabitActiveUseCase` solo necesitan el `id` del hábito.

El caso de uso valida (es el único sitio con reglas de negocio) y llama al repositorio.
`CreateHabitUseCase` genera `id` y fechas con `makeID`/`now` como closures, para poder
testearse; `UpdateHabitUseCase` conserva el `id` que recibe y usa `.now` directamente, porque
solo genera `updatedAt`. La validación (nombre recortado, color, repeticiones, frecuencia) es
la misma para crear y editar: vive en `HabitValidator`, que usan los dos casos de uso y lanza
`CreateHabitError`. Lo que el view model sí hace es traducir el estado de la UI a esos
parámetros (p. ej. su enum de frecuencia a `HabitFrequency`). `BaseViewModel.perform` muestra
cualquier error, también los de validación, como el mensaje genérico, porque la UI ya evita las
entradas inválidas (`canSave` es solo comodidad).

Flujo de guardado, en `HabitFormViewModel.save()`: con un `id` (modo edición) llama a
`UpdateHabitUseCase`; sin él, a `CreateHabitUseCase`.

```
Botón Guardar → HabitFormViewModel.save()
  → UpdateHabitUseCase.execute(id:...)     valida, construye HabitSchedule       (editar)
  → CreateHabitUseCase.execute(...)        valida, genera id y fechas, construye Habit   (crear)
  → HabitRepository.update / .create       protocolo de Core/Domain
  → SwiftDataHabitRepository               @ModelActor: HabitMapper.apply/makeEntity + save()
```

`delete` y `setActive` siguen el mismo patrón, sin formulario: la vista pide la acción
(swipe), el view model llama a su caso de uso, y este al repositorio.

### Composición

`MoldeaApp` crea el `ModelContainer` una sola vez con `MoldeaSchema.makeModelContainer()`, lo
propaga con `.modelContainer(_:)` y crea `SwiftDataHabitRepository(modelContainer:)`. Las
features reciben el repositorio como `any HabitRepository` en su `init` público y construyen sus
casos de uso por dentro, así que sus tipos de `Data` y de `Domain` siguen siendo `internal`.

### Colores de los hábitos

El color de un hábito se guarda como **hex `#RRGGBB` en mayúsculas** (`Habit.color`). Es un
contrato: cualquier módulo pinta un hábito con `HexColorConverter.color(fromHex:)` (en
`Core/Presentation/Converters`) sin depender de `Habits`.

Por qué hex y no otra cosa:

- `Color` de SwiftUI **no es `Codable`**, así que SwiftData no puede guardarlo.
- Guardar la clave de la paleta (`"blue"`) obligaría a `Today`, `Statistics` y los widgets a
  conocer `HabitPaletteColor`, que es de `Habits`, y las features no se conocen entre sí.
- La pantalla de creación tiene un `ColorPicker` nativo que devuelve cualquier color; con hex
  no hay que distinguir entre colores de paleta y personalizados.

Cómo funciona:

- `HabitPaletteColor` (en `Habits`) es la paleta de 13 colores; cada caso lleva su `hex`, y
  `color` se calcula a partir de él, así que el hex es la única fuente de verdad. Orden:
  `red, orange, yellow, green, mint, teal, blue, indigo, purple, pink, gray, brown, stone`. Los
  valores no son los colores del sistema, sino los definidos para la app.
- El view model guarda `selectedColorHex` y expone `selectedColor: Color` derivado. **El color
  por defecto es el gris de la paleta** (`#5B6470`), no `Color.accentColor`.
- Cuando el `ColorPicker` nativo devuelve un `Color`, `HexColorConverter.hex(from:in:)` lo
  convierte con `Color.resolve(in:)`, que necesita un `EnvironmentValues` (la vista lo obtiene
  con `@Environment(\.self)`). `Color.Resolved` usa sRGB de rango extendido, así que el
  componente se recorta a 0...1 antes de pasar a 0...255. Sin canal alfa.
- Un color es "personalizado" si su hex no está en la paleta.
- `HexColorConverter.color(fromHex:)` devuelve `nil` si el texto no es válido; `HabitPaletteColor`
  y el view model tienen `.gray` como red de seguridad. Un test garantiza que los 13 hex de la
  paleta parsean, así que el fallback no debería usarse nunca.
- `CreateHabitUseCase` valida el formato: `#` más 6 dígitos hexadecimales **ASCII**.
  `Character.isHexDigit` también acepta dígitos de ancho completo (`Ａ`–`Ｆ`), que
  `HexColorConverter` rechazaría; hay un test que lo cubre.

Contrapartidas conocidas:

- Con un hex fijo se pierde la adaptación automática de los colores del sistema a modo
  claro/oscuro y a contraste aumentado. Hay que revisar la legibilidad en modo oscuro.
- `stone` (`#DAD7D0`) tiene poco contraste en modo claro (≈1,3:1 calculado a mano sobre
  blanco, cuando lo habitual para gráficos es 3:1): el icono se ve muy poco. Se aceptó de
  momento y queda por revisar.
- El paso por 8 bits al convertir un `Color` puede acabar en el hex exacto de un color de la
  paleta; entonces se marca ese círculo. No se ha comprobado en pantalla.

### MVVM

- **Model** — los tipos de `Domain`. Sin lógica de UI, sin `import SwiftUI`.
- **View** — `struct` SwiftUI. Pinta estado y manda intenciones al view model. Sin lógica de
  negocio, sin acceso directo a repositorios.
- **ViewModel** — clase `@Observable` que traduce el modelo a lo que la vista necesita y expone
  métodos por intención (`load()`, `toggleCompletion(for:)`), no _setters_ sueltos.

```swift
@Observable
@MainActor
final class HabitsListViewModel {
    private(set) var habits: [Habit] = []
    private let repository: any HabitRepository   // protocolo de Domain

    init(repository: any HabitRepository) {
        self.repository = repository
    }

    func load() async {
        habits = await repository.fetchAll()
    }
}
```

Reglas:

- Un view model por pantalla, en `Presentation`, nombrado `<Pantalla>ViewModel`.
- `@Observable`, nunca `ObservableObject`. **Nada de Combine**: `async`/`await` y observación.
- Estado publicado con `private(set)`; se cambia desde métodos del propio view model.
- Las dependencias entran por el `init`, siempre como protocolo. Nada de _singletons_.
- En la vista, `@State private var viewModel = ...` cuando la vista lo posee; por parámetro
  cuando lo posee quien la presenta.
- Vistas pequeñas y privadas dentro del mismo fichero cuando son de un solo uso; `internal`
  dentro del paquete cuando se comparten entre ficheros del módulo (`WaveAnimation` en `Core`).
- Nada de `@MainActor` a mano en la vista: ya lo es. Sí en el view model.

### Navegación

Dos niveles, ambos en `Navigation` y ambos con routers `@Observable`:

- `AppRouter` / `AppFlow` — flujo raíz (`.splash`, `.tabView`), renderizado por `RootView`.
- `TabRouter` / `MainTab` — pestaña seleccionada, renderizada por `MainTabsView`.

Una feature no navega a otra feature por sí misma: publica la intención (callback o router del
entorno) y decide el nivel de composición.

### Textos

Cada paquete tiene **un** `Localizable.xcstrings` en `Presentation/Resources/` y **un** enum
`<Paquete>TextsEnum` en `Presentation/Enums/` como único punto de acceso. Todos resuelven
contra `Bundle.module`; sin eso el string se buscaría en el bundle de la app. Idiomas: `en`
(origen) y `es`. Un texto que use más de un módulo se mueve a `CoreTextsEnum`.

### Tests

Swift Testing (`import Testing`, `@Test`, `#expect`) para lógica; XCUIAutomation para UI. Cada
paquete trae su test target. Lo que se testea de verdad son los view models y los casos de uso,
que por eso reciben sus dependencias por protocolo.

- **Fakes con `actor`** para repositorios y casos de uso falsos: los protocolos son `Sendable`.
- **Persistencia:** los tests de `Core` usan `MoldeaSchema.makeModelContainer(inMemory: true)`
  y leen lo guardado con **otro** `ModelContext(container)`. **Hay que conservar el contenedor
  en una variable** mientras se use su contexto: si se encadena (`makeModelContainer(...).mainContext`)
  el contenedor se libera y el proceso de tests se cae (`SIGILL`) sin ningún ✘ visible; el
  síntoma es que los tests empiezan y nunca terminan.
- Los `*Entity` son `internal`, así que solo se ven con `@testable import Core`.
- **Destino del simulador:** los paquetes exigen iOS 26, así que hay que elegir un simulador con
  runtime 26.x. Con `xcodebuild -showdestinations -scheme <Paquete>` se ven los válidos; un
  `iPhone` con iOS 18.5 (que sí sale en `simctl`) no sirve.
- El rollback del repositorio ante un `save()` fallido no tiene test.

## Notas de trabajo

- Este fichero sirve como recordatorio de contexto para las próximas conversaciones sobre este proyecto.
- Cuando se pregunte sobre APIs, frameworks o patrones de Swift/SwiftUI, se debe verificar contra la documentación oficial de Apple (usando búsqueda web cuando sea necesario) antes de responder.
