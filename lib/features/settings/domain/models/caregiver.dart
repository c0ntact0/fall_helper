class Caregiver {
  final String name;
  final String email;
  final String phoneNumber;
  final String pin;

  const Caregiver({
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.pin,
  });

  Caregiver copyWith({
    String? name,
    String? email,
    String? phoneNumber,
    String? pin,
  }) {
    return Caregiver(
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      pin: pin ?? this.pin,
    );
  }
}
