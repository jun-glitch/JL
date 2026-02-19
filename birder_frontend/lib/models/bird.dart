class Bird {
  final String speciesCode;
  final String name; // common_name
  final String scientificName;
  final String order;

  final bool discovered; // observed
  final int observationCount;
  final DateTime? lastObservedAt;
  final String? imageUrl; // cover_image_url

  const Bird({
    required this.speciesCode,
    required this.name,
    required this.scientificName,
    required this.order,
    required this.discovered,
    required this.observationCount,
    required this.lastObservedAt,
    required this.imageUrl,
  });

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static DateTime? _toDate(dynamic v) {
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
    return null;
  }

  static bool _toBool(dynamic v) {
    if (v == true) return true;
    if (v is String) return v.toLowerCase() == 'true' || v == '1';
    if (v is num) return v != 0;
    return false;
  }

  factory Bird.fromFieldGuideJson(
      Map<String, dynamic> json, {
        required String orderName,
      }) {
    return Bird(
      speciesCode: (json['species_code'] ?? '').toString(),
      name: (json['common_name'] ?? '').toString(),
      scientificName: (json['scientific_name'] ?? '').toString(),
      order: orderName,
      discovered: _toBool(json['observed']),
      observationCount: _toInt(json['observation_count']),
      lastObservedAt: _toDate(json['last_observed_at']),
      imageUrl: json['cover_image_url']?.toString(),
    );
  }
}
