import 'package:flutter/material.dart';

class AppStoreLinksWidget extends StatelessWidget {
  const AppStoreLinksWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Color(0xfffabb0a), Color(0xfff08335)])),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Row(
          children: [
            SizedBox(
                width: MediaQuery.of(context).size.width * 0.12,
                child: Image.asset(
                  "assets/images/Sparewo Phone App.png",
                  fit: BoxFit.fill,
                )),
            SizedBox(width: MediaQuery.of(context).size.width * 0.01),
            const Text("Get faster Service\nvia our app.", style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white)),
          ],
        ),
        SizedBox(width: MediaQuery.of(context).size.width * 0.12),
        Row(
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.12,
              child: Image.asset("assets/images/appstore.png"),
            ),
            SizedBox(width: MediaQuery.of(context).size.width * 0.01),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.12,
              child: Image.asset("assets/images/google_store.png"),
            ),
          ],
        ),
      ]),
    );
  }
}
