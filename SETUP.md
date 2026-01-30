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

## Windows Installer (Inno Setup)

1. Install Inno Setup 6 (default path: `C:\Program Files (x86)\Inno Setup 6`).
2. Build the installer:
   ```powershell
   installer\build_installer.ps1
   ```
   or
   ```bat
   installer\build_installer.bat
   ```
3. Optional: set `INNO_SETUP_PATH` to your Inno Setup folder or full `ISCC.exe` path to override the default.