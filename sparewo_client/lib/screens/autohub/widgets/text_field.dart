import 'package:flutter/material.dart';

class TextFieldWidget extends StatelessWidget {
  final Map<String, dynamic> field;
  final bool isCurrentStep;
  final Function(String?) onChanged;

  const TextFieldWidget({
    super.key,
    required this.field,
    required this.isCurrentStep,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        hintText: field['hint'],
      ),
      onChanged: isCurrentStep ? onChanged : null,
      validator: (value) =>
          field['required'] && (value == null || value.isEmpty)
              ? 'This field is required'
              : null,
    );
  }
}
