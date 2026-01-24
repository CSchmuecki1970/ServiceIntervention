import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 1)
class Task extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final bool isCompleted;

  @HiveField(4)
  final int order;

  @HiveField(5)
  final String? notes;

  @HiveField(6)
  final DateTime? completedAt;

  @HiveField(7)
  final bool isStopped;

  @HiveField(8)
  final String? stopReason;

  @HiveField(9)
  final DateTime? stoppedAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    this.isCompleted = false,
    required this.order,
    this.notes,
    this.completedAt,
    this.isStopped = false,
    this.stopReason,
    this.stoppedAt,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    int? order,
    String? notes,
    DateTime? completedAt,
    bool? isStopped,
    String? stopReason,
    DateTime? stoppedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      order: order ?? this.order,
      notes: notes ?? this.notes,
      completedAt: completedAt ?? this.completedAt,
      isStopped: isStopped ?? this.isStopped,
      stopReason: stopReason ?? this.stopReason,
      stoppedAt: stoppedAt ?? this.stoppedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'order': order,
      'notes': notes,
      'completedAt': completedAt?.toIso8601String(),
      'isStopped': isStopped,
      'stopReason': stopReason,
      'stoppedAt': stoppedAt?.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
      order: json['order'] as int,
      notes: json['notes'] as String?,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      isStopped: json['isStopped'] as bool? ?? false,
      stopReason: json['stopReason'] as String?,
      stoppedAt: json['stoppedAt'] != null
          ? DateTime.parse(json['stoppedAt'] as String)
          : null,
    );
  }
}
