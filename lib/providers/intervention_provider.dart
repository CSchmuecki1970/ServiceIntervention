import 'package:flutter/foundation.dart';
import '../models/service_intervention.dart';
import '../services/storage_service.dart';

class InterventionProvider with ChangeNotifier {
  List<ServiceIntervention> _interventions = [];
  ServiceIntervention? _currentIntervention;
  String? _lastError;
  bool _isLoading = false;

  List<ServiceIntervention> get interventions => _interventions;
  ServiceIntervention? get currentIntervention => _currentIntervention;
  String? get lastError => _lastError;
  bool get isLoading => _isLoading;

  InterventionProvider() {
    loadInterventions();
  }

  void loadInterventions() {
    try {
      _lastError = null;
      _interventions = StorageService.getAllInterventions();
      _interventions.sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
      notifyListeners();
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
    }
  }

  Future<void> addIntervention(ServiceIntervention intervention) async {
    try {
      _lastError = null;
      await StorageService.saveIntervention(intervention);
      loadInterventions();
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateIntervention(ServiceIntervention intervention) async {
    try {
      _lastError = null;
      await StorageService.saveIntervention(intervention);
      
      // Update the in-memory list
      final index = _interventions.indexWhere((i) => i.id == intervention.id);
      if (index >= 0) {
        _interventions[index] = intervention;
      }
      
      if (_currentIntervention?.id == intervention.id) {
        _currentIntervention = intervention;
      }
      notifyListeners();
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteIntervention(String id) async {
    try {
      _lastError = null;
      await StorageService.deleteIntervention(id);
      loadInterventions();
      if (_currentIntervention?.id == id) {
        _currentIntervention = null;
      }
      notifyListeners();
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
    }
  }

  void setCurrentIntervention(ServiceIntervention? intervention) {
    _currentIntervention = intervention;
    notifyListeners();
  }

  Future<void> startIntervention(String id) async {
    try {
      _lastError = null;
      final intervention = StorageService.getIntervention(id);
      if (intervention != null) {
        final updated = intervention.copyWith(
          status: InterventionStatus.inProgress,
          startedAt: DateTime.now(),
        );
        await updateIntervention(updated);
      }
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
    }
  }

  Future<void> completeTask(String interventionId, String taskId) async {
    try {
      _lastError = null;
      final intervention = StorageService.getIntervention(interventionId);
      if (intervention != null) {
        final updatedTasks = intervention.tasks.map((task) {
          if (task.id == taskId) {
            if (task.isStopped) {
              return task;
            }
            return task.copyWith(
              isCompleted: true,
              completedAt: DateTime.now(),
              isStopped: false,
              stopReason: null,
              stoppedAt: null,
            );
          }
          return task;
        }).toList();

        final updated = intervention.copyWith(tasks: updatedTasks);

        // Check if all tasks are completed
        if (updated.isAllTasksCompleted &&
            updated.status != InterventionStatus.completed) {
          final finalUpdated = updated.copyWith(
            status: InterventionStatus.completed,
            completedAt: DateTime.now(),
          );
          await updateIntervention(finalUpdated);
        } else {
          await updateIntervention(updated);
        }
      }
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
    }
  }

  Future<void> stopTask(
    String interventionId,
    String taskId,
    String reason,
  ) async {
    try {
      _lastError = null;
      final intervention = StorageService.getIntervention(interventionId);
      if (intervention != null) {
        final updatedTasks = intervention.tasks.map((task) {
          if (task.id == taskId) {
            return task.copyWith(
              isStopped: true,
              stopReason: reason,
              stoppedAt: DateTime.now(),
              isCompleted: false,
              completedAt: null,
            );
          }
          return task;
        }).toList();

        final updated = intervention.copyWith(tasks: updatedTasks);

        if (updated.isAllTasksCompleted &&
            updated.status != InterventionStatus.completed) {
          final finalUpdated = updated.copyWith(
            status: InterventionStatus.completed,
            completedAt: DateTime.now(),
          );
          await updateIntervention(finalUpdated);
        } else {
          await updateIntervention(updated);
        }
      }
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateTaskStopReason(
    String interventionId,
    String taskId,
    String reason,
  ) async {
    try {
      _lastError = null;
      final intervention = StorageService.getIntervention(interventionId);
      if (intervention != null) {
        final updatedTasks = intervention.tasks.map((task) {
          if (task.id == taskId) {
            return task.copyWith(stopReason: reason);
          }
          return task;
        }).toList();

        final updated = intervention.copyWith(tasks: updatedTasks);
        await updateIntervention(updated);
      }
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateTaskNotes(
    String interventionId,
    String taskId,
    String notes,
  ) async {
    try {
      _lastError = null;
      final intervention = StorageService.getIntervention(interventionId);
      if (intervention != null) {
        final updatedTasks = intervention.tasks.map((task) {
          if (task.id == taskId) {
            return task.copyWith(notes: notes);
          }
          return task;
        }).toList();

        final updated = intervention.copyWith(tasks: updatedTasks);
        await updateIntervention(updated);
      }
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
    }
  }

  Future<void> reopenTask(String interventionId, String taskId) async {
    try {
      _lastError = null;
      final intervention = StorageService.getIntervention(interventionId);
      if (intervention != null) {
        final updatedTasks = intervention.tasks.map((task) {
          if (task.id == taskId) {
            return task.copyWith(
              isCompleted: false,
              completedAt: null,
              isStopped: false,
              stopReason: null,
              stoppedAt: null,
            );
          }
          return task;
        }).toList();

        final updated = intervention.copyWith(
          tasks: updatedTasks,
          // If intervention was completed but we're reopening a task, set status back to inProgress
          status: intervention.status == InterventionStatus.completed
              ? InterventionStatus.inProgress
              : intervention.status,
        );
        await updateIntervention(updated);
      }
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
    }
  }

  // Export functionality
  String exportData() {
    try {
      _lastError = null;
      return StorageService.exportToJson();
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Import functionality
  Future<void> importData(String jsonData) async {
    try {
      _lastError = null;
      _isLoading = true;
      notifyListeners();

      await StorageService.importFromJson(jsonData);
      loadInterventions();

      // Debug: Check how many interventions were loaded
      print('DEBUG: Imported data. Total interventions: ${_interventions.length}');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _lastError = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Get backup info
  Map<String, dynamic> getBackupInfo() {
    try {
      _lastError = null;
      return StorageService.getBackupMetadata();
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
      return {};
    }
  }

  // Search and filter methods
  List<ServiceIntervention> filterByStatus(InterventionStatus status) {
    try {
      _lastError = null;
      return _interventions.where((i) => i.status == status).toList();
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
      return [];
    }
  }

  List<ServiceIntervention> filterByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    try {
      _lastError = null;
      return StorageService.getInterventionsInDateRange(startDate, endDate);
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
      return [];
    }
  }

  List<ServiceIntervention> filterByCustomer(String customerId) {
    try {
      _lastError = null;
      return StorageService.getInterventionsByCustomer(customerId);
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<void> clearAllData() async {
    try {
      _lastError = null;
      await StorageService.clearAll();
      loadInterventions();
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
    }
  }
}
