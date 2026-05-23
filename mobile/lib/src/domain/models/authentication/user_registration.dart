class UserRegistration {
  UserRegistration({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
  });

  final String email;
  final String password;
  final String firstName;
  final String lastName;

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
      };
}

class RegisteredUser {
  RegisteredUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
  });

  factory RegisteredUser.fromJson(Map<String, dynamic> json) => RegisteredUser(
        id: json['id'] as String,
        email: json['email'] as String,
        firstName: (json['firstName'] as String?) ?? '',
        lastName: (json['lastName'] as String?) ?? '',
      );

  final String id;
  final String email;
  final String firstName;
  final String lastName;
}
