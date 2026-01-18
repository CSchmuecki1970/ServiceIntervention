# Service Intervention Planner

A Flutter application designed to help service technicians plan, organize, and execute service interventions at customer sites with a step-by-step roadmap guidance system.

## Features

### 📋 Planning & Organization
- **Create Service Interventions**: Plan interventions with customer information, scheduling, and task lists
- **Task Management**: Add multiple tasks to each intervention with custom descriptions
- **Customer Management**: Store customer details including name, address, phone, and email

### 🗺️ Roadmap & Guidance System
- **Step-by-Step Roadmap**: Visual roadmap showing all tasks with current progress
- **Task-by-Task Guidance**: Focus on one task at a time with clear instructions
- **Progress Tracking**: Real-time progress indicator showing completion percentage
- **Task Notes**: Add notes for each task during execution

### 📊 Status Management
- **Intervention Status**: Track interventions as Planned, In Progress, or Completed
- **Task Completion**: Mark tasks as complete with automatic progress updates
- **Visual Indicators**: Color-coded status badges and progress bars

## Tech Stack

- **Flutter**: Cross-platform mobile framework
- **Dart**: Programming language
- **Provider**: State management
- **Hive**: Local database for offline storage
- **Material Design 3**: Modern UI components

## Getting Started

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Dart SDK
- Android Studio / VS Code with Flutter extensions

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd K2TravelIQ
```

2. Install dependencies:
```bash
flutter pub get
```

3. Generate Hive adapters:
```bash
flutter pub run build_runner build
```

4. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── customer.dart
│   ├── task.dart
│   └── service_intervention.dart
├── providers/                # State management
│   └── intervention_provider.dart
├── screens/                  # UI screens
│   ├── home_screen.dart
│   ├── create_intervention_screen.dart
│   ├── intervention_detail_screen.dart
│   └── roadmap_screen.dart
└── services/                 # Business logic
    └── storage_service.dart
```

## Usage

### Creating an Intervention
1. Tap the "+" button on the home screen
2. Fill in intervention details (title, description)
3. Add customer information
4. Set scheduled date and time
5. Add tasks in the desired order
6. Save the intervention

### Starting an Intervention
1. Open an intervention from the home screen
2. Tap "Start Intervention" to begin
3. Follow the roadmap to complete tasks one by one
4. Add notes for each task as needed
5. Mark tasks as complete to move to the next one

### Roadmap Navigation
- The roadmap screen shows all tasks in order
- Current task is highlighted in blue
- Completed tasks are marked with green checkmarks
- Use "Complete & Next" to finish current task and move forward
- Use "Previous Task" to go back if needed

## Data Storage

All data is stored locally using Hive, ensuring:
- Offline functionality
- Fast data access
- No internet connection required
- Data persistence across app restarts

## Future Enhancements

Potential features to add:
- Photo attachments for tasks
- GPS location tracking
- Offline maps integration
- Export reports
- Cloud synchronization
- Team collaboration features

## License

This project is created for service intervention planning and management.
