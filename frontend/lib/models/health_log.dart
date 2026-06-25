class HealthLog {
  final int logId;
  final int plantCardId;
  final String entryType;
  final String? diagnosis;
  final double? confidence;
  final String? photoUrl;
  final DateTime createdAt;

  HealthLog({
    required this.logId,
    required this.plantCardId,
    required this.entryType,
    this.diagnosis,
    this.confidence,
    this.photoUrl,
    required this.createdAt,
  });

  factory HealthLog.fromJson(Map<String, dynamic> json) {
    return HealthLog(
      logId: json['log_id'],
      plantCardId: json['plant_card_id'],
      entryType: json['entry_type'],
      diagnosis: json['diagnosis'],
      confidence: json['confidence'] != null ? (json['confidence'] as num).toDouble() : null,
      photoUrl: json['photo_url'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'log_id': logId,
      'plant_card_id': plantCardId,
      'entry_type': entryType,
      'diagnosis': diagnosis,
      'confidence': confidence,
      'photo_url': photoUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
