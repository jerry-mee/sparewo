import 'package:flutter/widgets.dart';
import 'package:sparewo/utilis/constants.dart';

class SpecialOfferBanner extends StatelessWidget {
  const SpecialOfferBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      color: ColorConstant.yellow,
      child: Center(
          child: Text(
        "BLACK FRIDAY OFFER GET 10% DISCOUNT ON STOCK WORTH UGX. 1,000,000 THHIS NOVEMBER !",
        style: TextConstant.bottomLabelsTextStyle.copyWith(fontWeight: FontWeight.bold),
      )),
    );
  }
}
