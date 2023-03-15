import 'package:flutter/material.dart';

import '../../../../utilis/constants.dart';

class MenuBarWidget extends StatefulWidget {
  MenuBarWidget({super.key});

  @override
  State<MenuBarWidget> createState() => _MenuBarState();
}

class _MenuBarState extends State<MenuBarWidget> {
  String? dropdownValue;
  List<String> products = ['Wheels', 'Flash Lights', 'Engine', 'Chasis'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      color: ColorConstant.blueDarker,
      padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.02),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          SizedBox(height: 150, width: MediaQuery.of(context).size.width * 0.08, child: Image.asset("assets/images/logo.png")),
          searchBar(),
          const Text(
            "Request\nQuote",
            style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const Text(
            "Request\nService",
            style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.notification_important_rounded, color: Colors.white)),
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.message, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Container searchBar() {
    return Container(
      height: 50,
      width: MediaQuery.of(context).size.width * .55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onSubmitted: (value) {},
              decoration: const InputDecoration.collapsed(hintText: "Search eg car parts name"),
            ),
          ),
          const VerticalDivider(
            color: ColorConstant.yellow,
            thickness: 2,
          ),
          DropdownButton<String>(
            underline: const SizedBox(),
            hint: const Text(
              "All Categories",
              style: TextStyle(fontSize: 10),
            ),
            value: dropdownValue,
            items: products.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 10),
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                dropdownValue = newValue ?? "All Categories";
              });
            },
          ),
          const VerticalDivider(
            color: ColorConstant.yellow,
            thickness: 2,
          ),
          const Icon(Icons.search, color: Colors.grey)
        ],
      ),
    );
  }
}
