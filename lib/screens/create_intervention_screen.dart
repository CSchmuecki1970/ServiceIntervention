import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/intervention_provider.dart';
import '../providers/create_intervention_provider.dart';
import '../models/service_intervention.dart';
import '../models/customer.dart';
import '../models/task.dart';
import '../utils/currency_utils.dart';
import '../providers/settings_provider.dart';

class CreateInterventionScreen extends StatefulWidget {
  const CreateInterventionScreen({super.key});

  @override
  State<CreateInterventionScreen> createState() => _CreateInterventionScreenState();
}

class _CreateInterventionScreenState extends State<CreateInterventionScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  // Controllers for temporary text field management
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _customerNameController;
  late TextEditingController _customerAddressController;
  late TextEditingController _customerPhoneController;
  late TextEditingController _customerEmailController;
  late TextEditingController _hotelNameController;
  late TextEditingController _hotelAddressController;
  late TextEditingController _hotelCostSingleController;
  late TextEditingController _hotelCostDoubleController;
  late TextEditingController _hotelCostSuiteController;
  late TextEditingController _hotelRatingController;
  late TextEditingController _involvedPersonController;
  final Map<String, TextEditingController> _taskControllers = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Initialize controllers from provider
    final createProvider = context.read<CreateInterventionProvider>();
    
    _titleController = TextEditingController(text: createProvider.title);
    _descriptionController = TextEditingController(text: createProvider.description);
    _customerNameController = TextEditingController(text: createProvider.customerName);
    _customerAddressController = TextEditingController(text: createProvider.customerAddress);
    _customerPhoneController = TextEditingController(text: createProvider.customerPhone);
    _customerEmailController = TextEditingController(text: createProvider.customerEmail);
    _hotelNameController = TextEditingController(text: createProvider.hotelName);
    _hotelAddressController = TextEditingController(text: createProvider.hotelAddress);
    _hotelCostSingleController = TextEditingController(text: createProvider.hotelCostSingle);
    _hotelCostDoubleController = TextEditingController(text: createProvider.hotelCostDouble);
    _hotelCostSuiteController = TextEditingController(text: createProvider.hotelCostSuite);
    _hotelRatingController = TextEditingController(text: createProvider.hotelRating);
    _involvedPersonController = TextEditingController();

    // Set up listeners to sync with provider
    _titleController.addListener(() => createProvider.setTitle(_titleController.text));
    _descriptionController.addListener(() => createProvider.setDescription(_descriptionController.text));
    _customerNameController.addListener(() => createProvider.setCustomerName(_customerNameController.text));
    _customerAddressController.addListener(() => createProvider.setCustomerAddress(_customerAddressController.text));
    _customerPhoneController.addListener(() => createProvider.setCustomerPhone(_customerPhoneController.text));
    _customerEmailController.addListener(() => createProvider.setCustomerEmail(_customerEmailController.text));
    _hotelNameController.addListener(() => createProvider.setHotelName(_hotelNameController.text));
    _hotelAddressController.addListener(() => createProvider.setHotelAddress(_hotelAddressController.text));
    _hotelCostSingleController.addListener(() => createProvider.setHotelCostSingle(_hotelCostSingleController.text));
    _hotelCostDoubleController.addListener(() => createProvider.setHotelCostDouble(_hotelCostDoubleController.text));
    _hotelCostSuiteController.addListener(() => createProvider.setHotelCostSuite(_hotelCostSuiteController.text));
    _hotelRatingController.addListener(() => createProvider.setHotelRating(_hotelRatingController.text));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsProvider = context.read<SettingsProvider>();
      if (mounted) {
        final createProvider = context.read<CreateInterventionProvider>();
        createProvider.setCurrencyCode(settingsProvider.defaultCurrencyCode);
      }
    });
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
    final createProvider = context.read<CreateInterventionProvider>();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: createProvider.scheduledDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(createProvider.scheduledDate),
      );
      if (pickedTime != null) {
        final newDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        createProvider.setScheduledDate(newDate);
        setState(() {});
      }
    }
  }

  Future<void> _saveIntervention() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final createProvider = context.read<CreateInterventionProvider>();

    // Validate tasks
    for (var task in createProvider.tasks) {
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

    final tasks = createProvider.tasks.map((task) {
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
      scheduledDate: createProvider.scheduledDate,
      tasks: tasks,
      createdAt: DateTime.now(),
      startDate: createProvider.startDate,
      endDate: createProvider.endDate,
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
      hotelBreakfastIncluded: createProvider.hotelBreakfastIncluded,
      hotelRating: _hotelRatingController.text.trim().isEmpty
          ? null
          : double.tryParse(_hotelRatingController.text.trim()),
      involvedPersons: createProvider.involvedPersons,
      currencyCode: createProvider.currencyCode,
    );

    final provider = Provider.of<InterventionProvider>(context, listen: false);
    await provider.addIntervention(intervention);

    // Reset the form provider after successful save
    createProvider.reset();

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
      body: Consumer<CreateInterventionProvider>(
        builder: (context, createProvider, _) {
          return Form(
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
          );
        },
      ),
    );
  }

  Widget _buildBasicInfoTab() {
    final createProvider = context.read<CreateInterventionProvider>();
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
              '${createProvider.scheduledDate.day}/${createProvider.scheduledDate.month}/${createProvider.scheduledDate.year} at ${createProvider.scheduledDate.hour.toString().padLeft(2, '0')}:${createProvider.scheduledDate.minute.toString().padLeft(2, '0')}',
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
    final createProvider = context.read<CreateInterventionProvider>();
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
        if (createProvider.involvedPersons.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: createProvider.involvedPersons.asMap().entries.map((entry) {
              final index = entry.key;
              final person = entry.value;
              return Chip(
                label: Text(person),
                onDeleted: () {
                  createProvider.removeInvolvedPerson(index);
                  setState(() {});
                },
                deleteIcon: const Icon(Icons.close, size: 18),
              );
            }).toList(),
          ),
      ],
    );
  }

  void _addInvolvedPerson() {
    final createProvider = context.read<CreateInterventionProvider>();
    final personName = _involvedPersonController.text.trim();
    if (personName.isNotEmpty) {
      createProvider.addInvolvedPerson(personName);
      _involvedPersonController.clear();
      setState(() {});
    }
  }

  Widget _buildTravelTab() {
    final createProvider = context.read<CreateInterventionProvider>();
    final currencySymbol = CurrencyUtils.symbolFor(createProvider.currencyCode);
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
                    initialDate: createProvider.startDate ?? DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    createProvider.setStartDate(picked);
                    setState(() {});
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'From Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.date_range),
                  ),
                  child: Text(
                    createProvider.startDate == null
                        ? 'Select date'
                        : '${createProvider.startDate!.day}/${createProvider.startDate!.month}/${createProvider.startDate!.year}',
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
                    initialDate: createProvider.endDate ?? DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    createProvider.setEndDate(picked);
                    setState(() {});
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'To Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.date_range),
                  ),
                  child: Text(
                    createProvider.endDate == null
                        ? 'Select date'
                        : '${createProvider.endDate!.day}/${createProvider.endDate!.month}/${createProvider.endDate!.year}',
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Currency',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: createProvider.currencyCode,
          decoration: const InputDecoration(
            labelText: 'Currency',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.currency_exchange),
          ),
          items: CurrencyUtils.supportedCurrencies
              .map(
                (currency) => DropdownMenuItem(
                  value: currency.code,
                  child: Text(currency.code),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            createProvider.setCurrencyCode(value);
            setState(() {});
          },
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
                decoration: InputDecoration(
                  labelText: 'Single',
                  border: const OutlineInputBorder(),
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
                  border: const OutlineInputBorder(),
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
                  border: const OutlineInputBorder(),
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
                value: createProvider.hotelBreakfastIncluded,
                onChanged: (value) {
                  createProvider.setHotelBreakfastIncluded(value ?? false);
                  setState(() {});
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
    final createProvider = context.read<CreateInterventionProvider>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tasks (${createProvider.tasks.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                final newTask = Task(
                  id: const Uuid().v4(),
                  title: '',
                  description: '',
                  order: createProvider.tasks.length,
                  isCompleted: false,
                );
                createProvider.addTask(newTask);
                _taskControllers[newTask.id] = TextEditingController();
                setState(() {});
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Task'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (createProvider.tasks.isEmpty)
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
            children: List.generate(createProvider.tasks.length, (index) {
              final task = createProvider.tasks[index];
              // Ensure controller exists
              if (!_taskControllers.containsKey(task.id)) {
                _taskControllers[task.id] = TextEditingController(text: task.title);
              }
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
                                  _taskControllers[task.id]?.dispose();
                                  _taskControllers.remove(task.id);
                                  createProvider.removeTask(index);
                                  setState(() {});
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
