import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:io';
import '../providers/intervention_provider.dart';
import '../models/service_intervention.dart';
import '../models/task.dart';
import '../services/report_service.dart';
import 'create_intervention_screen.dart';

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
  final Map<String, TextEditingController> _stopReasonControllers = {};
  late stt.SpeechToText _speechToText;
  bool _isListening = false;
  String _listeningTaskId = '';
  final Map<String, bool> _isSaved = {};
  final Map<String, DateTime> _lastSaveTime = {};
  final Map<String, String> _listeningText = {};
  final Map<String, bool> _isReconnecting = {};

  @override
  void initState() {
    super.initState();
    _speechToText = stt.SpeechToText();
  }

  @override
  void dispose() {
    for (var controller in _notesControllers.values) {
      controller.dispose();
    }
    for (var controller in _stopReasonControllers.values) {
      controller.dispose();
    }
    _speechToText.stop();
    super.dispose();
  }

  void _initializeNotesControllers(List<Task> tasks) {
    for (var task in tasks) {
      if (!_notesControllers.containsKey(task.id)) {
        _notesControllers[task.id] =
            TextEditingController(text: task.notes ?? '');
      }
      if (!_stopReasonControllers.containsKey(task.id)) {
        _stopReasonControllers[task.id] =
            TextEditingController(text: task.stopReason ?? '');
      }
    }
  }

  int _getCurrentTaskIndex(ServiceIntervention intervention) {
    for (int i = 0; i < intervention.tasks.length; i++) {
      if (!intervention.tasks[i].isCompleted &&
          !intervention.tasks[i].isStopped) {
        return i;
      }
    }
    return intervention.tasks.length - 1;
  }

  void _startListening(String taskId) async {
    // Check if platform supports speech_to_text
    if (!Platform.isAndroid && !Platform.isIOS) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech-to-text is only available on Android and iOS'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (!_isListening) {
      bool available = await _speechToText.initialize(
        onError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${error.errorMsg}')),
          );
        },
        onStatus: (status) {
          if (!_isListening || _listeningTaskId.isEmpty) {
            return;
          }

          if (status == 'done' || status == 'notListening') {
            setState(() {
              _isReconnecting[_listeningTaskId] = true;
            });
            _restartListening(_listeningTaskId);
          }
        },
      );

      if (available) {
        setState(() {
          _isListening = true;
          _listeningTaskId = taskId;
          _isReconnecting[taskId] = false;
        });

        // Store the existing text before starting speech recognition
        String existingText = _notesControllers[taskId]!.text;
        String accumulatedFinalText = existingText; // Track all finalized text
        
        _speechToText.listen(
          listenFor: const Duration(minutes: 10), // Extended listening duration
          pauseFor: const Duration(minutes: 5), // Very long pause tolerance - 5 minutes
          partialResults: true,
          onResult: (result) {
            setState(() {
              if (_notesControllers.containsKey(taskId)) {
                String displayText = accumulatedFinalText;

                if (result.finalResult) {
                  // Append this finalized segment to our accumulated text
                  if (result.recognizedWords.isNotEmpty) {
                    if (accumulatedFinalText.isNotEmpty && !accumulatedFinalText.endsWith(' ')) {
                      accumulatedFinalText += ' ';
                    }
                    accumulatedFinalText += result.recognizedWords;
                  }
                  displayText = accumulatedFinalText;
                  _listeningText[taskId] = result.recognizedWords;
                } else {
                  // Interim result - show accumulated final text + current interim
                  if (result.recognizedWords.isNotEmpty) {
                    String interimText = result.recognizedWords;
                    if (displayText.isNotEmpty && !displayText.endsWith(' ')) {
                      displayText += ' ';
                    }
                    displayText += interimText;
                  }
                }

                _notesControllers[taskId]!.text = displayText;
              }
            });
          },
        );
      }
    } else {
      _stopListening();
    }
  }

  void _restartListening(String taskId) {
    if (!mounted || !_isListening || _listeningTaskId != taskId) {
      return;
    }

    if (_speechToText.isListening) {
      return;
    }

    _speechToText.listen(
      listenFor: const Duration(minutes: 10),
      pauseFor: const Duration(minutes: 5),
      partialResults: true,
      onResult: (result) {
        if (!mounted || !_notesControllers.containsKey(taskId)) {
          return;
        }

        setState(() {
          _isReconnecting[taskId] = false;
          final currentText = _notesControllers[taskId]!.text;
          String displayText = currentText;

          if (result.finalResult) {
            if (result.recognizedWords.isNotEmpty) {
              if (displayText.isNotEmpty && !displayText.endsWith(' ')) {
                displayText += ' ';
              }
              displayText += result.recognizedWords;
            }
            _listeningText[taskId] = result.recognizedWords;
          } else {
            if (result.recognizedWords.isNotEmpty) {
              if (displayText.isNotEmpty && !displayText.endsWith(' ')) {
                displayText += ' ';
              }
              displayText += result.recognizedWords;
            }
          }

          _notesControllers[taskId]!.text = displayText;
        });
      },
    );
  }

  void _stopListening() {
    _speechToText.stop();
    
    // Save the final text when stopping speech recognition
    if (_listeningTaskId.isNotEmpty && _notesControllers.containsKey(_listeningTaskId)) {
      try {
        String finalText = _notesControllers[_listeningTaskId]!.text;
        Provider.of<InterventionProvider>(context, listen: false)
            .updateTaskNotes(widget.interventionId, _listeningTaskId, finalText);
        
        // Show save confirmation and visual indicator
        setState(() {
          _isSaved[_listeningTaskId] = true;
          _lastSaveTime[_listeningTaskId] = DateTime.now();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Task notes saved from speech', style: TextStyle(color: Colors.white)),
              ],
            ),
            backgroundColor: Colors.green[600],
            duration: const Duration(seconds: 2),
          ),
        );

        // Reset save indicator after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _isSaved[_listeningTaskId] = false;
            });
          }
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Failed to save: ${e.toString()}', style: const TextStyle(color: Colors.white))),
              ],
            ),
            backgroundColor: Colors.red[600],
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
    
    setState(() {
      _listeningText.clear();
      _isReconnecting.clear();
      _isListening = false;
      _listeningTaskId = '';
    });
  }

  /// Manual save function for task notes
  Future<void> _saveCurrentTaskNotes() async {
    try {
      final intervention = Provider.of<InterventionProvider>(context, listen: false)
          .interventions
          .firstWhere((i) => i.id == widget.interventionId);
      
      final currentTask = intervention.tasks[_currentTaskIndex];
      final notes = _notesControllers[currentTask.id]?.text ?? '';
      
      await Provider.of<InterventionProvider>(context, listen: false)
          .updateTaskNotes(widget.interventionId, currentTask.id, notes);
      
      setState(() {
        _isSaved[currentTask.id] = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Task notes saved successfully', style: TextStyle(color: Colors.white)),
            ],
          ),
          backgroundColor: Colors.green[600],
          duration: const Duration(seconds: 2),
        ),
      );

      // Reset save indicator after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isSaved[currentTask.id] = false;
          });
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Failed to save: $e', style: const TextStyle(color: Colors.white))),
            ],
          ),
          backgroundColor: Colors.red[600],
          duration: const Duration(seconds: 3),
        ),
      );
    }
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
        
        // Initialize _currentTaskIndex only once, don't reset it on every build
        if (_currentTaskIndex >= intervention.tasks.length) {
          _currentTaskIndex = intervention.tasks.length - 1;
        }

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
        final isTaskBlocked = currentTask.isStopped;

        return Scaffold(
          appBar: AppBar(
            title: Text(intervention.title),
            actions: [
              PopupMenuButton<String>(
                tooltip: 'Export Report',
                onSelected: (value) async {
                  try {
                    File file;
                    if (value == 'pdf') {
                      file = await ReportService.exportReportAsPdf(intervention);
                    } else {
                      file = await ReportService.exportReportAsText(intervention);
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text('${value.toUpperCase()} report saved to: ${file.path}', style: const TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.green[600],
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error generating ${value.toUpperCase()} report: $e', style: const TextStyle(color: Colors.white)),
                        backgroundColor: Colors.red[600],
                      ),
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem<String>(
                    value: 'pdf',
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Export as PDF'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'text',
                    child: Row(
                      children: [
                        Icon(Icons.text_snippet),
                        SizedBox(width: 8),
                        Text('Export as Text'),
                      ],
                    ),
                  ),
                ],
              ),
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
              // Progress indicator - more compact
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Task ${_currentTaskIndex + 1} of ${intervention.tasks.length}',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                              ),
                        ),
                        Text(
                          '${(intervention.completionPercentage * 100).toInt()}% Complete',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: intervention.completionPercentage,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
                    ),
                  ],
                ),
              ),

              // Current task card and notes - give more space to notes
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Task roadmap visualization - more compact
                      _TaskRoadmap(
                        tasks: intervention.tasks,
                        currentIndex: _currentTaskIndex,
                      ),
                      const SizedBox(height: 12),

                      // Current task details - more compact
                      Card(
                        elevation: 4,
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final padding = constraints.maxWidth < 400 ? 8.0 : 12.0;
                            final spacing = constraints.maxWidth < 400 ? 6.0 : 8.0;
                            
                            return Padding(
                              padding: EdgeInsets.all(padding),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
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
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          currentTask.title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (currentTask.isCompleted) ...[
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.green[700],
                                          size: 24,
                                        ),
                                      ],
                                      if (currentTask.isStopped) ...[
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.block,
                                          color: Colors.red[700],
                                          size: 24,
                                        ),
                                      ],
                                    ],
                                  ),
                                  SizedBox(height: spacing),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      currentTask.description.isNotEmpty
                                          ? currentTask.description
                                          : currentTask.title,
                                      style: Theme.of(context).textTheme.bodySmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(height: spacing),
                                  if (_isSaved[currentTask.id] ?? false)
                                    Row(
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.green[600], size: 18),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Saved',
                                          style: TextStyle(
                                            color: Colors.green[600],
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Task selector dropdown and save button
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _currentTaskIndex,
                              decoration: InputDecoration(
                                labelText: 'Select Task',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(Icons.list),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: List.generate(
                                intervention.tasks.length,
                                (index) => DropdownMenuItem(
                                  value: index,
                                  child: SizedBox(
                                    width: 200,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: intervention.tasks[index].isCompleted
                                                ? Colors.green[700]
                                                : intervention.tasks[index].isStopped
                                                    ? Colors.red[700]
                                                    : Colors.blue[700],
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${index + 1}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            intervention.tasks[index].title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _currentTaskIndex = value;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _saveCurrentTaskNotes,
                            icon: const Icon(Icons.save),
                            label: const Text('Save'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Real-time listening display
                      if (_isListening && _listeningTaskId == currentTask.id)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[300]!, width: 2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.mic, color: Colors.red, size: 16),
                                  SizedBox(width: 8),
                                  Text(
                                    'Listening...',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _listeningText[currentTask.id] ?? '',
                                style: const TextStyle(fontSize: 14, color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                      if (_isListening && _listeningTaskId == currentTask.id)
                        const SizedBox(height: 12),
                      TextField(
                        controller: _notesControllers[currentTask.id],
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          hintText: _isListening && _listeningTaskId == currentTask.id
                              ? 'Listening... (speech will be appended)'
                              : 'Add notes for this task...',
                          hintStyle: const TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          suffixIcon: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: IconButton(
                              icon: Icon(
                                _isListening && _listeningTaskId == currentTask.id
                                    ? Icons.mic
                                    : Icons.mic_none,
                                color: (Platform.isAndroid || Platform.isIOS)
                                    ? (_isListening && _listeningTaskId == currentTask.id
                                        ? Colors.red
                                        : Colors.blue[700])
                                    : Colors.grey,
                              ),
                              onPressed: (Platform.isAndroid || Platform.isIOS) && _isReconnecting[currentTask.id] != true
                                  ? () {
                                      if (_isListening && _listeningTaskId == currentTask.id) {
                                        _stopListening();
                                      } else {
                                        _startListening(currentTask.id);
                                      }
                                    }
                                  : null,
                              tooltip: (Platform.isAndroid || Platform.isIOS)
                                  ? (_isListening && _listeningTaskId == currentTask.id
                                      ? 'Stop Recording (Text will be appended)'
                                      : 'Start Recording (Will append to existing text)')
                                  : 'Not available on this platform',
                            ),
                          ),
                        ),
                        maxLines: 8,
                        minLines: 6,
                        onChanged: (value) {
                          final currentProvider = Provider.of<InterventionProvider>(context, listen: false);
                          currentProvider.updateTaskNotes(
                            widget.interventionId,
                            currentTask.id,
                            value,
                          );
                        },
                      ),
                      if (_isListening && _listeningTaskId == currentTask.id)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '🎤 Speech will be appended to existing text',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _stopReasonControllers[currentTask.id],
                        decoration: InputDecoration(
                          labelText: 'Stop Reason (if task cannot be completed)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        maxLines: 3,
                        enabled: !currentTask.isCompleted,
                        onChanged: (value) {
                          if (currentTask.isStopped) {
                            final currentProvider = Provider.of<InterventionProvider>(context, listen: false);
                            currentProvider.updateTaskStopReason(
                              widget.interventionId,
                              currentTask.id,
                              value.trim(),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: (currentTask.isCompleted || currentTask.isStopped)
                              ? null
                              : () async {
                                  final reason =
                                      _stopReasonControllers[currentTask.id]!.text.trim();
                                  if (reason.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Please enter a stop reason first.'),
                                      ),
                                    );
                                    return;
                                  }
                                  final currentProvider = Provider.of<InterventionProvider>(context, listen: false);
                                  await currentProvider.stopTask(
                                    widget.interventionId,
                                    currentTask.id,
                                    reason,
                                  );
                                  if (mounted && !isLastTask) {
                                    setState(() {
                                      _currentTaskIndex++;
                                    });
                                  }
                                },
                          icon: const Icon(Icons.block),
                          label: const Text('Stop Task'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red[700],
                            side: BorderSide(color: Colors.red[700]!),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Navigation buttons
                      if (!isAllCompleted) ...[
                        LayoutBuilder(
                          builder: (context, constraints) {
                            // If screen is narrow (portrait), stack buttons vertically
                            if (constraints.maxWidth < 400) {
                              return Column(
                                children: [
                                  if (_currentTaskIndex > 0)
                                    SizedBox(
                                      width: double.infinity,
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
                                  if (_currentTaskIndex > 0) const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: (currentTask.isCompleted || isTaskBlocked)
                                          ? null
                                          : () async {
                                              final currentProvider = Provider.of<InterventionProvider>(context, listen: false);
                                              await currentProvider.completeTask(
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
                              );
                            } else {
                              // If screen is wide (landscape), use horizontal layout
                              return Row(
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
                                      onPressed: (currentTask.isCompleted || isTaskBlocked)
                                          ? null
                                          : () async {
                                              final currentProvider = Provider.of<InterventionProvider>(context, listen: false);
                                              await currentProvider.completeTask(
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
                              );
                            }
                          },
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
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        try {
                                          final file = await ReportService.exportReportAsPdf(intervention);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                children: [
                                                  const Icon(Icons.check_circle, color: Colors.white),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text('PDF report saved to: ${file.path}', style: const TextStyle(color: Colors.white)),
                                                  ),
                                                ],
                                              ),
                                              backgroundColor: Colors.green[600],
                                              duration: const Duration(seconds: 3),
                                            ),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Error generating PDF report: $e', style: const TextStyle(color: Colors.white)),
                                              backgroundColor: Colors.red[600],
                                            ),
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.picture_as_pdf),
                                      label: const Text('PDF Report'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red[700],
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        try {
                                          final file = await ReportService.exportReportAsText(intervention);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                children: [
                                                  const Icon(Icons.check_circle, color: Colors.white),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text('Text report saved to: ${file.path}', style: const TextStyle(color: Colors.white)),
                                                  ),
                                                ],
                                              ),
                                              backgroundColor: Colors.green[600],
                                              duration: const Duration(seconds: 3),
                                            ),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Error generating text report: $e', style: const TextStyle(color: Colors.white)),
                                              backgroundColor: Colors.red[600],
                                            ),
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.text_snippet),
                                      label: const Text('Text Report'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue[700],
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      ),
                                    ),
                                  ],
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
              final isStopped = task.isStopped;
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
                        color: isStopped
                            ? Colors.red[600]
                            : isCompleted
                                ? Colors.green
                                : isCurrent
                                    ? Colors.blue[700]
                                    : Colors.grey[300],
                        border: Border.all(
                          color: isStopped
                              ? Colors.red[700]!
                              : isCompleted
                                  ? Colors.green
                                  : isCurrent
                                      ? Colors.blue[700]!
                                      : Colors.grey[400]!,
                          width: 2,
                        ),
                      ),
                      child: isStopped
                          ? const Icon(Icons.block, size: 18, color: Colors.white)
                          : isCompleted
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
                        color: isStopped
                            ? Colors.red[300]
                            : isPast || isCompleted
                                ? Colors.green
                                : Colors.grey[300],
                        margin: const EdgeInsets.only(left: 15),
                      ),
                    if (index < tasks.length - 1) const SizedBox(width: 15),
                    // Task text beside the roadmap
                    Expanded(
                      child: Text(
                        '${index + 1}. ${task.title}',
                        style: TextStyle(
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isStopped
                              ? Colors.red[700]
                              : isCompleted
                                  ? Colors.grey[600]
                                  : isCurrent
                                      ? Colors.blue[700]
                                      : Colors.black87,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
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
