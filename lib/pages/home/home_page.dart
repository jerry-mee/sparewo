import 'package:flutter/material.dart';
import 'package:sparewo/common/widgets/custombutton.dart';
import 'package:sparewo/utilis/constants.dart';
import 'package:carousel_indicator/carousel_indicator.dart';
import 'package:carousel_slider/carousel_slider.dart';

import 'widgets/appstore_links_widget.dart';
import 'widgets/blog_widget.dart';
import 'widgets/bottom_information_panel.dart';
import 'widgets/cars_listing.dart';
import 'widgets/customsearchwidget.dart';
import 'widgets/menu_bar.dart';
import 'widgets/product_tiles.dart';
import 'widgets/searchbycatorgies.dart';
import 'widgets/special_offer_banner.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constrains) {
      print(constrains);
      return Scaffold(
        body: ListView(
          children: [
            SpecialOfferBanner(),
            MenuBarWidget(),
            SearchWidget(),
            SearchByCategory(),
            ProducatTiles(),
            CarsListings(),
            BlogWidget(),
            AppStoreLinksWidget(),
            BottomInformationPanel()
          ],
        ),
      );
    });
  }
}
