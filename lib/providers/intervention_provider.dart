import 'package:flutter/foundation.dart';
import '../models/service_intervention.dart';
import '../models/task.dart';
import '../services/storage_service.dart';

class InterventionProvider with ChangeNotifier {
  List<ServiceIntervention> _interventions = [];
  ServiceIntervention? _currentIntervention;

  List<ServiceIntervention> get interventions => _interventions;
  ServiceIntervention? get currentIntervention => _currentIntervention;

  InterventionProvider() {
    loadInterventions();
  }

  void loadInterventions() {
    _interventions = StorageService.getAllInterventions();
    _interventions.sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
    notifyListeners();
  }

  Future<void> addIntervention(ServiceIntervention intervention) async {
    await StorageService.saveIntervention(intervention);
    loadInterventions();
  }

  Future<void> updateIntervention(ServiceIntervention intervention) async {
    await StorageService.saveIntervention(intervention);
    loadInterventions();
    if (_currentIntervention?.id == intervention.id) {
      _currentIntervention = intervention;
    }
    notifyListeners();
  }

  Future<void> deleteIntervention(String id) async {
    await StorageService.deleteIntervention(id);
    loadInterventions();
    if (_currentIntervention?.id == id) {
      _currentIntervention = null;
    }
    notifyListeners();
  }

  void setCurrentIntervention(ServiceIntervention? intervention) {
    _currentIntervention = intervention;
    notifyListeners();
  }

  Future<void> startIntervention(String id) async {
    final intervention = StorageService.getIntervention(id);
    if (intervention != null) {
      final updated = intervention.copyWith(
        status: InterventionStatus.inProgress,
        startedAt: DateTime.now(),
      );
      await updateIntervention(updated);
    }
  }

  Future<void> completeTask(String interventionId, String taskId) async {
    final intervention = StorageService.getIntervention(interventionId);
    if (intervention != null) {
      final updatedTasks = intervention.tasks.map((task) {
        if (task.id == taskId) {
          return task.copyWith(
            isCompleted: true,
            completedAt: DateTime.now(),
          );
        }
        return task;
      }).toList();

      final updated = intervention.copyWith(tasks: updatedTasks);

      // Check if all tasks are completed
      if (updated.isAllTasksCompleted && updated.status != InterventionStatus.completed) {
        final finalUpdated = updated.copyWith(
          status: InterventionStatus.completed,
          completedAt: DateTime.now(),
        );
        await updateIntervention(finalUpdated);
      } else {
        await updateIntervention(updated);
      }
    }
  }

  Future<void> updateTaskNotes(String interventionId, String taskId, String notes) async {
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
  }
}
