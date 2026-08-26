class Product {
  final String title;
  final String price;
  final String location;
  final String imagePath;
  final String description;
  final String category;

  bool isFavorite;
  bool isFeatured;

  Product({
    required this.title,
    required this.price,
    required this.location,
    required this.imagePath,
    required this.description,
    required this.category,
    this.isFavorite = false,
    this.isFeatured = false,
  });
}