# Navigation

Paquete de navegación de Moldea. Define las dos capas de navegación de la app —el flujo raíz
y la tab bar principal— sin conocer el contenido de las pantallas: todas las vistas reciben
el contenido por `@ViewBuilder`, así que `Navigation` no depende de los paquetes de feature.

Depende de `Core` (de donde salen los títulos localizados de las pestañas).

## Configuración

- `swift-tools-version: 6.4`
- Plataforma mínima: `.iOS(.v26)`
- `swiftSettings`: `.enableUpcomingFeature("ApproachableConcurrency")` en target y test target
- Dependencia: `.package(path: "../Core")`

## Estructura

```
Sources/
├── AppFlow.swift        # enum: .splash | .tabView
├── AppRouter.swift      # @Observable, estado del flujo raíz
├── RootView.swift       # renderiza el flujo actual e inyecta el router en el entorno
└── TabNavigation/
    ├── MainTab.swift    # enum de pestañas + icono + título
    ├── TabRouter.swift  # @Observable, pestaña seleccionada
    └── MainTabsView.swift
Tests/NavigationTests/
```

Este paquete no sigue el esquema `Data`/`Domain`/`Presentation` de los paquetes de feature:
es puramente de presentación.

## Flujo raíz

`AppRouter` es un `@Observable` que guarda un `AppFlow` (`.splash` o `.tabView`, por defecto
`.tabView`). `flow` es `public private(set)`; se cambia con `navigate(value:)`, que es
`internal` a propósito —el flujo se dirige desde dentro del paquete, no desde la app—.

`RootView` recibe el router y un `@ViewBuilder (AppFlow) -> Content`, pinta el contenido del
flujo activo y publica el router con `.environment(router)`.

## Tab bar

`MainTab` es el enum de pestañas (`today`, `statistics`, `habits`, `settings`). Cada caso
aporta su `icon` (SF Symbol, `internal`) y su `description` (`LocalizedStringResource`,
`public`), que viene de `CoreTextsEnum`. El orden de las pestañas en pantalla lo fija el array
`tabs` de `MainTabsView`, no `CaseIterable`.

`TabRouter` es un `@Observable` con la pestaña seleccionada y `present(tab:)`.

`MainTabsView` monta el `TabView` con `Tab(value:)` y un `Label` por pestaña
(`.environment(\.symbolVariants, .none)` para que los iconos no se rellenen). Es genérica sobre
dos tipos: `Content` (el contenido de cada pestaña) y `SheetContent` (el contenido de la hoja
inferior). Usa estas APIs de la tab bar:

- `.tabBarMinimizeBehavior(.onScrollDown)` — la barra se minimiza al hacer scroll hacia abajo.
- `.tabViewBottomAccessory { ... }` — coloca el botón de entrada de voz sobre la tab bar y,
  cuando esta se minimiza, en línea a su lado. La acción se inyecta con el parámetro
  `accessoryAction`.
- `Tab(value:role:content:label:)` con `TabRole.prominent` — el caso `.microphone` se pinta como
  una cápsula separada al final de la barra, con el mismo tratamiento que el tab de búsqueda del
  sistema. `.prominent` es de iOS 27, así que hay un `#available` que cae a `.search` en iOS 26
  (que el sistema también fija al extremo final).

### El tab destacado no navega

`.microphone` no tiene pantalla: su contenido es `EmptyView`. La selección del `TabView` pasa por
un `Binding` intermedio (`tabSelection`) que, cuando el valor entrante es `.microphone`, activa
`isSheetPresented` en vez de escribir en el binding externo; así la pestaña anterior sigue activa
y se presenta la hoja inferior (`.sheet` con `presentationDetents([.medium, .large])`). El
contenido de esa hoja lo inyecta quien compone la vista con el `@ViewBuilder sheetContent`, para
que `Navigation` no conozca la feature de entrada de voz.

## Convenciones

- Routers: clases `@Observable` con `init()` público e intención expresada en métodos
  (`present(tab:)`, `navigate(value:)`), no mutando propiedades desde fuera.
- Vistas genéricas sobre `Content: View` para no acoplar navegación y features.
- Nada de Combine: SwiftUI + observación.

## Tests

Swift Testing (`import Testing`, `@Test`). `Tests/NavigationTests/NavigationTests.swift` es
todavía la plantilla generada.
