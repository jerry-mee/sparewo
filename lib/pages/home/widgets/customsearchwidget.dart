import 'package:flutter/material.dart';
import 'package:sparewo/common/widgets/custombutton.dart';

import 'package:sparewo/utilis/constants.dart';

import 'package:carousel_indicator/carousel_indicator.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class SearchWidget extends StatefulWidget {
  SearchWidget({
    super.key,
  });

  @override
  State<SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  CarouselController buttonCarouselController = CarouselController();

  List<String> bannerImages = [
    'assets/images/banner.jpg',
    'assets/images/banner.jpg',
    'assets/images/banner.jpg',
  ];

  int pageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 100, vertical: 10),
      child: Wrap(
          //mainAxisAlignment: MainAxisAlignment.center,

          direction: Axis.horizontal,
          children: [
            Container(
              width: MediaQuery.of(context).size.width * 0.4,
              height: 400,
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    children: [
                      Text(
                        'Select your Car to find Matching Parts',
                        textAlign: TextAlign.start,
                        style: TextConstant.homeProductButtonSelectedTitleTextStyle,
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      CarSearchDropDownButton(Text: 'Car Brand'),
                      SizedBox(
                        height: 10,
                      ),
                      CarSearchDropDownButton(Text: 'Car Model'),
                      SizedBox(
                        height: 10,
                      ),
                      CarSearchDropDownButton(Text: 'Car Name'),
                      SizedBox(
                        height: 10,
                      ),
                      CarSearchDropDownButton(Text: 'Car Number'),
                      SizedBox(
                        height: 10,
                      ),
                      CustomButton(text: 'Search', onPressed: () {})
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 20,
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.4,
              child: Column(
                children: [
                  CarouselSlider(
                    carouselController: buttonCarouselController,
                    options: CarouselOptions(
                        height: 390,
                        viewportFraction: 1,
                        onPageChanged: (value, a) {
                          pageIndex = value;
                          setState(() {});
                        }),
                    items: bannerImages.map((i) {
                      return Builder(
                        builder: (BuildContext context) {
                          return Container(
                            width: MediaQuery.of(context).size.width,
                            margin: EdgeInsets.symmetric(horizontal: 2.0),
                            decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.all(Radius.circular(30))),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(30.0),
                              child: Image.asset(
                                '$i',
                                fit: BoxFit.fill,
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                  CarouselIndicator(
                    activeColor: ColorConstant.kPrimerColor,
                    color: Colors.grey,
                    count: bannerImages.length,
                    index: pageIndex,
                  )
                ],
              ),
            ),

            // Container(
            //   padding: EdgeInsets.all(10),
            //   decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(20))),
            //   height: 400,
            //   child: Image.asset(
            //     'assets/images/banner.jpg',
            //     fit: BoxFit.cover,
            //   ),
            // )
          ]),
    );
  }
}

class CarSearchDropDownButton extends StatelessWidget {
  const CarSearchDropDownButton({
    required this.Text,
    super.key,
  });
  final String Text;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextField(
        onChanged: (a) {},
        decoration: InputDecoration(
          suffixIcon: Container(
            padding: EdgeInsets.all(3),
            child: IconButton(onPressed: () {}, icon: Icon(Icons.keyboard_arrow_down_outlined)),
          ),
          hintText: Text,
          hintStyle: TextStyle(color: Colors.grey),
          focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: ColorConstant.kPrimerColor, width: 2)),
          border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(width: 2)),
        ),
      ),
    );
  }
}
