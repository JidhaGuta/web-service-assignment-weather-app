class CitySuggestion {
  final String name;
  final String country;
  final String? state;
  final String displayName;

  CitySuggestion({
    required this.name,
    required this.country,
    this.state,
  }) : displayName = state != null ? '$name, $state, $country' : '$name, $country';

  factory CitySuggestion.fromJson(Map<String, dynamic> json) {
    return CitySuggestion(
      name: json['name'] ?? '',
      country: json['country'] ?? '',
      state: json['state'],
    );
  }
}

