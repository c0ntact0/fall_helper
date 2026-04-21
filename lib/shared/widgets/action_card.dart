import 'package:flutter/material.dart';

class ActionCard extends StatelessWidget {
  final String title;
  final String status;
  final String instruction;
  final Color backgroundColor;
  final VoidCallback onTap;
  final Widget? bottomChild;

  const ActionCard({
    super.key,
    required this.title,
    required this.status,
    required this.instruction,
    required this.backgroundColor,
    required this.onTap,
    this.bottomChild,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(24),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  status,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
                const SizedBox(height: 8),
                if (instruction.isNotEmpty)
                Text(
                  instruction,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                if (bottomChild != null) ...[
                  const SizedBox(height: 14),
                  bottomChild!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
