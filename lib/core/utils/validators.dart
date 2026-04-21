class AppValidators {
  static String? requiredField(String? value, {String fieldName = 'Campo'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName obrigatório';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obrigatório';
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Email inválido';
    }

    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obrigatório';
    }

    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 9) {
      return 'Telefone inválido';
    }

    return null;
  }

  static String? pin4Digits(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Introduza o PIN';
    }

    final digitsOnly = value.trim();

    if (digitsOnly.length != 4) {
      return 'O PIN deve ter 4 dígitos';
    }

    if (int.tryParse(digitsOnly) == null) {
      return 'O PIN deve conter apenas números';
    }

    return null;
  }
}
