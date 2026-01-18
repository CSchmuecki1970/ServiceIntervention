import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/intervention_provider.dart';
import '../models/service_intervention.dart';
import 'roadmap_screen.dart';

class InterventionDetailScreen extends StatelessWidget {
  final String interventionId;

  const InterventionDetailScreen({
    super.key,
    required this.interventionId,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<InterventionProvider>(
      builder: (context, provider, child) {
        final intervention = provider.interventions.firstWhere(
          (i) => i.id == interventionId,
          orElse: () => throw Exception('Intervention not found'),
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(intervention.title),
            actions: [
              if (intervention.status == InterventionStatus.planned ||
                  intervention.status == InterventionStatus.inProgress)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Intervention'),
                        content: const Text(
                          'Are you sure you want to delete this intervention?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true && context.mounted) {
                      await provider.deleteIntervention(interventionId);
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    }
                  },
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusCard(intervention: intervention),
                const SizedBox(height: 16),
                _CustomerCard(intervention: intervention),
                const SizedBox(height: 16),
                _ScheduleCard(intervention: intervention),
                const SizedBox(height: 16),
                _TasksCard(intervention: intervention),
                const SizedBox(height: 16),
                if (intervention.generalNotes != null &&
                    intervention.generalNotes!.isNotEmpty)
                  _NotesCard(intervention: intervention),
                const SizedBox(height: 80),
              ],
            ),
          ),
          floatingActionButton: _getActionButton(context, intervention, provider),
        );
      },
    );
  }

  Widget? _getActionButton(
    BuildContext context,
    ServiceIntervention intervention,
    InterventionProvider provider,
  ) {
    if (intervention.status == InterventionStatus.planned) {
      return FloatingActionButton.extended(
        onPressed: () async {
          await provider.startIntervention(intervention.id);
          if (context.mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => RoadmapScreen(
                  interventionId: intervention.id,
                ),
              ),
            );
          }
        },
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start Intervention'),
      );
    } else if (intervention.status == InterventionStatus.inProgress) {
      return FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RoadmapScreen(
                interventionId: intervention.id,
              ),
            ),
          );
        },
        icon: const Icon(Icons.route),
        label: const Text('Continue Roadmap'),
      );
    }
    return null;
  }
}

class _StatusCard extends StatelessWidget {
  final ServiceIntervention intervention;

  const _StatusCard({required this.intervention});

  Color _getStatusColor(InterventionStatus status) {
    switch (status) {
      case InterventionStatus.planned:
        return Colors.blue;
      case InterventionStatus.inProgress:
        return Colors.orange;
      case InterventionStatus.completed:
        return Colors.green;
      case InterventionStatus.cancelled:
        return Colors.grey;
    }
  }

  String _getStatusText(InterventionStatus status) {
    switch (status) {
      case InterventionStatus.planned:
        return 'Planned';
      case InterventionStatus.inProgress:
        return 'In Progress';
      case InterventionStatus.completed:
        return 'Completed';
      case InterventionStatus.cancelled:
        return 'Cancelled';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(intervention.status);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor, width: 1),
                  ),
                  child: Text(
                    _getStatusText(intervention.status),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (intervention.status == InterventionStatus.inProgress ||
                intervention.status == InterventionStatus.planned) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: intervention.completionPercentage,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${(intervention.completionPercentage * 100).toInt()}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${intervention.tasks.where((t) => t.isCompleted).length} of ${intervention.tasks.length} tasks completed',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final ServiceIntervention intervention;

  const _CustomerCard({required this.intervention});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Customer',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              intervention.customer.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    intervention.customer.address,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            if (intervention.customer.phone != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    intervention.customer.phone!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
            if (intervention.customer.email != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.email, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    intervention.customer.email!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final ServiceIntervention intervention;

  const _ScheduleCard({required this.intervention});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Schedule',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              dateFormat.format(intervention.scheduledDate),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Text(
              'at ${timeFormat.format(intervention.scheduledDate)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TasksCard extends StatelessWidget {
  final ServiceIntervention intervention;

  const _TasksCard({required this.intervention});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.checklist, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Tasks (${intervention.tasks.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...intervention.tasks.map((task) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: task.isCompleted
                            ? Colors.green
                            : Colors.grey[300],
                        border: Border.all(
                          color: task.isCompleted
                              ? Colors.green
                              : Colors.grey[400]!,
                          width: 2,
                        ),
                      ),
                      child: task.isCompleted
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${task.order + 1}. ${task.title}',
                        style: TextStyle(
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: task.isCompleted
                              ? Colors.grey[600]
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  final ServiceIntervention intervention;

  const _NotesCard({required this.intervention});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Notes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(intervention.generalNotes!),
          ],
        ),
      ),
    );
  }
}
