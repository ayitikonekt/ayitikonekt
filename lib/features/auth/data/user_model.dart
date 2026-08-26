class UserModel {
  final String uid;
  final String email;

  final String name;
  final String lastName;
  final String phone;

  final String country;
  final String city;
  final String address;
  final String language;

  final String photo;

  final bool verified;

  final double reputation;

  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.lastName,
    required this.phone,
    required this.country,
    required this.city,
    this.address = '',
    required this.language,
    required this.photo,
    required this.verified,
    required this.reputation,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      "uid": uid,
      "email": email,
      "name": name,
      "lastName": lastName,
      "phone": phone,
      "country": country,
      "city": city,
      "address": address,
      "language": language,
      "photo": photo,
      "verified": verified,
      "reputation": reputation,
      "createdAt": createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map["uid"] ?? "",
      email: map["email"] ?? "",
      name: map["name"] ?? "",
      lastName: map["lastName"] ?? "",
      phone: map["phone"] ?? "",
      country: map["country"] ?? "",
      city: map["city"] ?? "",
      address: map["address"] ?? "",
      language: map["language"] ?? "",
      photo: map["photo"] ?? "",
      verified: map["verified"] ?? false,
      reputation: (map["reputation"] ?? 5).toDouble(),
      createdAt: DateTime.tryParse(map["createdAt"] ?? "") ?? DateTime.now(),
    );
  }

  UserModel copyWith({
    String? email,
    String? name,
    String? lastName,
    String? phone,
    String? country,
    String? city,
    String? address,
    String? language,
    String? photo,
    bool? verified,
    double? reputation,
  }) {
    return UserModel(
      uid: uid,
      email: email ?? this.email,
      name: name ?? this.name,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      country: country ?? this.country,
      city: city ?? this.city,
      address: address ?? this.address,
      language: language ?? this.language,
      photo: photo ?? this.photo,
      verified: verified ?? this.verified,
      reputation: reputation ?? this.reputation,
      createdAt: createdAt,
    );
  }
}
