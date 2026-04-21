import 'package:flutter/material.dart';

class PinKeyboard extends StatelessWidget {
  final ValueChanged<String> onDigitPressed;
  final VoidCallback onBackspacePressed;

  const PinKeyboard({
    super.key,
    required this.onDigitPressed,
    required this.onBackspacePressed,
  });

  @override
  Widget build(BuildContext context) {
    const digits = ['1', '2', '3', '4', '5', '6', '7', '8', '9'];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            for (final digit in digits)
              _PinKey(label: digit, onTap: () => onDigitPressed(digit)),
            const SizedBox.shrink(),
            _PinKey(label: '0', onTap: () => onDigitPressed('0')),
            _PinKey(label: '⌫', onTap: onBackspacePressed),
          ],
        ),
      ),
    );
  }
}

class _PinKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PinKey({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}
