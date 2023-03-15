import 'package:flutter/material.dart';
import 'package:sparewo/utilis/constants.dart';

class SearchByCategory extends StatelessWidget {
  const SearchByCategory({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 100, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search by Category',
            style: TextConstant.homeProductButtonSelectedTitleTextStyle,
          ),
          SizedBox(
            height: 20,
          ),
          Wrap(
            children: [
              SearchByCategoryButton(
                categoryName: 'Engine',
                categoryImage: 'assets/images/Engine.png',
                onTapped: () {},
              ),
              SearchByCategoryButton(
                categoryName: 'Electricals',
                categoryImage: 'assets/images/Electricals.png',
                onTapped: () {},
              ),
              SearchByCategoryButton(
                categoryName: 'Steering',
                categoryImage: 'assets/images/Steering Wheel Icon.png',
                onTapped: () {},
              ),
              SearchByCategoryButton(
                categoryName: 'Body Kits',
                categoryImage: 'assets/images/body_kit.png',
                onTapped: () {},
              ),
              SearchByCategoryButton(
                categoryName: 'Chasis',
                categoryImage: 'assets/images/Chasis.png',
                onTapped: () {},
              ),
              SearchByCategoryButton(
                categoryName: 'Accessories',
                categoryImage: 'assets/images/Accessories.png',
                onTapped: () {},
              ),
              SearchByCategoryButton(
                categoryName: 'Motor Oils',
                categoryImage: 'assets/images/Motor Oils.png',
                onTapped: () {},
              ),
              SearchByCategoryButton(
                categoryName: 'All Others',
                categoryImage: 'assets/images/Other Categories Icon.png',
                onTapped: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SearchByCategoryButton extends StatelessWidget {
  const SearchByCategoryButton({
    required this.categoryName,
    required this.categoryImage,
    required this.onTapped,
    super.key,
  });
  final String categoryImage;
  final String categoryName;
  final VoidCallback onTapped;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: GestureDetector(
        onTap: onTapped,
        child: Column(
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.08,
              child: Image.asset(
                categoryImage,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Text(categoryName),
          ],
        ),
      ),
    );
  }
}
