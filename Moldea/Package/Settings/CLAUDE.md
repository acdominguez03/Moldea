# Settings

Paquete de la feature **Configuración**: la pestaña de ajustes y preferencias de Moldea.

Contiene la pantalla raíz `SettingsView`: la sección de notificaciones (permiso del sistema,
toggle de avisos y recordatorios por hábito) y su hoja de edición de recordatorio. La capa
`Data` sigue vacía: la persistencia de preferencias vive en `Core` (`UserDefaultsRepository`),
no aquí.

Depende de `Core` (`.package(path: "../Core")`), de donde salen las entidades de dominio
(`Habit`, `HabitReminder`…), `HabitRepository`, `UserDefaultsRepository`,
`RequestNotificationAuthorizationUseCase` y `BaseViewModel`.

## Configuración

- `swift-tools-version: 6.4`
- Plataforma mínima: `.iOS(.v26)`
- `swiftSettings`: `.enableUpcomingFeature("ApproachableConcurrency")` en target y test target
- Dependencia: `.package(path: "../Core")`

## Estructura

```
Sources/Settings/
├── DI/SettingsDependencies.swift          # contenedor + @Entry \.settingsDependencies
├── Data/                                  # vacía: la persistencia vive en Core
├── Domain/
│   └── UseCases/
│       ├── GetIsNotificationsEnabledUseCase.swift
│       ├── SetIsNotificationsEnabledUseCase.swift
│       ├── GetIsDailySummaryEnabledUseCase.swift
│       ├── SetIsDailySummaryEnabledUseCase.swift
│       ├── GetIsNotificationPermissionAllowedUseCase.swift
│       ├── GetMicrophonePermissionStatusUseCase.swift
│       ├── SetHabitReminderEnabledUseCase.swift
│       └── UpdateHabitReminderUseCase.swift
└── Presentation/
    ├── SettingsView.swift
    ├── SettingsViewModel.swift
    ├── HabitReminderSheet.swift
    ├── HabitReminderSheetViewModel.swift
    ├── Components/
    │   ├── HabitReminderRow.swift
    │   └── PermissionDisabledRow.swift
    ├── Enums/
    │   └── SettingsTextsEnum.swift
    └── Resources/
        └── Localizable.xcstrings
Tests/SettingsTests/
```

Es la misma estructura de tres capas que `Core` y que el resto de paquetes de feature
(`Today`, `Statistics`, `Habits`). Las vistas y los modelos de vista van en `Presentation`.

## Pantalla

`SettingsView` es el punto de entrada público del paquete: un `NavigationStack` con una `List`
agrupada y el título de pantalla en grande. La compone el target `Moldea` en el caso `.settings`
de `MainTabEnum` como `SettingsView()`: es `public init()`, lee `\.settingsDependencies` y pinta
`SettingsContentView(viewModel:makeReminderSheetViewModel:)` (patrón `XView` / `XContentView`
del `CLAUDE.md` raíz), o `MissingDependenciesView` si no hay inyección.

`DI/SettingsDependencies.swift` recibe un `CoreDependencies` y construye los casos de uso propios
del paquete a partir de sus repositorios: `makeSettingsViewModel()` con
`GetIsNotificationsEnabledUseCase`, `SetIsNotificationsEnabledUseCase`,
`GetIsNotificationPermissionAllowedUseCase`, `RequestNotificationAuthorizationUseCase` (de `Core`)
y `DefaultSetHabitReminderEnabledUseCase` (que además de guardar el ajuste cancela y reprograma las
notificaciones de ese hábito); y `makeHabitReminderSheetViewModel(habit:)` con
`DefaultUpdateHabitReminderUseCase`. `SettingsView` pasa esa factoría a `SettingsContentView`
por `init`, que la usa al abrir la hoja; la subvista no lee el entorno. Así sus tipos de
`Domain` siguen siendo `internal`.

## Permiso de notificaciones

