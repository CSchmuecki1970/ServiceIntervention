import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/intervention_provider.dart';
import '../models/service_intervention.dart';
import 'roadmap_screen.dart';
import 'edit_intervention_screen.dart';
import 'report_preview_screen.dart';
import '../utils/currency_utils.dart';

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
              IconButton(
                icon: const Icon(Icons.preview),
                tooltip: 'Report Preview',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReportPreviewScreen(
                        intervention: intervention,
                      ),
                    ),
                  );
                },
              ),
              if (intervention.status == InterventionStatus.planned ||
                  intervention.status == InterventionStatus.inProgress)
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit Intervention',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditInterventionScreen(
                          intervention: intervention,
                        ),
                      ),
                    );
                  },
                ),
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
                if (intervention.involvedPersons.isNotEmpty)
                  _InvolvedPersonsCard(intervention: intervention),
                if (intervention.involvedPersons.isNotEmpty)
                  const SizedBox(height: 16),
                if (intervention.startDate != null || intervention.endDate != null || 
                    intervention.hotelName != null || intervention.hotelAddress != null)
                  _TravelInformationCard(intervention: intervention),
                if (intervention.startDate != null || intervention.endDate != null || 
                    intervention.hotelName != null || intervention.hotelAddress != null)
                  const SizedBox(height: 16),
                _TasksCard(intervention: intervention),
                const SizedBox(height: 16),
                if (intervention.documents.isNotEmpty)
                  _DocumentsCard(intervention: intervention),
                if (intervention.documents.isNotEmpty)
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
    } else if (intervention.status == InterventionStatus.completed) {
      return FloatingActionButton.extended(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(Icons.home),
        label: const Text('Back to Home'),
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
                '${intervention.tasks.where((t) => t.isCompleted || t.isStopped).length} of ${intervention.tasks.length} tasks done',
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
                  'Planned Information',
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
              final isStopped = task.isStopped;
              final isCompleted = task.isCompleted;
              final statusColor = isStopped
                  ? Colors.red
                  : isCompleted
                      ? Colors.green
                      : Colors.grey[300];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor,
                        border: Border.all(
                          color: isStopped
                              ? Colors.red[700]!
                              : isCompleted
                                  ? Colors.green
                                  : Colors.grey[400]!,
                          width: 2,
                        ),
                      ),
                      child: isStopped
                          ? const Icon(Icons.block, size: 16, color: Colors.white)
                          : isCompleted
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
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: isStopped
                              ? Colors.red[700]
                              : isCompleted
                                  ? Colors.grey[600]
                                  : null,
                        ),
                      ),
                    ),
                    if (isStopped)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(Icons.block, color: Colors.red[700], size: 18),
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
class _TravelInformationCard extends StatelessWidget {
  final ServiceIntervention intervention;

  const _TravelInformationCard({required this.intervention});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencySymbol = CurrencyUtils.symbolFor(intervention.currencyCode);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.travel_explore, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Travel Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (intervention.startDate != null || intervention.endDate != null) ...[
              _buildInfoRow('Travel Dates', context),
              if (intervention.startDate != null)
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Icon(Icons.date_range, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'From: ${dateFormat.format(intervention.startDate!)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              if (intervention.endDate != null)
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Icon(Icons.date_range, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'To: ${dateFormat.format(intervention.endDate!)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
            ],
            if (intervention.hotelName != null && intervention.hotelName!.isNotEmpty) ...[
              _buildInfoRow('Hotel Information', context),
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 16),
                        Icon(Icons.hotel, size: 18, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                intervention.hotelName!,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              if (intervention.hotelAddress != null &&
                                  intervention.hotelAddress!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    intervention.hotelAddress!,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Hotel Costs
                    if (intervention.hotelCostSingle != null ||
                        intervention.hotelCostDouble != null ||
                        intervention.hotelCostSuite != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Costs per Day (${intervention.currencyCode})',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 16,
                        children: [
                          if (intervention.hotelCostSingle != null)
                            Text(
                              'Single: $currencySymbol${intervention.hotelCostSingle}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          if (intervention.hotelCostDouble != null)
                            Text(
                              'Double: $currencySymbol${intervention.hotelCostDouble}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          if (intervention.hotelCostSuite != null)
                            Text(
                              'Suite: $currencySymbol${intervention.hotelCostSuite}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ],
                    // Hotel Breakfast & Rating
                    if (intervention.hotelBreakfastIncluded != null ||
                        intervention.hotelRating != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (intervention.hotelBreakfastIncluded == true)
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(Icons.restaurant, size: 16, color: Colors.orange[700]),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Breakfast Included',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          if (intervention.hotelRating != null)
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(Icons.star, size: 16, color: Colors.amber[700]),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${intervention.hotelRating}/5',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
      ),
    );
  }
}

class _DocumentsCard extends StatelessWidget {
  final ServiceIntervention intervention;

  const _DocumentsCard({required this.intervention});

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
                Icon(Icons.attach_file, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Documents & Pictures (${intervention.documents.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: intervention.documents.length,
              itemBuilder: (context, index) {
                final docPath = intervention.documents[index];
                final fileName = docPath.split('/').last;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        _getDocumentIcon(fileName),
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          fileName,
                          style: Theme.of(context).textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDocumentIcon(String fileName) {
    if (fileName.toLowerCase().endsWith('.pdf')) {
      return Icons.picture_as_pdf;
    } else if (_isImageFile(fileName)) {
      return Icons.image;
    } else if (fileName.toLowerCase().endsWith('.doc') ||
        fileName.toLowerCase().endsWith('.docx')) {
      return Icons.description;
    }
    return Icons.attach_file;
  }

  bool _isImageFile(String fileName) {
    final ext = fileName.toLowerCase();
    return ext.endsWith('.jpg') ||
        ext.endsWith('.jpeg') ||
        ext.endsWith('.png') ||
        ext.endsWith('.gif') ||
        ext.endsWith('.webp');
  }
}

class _InvolvedPersonsCard extends StatelessWidget {
  final ServiceIntervention intervention;

  const _InvolvedPersonsCard({required this.intervention});

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
                Icon(Icons.group, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'People Involved',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: intervention.involvedPersons.map((person) {
                return Chip(
                  label: Text(person),
                  avatar: Icon(Icons.person, size: 18, color: Colors.blue[700]),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}