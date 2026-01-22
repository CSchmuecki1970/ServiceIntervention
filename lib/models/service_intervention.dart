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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer': customer.toJson(),
      'title': title,
      'description': description,
      'scheduledDate': scheduledDate.toIso8601String(),
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'generalNotes': generalNotes,
    };
  }

  factory ServiceIntervention.fromJson(Map<String, dynamic> json) {
    return ServiceIntervention(
      id: json['id'] as String,
      customer: Customer.fromJson(json['customer'] as Map<String, dynamic>),
      title: json['title'] as String,
      description: json['description'] as String,
      scheduledDate: DateTime.parse(json['scheduledDate'] as String),
      tasks: (json['tasks'] as List<dynamic>)
          .map((t) => Task.fromJson(t as Map<String, dynamic>))
          .toList(),
      status: InterventionStatus.values
          .firstWhere((e) => e.name == json['status']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      generalNotes: json['generalNotes'] as String?,
    );
  }
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
