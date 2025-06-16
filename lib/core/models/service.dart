class CleaningService {
  final String id;
  final String name;
  final String description;
  final double price;
  final Duration estimatedDuration;

  CleaningService({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.estimatedDuration,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'estimatedDuration': estimatedDuration.inMinutes,
    };
  }

  factory CleaningService.fromJson(Map<String, dynamic> json) {
    return CleaningService(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: json['price'].toDouble(),
      estimatedDuration: Duration(minutes: json['estimatedDuration']),
    );
  }
}
