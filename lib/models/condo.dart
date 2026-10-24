class Condo {
  const Condo({
    required this.buildingName,
    required this.address,
    required this.tower,
    required this.unit,
    required this.bedrooms,
    required this.bathrooms,
    required this.accessNotes,
    required this.hasPets,
  });

  final String buildingName;
  final String address;
  final String tower;
  final String unit;
  final int bedrooms;
  final int bathrooms;
  final String accessNotes;
  final bool hasPets;

  /// Shown to cleaners before they accept. Tower and unit stay private until
  /// a cleaner owns the job.
  String get publicLabel => '$buildingName · $bedroomLabel';

  String get fullLabel {
    final towerPart = tower.isEmpty ? '' : '$tower, ';
    return '$buildingName, ${towerPart}Unit $unit';
  }

  String get bedroomLabel {
    final bed = bedrooms == 0 ? 'Studio' : '$bedrooms BR';
    return '$bed · $bathrooms BA';
  }
}
