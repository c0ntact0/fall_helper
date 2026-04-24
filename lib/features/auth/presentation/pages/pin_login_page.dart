import 'package:flutter/material.dart';

import '../../../../core/services/storage_service.dart';
import '../../../../shared/widgets/pin_keyboard.dart';
import '../../../light_sensor/presentation/controllers/light_sensor_controller.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../controllers/pin_login_controller.dart';

class PinLoginPage extends StatefulWidget {
  final LightSensorController? lightSensorController;

  const PinLoginPage({super.key, this.lightSensorController});

  @override
  State<PinLoginPage> createState() => _PinLoginPageState();
}

class _PinLoginPageState extends State<PinLoginPage> {
  late final PinLoginController _controller;

  @override
  void initState() {
    super.initState();

    _controller = PinLoginController(storageService: StorageService());

    _controller.addListener(_onControllerChanged);
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    final errorMessage = _controller.errorMessage;

    if (errorMessage != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
      _controller.clearError();
    }
  }

  Future<void> _handleDigitPressed(String digit) async {
    _controller.onDigitPressed(digit);

    if (_controller.shouldValidateNow) {
      final isValid = _controller.validatePin();

      if (isValid) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SettingsPage(
              lightSensorController: widget.lightSensorController,
            ),
          ),
        );

        if (!mounted) return;

        Navigator.pop(context, result ?? true);
      }
    }
  }

  void _handleBackspacePressed() {
    _controller.onBackspacePressed();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.isLoading) {
          return const Scaffold(
            body: SafeArea(child: Center(child: CircularProgressIndicator())),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('PIN de configuração'),
            leading: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  const Text(
                    'PIN de configuração',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  _PinDisplay(
                    pinLength: PinLoginController.pinLength,
                    enteredPinLength: _controller.enteredPin.length,
                  ),
                  const SizedBox(height: 16),
                  if (_controller.savedPin == '0000') ...[
                    const Text(
                      'O PIN predefinido é 0000',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Expanded(
                    child: PinKeyboard(
                      onDigitPressed: _handleDigitPressed,
                      onBackspacePressed: _handleBackspacePressed,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Voltar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PinDisplay extends StatelessWidget {
  final int pinLength;
  final int enteredPinLength;

  const _PinDisplay({required this.pinLength, required this.enteredPinLength});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pinLength, (index) {
        final bool isFilled = index < enteredPinLength;

        return Container(
          width: 20,
          height: 20,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: isFilled ? Colors.black : Colors.transparent,
            border: Border.all(color: Colors.black54),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}
