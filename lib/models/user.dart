enum UserRole { driver, passenger }
enum UserStatus { pending, approved, rejected }

class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final UserRole role;
  final UserStatus status;
  final DriverDetails? driverDetails;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.status,
    this.driverDetails,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      role: UserRole.values.firstWhere(
        (role) => role.toString() == 'UserRole.${json['role']}',
        orElse: () => UserRole.passenger,
      ),
      status: UserStatus.values.firstWhere(
        (status) => status.toString() == 'UserStatus.${json['status']}',
        orElse: () => UserStatus.pending,
      ),
      driverDetails: json['driverDetails'] != null
          ? DriverDetails.fromJson(json['driverDetails'])
          : null,
    );
  }
}

// Driver Details Model
class DriverDetails {
  final String vehicleType;
  final String vehicleBrand;
  final String vehicleModel;
  final String registrationNumber;
  final int seatsAvailable;

  DriverDetails({
    required this.vehicleType,
    required this.vehicleBrand,
    required this.vehicleModel,
    required this.registrationNumber,
    required this.seatsAvailable,
  });

  factory DriverDetails.fromJson(Map<String, dynamic> json) {
    return DriverDetails(
      vehicleType: json['vehicleType'],
      vehicleBrand: json['vehicleBrand'],
      vehicleModel: json['vehicleModel'],
      registrationNumber: json['registrationNumber'],
      seatsAvailable: json['seatsAvailable'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicleType': vehicleType,
      'vehicleBrand': vehicleBrand,
      'vehicleModel': vehicleModel,
      'registrationNumber': registrationNumber,
      'seatsAvailable': seatsAvailable,
    };
  }
}

// Enums
