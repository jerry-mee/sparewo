class Product {
  Product({
    required this.title,
    required this.image,
    required this.price,
  });
  final String title;
  final String image;
  final String price;
}

List<Product> products = [
  Product(title: 'Pirelli Cinturato P7', image: 'assets/images/Tyre Preview 1.png', price: '480,000'),
  Product(title: 'BOSCH S4 Battery', image: 'assets/images/Battery Preview.png', price: '480,000'),
  Product(title: 'BMW Front Lights', image: 'assets/images/BMW Headlight.png', price: '480,000'),
  Product(title: 'Seat Covers', image: 'assets/images/Car Seat Cover Product Item.png', price: '480,000'),
  Product(title: 'Dual Pipe Exhaust', image: 'assets/images/Exhaust Product Item.png', price: '480,000'),
  Product(title: 'Matter Black Rims', image: 'assets/images/Wheel Product Item.png', price: '480,000'),
  Product(title: 'Full Set ToolBox', image: 'assets/images/Toolbox Product Item.png', price: '480,000'),
  Product(title: 'BOSCH oil Filter', image: 'assets/images/Oil Filter Product Item.png', price: '480,000'),
];
