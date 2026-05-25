import 'package:flutter/material.dart';

import 'settings_section.dart';
import '../../../../core/logging/app_logger.dart';

class CaregiverSection extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController pinController;
  final String? Function(String?) validateName;
  final String? Function(String?) validateEmail;
  final String? Function(String?) validatePhone;
  final String? Function(String?) validatePin;
  final AppLogger logger;

  const CaregiverSection({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.pinController,
    required this.validateName,
    required this.validateEmail,
    required this.validatePhone,
    required this.validatePin,
    required this.logger,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'Configuração do cuidador',
      child: Column(
        children: [
          TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Nome',
              border: OutlineInputBorder(),
            ),
            validator: validateName,
            onTap: () {
              logger.logUserAction(module: 'caregiver_section', action: 'name_taped');
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: validateEmail,
            onTap: () {
              logger.logUserAction(
                module: 'caregiver_section',
                action: 'email_taped',
              );
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: phoneController,
            decoration: const InputDecoration(
              labelText: 'Telefone',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            validator: validatePhone,
            onTap: () {
              logger.logUserAction(
                module: 'caregiver_section',
                action: 'phone_taped',
              );
            },
            
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: pinController,
            decoration: const InputDecoration(
              labelText: 'PIN configuração',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            validator: validatePin,
            onTap: () {
              logger.logUserAction(
                module: 'caregiver_section',
                action: 'pin_taped',
              );
            },
          ),
        ],
      ),
    );
  }
}
