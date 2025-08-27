class Earthquake {
  final String id;
  final DateTime date;
  final double latitude;
  final double longitude;
  final double depth;
  final double magnitude;
  final String location;
  final String? city;
  final String? district;

  Earthquake({
    required this.id,
    required this.date,
    required this.latitude,
    required this.longitude,
    required this.depth,
    required this.magnitude,
    required this.location,
    this.city,
    this.district,
  });

  factory Earthquake.fromJson(Map<String, dynamic> json) {
    return Earthquake(
      id: json['earthquake_id'] ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.parse(json['date']),
      latitude: double.parse(json['lat'].toString()),
      longitude: double.parse(json['lng'].toString()),
      depth: double.parse(json['depth'].toString()),
      magnitude: double.parse(json['mag'].toString()),
      location: json['title'] ?? '',
      city: json['city'],
      district: json['district'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'earthquake_id': id,
      'date': date.toIso8601String(),
      'lat': latitude,
      'lng': longitude,
      'depth': depth,
      'mag': magnitude,
      'title': location,
      'city': city,
      'district': district,
    };
  }
}
