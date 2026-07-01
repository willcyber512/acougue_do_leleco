class SupplierProfile {
  const SupplierProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.responsible,
    required this.city,
    required this.address,
    required this.notes,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String phone;
  final String responsible;
  final String city;
  final String address;
  final String notes;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  SupplierProfile copyWith({
    String? name,
    String? phone,
    String? responsible,
    String? city,
    String? address,
    String? notes,
    bool? active,
    DateTime? updatedAt,
  }) {
    return SupplierProfile(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      responsible: responsible ?? this.responsible,
      city: city ?? this.city,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      active: active ?? this.active,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'responsible': responsible,
      'city': city,
      'address': address,
      'notes': notes,
      'active': active,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SupplierProfile.fromMap(Map<String, dynamic> map) {
    return SupplierProfile(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      responsible: map['responsible']?.toString() ?? '',
      city: map['city']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      notes: map['notes']?.toString() ?? '',
      active: _toBool(map['active']),
      createdAt: _toDate(map['createdAt']),
      updatedAt: _toDate(map['updatedAt']),
    );
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;

    final text = value?.toString().toLowerCase() ?? '';
    if (text == 'false') return false;

    return true;
  }

  static DateTime _toDate(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }
}
