import 'package:flutter/foundation.dart';
import '../models/task.dart';

/// Provider for managing form data during intervention creation
/// Persists data across tab changes and screen dismissals
class CreateInterventionProvider with ChangeNotifier {
  // Basic Info
  String _title = '';
  String _description = '';

  // Customer
  String _customerName = '';
  String _customerAddress = '';
  String _customerPhone = '';
  String _customerEmail = '';

  // Travel
  String _hotelName = '';
  String _hotelAddress = '';
  String _hotelCostSingle = '';
  String _hotelCostDouble = '';
  String _hotelCostSuite = '';
  String _hotelRating = '';
  bool _hotelBreakfastIncluded = false;
  String _currencyCode = 'EUR';

  // Schedule
  DateTime _scheduledDate = DateTime.now().add(const Duration(days: 1));
  DateTime? _startDate;
  DateTime? _endDate;

  // Tasks
  List<Task> _tasks = [];

  // Involved Persons
  List<String> _involvedPersons = [];

  // Getters
  String get title => _title;
  String get description => _description;

  String get customerName => _customerName;
  String get customerAddress => _customerAddress;
  String get customerPhone => _customerPhone;
  String get customerEmail => _customerEmail;

  String get hotelName => _hotelName;
  String get hotelAddress => _hotelAddress;
  String get hotelCostSingle => _hotelCostSingle;
  String get hotelCostDouble => _hotelCostDouble;
  String get hotelCostSuite => _hotelCostSuite;
  String get hotelRating => _hotelRating;
  bool get hotelBreakfastIncluded => _hotelBreakfastIncluded;
  String get currencyCode => _currencyCode;

  DateTime get scheduledDate => _scheduledDate;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  List<Task> get tasks => _tasks;
  List<String> get involvedPersons => _involvedPersons;

  // Setters
  void setTitle(String value) {
    _title = value;
    notifyListeners();
  }

  void setDescription(String value) {
    _description = value;
    notifyListeners();
  }

  void setCustomerName(String value) {
    _customerName = value;
    notifyListeners();
  }

  void setCustomerAddress(String value) {
    _customerAddress = value;
    notifyListeners();
  }

  void setCustomerPhone(String value) {
    _customerPhone = value;
    notifyListeners();
  }

  void setCustomerEmail(String value) {
    _customerEmail = value;
    notifyListeners();
  }

  void setHotelName(String value) {
    _hotelName = value;
    notifyListeners();
  }

  void setHotelAddress(String value) {
    _hotelAddress = value;
    notifyListeners();
  }

  void setHotelCostSingle(String value) {
    _hotelCostSingle = value;
    notifyListeners();
  }

  void setHotelCostDouble(String value) {
    _hotelCostDouble = value;
    notifyListeners();
  }

  void setHotelCostSuite(String value) {
    _hotelCostSuite = value;
    notifyListeners();
  }

  void setHotelRating(String value) {
    _hotelRating = value;
    notifyListeners();
  }

  void setHotelBreakfastIncluded(bool value) {
    _hotelBreakfastIncluded = value;
    notifyListeners();
  }

  void setCurrencyCode(String value) {
    _currencyCode = value;
    notifyListeners();
  }

  void setScheduledDate(DateTime value) {
    _scheduledDate = value;
    notifyListeners();
  }

  void setStartDate(DateTime? value) {
    _startDate = value;
    notifyListeners();
  }

  void setEndDate(DateTime? value) {
    _endDate = value;
    notifyListeners();
  }

  void setTasks(List<Task> tasks) {
    _tasks = tasks;
    notifyListeners();
  }

  void addTask(Task task) {
    _tasks.add(task);
    notifyListeners();
  }

  void removeTask(int index) {
    if (index >= 0 && index < _tasks.length) {
      _tasks.removeAt(index);
      notifyListeners();
    }
  }

  void updateTask(int index, Task task) {
    if (index >= 0 && index < _tasks.length) {
      _tasks[index] = task;
      notifyListeners();
    }
  }

  void setInvolvedPersons(List<String> persons) {
    _involvedPersons = persons;
    notifyListeners();
  }

  void addInvolvedPerson(String person) {
    _involvedPersons.add(person);
    notifyListeners();
  }

  void removeInvolvedPerson(int index) {
    if (index >= 0 && index < _involvedPersons.length) {
      _involvedPersons.removeAt(index);
      notifyListeners();
    }
  }

  /// Reset all form data
  void reset() {
    _title = '';
    _description = '';
    _customerName = '';
    _customerAddress = '';
    _customerPhone = '';
    _customerEmail = '';
    _hotelName = '';
    _hotelAddress = '';
    _hotelCostSingle = '';
    _hotelCostDouble = '';
    _hotelCostSuite = '';
    _hotelRating = '';
    _hotelBreakfastIncluded = false;
    _currencyCode = 'EUR';
    _scheduledDate = DateTime.now().add(const Duration(days: 1));
    _startDate = null;
    _endDate = null;
    _tasks = [];
    _involvedPersons = [];
    notifyListeners();
  }
}
