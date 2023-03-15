import 'package:flutter/material.dart';
import 'package:sparewo/utilis/constants.dart';

class BottomInformationPanel extends StatelessWidget {
  const BottomInformationPanel({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: ColorConstant.blueDarker,
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.center, children: const [
            SocialMediaLogin(),
            SizedBox(width: 20),
            AboutSection(),
            LegalWidget(),
            NewsLetter(),
          ]),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(
              color: Colors.grey,
            ),
          ),
          const Text(
            'SpareWo LLC @ Rights Reserved. 2016-2022',
            style: TextConstant.bottomLabelsTextStyle,
          )
        ],
      ),
    );
  }
}

class NewsLetter extends StatelessWidget {
  const NewsLetter({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 50),
        const Text("NEWSLETTER", style: TextConstant.bottomHeaderTextStyle),
        const SizedBox(height: 20),
        const Text("Signup to our newsletter \nfor updates and more", textScaleFactor: 1.2, style: TextConstant.bottomLabelsTextStyle),
        const SizedBox(height: 10),
        Container(
          height: 30,
          width: 180,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2)),
          child: Row(children: [
            Expanded(
              child: TextField(
                onSubmitted: (value) {},
                decoration: const InputDecoration.collapsed(hintText: "Email Address").copyWith(hintStyle: const TextStyle(fontSize: 10)),
              ),
            ),
            Container(
              color: ColorConstant.yellow,
              child: const Icon(
                Icons.arrow_forward_ios_sharp,
                color: Colors.white,
              ),
            )
          ]),
        )
      ],
    );
  }
}

class LegalWidget extends StatelessWidget {
  const LegalWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SizedBox(height: 50),
        Text(
          "LEGAL",
          style: TextConstant.bottomHeaderTextStyle,
        ),
        SizedBox(height: 20),
        Text("Merchant Application Form", style: TextConstant.bottomLabelsTextStyle),
        SizedBox(height: 4),
        Text("Terms and Conditions", style: TextConstant.bottomLabelsTextStyle),
        SizedBox(height: 4),
        Text('Privacy Policy', style: TextConstant.bottomLabelsTextStyle),
        SizedBox(height: 4),
      ],
    );
  }
}

class AboutSection extends StatelessWidget {
  const AboutSection({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SizedBox(height: 50),
        Text(
          "ABOUT",
          style: TextConstant.bottomHeaderTextStyle,
        ),
        SizedBox(height: 20),
        Text("About US", style: TextConstant.bottomLabelsTextStyle),
        SizedBox(height: 4),
        Text("Services", style: TextConstant.bottomLabelsTextStyle),
        SizedBox(height: 4),
        Text('Blog', style: TextConstant.bottomLabelsTextStyle),
        SizedBox(height: 4),
        Text("Contact", style: TextConstant.bottomLabelsTextStyle),
      ],
    );
  }
}

class SocialMediaLogin extends StatelessWidget {
  const SocialMediaLogin({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 150, width: 150, child: Image.asset("assets/images/logo.png")),
        Row(
          children: const [
            CircleAvatar(
              radius: 18,
              backgroundColor: ColorConstant.yellow,
              child: SocialImage(imageUrl: 'assets/images/Facebook.png'),
            ),
            SizedBox(width: 10),
            CircleAvatar(radius: 18, backgroundColor: ColorConstant.yellow, child: SocialImage(imageUrl: 'assets/images/Instagram.png')),
            SizedBox(width: 10),
            CircleAvatar(radius: 18, backgroundColor: ColorConstant.yellow, child: SocialImage(imageUrl: 'assets/images/Twitter.png')),
            SizedBox(width: 10),
            CircleAvatar(
              radius: 18,
              backgroundColor: ColorConstant.yellow,
              child: SocialImage(imageUrl: 'assets/images/Whatsapp.png'),
            )
          ],
        )
      ],
    );
  }
}

class SocialImage extends StatelessWidget {
  const SocialImage({Key? key, required this.imageUrl}) : super(key: key);
  final String imageUrl;
  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 20, width: 20, child: Image.asset(imageUrl));
  }
}
