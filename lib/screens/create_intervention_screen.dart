import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/intervention_provider.dart';
import '../models/service_intervention.dart';
import '../models/customer.dart';
import '../models/task.dart';

class CreateInterventionScreen extends StatefulWidget {
  const CreateInterventionScreen({super.key});

  @override
  State<CreateInterventionScreen> createState() => _CreateInterventionScreenState();
}

class _CreateInterventionScreenState extends State<CreateInterventionScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  // Basic Info Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Customer Controllers
  final _customerNameController = TextEditingController();
  final _customerAddressController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerEmailController = TextEditingController();

  // Travel Controllers
  final _hotelNameController = TextEditingController();
  final _hotelAddressController = TextEditingController();
  final _hotelCostSingleController = TextEditingController();
  final _hotelCostDoubleController = TextEditingController();
  final _hotelCostSuiteController = TextEditingController();
  final _hotelRatingController = TextEditingController();
  bool _hotelBreakfastIncluded = false;

  // Schedule
  DateTime _scheduledDate = DateTime.now().add(const Duration(days: 1));
  DateTime? _startDate;
  DateTime? _endDate;

  // Tasks
  final List<Task> _tasks = [];
  final Map<String, TextEditingController> _taskControllers = {};

  // Involved Persons
  final List<String> _involvedPersons = [];
  final _involvedPersonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
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
    for (var controller in _taskControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_scheduledDate),
      );
      if (pickedTime != null) {
        setState(() {
          _scheduledDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _saveIntervention() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    for (var task in _tasks) {
      if (_taskControllers[task.id]!.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter all task titles')),
        );
        return;
      }
    }

    final customer = Customer(
      id: const Uuid().v4(),
      name: _customerNameController.text.trim(),
      address: _customerAddressController.text.trim(),
      phone: _customerPhoneController.text.trim().isEmpty
          ? null
          : _customerPhoneController.text.trim(),
      email: _customerEmailController.text.trim().isEmpty
          ? null
          : _customerEmailController.text.trim(),
    );

    final tasks = _tasks.map((task) {
      final controller = _taskControllers[task.id]!;
      return task.copyWith(
        title: controller.text.trim(),
        description: controller.text.trim(),
      );
    }).toList();

    final intervention = ServiceIntervention(
      id: const Uuid().v4(),
      customer: customer,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      scheduledDate: _scheduledDate,
      tasks: tasks,
      createdAt: DateTime.now(),
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
      involvedPersons: _involvedPersons,
    );

    final provider = Provider.of<InterventionProvider>(context, listen: false);
    await provider.addIntervention(intervention);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Intervention created successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Intervention'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Basic Info', icon: Icon(Icons.info)),
            Tab(text: 'Customer', icon: Icon(Icons.person)),
            Tab(text: 'Travel', icon: Icon(Icons.hotel)),
            Tab(text: 'Tasks', icon: Icon(Icons.checklist)),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildBasicInfoTab(),
            _buildCustomerTab(),
            _buildTravelTab(),
            _buildTasksTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Intervention Title',
            hintText: 'e.g., Annual Maintenance',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.title),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a title';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'Brief description of the intervention',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description),
          ),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a description';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        Text(
          'Scheduled Date & Time',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => _selectDate(context),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Scheduled Date & Time',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.calendar_today),
            ),
            child: Text(
              '${_scheduledDate.day}/${_scheduledDate.month}/${_scheduledDate.year} at ${_scheduledDate.hour.toString().padLeft(2, '0')}:${_scheduledDate.minute.toString().padLeft(2, '0')}',
            ),
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: _saveIntervention,
          icon: const Icon(Icons.check),
          label: const Text('Create Intervention'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
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
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter customer name';
            }
            return null;
          },
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
        const SizedBox(height: 20),
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

  void _addInvolvedPerson() {
    final personName = _involvedPersonController.text.trim();
    if (personName.isNotEmpty) {
      setState(() {
        _involvedPersons.add(personName);
        _involvedPersonController.clear();
      });
    }
  }

  Widget _buildTravelTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
                    initialDate: _startDate ?? DateTime.now(),
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
                  child: Text(
                    _startDate == null
                        ? 'Select date'
                        : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _endDate ?? DateTime.now(),
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
                  child: Text(
                    _endDate == null
                        ? 'Select date'
                        : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
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
                decoration: const InputDecoration(
                  labelText: 'Single',
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _hotelCostDoubleController,
                decoration: const InputDecoration(
                  labelText: 'Double',
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _hotelCostSuiteController,
                decoration: const InputDecoration(
                  labelText: 'Suite',
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
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
                  _taskControllers[newTask.id] = TextEditingController();
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
              final controller = _taskControllers[task.id]!;
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
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _taskControllers[task.id]!.dispose();
                                    _taskControllers.remove(task.id);
                                    _tasks.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                          TextFormField(
                            controller: controller,
                            decoration: const InputDecoration(
                              labelText: 'Task Title',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a task title';
                              }
                              return null;
                            },
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
}
