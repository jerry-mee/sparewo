import 'package:flutter/material.dart';
import 'package:sparewo/common/widgets/custombutton.dart';
import 'package:sparewo/common/widgets/customtextfield.dart';
import 'package:sparewo/common/widgets/custom_title.dart';
import 'package:sparewo/common/widgets/socialmediabutton.dart';
import 'package:sparewo/routes/routes.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 100,
                child: Image.asset(
                  'assets/logo/Group.png',
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Card(
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: SizedBox(
                    width: 300,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CustomTitle(title: 'Login'),
                        const SizedBox(
                          height: 10,
                        ),
                        CustomTextField(
                          hint: 'Email',
                          onValueChanged: (a) {},
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        CustomTextField(
                          hint: 'Password',
                          onValueChanged: (a) {},
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [TextButton(onPressed: () {}, child: const Text('Forget Password?'))],
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        CustomButton(
                          text: 'Login',
                          onPressed: () {
                            Navigator.pushNamed(context, homePageName);
                          },
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        const Text('or login with'),
                        const SizedBox(
                          height: 10,
                        ),
                        SocialLoginButton(
                          text: 'Google',
                          icon: 'assets/logo/google.png',
                          onPressed: () {},
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        SocialLoginButton(
                          text: 'Facebook',
                          icon: 'assets/logo/facebook.png',
                          onPressed: () {},
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Don\'t have an account?'),
                            TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, signUpPageName);
                                },
                                child: const Text('Sign Up'))
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}