La sección de notificaciones se pinta de una forma u otra según
`settingsViewModel.isNotificationPermissionAllowed`:

- **Permiso concedido**: el `Toggle` de "Permitir avisos" (preferencia de producto,
  `isNotificationsEnabled` en `Core`) y, si hay hábitos con recordatorio activo, la lista de
  `HabitReminderRow` por hábito.
- **Permiso denegado**: en su lugar, una única fila —`PermissionDisabledRow`—
  con el icono `bell.slash.fill` dentro de `HabitIconBadge` (de `Core`, en rojo), el título
  "Notificaciones deshabilitadas" y una descripción que invita a tocarla. Al tocarla, abre
  `UIApplication.openNotificationSettingsURLString` con `@Environment(\.openURL)`.

- **Resumen del día**: una segunda sección, solo visible con "Permitir avisos" activo y hábitos
  con recordatorio, con un `Toggle` (`isDailySummaryEnabled`, `UserDefaults` como
  `isNotificationsEnabled`) y un pie que dice la hora (21:30, fija). Al cambiarlo,
  `SetIsDailySummaryEnabledUseCase` guarda y llama a `syncReminders()`; qué hábitos cuentan y
  cuándo se quita lo decide `ReminderPlanner` en `Core`. Apagado por defecto.
- `SetIsNotificationsEnabledUseCase` ya no recibe la lista de hábitos: al encender hace una sola
  sincronización, que programa los avisos de los hábitos y el de la noche.

Estas dos preferencias son independientes por diseño (razonamiento completo en el `CLAUDE.md`
de `Core`, en `PreferenceKeyEnum`): el permiso del sistema (`isNotificationPermissionAllowed`) no es
lo mismo que "quiero avisos de mis hábitos" (`isNotificationsEnabled`).

`isNotificationPermissionAllowed` se resincroniza con el sistema real, no solo con lo último
guardado, mediante `@Environment(\.scenePhase)`: cuando la escena pasa a `.active` (p. ej. al
volver de Ajustes), `SettingsView` llama a `settingsViewModel.refreshNotificationPermissionStatus()`,
que vuelve a invocar `RequestNotificationAuthorizationUseCase.execute()`. Esto funciona porque
`UNUserNotificationCenter.requestAuthorization` no repite el diálogo si el usuario ya respondió:
solo devuelve el estado actual. **Importante:** no basta con releer `UserDefaults`
(`GetIsNotificationPermissionAllowedUseCase`) al refrescar, porque ese valor solo se actualiza
la primera vez que se pide el permiso, al arrancar la app (`MoldeaApp`); hay que volver a
consultar `UNUserNotificationCenter` de verdad.

## Permiso de micrófono

Si el usuario deniega el micrófono al abrir el sheet de voz (ver _Cuándo se pide cada permiso_ en
el `CLAUDE.md` de `Core`), además del aviso del sheet aparece en Ajustes una sección «Comandos de
voz» con una `PermissionDisabledRow` (`mic.slash.fill`). Es la misma fila que la de
notificaciones, parametrizada con icono, título y descripción.

- Solo se pinta si `settingsViewModel.showsMicrophonePermissionRow`: el dispositivo es compatible
  con Apple Intelligence (`isVoiceInputAvailable`, que `SettingsDependencies` rellena con
  `FoundationModelsDeviceEligibility.isDeviceEligible`, el mismo criterio que la pestaña del
  micrófono) **y** el estado es `.denied`. Con `.notDetermined` no sale: el usuario aún no ha
  abierto el sheet y no se le ha preguntado.
- Al tocarla abre `UIApplication.openSettingsURLString` (la página de la app en Ajustes, donde
  está el interruptor del micrófono), no la de notificaciones.
- El estado se lee con `GetMicrophonePermissionStatusUseCase` → `authorizationStatus()`, que no
  muestra alerta. Por eso el refresco al pasar a `.active`
  (`refreshMicrophonePermissionStatus()`) es síncrono y, a diferencia del de notificaciones, no
  vuelve a pedir el permiso: pedirlo aquí sacaría la alerta en Ajustes si aún no se ha decidido.

