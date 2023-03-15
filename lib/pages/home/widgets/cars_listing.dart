import 'package:flutter/material.dart';

class CarsListings extends StatelessWidget {
  const CarsListings({super.key});

  @override
  Widget build(BuildContext context) {
    List<String> carList = ["jeep", "nissan", 'lexus', "sib", "toyota", "mit", "honda", "bmw"];
    return Container(
        alignment: Alignment.center,
        height: 200,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            carList.length,
            (index) => Padding(
              padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.02),
              child: SizedBox(
                height: MediaQuery.of(context).size.width * 0.06,
                width: MediaQuery.of(context).size.width * 0.06,
                // ignore: prefer_interpolation_to_compose_strings
                child: Image.asset("assets/images/" + carList[index] + '.png'),
              ),
            ),
          ),
        ));
  }
}
