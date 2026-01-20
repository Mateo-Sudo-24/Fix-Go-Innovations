enum UserRole { client, technician, admin }

class UserModel {
  final String id;
  final String email;
  final String fullName;  // Cambiado de 'name' a 'fullName'
  final UserRole role;
  final String? phone;
  final String? address;
  final String? specialty; // Para técnicos
  final String? cedula; // Para técnicos
  
  UserModel({
    required this.id,
    required this.email,
    required this.fullName,  // Cambiado aquí también
    required this.role,
    this.phone,
    this.address,
    this.specialty,
    this.cedula,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],  // Mapea desde la BD
      role: UserRole.values.firstWhere((e) => e.name == json['role']),
      phone: json['phone'],
      address: json['address'],
      specialty: json['specialty'],
      cedula: json['cedula'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,  // Guarda en la BD como 'full_name'
      'role': role.name,
      'phone': phone,
      'address': address,
      'specialty': specialty,
      'cedula': cedula,
    };
  }
}