## Textos y localización

Un único catálogo por paquete —`Presentation/Resources/Localizable.xcstrings`— y un único
punto de acceso —`SettingsTextsEnum`—, que expone constantes `LocalizedStringResource`:

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
(`Settings_Settings`) automáticamente al detectar el catálogo; no hace falta declarar
`resources:` en `Package.swift`.

Claves actuales:

| Clave | en | es |
|---|---|---|
| `settings_screen_title` | Settings | Configuración |
| `settings_general_section` | General | General |
| `settings_notifications_permission_disabled_title` | Notifications disabled | Notificaciones deshabilitadas |
| `settings_notifications_permission_disabled_description` | You won't receive notifications for your habits. Tap here to enable them from Settings. | No recibirás notificaciones de tus hábitos. Toca aquí para activarlas desde Ajustes. |

Para añadir un texto: añade la entrada al `Localizable.xcstrings` (en `en` y `es`, con
`"extractionState": "manual"`) y expón la constante en `SettingsTextsEnum`. Las claves van en
`snake_case` con el prefijo `settings_`; las constantes, en `camelCase`.

Los textos que acaben usándose desde más de un módulo se mueven a `CoreTextsEnum`. Ojo: el
título de la pestaña ya vive en `Core` como `settings_title` —lo consume `MainTabEnum`—;
`settings_screen_title` es el título de la pantalla, no el de la pestaña.

Este paquete acumulará muchas etiquetas cortas (secciones, filas, pies de ayuda). Mantén el
prefijo por sección al nombrar claves —`settings_general_…`, `settings_about_…`— para que el
catálogo siga siendo legible.

## Tests

Swift Testing (`import Testing`, `@Test`). Los casos de uso y repositorios falsos son `actor`
cuando el protocolo es `async` (p. ej. `RequestNotificationAuthorizationUseCase`); el fake de
`UserDefaultsRepository` es una `final class @unchecked Sendable` porque ese protocolo declara
métodos síncronos.

- `GetIsNotificationPermissionAllowedUseCaseTests`: devuelve el valor guardado y `false` por
  defecto si no hay nada guardado.
- `SettingsViewModelTests`: el `init` refleja el último valor guardado (no el real del
  sistema), y `refreshNotificationPermissionStatus()` sí vuelve a consultar el
  `RequestNotificationAuthorizationUseCase` inyectado, en ambos sentidos (concede y deniega).
  La fila de micrófono solo sale con `.denied` en un dispositivo compatible, y
  `refreshMicrophonePermissionStatus()` refleja el cambio del repositorio. El fake de
  `MicrophonePermissionRepository` es una `final class @unchecked Sendable` con `status` mutable,
  porque `authorizationStatus()` es síncrono.
- `GetMicrophonePermissionStatusUseCaseTests`: devuelve el estado del repositorio.

`Tests/SettingsTests/SettingsTests.swift` es todavía la plantilla generada.

## Accesibilidad

`HabitReminderRow` añade la acción «Editar recordatorio» al `Toggle` (el botón de su label no
se alcanza con VoiceOver). La hoja de recordatorio admite `[.medium, .large]`.

El interruptor de «Resumen del día» es un `Toggle` nativo con la etiqueta como texto, así que
VoiceOver lee nombre, estado y trait sin nada más; la cabecera de la sección es de sistema (lleva
`.isHeader` sola) y el pie, que dice la hora, es el elemento siguiente. Cambia de estado **antes**
de esperar a la sincronización para que el valor que anuncia VoiceOver sea inmediato. No hay hints
duplicados del pie ni identificadores: los tests de UI buscan por el texto visible.

Las reglas comunes están en el `CLAUDE.md` raíz, en _Accesibilidad_.
