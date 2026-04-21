class Caregiver {
  final String name;
  final String email;
  final String phoneNumber;

  const Caregiver({
    required this.name,
    required this.email,
    required this.phoneNumber,
  });

  Caregiver copyWith({String? name, String? email, String? phoneNumber}) {
    return Caregiver(
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}
