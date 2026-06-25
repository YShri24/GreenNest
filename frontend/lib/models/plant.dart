class Plant {
  final int plantId;
  final String name;
  final String category;
  final String? description;
  final double price;
  final int stock;
  final String? sunlight;
  final String? waterFrequency;
  final String? imageUrl;
  final List<String> purpose;
  final List<String> location;
  final List<String> light;
  final List<String> season;
  final String maintenance;
  final List<String> giftFor;
  final List<String> occasion;

  Plant({
    required this.plantId,
    required this.name,
    required this.category,
    this.description,
    required this.price,
    required this.stock,
    this.sunlight,
    this.waterFrequency,
    this.imageUrl,
    required this.purpose,
    required this.location,
    required this.light,
    required this.season,
    required this.maintenance,
    required this.giftFor,
    required this.occasion,
  });

  factory Plant.fromJson(Map<String, dynamic> json) {
    return Plant(
      plantId: json['plant_id'],
      name: json['name'],
      category: json['category'],
      description: json['description'],
      price: json['price'] is String ? double.parse(json['price']) : (json['price'] as num).toDouble(),
      stock: json['stock'],
      sunlight: json['sunlight'],
      waterFrequency: json['water_frequency'],
      imageUrl: json['image_url'],
      purpose: List<String>.from(json['purpose'] ?? []),
      location: List<String>.from(json['location'] ?? []),
      light: List<String>.from(json['light'] ?? []),
      season: List<String>.from(json['season'] ?? []),
      maintenance: json['maintenance'] ?? 'Low',
      giftFor: List<String>.from(json['gift_for'] ?? []),
      occasion: List<String>.from(json['occasion'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plant_id': plantId,
      'name': name,
      'category': category,
      'description': description,
      'price': price,
      'stock': stock,
      'sunlight': sunlight,
      'water_frequency': waterFrequency,
      'image_url': imageUrl,
      'purpose': purpose,
      'location': location,
      'light': light,
      'season': season,
      'maintenance': maintenance,
      'gift_for': giftFor,
      'occasion': occasion,
    };
  }
}
