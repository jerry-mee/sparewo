import 'package:flutter/material.dart';

class ColorConstant {
  static const Color blueDarker = Color(0xff122531);
  static const Color yellow = Color(0xfffabb0a);
  static const Color whilte = Colors.white;
  static const Color black = Colors.black;
  static const Color kPrimerColor = Color(0xfffbbc09);
  static const Color kSecondaryColor = Color(0xffF4E110);
  static const Color kTertiryColor = Color(0xff38B887);
}

class TextConstant {
  static const TextStyle bottomLabelsTextStyle =
      TextStyle(color: Colors.white, fontSize: 12);
  static const bottomHeaderTextStyle = TextStyle(
      color: ColorConstant.yellow, fontWeight: FontWeight.bold, fontSize: 18);
  static const newLabelTextStyle = TextStyle(
      color: ColorConstant.whilte, fontWeight: FontWeight.bold, fontSize: 16);
  static const productTilePriceTextStyle = TextStyle(
      color: ColorConstant.yellow, fontWeight: FontWeight.bold, fontSize: 16);
  static const productTileTitleTextStyle = TextStyle(
      color: ColorConstant.black, fontWeight: FontWeight.bold, fontSize: 18);
  static const homeProductButtonSelectedTitleTextStyle = TextStyle(
      color: ColorConstant.yellow, fontWeight: FontWeight.bold, fontSize: 20);
  static const homeProductButtonUnSelectedTitleTextStyle =
      TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 20);
}
