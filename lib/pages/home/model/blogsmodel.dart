class Blog {
  Blog({
    required this.title,
    required this.image,
    required this.breif,
  });
  final String title;
  final String image;
  final String breif;
}

List<Blog> blogs = [
  Blog(
      title: 'How to professionally clean your engine',
      image: 'assets/images/Blog Post 1.png',
      breif: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec non est sed magna dapibus commodo luctus quis est.'),
  Blog(
      title: 'Cool accessories for true car lovers',
      image: 'assets/images/Blog Post 2.png',
      breif: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec non est sed magna dapibus commodo luctus quis est.'),
  Blog(
      title: 'Car Detailing jobs you need to check out',
      image: 'assets/images/Blog Post 3.png',
      breif: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec non est sed magna dapibus commodo luctus quis est.'),
];
