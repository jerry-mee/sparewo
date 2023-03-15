import 'package:flutter/material.dart';
import 'package:sparewo/utilis/constants.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    required this.hint,
    required this.onValueChanged,
    super.key,
  });
  final String hint;
  final Function(String) onValueChanged;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextField(
        onChanged: onValueChanged,
        decoration: InputDecoration(
          hintText: hint,
          focusedBorder: const OutlineInputBorder(
              borderSide:
                  BorderSide(color: ColorConstant.kPrimerColor, width: 2)),
          border: const OutlineInputBorder(borderSide: BorderSide(width: 2)),
        ),
      ),
    );
  }
}
