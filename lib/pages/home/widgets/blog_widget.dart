import 'package:flutter/material.dart';
import 'package:sparewo/pages/home/model/blogsmodel.dart';
import 'package:sparewo/utilis/constants.dart';

class BlogWidget extends StatelessWidget {
  const BlogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
            height: MediaQuery.of(context).size.height * 1.5,
            color: ColorConstant.blueDarker,
            child: Column(
              children: [
                Container(
                  height: 120,
                  color: Colors.white,
                ),
              ],
            )),
        Container(
          alignment: Alignment.center,
          height: MediaQuery.of(context).size.height * 1.5,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    GestureDetector(
                      onTap: () {},
                      child: const ActionStack(
                        label: "Get Quote",
                        imageUrl: 'assets/images/quote.png',
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () {},
                      child: const ActionStack(
                        label: "Request\nService",
                        imageUrl: 'assets/images/service.png',
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Stack(
                  alignment: Alignment.bottomLeft,
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.width * 0.30,
                      width: MediaQuery.of(context).size.width * 0.39,
                      child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.asset("assets/images/person.jpg", fit: BoxFit.fill)),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Become a\nMerchant',
                            style: TextStyle(fontSize: 50, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Reach even more customers\nby selling your products\nwith us.",
                            textScaleFactor: 1.2,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Join Now",
                            style: TextStyle(
                                decorationThickness: 2,
                                decoration: TextDecoration.underline,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Colors.white),
                          ),
                          SizedBox(height: 10),
                        ],
                      ),
                    )
                  ],
                )
              ],
            ),
            const SizedBox(height: 20),
            const SOSWidget(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 200.0),
              child: Text(
                'FROM OUR BLOG',
                style: TextConstant.bottomHeaderTextStyle.copyWith(fontWeight: FontWeight.w900, fontSize: 30),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.05),
            const BlogCard()
          ]),
        ),
      ],
    );
  }
}

class ActionStack extends StatelessWidget {
  const ActionStack({Key? key, required this.imageUrl, required this.label}) : super(key: key);
  final String imageUrl;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        SizedBox(
            height: MediaQuery.of(context).size.width * 0.143,
            width: MediaQuery.of(context).size.width * 0.39,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(imageUrl, fit: BoxFit.fill),
            )),
        Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: Text(
            label,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white),
          ),
        )
      ],
    );
  }
}

class SOSWidget extends StatelessWidget {
  const SOSWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Container(
            height: MediaQuery.of(context).size.height * 0.1,
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.1),
            child: Image.asset("assets/images/sos.jpg", fit: BoxFit.fill)));
  }
}

class BlogCard extends StatelessWidget {
  const BlogCard({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
                blogs.length,
                (index) => Container(
                      alignment: Alignment.center,
                      width: MediaQuery.of(context).size.width * 0.2,
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.3,
                          width: double.infinity,
                          child: ClipRRect(
                              borderRadius: BorderRadius.circular(30.0),
                              child: Image.asset(
                                blogs[index].image,
                                fit: BoxFit.fill,
                              )),
                        ),
                        SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                        Text(
                          blogs[index].title,
                          style: TextConstant.bottomHeaderTextStyle.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          blogs[index].breif,
                          style: TextConstant.bottomLabelsTextStyle,
                        ),
                        SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                        Row(
                          children: const [
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: ColorConstant.yellow,
                              child: Icon(
                                Icons.arrow_forward_ios_sharp,
                                color: Colors.white,
                                size: 10,
                              ),
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Text(
                              "Read More",
                              style: TextConstant.bottomHeaderTextStyle,
                            )
                          ],
                        )
                      ]),
                    ))));
  }
}
