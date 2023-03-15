import 'package:flutter/material.dart';

class SocialLoginButton extends StatelessWidget {
  const SocialLoginButton({
    required this.onPressed,
    required this.icon,
    required this.text,
    super.key,
  });
  final String icon;
  final VoidCallback onPressed;
  final String text;
  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          minimumSize:
              MaterialStateProperty.all(const Size(double.infinity, 50)),
          shape: MaterialStateProperty.all(RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              width: 25,
              height: 25,
              child: Image.asset(
                icon,
              ),
            ),
            Text(
              text,
              style: const TextStyle(color: Colors.black),
            ),
            const SizedBox(),
          ],
        ));
  }
}
