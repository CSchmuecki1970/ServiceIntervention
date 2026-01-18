import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/intervention_provider.dart';
import '../models/service_intervention.dart';
import '../models/task.dart';

class RoadmapScreen extends StatefulWidget {
  final String interventionId;

  const RoadmapScreen({
    super.key,
    required this.interventionId,
  });

  @override
  State<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen> {
  int _currentTaskIndex = 0;
  final Map<String, TextEditingController> _notesControllers = {};

  @override
  void dispose() {
    for (var controller in _notesControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeNotesControllers(List<Task> tasks) {
    for (var task in tasks) {
      if (!_notesControllers.containsKey(task.id)) {
        _notesControllers[task.id] =
            TextEditingController(text: task.notes ?? '');
      }
    }
  }

  int _getCurrentTaskIndex(ServiceIntervention intervention) {
    for (int i = 0; i < intervention.tasks.length; i++) {
      if (!intervention.tasks[i].isCompleted) {
        return i;
      }
    }
    return intervention.tasks.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InterventionProvider>(
      builder: (context, provider, child) {
        final intervention = provider.interventions.firstWhere(
          (i) => i.id == widget.interventionId,
          orElse: () => throw Exception('Intervention not found'),
        );

        _initializeNotesControllers(intervention.tasks);
        _currentTaskIndex = _getCurrentTaskIndex(intervention);

        if (intervention.tasks.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text(intervention.title)),
            body: const Center(
              child: Text('No tasks available'),
            ),
          );
        }

        final currentTask = intervention.tasks[_currentTaskIndex];
        final isLastTask = _currentTaskIndex == intervention.tasks.length - 1;
        final isAllCompleted = intervention.isAllTasksCompleted;

        return Scaffold(
          appBar: AppBar(
            title: Text(intervention.title),
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Intervention Info'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Customer: ${intervention.customer.name}'),
                          const SizedBox(height: 8),
                          Text('Address: ${intervention.customer.address}'),
                          if (intervention.customer.phone != null) ...[
                            const SizedBox(height: 8),
                            Text('Phone: ${intervention.customer.phone}'),
                          ],
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Progress indicator
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blue[50],
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Task ${_currentTaskIndex + 1} of ${intervention.tasks.length}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          '${(intervention.completionPercentage * 100).toInt()}% Complete',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: intervention.completionPercentage,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
                    ),
                  ],
                ),
              ),

              // Current task card
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Task roadmap visualization
                      _TaskRoadmap(
                        tasks: intervention.tasks,
                        currentIndex: _currentTaskIndex,
                      ),
                      const SizedBox(height: 24),

                      // Current task details
                      Card(
                        elevation: 4,
                        color: Colors.blue[50],
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.blue[700],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${_currentTaskIndex + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      currentTask.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                  if (currentTask.isCompleted)
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green[700],
                                      size: 32,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  currentTask.description.isNotEmpty
                                      ? currentTask.description
                                      : currentTask.title,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Task Notes:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _notesControllers[currentTask.id],
                                decoration: InputDecoration(
                                  hintText: 'Add notes for this task...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                maxLines: 4,
                                onChanged: (value) {
                                  provider.updateTaskNotes(
                                    widget.interventionId,
                                    currentTask.id,
                                    value,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Navigation buttons
                      if (!isAllCompleted) ...[
                        Row(
                          children: [
                            if (_currentTaskIndex > 0)
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _currentTaskIndex--;
                                    });
                                  },
                                  icon: const Icon(Icons.arrow_back),
                                  label: const Text('Previous Task'),
                                ),
                              ),
                            if (_currentTaskIndex > 0) const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: currentTask.isCompleted
                                    ? null
                                    : () async {
                                        await provider.completeTask(
                                          widget.interventionId,
                                          currentTask.id,
                                        );
                                        if (mounted) {
                                          setState(() {
                                            if (!isLastTask) {
                                              _currentTaskIndex++;
                                            }
                                          });
                                        }
                                      },
                                icon: Icon(
                                  isLastTask ? Icons.check : Icons.arrow_forward,
                                ),
                                label: Text(
                                  isLastTask ? 'Complete' : 'Complete & Next',
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: Colors.blue[700],
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Card(
                          color: Colors.green[50],
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 64,
                                  color: Colors.green[700],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'All Tasks Completed!',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[700],
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Great job! You have completed all tasks for this intervention.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TaskRoadmap extends StatelessWidget {
  final List<Task> tasks;
  final int currentIndex;

  const _TaskRoadmap({
    required this.tasks,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task Roadmap',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...tasks.asMap().entries.map((entry) {
              final index = entry.key;
              final task = entry.value;
              final isCurrent = index == currentIndex;
              final isCompleted = task.isCompleted;
              final isPast = index < currentIndex;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    // Status indicator
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? Colors.green
                            : isCurrent
                                ? Colors.blue[700]
                                : Colors.grey[300],
                        border: Border.all(
                          color: isCompleted
                              ? Colors.green
                              : isCurrent
                                  ? Colors.blue[700]!
                                  : Colors.grey[400]!,
                          width: 2,
                        ),
                      ),
                      child: isCompleted
                          ? const Icon(Icons.check, size: 18, color: Colors.white)
                          : isCurrent
                              ? Center(
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : null,
                    ),
                    // Connector line
                    if (index < tasks.length - 1)
                      Container(
                        width: 2,
                        height: 40,
                        color: isPast || isCompleted
                            ? Colors.green
                            : Colors.grey[300],
                        margin: const EdgeInsets.only(left: 15),
                      ),
                    if (index < tasks.length - 1) const SizedBox(width: 15),
                  ],
                ),
              );
            }),
            // Task labels
            ...tasks.asMap().entries.map((entry) {
              final index = entry.key;
              final task = entry.value;
              final isCurrent = index == currentIndex;
              final isCompleted = task.isCompleted;

              return Padding(
                padding: EdgeInsets.only(
                  left: 48,
                  bottom: index < tasks.length - 1 ? 16 : 0,
                ),
                child: Text(
                  '${index + 1}. ${task.title}',
                  style: TextStyle(
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isCompleted
                        ? Colors.grey[600]
                        : isCurrent
                            ? Colors.blue[700]
                            : Colors.black87,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
