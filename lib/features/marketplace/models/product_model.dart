class ProductModel {
  final String id;

  // Información básica
  final String title;
  final String description;
  final double price;
  final String category;

  // Ubicación
  final String city;
  final String country;
  final String address;
  final double latitude;
  final double longitude;

  // Imágenes
  final List<String> images;

  // Información del vendedor
  final String sellerId;
  final String sellerName;
  final String sellerPhoto;
  final String sellerPhone;
  final String sellerEmail;

  // Estado del producto
  final String condition;
  final bool isFeatured;
  final bool isSold;

  // Estadísticas
  final int views;
  final int favorites;

  // Fechas
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.city,
    required this.country,
    this.address = '',
    this.latitude = 0,
    this.longitude = 0,
    this.images = const [],
    this.sellerId = '',
    this.sellerName = '',
    this.sellerPhoto = '',
    this.sellerPhone = '',
    this.sellerEmail = '',
    this.condition = 'Usado',
    this.isFeatured = false,
    this.isSold = false,
    this.views = 0,
    this.favorites = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  ProductModel copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    String? category,
    String? city,
    String? country,
    String? address,
    double? latitude,
    double? longitude,
    List<String>? images,
    String? sellerId,
    String? sellerName,
    String? sellerPhoto,
    String? sellerPhone,
    String? sellerEmail,
    String? condition,
    bool? isFeatured,
    bool? isSold,
    int? views,
    int? favorites,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      city: city ?? this.city,
      country: country ?? this.country,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      images: images ?? this.images,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      sellerPhoto: sellerPhoto ?? this.sellerPhoto,
      sellerPhone: sellerPhone ?? this.sellerPhone,
      sellerEmail: sellerEmail ?? this.sellerEmail,
      condition: condition ?? this.condition,
      isFeatured: isFeatured ?? this.isFeatured,
      isSold: isSold ?? this.isSold,
      views: views ?? this.views,
      favorites: favorites ?? this.favorites,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      category: map['category'] ?? '',
      city: map['city'] ?? '',
      country: map['country'] ?? '',
      address: map['address'] ?? '',
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      images: List<String>.from(map['images'] ?? []),
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? '',
      sellerPhoto: map['sellerPhoto'] ?? '',
      sellerPhone: map['sellerPhone'] ?? '',
      sellerEmail: map['sellerEmail'] ?? '',
      condition: map['condition'] ?? 'Usado',
      isFeatured: map['isFeatured'] ?? false,
      isSold: map['isSold'] ?? false,
      views: map['views'] ?? 0,
      favorites: map['favorites'] ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'city': city,
      'country': country,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'images': images,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerPhoto': sellerPhoto,
      'sellerPhone': sellerPhone,
      'sellerEmail': sellerEmail,
      'condition': condition,
      'isFeatured': isFeatured,
      'isSold': isSold,
      'views': views,
      'favorites': favorites,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}