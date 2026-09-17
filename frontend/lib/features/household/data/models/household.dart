/// Mirrors the backend's `HouseholdRead` schema exactly
/// (`backend/src/schemas/household.py`).
class Household {
  const Household({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.currency,
    required this.timezone,
  });

  factory Household.fromJson(Map<String, dynamic> json) {
    return Household(
      id: json['id'] as String,
      name: json['name'] as String,
      createdBy: json['created_by'] as String,
      currency: json['currency'] as String,
      timezone: json['timezone'] as String,
    );
  }

  final String id;
  final String name;
  final String createdBy;
  final String currency;
  final String timezone;
}
