class MedicineModel {
  final String id;
  final String title;
  final String count;
  final bool isAvailable;
  final String description;

  MedicineModel({
    required this.id,
    required this.title,
    required this.count,
    required this.isAvailable,
    this.description = "",
  });

  factory MedicineModel.fromJson(Map<String, dynamic> json) {
    return MedicineModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      count: json['count'] ?? '0',
      isAvailable: json['available'] == 'true' || json['available'] == true,
      description: json['description'] ?? '',
    );
  }
}
