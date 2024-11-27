import 'package:flutter/material.dart';

class TermsCheckbox extends StatelessWidget {
  final bool accepted;
  final ValueChanged<bool?> onChanged;

  const TermsCheckbox({
    super.key,
    required this.accepted,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Checkbox(
            value: accepted,
            onChanged: onChanged,
          ),
          const Expanded(
            child: Text(
              'I accept the terms and conditions',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
