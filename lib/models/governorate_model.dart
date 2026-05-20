class GovernorateModel {
  final String id;
  final String name;

  const GovernorateModel({required this.id, required this.name});

  factory GovernorateModel.fromJson(Map<String, dynamic> json) {
    return GovernorateModel(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}
