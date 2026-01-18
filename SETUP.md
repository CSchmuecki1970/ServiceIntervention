# Setup Instructions

## Initial Setup

1. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

2. **Generate Hive adapters:**
   Since we're using Hive for local storage, you need to generate the adapter files:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```
   
   This will generate the following files:
   - `lib/models/customer.g.dart`
   - `lib/models/task.g.dart`
   - `lib/models/service_intervention.g.dart`

3. **Run the app:**
   ```bash
   flutter run
   ```

## Troubleshooting

If you encounter errors about missing `.g.dart` files, make sure you've run the build_runner command above.

If you get Hive adapter registration errors, ensure all model files have the `@HiveType` and `@HiveField` annotations properly set up (which they already do).
