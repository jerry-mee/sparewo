import 'package:flutter/material.dart';
import 'package:sparewo/pages/home/home_page.dart';
import 'package:sparewo/pages/login/login_page.dart';
import 'package:sparewo/pages/sigup/signup_page.dart';

const String signUpPageName = '/SignUp';
const String signInPageName = '/SignIn';
const String homePageName = "/HomePage";

Map<String, WidgetBuilder> route = {
  signUpPageName: (context) => const SignUpPage(),
  signInPageName: (context) => const LoginPage(),
  homePageName: (context) => HomePage(),
};
