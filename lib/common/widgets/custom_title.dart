// ignore: file_names
import 'package:flutter/material.dart';
import 'package:sparewo/utilis/constants.dart';

class CustomTitle extends StatelessWidget {
  const CustomTitle({
    required this.title,
    super.key,
  });
  final String title;
  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(
          color: ColorConstant.kPrimerColor,
          fontSize: 30,
          fontWeight: FontWeight.bold,
        ));
  }
}
