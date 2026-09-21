
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

**Habit**

| Campo      | Tipo      |
| ---------- | --------- |
| id         | uuid (PK) |
| name       | string    |
| color      | string    |
| icon       | string    |
| created_at | date      |
| updated_at | date      |

**HabitSchedule**

| Campo               | Tipo                                           |
| ------------------- | ---------------------------------------------- |
| id                  | uuid (PK)                                      |
| habit_id            | uuid (FK → Habit)                              |
| frequency_type      | enum (`daily` / `weekly_count` / `fixed_days`) |
| times_per_week      | int (solo si `weekly_count`)                   |
| fixed_weekdays      | set (solo si `fixed_days`)                     |
| repetitions_per_day | int                                            |

**HabitCompletion**

| Campo            | Tipo              |
| ---------------- | ----------------- |
| id               | uuid (PK)         |
| habit_id         | uuid (FK → Habit) |
| day              | date              |
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
- **Foundation Models** — framework de modelos de lenguaje on-device de Apple Intelligence; permite responder preguntas en lenguaje natural sobre los hábitos del usuario, apoyándose en herramientas (`Tool`) que consultan los datos de la app.
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
│   ├── MoldeaApp.swift        # @main: composición de la navegación (el ModelContainer aún no está)
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

`Moldea/` es un *filesystem-synchronized group* en el `.xcodeproj`. Xcode descubre solo los
paquetes locales que hay dentro de `Package/`; cada uno aparece en el proyecto con dos piezas:

1. una excepción de pertenencia (`membershipExceptions`) para que sus fuentes **no** se
   compilen dentro del target de la app, y
2. una `XCSwiftPackageProductDependency` que enlaza su producto al target `Moldea`.

Si añades un paquete nuevo a mano, necesita las dos cosas o no compilará bien.

### Configuración común de los paquetes

Todos los `Package.swift` son iguales salvo el nombre y las dependencias:

- `swift-tools-version: 6.4`
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
4. Enlázalo al target `Moldea` (Xcode lo detecta solo; el enlace se hace en *General → Frameworks,
   Libraries, and Embedded Content*).
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
- Solo el target `Moldea` importa features. `MoldeaApp` es el punto de composición: instancia
  los routers, decide qué vista va en cada `MainTab` y qué contenido va en la hoja inferior de
  la tab bar (hoy `SpeechToTextView` de `Core`, con sus `presentationDetents`). El
  `ModelContainer` se creará aquí cuando entre SwiftData.

### Las tres capas de un paquete de feature

```
Sources/<Feature>/
├── Domain/         # el qué: modelos, casos de uso, protocolos de repositorio
├── Data/           # el cómo: implementaciones de repositorio, SwiftData, red, defaults
└── Presentation/   # la UI: vistas, view models, textos, recursos
```

Dirección de las dependencias: `Presentation → Domain ← Data`. `Domain` es el centro y no
importa a las otras dos. `Presentation` nunca habla con `Data` directamente; habla con los
protocolos que declara `Domain`, y la implementación se inyecta desde fuera. Eso es lo que
permite testear un view model sin base de datos.

Los `@Model` de SwiftData (`Habit`, `HabitSchedule`, `HabitCompletion`, `HabitReminder`) van en
`Core/Domain`, no en `Habits`: los consumen `Today`, `Statistics`, `Habits` y, más adelante, los
widgets y los App Intents. El `ModelContainer` se crea una sola vez, en `MoldeaApp`, y se
propaga con `.modelContainer(_:)`.

### MVVM

- **Model** — los tipos de `Domain`. Sin lógica de UI, sin `import SwiftUI`.
- **View** — `struct` SwiftUI. Pinta estado y manda intenciones al view model. Sin lógica de
  negocio, sin acceso directo a repositorios.
- **ViewModel** — clase `@Observable` que traduce el modelo a lo que la vista necesita y expone
  métodos por intención (`load()`, `toggleCompletion(for:)`), no *setters* sueltos.

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
- Las dependencias entran por el `init`, siempre como protocolo. Nada de *singletons*.
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

## Notas de trabajo

- Este fichero sirve como recordatorio de contexto para las próximas conversaciones sobre este proyecto.
- Cuando se pregunte sobre APIs, frameworks o patrones de Swift/SwiftUI, se debe verificar contra la documentación oficial de Apple (usando búsqueda web cuando sea necesario) antes de responder.
