import 'package:hive/hive.dart';

part 'customer.g.dart';

@HiveType(typeId: 0)
class Customer extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String address;

  @HiveField(3)
  final String? phone;

  @HiveField(4)
  final String? email;

  @HiveField(5)
  final String? notes;

  Customer({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
    this.email,
    this.notes,
  });

  Customer copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    String? email,
    String? notes,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'notes': notes,
    };
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      notes: json['notes'] as String?,
    );
  }
}
