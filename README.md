# TurnReserved - iOS

App nativa iOS (Swift/SwiftUI) para [TurnReserved](https://turnreserved.com).

## Requisitos

- Xcode 15+
- iOS 16+ (soporta las últimas 4 versiones)
- Swift 5.9+

## Arquitectura

- **MVVM** con SwiftUI
- **Async/Await** para networking
- **Keychain** para almacenamiento seguro de tokens
- **Actor-based** API service (thread-safe)

## Estructura

```
TurnReserved/
├── App/              # Entry point, RootView
├── Models/           # Tipos de datos (User, Service, Booking, etc.)
├── Services/         # APIService, KeychainService, AuthViewModel
├── Views/
│   ├── Auth/         # Login, Register
│   ├── Dashboard/    # Services, Agenda, Clients, Schedule
│   ├── Booking/      # Public booking flow
│   ├── Subscription/ # Plan selection
│   └── Components/   # Reusable UI
└── Utils/            # Colors, themes
```

## Setup

1. Clonar el repo
2. Abrir `TurnReserved.xcodeproj` en Xcode (o crear nuevo proyecto y arrastrar la carpeta `TurnReserved/`)
3. Configurar Bundle Identifier
4. Build & Run

## API

Conecta a `https://turnreserved.com/api`. El backend está en [turnosBackend](https://github.com/jacquet33/turnosBackend).

## Features

- Login / Registro con email
- Dashboard con 3 tabs: Servicios, Agenda, Clientes
- Configuración de horarios por servicio
- Gestión de turnos (pendiente → completado / cancelado)
- Búsqueda de clientes
- Suscripciones via MercadoPago
- Deep links para booking público (`turnreserved://book/{linkId}`)
- Almacenamiento seguro con Keychain
- Dark theme nativo que replica la web
