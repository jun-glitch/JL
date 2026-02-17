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

  factory Bird.fromFieldGuideJson(Map<String, dynamic> json) {
    final last = json['last_observed_at'];
    DateTime? lastDt;
    if (last is String && last.isNotEmpty) {
      // DRF가 ISO로 내려주는 경우 보통 parse 가능
      lastDt = DateTime.tryParse(last);
    }

    return Bird(
      speciesCode: (json['species_code'] ?? '').toString(),
      name: (json['common_name'] ?? '').toString(),
      scientificName: (json['scientific_name'] ?? '').toString(),
      order: (json['order'] ?? '').toString(),
      discovered: json['observed'] == true,
      observationCount: (json['observation_count'] ?? 0) as int,
      lastObservedAt: lastDt,
      imageUrl: json['cover_image_url']?.toString(),
    );
  }
}