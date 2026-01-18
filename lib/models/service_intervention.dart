import 'package:hive/hive.dart';
import 'customer.dart';
import 'task.dart';

part 'service_intervention.g.dart';

@HiveType(typeId: 2)
class ServiceIntervention extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final Customer customer;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String description;

  @HiveField(4)
  final DateTime scheduledDate;

  @HiveField(5)
  final List<Task> tasks;

  @HiveField(6)
  final InterventionStatus status;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final DateTime? startedAt;

  @HiveField(9)
  final DateTime? completedAt;

  @HiveField(10)
  final String? generalNotes;

  ServiceIntervention({
    required this.id,
    required this.customer,
    required this.title,
    required this.description,
    required this.scheduledDate,
    required this.tasks,
    this.status = InterventionStatus.planned,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.generalNotes,
  });

  ServiceIntervention copyWith({
    String? id,
    Customer? customer,
    String? title,
    String? description,
    DateTime? scheduledDate,
    List<Task>? tasks,
    InterventionStatus? status,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    String? generalNotes,
  }) {
    return ServiceIntervention(
      id: id ?? this.id,
      customer: customer ?? this.customer,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      tasks: tasks ?? this.tasks,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      generalNotes: generalNotes ?? this.generalNotes,
    );
  }

  double get completionPercentage {
    if (tasks.isEmpty) return 0.0;
    final completedTasks = tasks.where((t) => t.isCompleted).length;
    return completedTasks / tasks.length;
  }

  bool get isAllTasksCompleted => tasks.every((t) => t.isCompleted);
}

@HiveType(typeId: 3)
enum InterventionStatus {
  @HiveField(0)
  planned,
  @HiveField(1)
  inProgress,
  @HiveField(2)
  completed,
  @HiveField(3)
  cancelled,
}
