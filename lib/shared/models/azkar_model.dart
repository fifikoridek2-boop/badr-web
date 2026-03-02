class AzkarModel {
  final int id;
  final String text;
  final String category;
  final int count;
  int currentCount;

  AzkarModel({
    required this.id,
    required this.text,
    required this.category,
    required this.count,
    this.currentCount = 0,
  });

  factory AzkarModel.fromJson(Map<String, dynamic> json, String category) {
    return AzkarModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      text: json['text']?.toString() ?? '',
      category: category,
      count: int.tryParse(json['count'].toString()) ?? 1,
    );
  }

  bool get isDone => currentCount >= count;

  void increment() {
    if (!isDone) currentCount++;
  }

  void reset() {
    currentCount = 0;
  }
}
