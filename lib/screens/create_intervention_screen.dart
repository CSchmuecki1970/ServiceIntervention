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

class _CreateInterventionScreenState extends State<CreateInterventionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _customerAddressController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerEmailController = TextEditingController();
  DateTime _scheduledDate = DateTime.now().add(const Duration(days: 1));
  final List<Task> _tasks = [];
  final Map<String, TextEditingController> _taskControllers = {};

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _customerNameController.dispose();
    _customerAddressController.dispose();
    _customerPhoneController.dispose();
    _customerEmailController.dispose();
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
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_scheduledDate),
      );
      if (time != null) {
        setState(() {
          _scheduledDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _addTask() {
    final taskId = const Uuid().v4();
    final controller = TextEditingController();
    _taskControllers[taskId] = controller;

    setState(() {
      _tasks.add(Task(
        id: taskId,
        title: '',
        description: '',
        order: _tasks.length,
      ));
    });
  }

  void _removeTask(int index) {
    final task = _tasks[index];
    _taskControllers[task.id]?.dispose();
    _taskControllers.remove(task.id);
    setState(() {
      _tasks.removeAt(index);
      // Reorder remaining tasks
      for (int i = 0; i < _tasks.length; i++) {
        _tasks[i] = _tasks[i].copyWith(order: i);
      }
    });
  }

  Future<void> _saveIntervention() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one task')),
      );
      return;
    }

    // Validate tasks
    for (var task in _tasks) {
      final controller = _taskControllers[task.id];
      if (controller == null || controller.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all task titles')),
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
      ),
      body: Form(
        key: _formKey,
        child: ListView(
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
            const Text(
              'Customer Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _customerAddressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _customerPhoneController,
              decoration: const InputDecoration(
                labelText: 'Phone (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _customerEmailController,
              decoration: const InputDecoration(
                labelText: 'Email (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            const Text(
              'Schedule',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tasks',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: _addTask,
                  icon: const Icon(Icons.add_circle),
                  tooltip: 'Add Task',
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_tasks.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Text('No tasks added yet. Tap + to add tasks.'),
                ),
              )
            else
              ..._tasks.asMap().entries.map((entry) {
                final index = entry.key;
                final task = entry.value;
                final controller = _taskControllers[task.id] ?? TextEditingController();
                if (_taskControllers[task.id] == null) {
                  _taskControllers[task.id] = controller;
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: controller,
                            decoration: InputDecoration(
                              labelText: 'Task ${index + 1}',
                              hintText: 'Enter task description',
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _removeTask(index),
                          icon: const Icon(Icons.delete_outline),
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveIntervention,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Create Intervention'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
