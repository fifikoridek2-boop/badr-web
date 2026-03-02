class SurahModel {
  final int id;
  final int number;
  final String arName;
  final String nameEn;
  final String type;
  final int ayatCount;

  SurahModel({
    required this.id,
    required this.number,
    required this.arName,
    required this.nameEn,
    required this.type,
    required this.ayatCount,
  });

  factory SurahModel.fromJson(Map<String, dynamic> json) {
    return SurahModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      number: int.tryParse(json['number'].toString()) ?? 0,
      arName: json['name_ar']?.toString() ?? '',
      nameEn: json['name_en']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      ayatCount: int.tryParse(json['ayat_count'].toString()) ?? 0,
    );
  }

  String get typeAr => type == 'Meccan' ? 'مكية' : 'مدنية';
}
