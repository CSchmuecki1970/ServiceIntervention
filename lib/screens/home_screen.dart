import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/intervention_provider.dart';
import '../providers/theme_provider.dart';
import '../models/service_intervention.dart';
import 'intervention_detail_screen.dart';
import 'create_intervention_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Interventions'),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Center(
              child: Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return DropdownButton<AppTheme>(
                    value: themeProvider.currentTheme,
                    items: AppTheme.values.map((theme) {
                      return DropdownMenuItem(
                        value: theme,
                        child: Text(_getThemeName(theme)),
                      );
                    }).toList(),
                    onChanged: (theme) {
                      if (theme != null) {
                        themeProvider.setTheme(theme);
                      }
                    },
                    underline: const SizedBox(),
                    icon: const Icon(Icons.palette),
                  );
                },
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<InterventionProvider>(
        builder: (context, provider, child) {
          if (provider.lastError != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 80,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading data',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      provider.lastError ?? 'Unknown error',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            );
          }

          final interventions = provider.interventions;

          if (interventions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No interventions planned',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to create your first intervention',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: interventions.length,
            itemBuilder: (context, index) {
              final intervention = interventions[index];
              return _InterventionCard(intervention: intervention);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateInterventionScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Intervention'),
      ),
    );
  }

  String _getThemeName(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return 'Light';
      case AppTheme.dark:
        return 'Dark';
      case AppTheme.blue:
        return 'Blue';
      case AppTheme.green:
        return 'Green';
      case AppTheme.purple:
        return 'Purple';
      case AppTheme.orange:
        return 'Orange';
      case AppTheme.pink:
        return 'Pink';
      case AppTheme.dracula:
        return 'Darkula';
    }
  }
}

class _InterventionCard extends StatelessWidget {
  final ServiceIntervention intervention;

  const _InterventionCard({required this.intervention});

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
    final dateFormat = DateFormat('MMM dd, yyyy • HH:mm');
    final statusColor = _getStatusColor(intervention.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InterventionDetailScreen(
                interventionId: intervention.id,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      intervention.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
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
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    intervention.customer.name,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      intervention.customer.address,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(intervention.scheduledDate),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
              if (intervention.status == InterventionStatus.inProgress ||
                  intervention.status == InterventionStatus.planned) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: intervention.completionPercentage,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(intervention.completionPercentage * 100).toInt()}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
