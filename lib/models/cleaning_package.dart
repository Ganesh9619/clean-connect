class CleaningPackage {
  const CleaningPackage({
    required this.id,
    required this.name,
    required this.tagline,
    required this.basePrice,
    required this.pricePerExtraBedroom,
    required this.durationHours,
    required this.includes,
  });

  final String id;
  final String name;
  final String tagline;
  final int basePrice;
  final int pricePerExtraBedroom;
  final double durationHours;
  final List<String> includes;

  static const includedBedrooms = 2;

  int priceFor(int bedrooms) {
    final extra = bedrooms > includedBedrooms ? bedrooms - includedBedrooms : 0;
    return basePrice + extra * pricePerExtraBedroom;
  }

  /// Cleaners receive the job price minus the platform commission.
  int cleanerPayoutFor(int bedrooms) => (priceFor(bedrooms) * 0.8).round();
}
