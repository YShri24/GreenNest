import 'package:greennest/models/health_log.dart';

class PlantCard {
  final int plantCardId;
  final int userId;
  final String nickname;
  final String species;
  final String? photoUrl;
  final String? location;
  final String? lightExposure;
  final DateTime dateAdded;
  final String? waterFrequency;
  final String? fertilizeFrequency;
  final List<HealthLog> healthLogs;

  PlantCard({
    required this.plantCardId,
    required this.userId,
    required this.nickname,
    required this.species,
    this.photoUrl,
    this.location,
    this.lightExposure,
    required this.dateAdded,
    this.waterFrequency,
    this.fertilizeFrequency,
    required this.healthLogs,
  });

  factory PlantCard.fromJson(Map<String, dynamic> json) {
    var list = json['health_logs'] as List? ?? [];
    List<HealthLog> logsList = list.map((i) => HealthLog.fromJson(i)).toList();

    return PlantCard(
      plantCardId: json['plant_card_id'],
      userId: json['user_id'],
      nickname: json['nickname'],
      species: json['species'],
      photoUrl: json['photo_url'],
      location: json['location'],
      lightExposure: json['light_exposure'],
      dateAdded: DateTime.parse(json['date_added']),
      waterFrequency: json['water_frequency'],
      fertilizeFrequency: json['fertilize_frequency'],
      healthLogs: logsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plant_card_id': plantCardId,
      'user_id': userId,
      'nickname': nickname,
      'species': species,
      'photo_url': photoUrl,
      'location': location,
      'light_exposure': lightExposure,
      'date_added': "${dateAdded.year.toString().padLeft(4, '0')}-${dateAdded.month.toString().padLeft(2, '0')}-${dateAdded.day.toString().padLeft(2, '0')}",
      'water_frequency': waterFrequency,
      'fertilize_frequency': fertilizeFrequency,
      'health_logs': healthLogs.map((e) => e.toJson()).toList(),
    };
  }
}
