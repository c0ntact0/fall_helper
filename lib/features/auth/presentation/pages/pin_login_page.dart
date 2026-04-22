import 'package:flutter/material.dart';

import '../../../../app/routes.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/pin_keyboard.dart';

class PinLoginPage extends StatefulWidget {
  const PinLoginPage({super.key});

  @override
  State<PinLoginPage> createState() => _PinLoginPageState();
}

class _PinLoginPageState extends State<PinLoginPage> {
  static const int _pinLength = 4;

  final StorageService _storageService = StorageService();

  String _enteredPin = '';
  String? _errorMessage;
  String _savedPin = '0000';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedPin();
  }

  Future<void> _loadSavedPin() async {
    final caregiver = await _storageService.loadCaregiver();

    if (!mounted) return;

    setState(() {
      _savedPin = caregiver.pin;
      _isLoading = false;
    });
  }

  void _onDigitPressed(String digit) {
    if (_isLoading) return;
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
    if (_isLoading) return;
    if (_enteredPin.isEmpty) return;

    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _errorMessage = null;
    });
  }

  void _validatePin() {
    final validationError = AppValidators.pin4Digits(_enteredPin);
    if (validationError != null) {
      setState(() {
        _enteredPin = '';
        _errorMessage = validationError;
      });
      return;
    }

    if (_enteredPin == _savedPin) {
      _openSettings();
      return;
    }

    setState(() {
      _enteredPin = '';
      _errorMessage = 'PIN incorreto';
    });
  }

  Future<void> _openSettings() async {
    final result = await Navigator.pushNamed(context, AppRoutes.settings);

    if (!mounted) return;

    Navigator.pop(context, result ?? true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
                pinLength: _pinLength,
                enteredPinLength: _enteredPin.length,
              ),
              const SizedBox(height: 16),
              if (_savedPin == '0000') ...[
                const Text(
                  'O PIN predefinido é 0000',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
              ],
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
