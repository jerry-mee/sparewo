# Feature Structure Template

Each feature should follow this structure:

```
feature_name/
├── domain/           # Business entities and rules
│   ├── models/      # Data models (Freezed)
│   └── repositories/ # Repository interfaces
├── data/            # Data implementation
│   ├── repositories/ # Repository implementations
│   └── sources/     # Remote/local data sources
├── application/     # Business logic
│   └── providers/   # Riverpod providers
└── presentation/    # UI layer
    ├── screens/     # Full screens
    └── widgets/     # Feature-specific widgets
```

## Guidelines:
1. Keep features independent
2. Use dependency injection via Riverpod
3. Models are immutable (Freezed)
4. Repositories handle data operations
5. Providers manage state
6. Screens are responsive
