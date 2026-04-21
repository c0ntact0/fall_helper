import 'package:flutter/material.dart';
import '../../../../app/routes.dart';
import '../../../../shared/widgets/pin_keyboard.dart';

class PinLoginPage extends StatefulWidget {
  const PinLoginPage({super.key});

  @override
  State<PinLoginPage> createState() => _PinLoginPageState();
}

class _PinLoginPageState extends State<PinLoginPage> {
  static const String _defaultPin = '0000';
  static const int _pinLength = 4;

  String _enteredPin = '';
  String? _errorMessage;

  void _onDigitPressed(String digit) {
    if (_enteredPin.length >= _pinLength) return;

    setState(() {
      _enteredPin += digit;
      _errorMessage = null;
    });

    if (_enteredPin.length == _pinLength) {
      _validatePin();
    }
  }

  void _onBackspacePressed() {
    if (_enteredPin.isEmpty) return;

    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _errorMessage = null;
    });
  }

  void _validatePin() {
    if (_enteredPin == _defaultPin) {
      Navigator.pushReplacementNamed(context, AppRoutes.settings);
      return;
    }

    setState(() {
      _enteredPin = '';
      _errorMessage = 'PIN incorreto';
    });
  }

  @override
  Widget build(BuildContext context) {
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
                pinLength: _pinLength,
                enteredPinLength: _enteredPin.length,
              ),
              const SizedBox(height: 16),
              const Text(
                'O PIN predefinido é 0000',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(height: 24),
              Expanded(
                child: PinKeyboard(
                  onDigitPressed: _onDigitPressed,
                  onBackspacePressed: _onBackspacePressed,
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
        final isFilled = index < enteredPinLength;

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
