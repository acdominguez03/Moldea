# Navigation

Paquete de navegación de Moldea. Define las dos capas de navegación de la app —el flujo raíz
y la tab bar principal— sin conocer el contenido de las pantallas: todas las vistas reciben
el contenido por `@ViewBuilder`, así que `Navigation` no depende de los paquetes de feature.

Depende de `Core` (de donde salen los títulos localizados de las pestañas).

## Configuración

- `swift-tools-version: 6.2`
- Plataforma mínima: `.iOS(.v26)`
- `swiftSettings`: `.enableUpcomingFeature("ApproachableConcurrency")` en target y test target
- Dependencia: `.package(path: "../Core")`

## Estructura

```
Sources/
├── AppFlowEnum.swift        # enum: .splash | .tabView
├── AppRouter.swift      # @Observable, estado del flujo raíz
├── RootView.swift       # renderiza el flujo actual e inyecta el router en el entorno
└── TabNavigation/
    ├── MainTabEnum.swift    # enum de pestañas + icono + título
    ├── TabRouter.swift  # @Observable, pestaña seleccionada
    └── MainTabsView.swift
Tests/NavigationTests/
```

Este paquete no sigue el esquema `Data`/`Domain`/`Presentation` de los paquetes de feature:
es puramente de presentación.

## Flujo raíz

`AppRouter` es un `@Observable` que guarda un `AppFlowEnum` (`.splash` o `.tabView`, por defecto
`.tabView`). `flow` es `public private(set)`; se cambia con `navigate(value:)`, que es
`internal` a propósito —el flujo se dirige desde dentro del paquete, no desde la app—.

`RootView` recibe el router y un `@ViewBuilder (AppFlowEnum) -> Content`, pinta el contenido del
flujo activo y publica el router con `.environment(router)`.

## Tab bar

`MainTabEnum` es el enum de pestañas (`today`, `statistics`, `habits`, `settings`). Cada caso
aporta su `icon` (SF Symbol, `internal`) y su `description` (`LocalizedStringResource`,
`public`), que viene de `CoreTextsEnum`. El orden de las pestañas en pantalla lo fija el array
`tabs` de `MainTabsView`, no `CaseIterable`.

`TabRouter` es un `@Observable` con la pestaña seleccionada y `present(tab:)`.

`MainTabsView` monta el `TabView` con `Tab(value:)` y un `Label` por pestaña
(`.environment(\.symbolVariants, .none)` para que los iconos no se rellenen). Es genérica sobre
dos tipos: `Content` (el contenido de cada pestaña) y `SheetContent` (el contenido de la hoja
inferior). Usa estas APIs de la tab bar:

- `.tabBarMinimizeBehavior(.onScrollDown)` — la barra se minimiza al hacer scroll hacia abajo.
- `Tab(value:role:content:label:)` con `TabRole.prominent` — el caso `.microphone` se pinta como
  una cápsula separada al final de la barra, con el mismo tratamiento que el tab de búsqueda del
  sistema. `.prominent` es de iOS 27, así que hay un `#available` que cae a `.search` en iOS 26
  (que el sistema también fija al extremo final).

### Cuándo aparece el tab del micrófono

`MainTabsView` recibe `showsMicrophoneTab: Bool` y solo pinta `.microphone` si es `true`.
`Navigation` no importa `FoundationModels`: quien decide es `MoldeaApp`, que le pasa
`FoundationModelsDeviceEligibility.isDeviceEligible` de `Core`. Ese valor solo es `false` con
`.unavailable(.deviceNotEligible)` (el hardware no admite Apple Intelligence). Con
`appleIntelligenceNotEnabled` o `modelNotReady` el tab sí se muestra, porque el usuario puede
arreglarlo, y `HabitCommandView` explica el motivo. Se lee una vez al arrancar: que un
dispositivo sea compatible no cambia mientras la app está abierta.

### El tab destacado no navega

`.microphone` no tiene pantalla: su contenido es `EmptyView`. La selección del `TabView` pasa por
un `Binding` intermedio (`tabSelection`) que, cuando el valor entrante es `.microphone`, activa
`isSheetPresented` en vez de escribir en el binding externo; así la pestaña anterior sigue activa
y se presenta la hoja inferior (`.sheet` con `NavigationStack` y `presentationDragIndicator`). El
contenido de esa hoja lo inyecta quien compone la vista con el `@ViewBuilder sheetContent`, para
que `Navigation` no conozca la feature de entrada de voz. Los `presentationDetents` **no** se
fijan aquí: un `presentationDetents` aplicado por encima gana sobre el que declare el contenido
inyectado, así que es `sheetContent` quien decide el tamaño. Hoy lo hace `MoldeaApp`, que pasa
`SpeechToTextView()` de `Core` con `.fittingSheetDetents()`.

Antes de presentar la hoja, `MainTabsView` espera a `prepareSheet: () async -> Void` (por
defecto vacío). `MoldeaApp` lo usa para pedir el permiso de micrófono, así la alerta del sistema
sale antes que el sheet y no encima de él. Mientras se espera, `isPreparingSheet` ignora los
toques repetidos en la pestaña.

## Convenciones

- Routers: clases `@Observable` con `init()` público e intención expresada en métodos
  (`present(tab:)`, `navigate(value:)`), no mutando propiedades desde fuera.
- Vistas genéricas sobre `Content: View` para no acoplar navegación y features.
- Nada de Combine: SwiftUI + observación.

## Tests

Swift Testing (`import Testing`, `@Test`). `Tests/NavigationTests/NavigationTests.swift` es
todavía la plantilla generada.
