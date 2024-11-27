import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateTimeField extends StatelessWidget {
  final Map<String, dynamic> field;
  final bool isCurrentStep;
  final Function(String?) onChanged;

  const DateTimeField({
    super.key,
    required this.field,
    required this.isCurrentStep,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isCurrentStep
          ? () async {
              DateTime? date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              TimeOfDay? time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (time != null) {
                final selectedDateTime = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  time.hour,
                  time.minute,
                );
                onChanged(
                    DateFormat('MMM dd, yyyy HH:mm').format(selectedDateTime));
              }
            }
          : null,
      child: AbsorbPointer(
        child: TextFormField(
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            hintText: field['hint'],
          ),
          validator: (value) =>
              field['required'] && (value == null || value.isEmpty)
                  ? 'Please select a date and time'
                  : null,
        ),
      ),
    );
  }
}
