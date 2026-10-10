# Task Per Day

A dark-first, offline daily planner that keeps the focus on three meaningful
tasks: one for the morning, afternoon, and evening.

## Features

- Local email and password accounts with salted SHA-256 password hashes.
- Persistent sessions and user-scoped task data.
- SQLite storage on Android and SQLite in browser IndexedDB on Chrome.
- A maximum of three tasks per day, with one task per time slot.
- Task editing, completion, swipe-to-delete, history, and completion streaks.
- Dark theme by default, with a saved appearance preference.

## Run

```sh
flutter pub get
flutter run -d chrome
```

To run on Android, install the Android SDK and start an emulator or connect a
device, then run:

```sh
flutter run
```

The web SQLite worker and WASM binary are included under `web/`. If the
`sqflite_common_ffi_web` version changes, regenerate them with:

```sh
dart run sqflite_common_ffi_web:setup --force
```

Browser data is stored in IndexedDB and is scoped to the site origin. Mobile
data is stored in the app's local SQLite database.

## Validate

```sh
flutter analyze
flutter test
flutter build web
```
