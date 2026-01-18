import 'package:hive_flutter/hive_flutter.dart';
import '../models/customer.dart';
import '../models/task.dart';
import '../models/service_intervention.dart';

class StorageService {
  static late Box<ServiceIntervention> interventionsBox;
  static late Box<Customer> customersBox;

  static Future<void> init() async {
    Hive.registerAdapter(CustomerAdapter());
    Hive.registerAdapter(TaskAdapter());
    Hive.registerAdapter(ServiceInterventionAdapter());
    Hive.registerAdapter(InterventionStatusAdapter());

    interventionsBox = await Hive.openBox<ServiceIntervention>('interventions');
    customersBox = await Hive.openBox<Customer>('customers');
  }

  static Future<void> saveIntervention(ServiceIntervention intervention) async {
    await interventionsBox.put(intervention.id, intervention);
  }

  static Future<void> deleteIntervention(String id) async {
    await interventionsBox.delete(id);
  }

  static List<ServiceIntervention> getAllInterventions() {
    return interventionsBox.values.toList();
  }

  static ServiceIntervention? getIntervention(String id) {
    return interventionsBox.get(id);
  }

  static Future<void> saveCustomer(Customer customer) async {
    await customersBox.put(customer.id, customer);
  }

  static List<Customer> getAllCustomers() {
    return customersBox.values.toList();
  }

  static Customer? getCustomer(String id) {
    return customersBox.get(id);
  }
}
