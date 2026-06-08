# ETA Service

Standalone Dart service for collecting Batumi GPS data into SQLite and exporting a Firebase-like JSON snapshot.

## Commands

```bash
dart run bin/eta_service.dart migrate
dart run bin/eta_service.dart import-batumi
dart run bin/eta_service.dart poll-batumi --route-id 123
dart run bin/eta_service.dart export-json --out ./snapshot.json
dart run bin/server.dart
```

## Environment

- `ETA_RUNTIME_DIR` sets the directory where the SQLite file is stored.
- `ETA_DB_PATH` overrides the full SQLite path.
- `ETA_HOST` and `ETA_PORT` control the HTTP listener.
- `BATUMI_BASE_URL` controls the Batumi/thetamaps upstream, defaulting to `https://thetamaps.site:54321`.

By default the database is stored at `services/eta_service/runtime/eta_service.db`.
