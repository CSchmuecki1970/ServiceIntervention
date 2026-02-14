import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import '../models/customer.dart';
import '../models/task.dart';
import '../models/service_intervention.dart';
import 'settings_service.dart';

class StorageException implements Exception {
  final String message;
  StorageException(this.message);

  @override
  String toString() => 'StorageException: $message';
}

class StorageService {
  static late Box<ServiceIntervention> interventionsBox;
  static late Box<Customer> customersBox;
  static DateTime? lastSync;

  static Future<void> init() async {
    try {
      Hive.registerAdapter(CustomerAdapter());
      Hive.registerAdapter(TaskAdapter());
      Hive.registerAdapter(ServiceInterventionAdapter());
      Hive.registerAdapter(InterventionStatusAdapter());

      await SettingsService.init();

      try {
        interventionsBox =
            await Hive.openBox<ServiceIntervention>('interventions');
      } catch (e) {
        // If there's an error opening the box (likely due to schema changes), delete it and recreate
        try {
          await Hive.close(); // Close all boxes first
          await Future.delayed(const Duration(
              milliseconds: 500)); // Wait for file locks to release
          await Hive.deleteBoxFromDisk('interventions');
        } catch (deleteError) {
          // If we still can't delete, just try to open a new one
          print(
              'Warning: Could not delete corrupted interventions box: $deleteError');
        }
        interventionsBox =
            await Hive.openBox<ServiceIntervention>('interventions');
      }

      try {
        customersBox = await Hive.openBox<Customer>('customers');
      } catch (e) {
        try {
          await Hive.close();
          await Future.delayed(const Duration(milliseconds: 500));
          await Hive.deleteBoxFromDisk('customers');
        } catch (deleteError) {
          print(
              'Warning: Could not delete corrupted customers box: $deleteError');
        }
        customersBox = await Hive.openBox<Customer>('customers');
      }

      lastSync = DateTime.now();
    } catch (e) {
      throw StorageException('Failed to initialize storage: $e');
    }
  }

  // Single operations
  static Future<void> saveIntervention(ServiceIntervention intervention) async {
    try {
      await interventionsBox.put(intervention.id, intervention);
      lastSync = DateTime.now();
    } catch (e) {
      throw StorageException('Failed to save intervention: $e');
    }
  }

  static Future<void> deleteIntervention(String id) async {
    try {
      await interventionsBox.delete(id);
      lastSync = DateTime.now();
    } catch (e) {
      throw StorageException('Failed to delete intervention: $e');
    }
  }

  static List<ServiceIntervention> getAllInterventions() {
    try {
      return interventionsBox.values.toList();
    } catch (e) {
      throw StorageException('Failed to get interventions: $e');
    }
  }

  static ServiceIntervention? getIntervention(String id) {
    try {
      return interventionsBox.get(id);
    } catch (e) {
      throw StorageException('Failed to get intervention: $e');
    }
  }

  static Future<void> saveCustomer(Customer customer) async {
    try {
      await customersBox.put(customer.id, customer);
      lastSync = DateTime.now();
    } catch (e) {
      throw StorageException('Failed to save customer: $e');
    }
  }

  static List<Customer> getAllCustomers() {
    try {
      return customersBox.values.toList();
    } catch (e) {
      throw StorageException('Failed to get customers: $e');
    }
  }

  static Customer? getCustomer(String id) {
    try {
      return customersBox.get(id);
    } catch (e) {
      throw StorageException('Failed to get customer: $e');
    }
  }

  // Batch operations
  static Future<void> saveInterventionsBatch(
    List<ServiceIntervention> interventions,
  ) async {
    try {
      final Map<String, ServiceIntervention> batch = {};
      for (var intervention in interventions) {
        batch[intervention.id] = intervention;
      }
      await interventionsBox.putAll(batch);
      lastSync = DateTime.now();
    } catch (e) {
      throw StorageException('Failed to save batch of interventions: $e');
    }
  }

