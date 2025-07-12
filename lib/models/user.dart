enum UserRole { driver, passenger }
enum UserStatus { pending, approved, rejected }

class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final UserRole role;
  final UserStatus status;
  final int seatingCapacity;
  final DriverDetails? driverDetails;
  final String? phone;
  final String? createdAt; // Handling the array [timestamp, float] as a string for now

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.status,
    required this.seatingCapacity,
    this.driverDetails,
    this.phone,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      role: UserRole.values.firstWhere(
        (role) => role.toString() == 'UserRole.${json['role']}',
        orElse: () => UserRole.passenger,
      ),
      status: UserStatus.values.firstWhere(
        (status) => status.toString() == 'UserStatus.${json['status']}',
        orElse: () => UserStatus.pending,
      ),
      seatingCapacity: json['seatingCapacity'] as int,
      driverDetails: json['driverDetails'] != null
          ? DriverDetails.fromJson(json['driverDetails'])
          : null,
      phone: json['phone'] as String?,
      createdAt: json['createdAt'] != null ? json['createdAt'].toString() : null,
    );
  }
}

// Driver Details Model
class DriverDetails {
  final String vehicleType;
  final String vehicleBrand;
  final String vehicleModel;
  final String vehicleRegistrationNumber;
  final int seatingCapacity;

  DriverDetails({
    required this.vehicleType,
    required this.vehicleBrand,
    required this.vehicleModel,
    required this.vehicleRegistrationNumber,
    required this.seatingCapacity,
  });

  factory DriverDetails.fromJson(Map<String, dynamic> json) {
    return DriverDetails(
      vehicleType: json['vehicleType'] as String,
      vehicleBrand: json['vehicleBrand'] as String,
      vehicleModel: json['vehicleModel'] as String,
      vehicleRegistrationNumber: json['vehicleRegistrationNumber'] as String,
      seatingCapacity: json['seatingCapacity'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicleType': vehicleType,
      'vehicleBrand': vehicleBrand,
      'vehicleModel': vehicleModel,
      'vehicleRegistrationNumber': vehicleRegistrationNumber,
      'seatingCapacity': seatingCapacity,
    };
  }
}