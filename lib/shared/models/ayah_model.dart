class AyahModel {
  final int id;
  final int surahId;
  final int ayahNumber;
  final String text;
  final int juzNumber;
  final int hizbNumber;
  final bool sajda;

  AyahModel({
    required this.id,
    required this.surahId,
    required this.ayahNumber,
    required this.text,
    required this.juzNumber,
    required this.hizbNumber,
    required this.sajda,
  });

  factory AyahModel.fromJson(Map<String, dynamic> json) {
    return AyahModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      surahId: int.tryParse(json['surah_id'].toString()) ?? 0,
      ayahNumber: int.tryParse(json['ayah_number'].toString()) ?? 0,
      text: json['text']?.toString() ?? '',
      juzNumber: int.tryParse(json['juz_number'].toString()) ?? 0,
      hizbNumber: int.tryParse(json['hizb_number'].toString()) ?? 0,
      sajda: json['sajda'] == true || json['sajda'] == 'true',
    );
  }
}
