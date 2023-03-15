import 'package:flutter/material.dart';
import 'package:sparewo/common/widgets/custombutton.dart';
import 'package:sparewo/common/widgets/customtextfield.dart';
import 'package:sparewo/common/widgets/custom_title.dart';
import 'package:sparewo/common/widgets/socialmediabutton.dart';
import 'package:sparewo/routes/routes.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({Key? key}) : super(key: key);

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
                width: 200,
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
                        const CustomTitle(title: 'Sign Up'),
                        const SizedBox(
                          height: 10,
                        ),
                        CustomTextField(
                          hint: 'Email/Phone Number',
                          onValueChanged: (a) {},
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        CustomButton(
                          text: 'Sign Up',
                          onPressed: () {
                            Navigator.pushNamed(context, signInPageName);
                          },
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        const Text('or you can use'),
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
                            const Text('Already have account?'),
                            TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, signInPageName);
                                },
                                child: const Text('Sign in'))
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