  static Future<void> saveCustomersBatch(List<Customer> customers) async {
    try {
      final Map<String, Customer> batch = {};
      for (var customer in customers) {
        batch[customer.id] = customer;
      }
      await customersBox.putAll(batch);
      lastSync = DateTime.now();
    } catch (e) {
      throw StorageException('Failed to save batch of customers: $e');
    }
  }

  static Future<void> deleteInterventionsBatch(List<String> ids) async {
    try {
      await interventionsBox.deleteAll(ids);
      lastSync = DateTime.now();
    } catch (e) {
      throw StorageException('Failed to delete batch of interventions: $e');
    }
  }

  // Clear all data
  static Future<void> clearAll() async {
    try {
      await interventionsBox.clear();
      await customersBox.clear();
      lastSync = DateTime.now();
    } catch (e) {
      throw StorageException('Failed to clear storage: $e');
    }
  }

  // Export to JSON
  static String exportToJson() {
    try {
      final interventions = getAllInterventions();
      final customers = getAllCustomers();

      final data = {
        'version': 1,
        'exportDate': DateTime.now().toIso8601String(),
        'interventions': interventions.map((i) => i.toJson()).toList(),
        'customers': customers.map((c) => c.toJson()).toList(),
      };

      return jsonEncode(data);
    } catch (e) {
      throw StorageException('Failed to export data to JSON: $e');
    }
  }

  // Import from JSON
  static Future<void> importFromJson(String jsonString) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      if (data['version'] != 1) {
        throw StorageException('Unsupported data version');
      }

      // Import customers first
      final customersList = <Customer>[];
      for (final c in (data['customers'] as List? ?? [])) {
        try {
          customersList.add(Customer.fromJson(c as Map<String, dynamic>));
        } catch (e) {
          print('WARNING: Failed to parse customer: $e');
          // Continue importing other records instead of failing entirely
        }
      }
      if (customersList.isNotEmpty) {
        await saveCustomersBatch(customersList);
      }

      // Import interventions
      final interventionsList = <ServiceIntervention>[];
      final duplicateIds = <String>{};
      for (final i in (data['interventions'] as List? ?? [])) {
        try {
          final intervention =
              ServiceIntervention.fromJson(i as Map<String, dynamic>);
          if (duplicateIds.contains(intervention.id)) {
            print(
                'WARNING: Skipping duplicate intervention ID: ${intervention.id}');
            continue; // Skip duplicates
          }
          duplicateIds.add(intervention.id);
          interventionsList.add(intervention);
        } catch (e) {
          print('WARNING: Failed to parse intervention: $e');
          // Continue importing other records instead of failing entirely
        }
      }
      if (interventionsList.isNotEmpty) {
        await saveInterventionsBatch(interventionsList);
      }

      if (interventionsList.isEmpty && customersList.isEmpty) {
        throw StorageException('No valid data found in import file');
      }

      lastSync = DateTime.now();
    } catch (e) {
      throw StorageException('Failed to import data from JSON: $e');
    }
  }

  // Get backup data with metadata
  static Map<String, dynamic> getBackupMetadata() {
    try {
      return {
        'interventionsCount': interventionsBox.length,
        'customersCount': customersBox.length,
        'lastSync': lastSync?.toIso8601String(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw StorageException('Failed to get backup metadata: $e');
    }
  }

  // Search interventions by customer
  static List<ServiceIntervention> getInterventionsByCustomer(
      String customerId) {
    try {
      return getAllInterventions()
          .where((i) => i.customer.id == customerId)
          .toList();
    } catch (e) {
      throw StorageException('Failed to search interventions: $e');
    }
  }

  // Get interventions by status
  static List<ServiceIntervention> getInterventionsByStatus(
    InterventionStatus status,
  ) {
    try {
      return getAllInterventions().where((i) => i.status == status).toList();
    } catch (e) {
      throw StorageException('Failed to filter interventions by status: $e');
    }
  }

  // Get interventions in date range
  static List<ServiceIntervention> getInterventionsInDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    try {
      return getAllInterventions()
          .where((i) =>
              i.scheduledDate.isAfter(startDate) &&
              i.scheduledDate.isBefore(endDate))
          .toList();
    } catch (e) {
      throw StorageException('Failed to get interventions in date range: $e');
    }
  }
}
