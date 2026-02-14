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

  @HiveField(5, defaultValue: const <Task>[])
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

  @HiveField(11)
  final DateTime? startDate;

  @HiveField(12)
  final DateTime? endDate;

  @HiveField(13)
  final String? hotelName;

  @HiveField(14)
  final String? hotelAddress;

  @HiveField(15, defaultValue: const <String>[])
  final List<String> documents; // File paths to pictures and invoices

  @HiveField(16)
  final double? hotelCostSingle;

  @HiveField(17)
  final double? hotelCostDouble;

  @HiveField(18)
  final double? hotelCostSuite;

  @HiveField(19)
  final bool? hotelBreakfastIncluded;

  @HiveField(20)
  final double? hotelRating;

  @HiveField(21, defaultValue: const <String>[])
  final List<String>
      involvedPersons; // Names of people involved in the intervention

  @HiveField(22, defaultValue: 'EUR')
  final String currencyCode;

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
    this.startDate,
    this.endDate,
    this.hotelName,
    this.hotelAddress,
    this.documents = const [],
    this.hotelCostSingle,
    this.hotelCostDouble,
    this.hotelCostSuite,
    this.hotelBreakfastIncluded,
    this.hotelRating,
    this.involvedPersons = const [],
    this.currencyCode = 'EUR',
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
    DateTime? startDate,
    DateTime? endDate,
    String? hotelName,
    String? hotelAddress,
    List<String>? documents,
    double? hotelCostSingle,
    double? hotelCostDouble,
    double? hotelCostSuite,
    bool? hotelBreakfastIncluded,
    double? hotelRating,
    List<String>? involvedPersons,
    String? currencyCode,
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
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      hotelName: hotelName ?? this.hotelName,
      hotelAddress: hotelAddress ?? this.hotelAddress,
      documents: documents ?? this.documents,
      hotelCostSingle: hotelCostSingle ?? this.hotelCostSingle,
      hotelCostDouble: hotelCostDouble ?? this.hotelCostDouble,
      hotelCostSuite: hotelCostSuite ?? this.hotelCostSuite,
      hotelBreakfastIncluded:
          hotelBreakfastIncluded ?? this.hotelBreakfastIncluded,
      hotelRating: hotelRating ?? this.hotelRating,
      involvedPersons: involvedPersons ?? this.involvedPersons,
      currencyCode: currencyCode ?? this.currencyCode,
    );
  }

  double get completionPercentage {
    if (tasks.isEmpty) return 0.0;
    final completedTasks =
        tasks.where((t) => t.isCompleted || t.isStopped).length;
    return completedTasks / tasks.length;
  }

  bool get isAllTasksCompleted =>
      tasks.every((t) => t.isCompleted || t.isStopped);

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
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'hotelName': hotelName,
      'hotelAddress': hotelAddress,
      'documents': documents,
      'hotelCostSingle': hotelCostSingle,
      'hotelCostDouble': hotelCostDouble,
      'hotelCostSuite': hotelCostSuite,
      'hotelBreakfastIncluded': hotelBreakfastIncluded,
      'hotelRating': hotelRating,
      'involvedPersons': involvedPersons,
      'currencyCode': currencyCode,
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
      status:
          InterventionStatus.values.firstWhere((e) => e.name == json['status']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      generalNotes: json['generalNotes'] as String?,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : null,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      hotelName: json['hotelName'] as String?,
      hotelAddress: json['hotelAddress'] as String?,
      documents: (json['documents'] as List<dynamic>?)
              ?.map((d) => d as String)
              .toList() ??
          [],
      hotelCostSingle: json['hotelCostSingle'] as double?,
      hotelCostDouble: json['hotelCostDouble'] as double?,
      hotelCostSuite: json['hotelCostSuite'] as double?,
      hotelBreakfastIncluded: json['hotelBreakfastIncluded'] as bool?,
      hotelRating: json['hotelRating'] as double?,
      involvedPersons: (json['involvedPersons'] as List<dynamic>?)
              ?.map((p) => p as String)
              .toList() ??
          [],
      currencyCode: json['currencyCode'] as String? ?? 'EUR',
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
