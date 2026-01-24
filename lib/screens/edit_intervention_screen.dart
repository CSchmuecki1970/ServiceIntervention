import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_selector/file_selector.dart';
import 'package:uuid/uuid.dart';
import '../providers/intervention_provider.dart';
import '../models/service_intervention.dart';
import '../models/task.dart';
import '../utils/currency_utils.dart';

class EditInterventionScreen extends StatefulWidget {
  final ServiceIntervention intervention;

  const EditInterventionScreen({
    super.key,
    required this.intervention,
  });

  @override
  State<EditInterventionScreen> createState() => _EditInterventionScreenState();
}

class _EditInterventionScreenState extends State<EditInterventionScreen>
    with TickerProviderStateMixin {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _generalNotesController;
  late final TextEditingController _customerNameController;
  late final TextEditingController _customerAddressController;
  late final TextEditingController _customerPhoneController;
  late final TextEditingController _customerEmailController;
  late final TextEditingController _hotelNameController;
  late final TextEditingController _hotelAddressController;
  late final TextEditingController _hotelCostSingleController;
  late final TextEditingController _hotelCostDoubleController;
  late final TextEditingController _hotelCostSuiteController;
  late final TextEditingController _hotelRatingController;
  late String _currencyCode;
  late bool _hotelBreakfastIncluded;
  late DateTime _startDate;
  late DateTime _endDate;
  late List<String> _documents;
  late List<String> _involvedPersons;
  late final TextEditingController _involvedPersonController;
  late TabController _tabController;
  late List<Task> _tasks;
  final Map<String, TextEditingController> _taskTitleControllers = {};
  final Map<String, TextEditingController> _taskDescriptionControllers = {};
  final Map<String, TextEditingController> _taskNotesControllers = {};
  final Map<String, TextEditingController> _taskStopReasonControllers = {};

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.intervention.title);
    _descriptionController =
        TextEditingController(text: widget.intervention.description);
    _generalNotesController =
        TextEditingController(text: widget.intervention.generalNotes ?? '');
    _customerNameController =
      TextEditingController(text: widget.intervention.customer.name);
    _customerAddressController =
      TextEditingController(text: widget.intervention.customer.address);
    _customerPhoneController = TextEditingController(
      text: widget.intervention.customer.phone ?? '');
    _customerEmailController = TextEditingController(
      text: widget.intervention.customer.email ?? '');
    _hotelNameController =
        TextEditingController(text: widget.intervention.hotelName ?? '');
    _hotelAddressController =
        TextEditingController(text: widget.intervention.hotelAddress ?? '');
    _hotelCostSingleController = TextEditingController(
        text: widget.intervention.hotelCostSingle?.toString() ?? '');
    _hotelCostDoubleController = TextEditingController(
        text: widget.intervention.hotelCostDouble?.toString() ?? '');
    _hotelCostSuiteController = TextEditingController(
        text: widget.intervention.hotelCostSuite?.toString() ?? '');
    _hotelRatingController =
        TextEditingController(text: widget.intervention.hotelRating?.toString() ?? '');
    _hotelBreakfastIncluded = widget.intervention.hotelBreakfastIncluded ?? false;
    _currencyCode = widget.intervention.currencyCode;
    _startDate = widget.intervention.startDate ?? DateTime.now();
    _endDate = widget.intervention.endDate ?? DateTime.now().add(const Duration(days: 1));
    _documents = List.from(widget.intervention.documents);
    _involvedPersons = List.from(widget.intervention.involvedPersons);
    _involvedPersonController = TextEditingController();
    _tasks = List.from(widget.intervention.tasks);
    for (final task in _tasks) {
      _taskTitleControllers[task.id] = TextEditingController(text: task.title);
      _taskDescriptionControllers[task.id] =
          TextEditingController(text: task.description);
      _taskNotesControllers[task.id] =
          TextEditingController(text: task.notes ?? '');
      _taskStopReasonControllers[task.id] =
        TextEditingController(text: task.stopReason ?? '');
    }
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _generalNotesController.dispose();
    _customerNameController.dispose();
    _customerAddressController.dispose();
    _customerPhoneController.dispose();
    _customerEmailController.dispose();
    _hotelNameController.dispose();
    _hotelAddressController.dispose();
    _hotelCostSingleController.dispose();
    _hotelCostDoubleController.dispose();
    _hotelCostSuiteController.dispose();
    _hotelRatingController.dispose();
    _involvedPersonController.dispose();
    for (final controller in _taskTitleControllers.values) {
      controller.dispose();
    }
    for (final controller in _taskDescriptionControllers.values) {
      controller.dispose();
    }
    for (final controller in _taskNotesControllers.values) {
      controller.dispose();
    }
    for (final controller in _taskStopReasonControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveChanges() async {
    for (final task in _tasks) {
      final title = _taskTitleControllers[task.id]?.text.trim() ?? '';
      if (title.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter all task titles')),
          );
        }
        return;
      }
      if (task.isStopped) {
        final reason = _taskStopReasonControllers[task.id]?.text.trim() ?? '';
        if (reason.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please enter a stop reason for stopped tasks')),
            );
          }
          return;
        }
      }
    }

    final updatedTasks = _tasks.asMap().entries.map((entry) {
      final index = entry.key;
      final task = entry.value;
      final title = _taskTitleControllers[task.id]!.text.trim();
      final description = _taskDescriptionControllers[task.id]!.text.trim();
      final notes = _taskNotesControllers[task.id]!.text.trim();
      final stopReason = _taskStopReasonControllers[task.id]!.text.trim();
      return task.copyWith(
        title: title,
        description: description.isEmpty ? title : description,
        order: index,
        notes: notes.isEmpty ? null : notes,
        stopReason: task.isStopped
            ? (stopReason.isEmpty ? null : stopReason)
            : null,
      );
    }).toList();

    final updated = widget.intervention.copyWith(
      customer: widget.intervention.customer.copyWith(
        name: _customerNameController.text.trim(),
        address: _customerAddressController.text.trim(),
        phone: _customerPhoneController.text.trim().isEmpty
            ? null
            : _customerPhoneController.text.trim(),
        email: _customerEmailController.text.trim().isEmpty
            ? null
            : _customerEmailController.text.trim(),
      ),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      tasks: updatedTasks,
      generalNotes: _generalNotesController.text.trim().isEmpty
          ? null
          : _generalNotesController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      hotelName: _hotelNameController.text.trim().isEmpty
          ? null
          : _hotelNameController.text.trim(),
      hotelAddress: _hotelAddressController.text.trim().isEmpty
          ? null
          : _hotelAddressController.text.trim(),
      hotelCostSingle: _hotelCostSingleController.text.trim().isEmpty
          ? null
          : double.tryParse(_hotelCostSingleController.text.trim()),
      hotelCostDouble: _hotelCostDoubleController.text.trim().isEmpty
          ? null
          : double.tryParse(_hotelCostDoubleController.text.trim()),
      hotelCostSuite: _hotelCostSuiteController.text.trim().isEmpty
          ? null
          : double.tryParse(_hotelCostSuiteController.text.trim()),
      hotelBreakfastIncluded: _hotelBreakfastIncluded,
      hotelRating: _hotelRatingController.text.trim().isEmpty
          ? null
          : double.tryParse(_hotelRatingController.text.trim()),
      documents: _documents,
      involvedPersons: _involvedPersons,
      currencyCode: _currencyCode,
    );

    final provider = Provider.of<InterventionProvider>(context, listen: false);
    await provider.updateIntervention(updated);

    if (mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Intervention updated successfully')),
      );
    }
  }

  void _removeDocument(int index) {
    setState(() {
      _documents.removeAt(index);
    });
  }

  Future<void> _pickFiles() async {
    try {
      const XTypeGroup typeGroup = XTypeGroup(
        label: 'Documents and Images',
        extensions: <String>['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx', 'xls', 'xlsx'],
      );
      final List<XFile> files = await openFiles(
        acceptedTypeGroups: <XTypeGroup>[typeGroup],
      );

      if (files.isNotEmpty && mounted) {
        setState(() {
          _documents.addAll(files.map((f) => f.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking files: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Intervention'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Info & Travel', icon: Icon(Icons.edit)),
            Tab(text: 'Customer', icon: Icon(Icons.person)),
            Tab(text: 'Notes', icon: Icon(Icons.notes)),
            Tab(text: 'Documents', icon: Icon(Icons.attach_file)),
            Tab(text: 'Tasks', icon: Icon(Icons.checklist)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInfoTab(),
          _buildCustomerTab(),
          _buildNotesTab(),
          _buildDocumentsTab(),
          _buildTasksTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveChanges,
        label: const Text('Save Changes'),
        icon: const Icon(Icons.save),
      ),
    );
  }

  Widget _buildInfoTab() {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencySymbol = CurrencyUtils.symbolFor(_currencyCode);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Basic Info
        Text(
          'Basic Information',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Title',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.title),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 24),
        // Travel Dates
        Text(
          'Travel Dates',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() {
                      _startDate = picked;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'From Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.date_range),
                  ),
                  child: Text(dateFormat.format(_startDate)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _endDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() {
                      _endDate = picked;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'To Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.date_range),
                  ),
                  child: Text(dateFormat.format(_endDate)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Currency
        Text(
          'Currency',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _currencyCode,
          decoration: const InputDecoration(
            labelText: 'Currency',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.currency_exchange),
          ),
          items: CurrencyUtils.supportedCurrencies
              .map(
                (currency) => DropdownMenuItem(
                  value: currency.code,
                  child: Text(CurrencyUtils.labelFor(currency.code)),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _currencyCode = value;
            });
          },
        ),
        const SizedBox(height: 24),
        // Hotel Information
        Text(
          'Hotel Information',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _hotelNameController,
          decoration: const InputDecoration(
            labelText: 'Hotel Name',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.hotel),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _hotelAddressController,
          decoration: const InputDecoration(
            labelText: 'Hotel Address',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        Text(
          'Costs per Day (per room)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _hotelCostSingleController,
                decoration: InputDecoration(
                  labelText: 'Single',
                  border: OutlineInputBorder(),
                  prefixText: '$currencySymbol ',
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _hotelCostDoubleController,
                decoration: InputDecoration(
                  labelText: 'Double',
                  border: OutlineInputBorder(),
                  prefixText: '$currencySymbol ',
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _hotelCostSuiteController,
                decoration: InputDecoration(
                  labelText: 'Suite',
                  border: OutlineInputBorder(),
                  prefixText: '$currencySymbol ',
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                title: const Text('Breakfast Included'),
                value: _hotelBreakfastIncluded,
                onChanged: (value) {
                  setState(() {
                    _hotelBreakfastIncluded = value ?? false;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ),
            Expanded(
              child: TextFormField(
                controller: _hotelRatingController,
                decoration: const InputDecoration(
                  labelText: 'Rating (1-5)',
                  border: OutlineInputBorder(),
                  suffixText: '★',
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // People Involved
        Text(
          'People Involved',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _involvedPersonController,
                decoration: const InputDecoration(
                  labelText: 'Add person name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_add),
                ),
                onFieldSubmitted: (_) => _addInvolvedPerson(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _addInvolvedPerson,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_involvedPersons.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _involvedPersons.map((person) {
              return Chip(
                label: Text(person),
                onDeleted: () {
                  setState(() {
                    _involvedPersons.remove(person);
                  });
                },
                deleteIcon: const Icon(Icons.close, size: 18),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildCustomerTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextFormField(
          controller: _customerNameController,
          decoration: const InputDecoration(
            labelText: 'Customer Name',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _customerAddressController,
          decoration: const InputDecoration(
            labelText: 'Address',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _customerPhoneController,
          decoration: const InputDecoration(
            labelText: 'Phone (Optional)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _customerEmailController,
          decoration: const InputDecoration(
            labelText: 'Email (Optional)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );
  }

  void _addInvolvedPerson() {
    final personName = _involvedPersonController.text.trim();
    if (personName.isNotEmpty) {
      setState(() {
        _involvedPersons.add(personName);
        _involvedPersonController.clear();
      });
    }
  }

  Widget _buildNotesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'General Notes',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _generalNotesController,
          decoration: const InputDecoration(
            labelText: 'Additional Notes',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.note),
            hintText: 'Add any additional notes about this intervention',
          ),
          maxLines: 10,
        ),
      ],
    );
  }

  Widget _buildDocumentsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Documents & Pictures (${_documents.length})',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
            ),
            ElevatedButton.icon(
              onPressed: _pickFiles,
              icon: const Icon(Icons.add),
              label: const Text('Add Files'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_documents.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.insert_drive_file_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No documents added yet',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: List.generate(_documents.length, (index) {
              final fileName = _documents[index].split('/').last;
              return Card(
                child: ListTile(
                  leading: Icon(
                    _getFileIcon(fileName),
                    color: Colors.blue[700],
                  ),
                  title: Text(fileName),
                  subtitle: Text(_documents[index]),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeDocument(index),
                  ),
                ),
              );
            }),
          ),
      ],
    );
  }

  Widget _buildTasksTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tasks (${_tasks.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  final newTask = Task(
                    id: const Uuid().v4(),
                    title: '',
                    description: '',
                    order: _tasks.length,
                    isCompleted: false,
                  );
                  _tasks.add(newTask);
                  _taskTitleControllers[newTask.id] = TextEditingController();
                  _taskDescriptionControllers[newTask.id] =
                      TextEditingController();
                  _taskNotesControllers[newTask.id] = TextEditingController();
                  _taskStopReasonControllers[newTask.id] =
                      TextEditingController();
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Task'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_tasks.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tasks added yet. Click "Add Task" to get started.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: List.generate(_tasks.length, (index) {
              final task = _tasks[index];
              final titleController = _taskTitleControllers[task.id]!;
              final descriptionController =
                  _taskDescriptionControllers[task.id]!;
              final notesController = _taskNotesControllers[task.id]!;
                final stopReasonController =
                  _taskStopReasonControllers[task.id]!;
              return Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Task ${index + 1}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _taskTitleControllers[task.id]!.dispose();
                                    _taskDescriptionControllers[task.id]!
                                        .dispose();
                                    _taskNotesControllers[task.id]!.dispose();
                                    _taskStopReasonControllers[task.id]!
                                        .dispose();
                                    _taskTitleControllers.remove(task.id);
                                    _taskDescriptionControllers.remove(task.id);
                                    _taskNotesControllers.remove(task.id);
                                    _taskStopReasonControllers.remove(task.id);
                                    _tasks.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Completed'),
                            value: task.isCompleted,
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _tasks[index] = task.copyWith(
                                  isCompleted: value,
                                  completedAt:
                                      value ? DateTime.now() : null,
                                  isStopped: value ? false : task.isStopped,
                                  stopReason: value ? null : task.stopReason,
                                  stoppedAt: value ? null : task.stoppedAt,
                                );
                              });
                            },
                          ),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Stopped (Cannot be completed)'),
                            value: task.isStopped,
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                if (!value) {
                                  _taskStopReasonControllers[task.id]!.clear();
                                }
                                _tasks[index] = task.copyWith(
                                  isStopped: value,
                                  stoppedAt: value ? DateTime.now() : null,
                                  isCompleted: value ? false : task.isCompleted,
                                  completedAt: value ? null : task.completedAt,
                                  stopReason: value ? task.stopReason : null,
                                );
                              });
                            },
                          ),
                          TextFormField(
                            controller: titleController,
                            decoration: const InputDecoration(
                              labelText: 'Task Title',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Task Details (Optional)',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: notesController,
                            decoration: const InputDecoration(
                              labelText: 'Task Notes (Optional)',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: stopReasonController,
                            enabled: task.isStopped,
                            decoration: const InputDecoration(
                              labelText: 'Stop Reason (Required if stopped)',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              );
            }),
          ),
      ],
    );
  }

  IconData _getFileIcon(String fileName) {
    if (fileName.endsWith('.pdf')) {
      return Icons.picture_as_pdf;
    } else if (fileName.endsWith('.doc') || fileName.endsWith('.docx')) {
      return Icons.description;
    } else if (fileName.endsWith('.jpg') ||
        fileName.endsWith('.jpeg') ||
        fileName.endsWith('.png')) {
      return Icons.image;
    }
    return Icons.insert_drive_file;
  }
}
