import 'package:flutter/material.dart';
import 'dropdown_field.dart';
import 'datetime_field.dart';
import 'textarea_field.dart';
import 'text_field.dart';

class FormFieldWidget extends StatelessWidget {
  final Map<String, dynamic> field;
  final bool isCurrentStep;
  final ValueChanged<String?> onChanged;

  const FormFieldWidget({
    super.key,
    required this.field,
    required this.isCurrentStep,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Extract label with a default empty value if not provided
    final label = field['label'] as String? ?? "";

    switch (field['type']) {
      case 'dropdown':
        return DropdownField(
          field: field,
          isCurrentStep: isCurrentStep,
          onChanged: onChanged,
          label: label, items: const [], // Use the extracted label
        );
      case 'datetime':
        return DateTimeField(
          field: field,
          isCurrentStep: isCurrentStep,
          onChanged: onChanged,
        );
      case 'textarea':
        return TextAreaField(
          field: field,
          isCurrentStep: isCurrentStep,
          onChanged: onChanged,
        );
      default:
        return TextFieldWidget(
          field: field,
          isCurrentStep: isCurrentStep,
          onChanged: onChanged,
        );
    }
  }
}
