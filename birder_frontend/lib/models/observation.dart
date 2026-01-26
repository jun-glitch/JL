class Observation {
  final String locationText;   // "올림픽공원 부근"
  final String coordText;      // "15°N 135°W" (원하면 double lat/lon으로)
  final DateTime observedAt;

  const Observation({
    required this.locationText,
    required this.coordText,
    required this.observedAt,
  });
}