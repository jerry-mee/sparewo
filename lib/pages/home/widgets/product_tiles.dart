import 'package:flutter/material.dart';
import 'package:sparewo/utilis/constants.dart';

import '../model/productmodel.dart';

class ProducatTiles extends StatelessWidget {
  const ProducatTiles({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 100, vertical: 10),
          child: Column(children: [
            Row(
              children: [
                HomeProductButton(
                  text: 'Brand New',
                  selected: true,
                  onPressed: () {},
                ),
                HomeProductButton(
                  text: 'Top Selling',
                  selected: false,
                  onPressed: () {},
                )
              ],
            ),
            Divider(
              color: ColorConstant.kPrimerColor,
              height: 2,
            ),
          ]),
        ),
        Container(
          padding: EdgeInsets.only(left: 100, right: 100, bottom: 50, top: 10),
          child: Wrap(
              children: List.generate(
            products.length,
            (index) => ProductTile(
              productTitle: products[index].title,
              productImage: products[index].image,
              productPrice: products[index].price,
              chartTap: () {},
              favoriteTap: () {},
            ),
          )),
        ),
      ],
    );
  }
}

class ProductTile extends StatelessWidget {
  const ProductTile({
    required this.productTitle,
    required this.productImage,
    required this.productPrice,
    required this.chartTap,
    required this.favoriteTap,
    super.key,
  });
  final String productTitle;
  final String productImage;
  final String productPrice;
  final VoidCallback favoriteTap;
  final VoidCallback chartTap;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 315,
      height: 350,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(color: ColorConstant.kPrimerColor, padding: EdgeInsets.all(2), child: Text('New', style: TextConstant.newLabelTextStyle)),
              ],
            ),
            SizedBox(
                height: 210,
                child: Image.asset(
                  productImage,
                  fit: BoxFit.fill,
                )),
            SizedBox(
              height: 10,
            ),
            Text(
              productTitle,
              style: TextConstant.productTileTitleTextStyle,
            ),
            SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'UGX.',
                      style: TextConstant.productTilePriceTextStyle,
                    ),
                    Text(
                      productPrice,
                      style: TextConstant.productTilePriceTextStyle,
                    ),
                  ],
                ),
                Row(
                  children: [
                    ProductTitleButton(icon: Icons.favorite_border_outlined, onTap: favoriteTap),
                    SizedBox(
                      width: 3,
                    ),
                    ProductTitleButton(icon: Icons.shopping_cart_outlined, onTap: chartTap)
                  ],
                )
              ],
            )
          ]),
        ),
      ),
    );
  }
}

class ProductTitleButton extends StatelessWidget {
  const ProductTitleButton({
    required this.icon,
    required this.onTap,
    super.key,
  });
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 14,
        backgroundColor: ColorConstant.kPrimerColor,
        child: Icon(icon, color: ColorConstant.whilte),
      ),
    );
  }
}

class HomeProductButton extends StatelessWidget {
  const HomeProductButton({
    required this.text,
    required this.selected,
    required this.onPressed,
    super.key,
  });
  final String text;
  final bool selected;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: selected
                ? Border(
                    bottom: BorderSide(
                      width: 3,
                      color: ColorConstant.kPrimerColor,
                    ),
                  )
                : Border(),
          ),
          child: Text(
            text,
            style: selected ? TextConstant.homeProductButtonSelectedTitleTextStyle : TextConstant.homeProductButtonUnSelectedTitleTextStyle,
          )),
    );
  }
}
