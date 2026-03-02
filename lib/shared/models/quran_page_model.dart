class QuranPageModel {
  final int pageNumber;
  final String surahNameAr;
  final int surahNumber;
  final int juzNumber;
  final List<PageAyahModel> ayahs;

  QuranPageModel({
    required this.pageNumber,
    required this.surahNameAr,
    required this.surahNumber,
    required this.juzNumber,
    required this.ayahs,
  });

  factory QuranPageModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final ayahsList = data['ayahs'] as List? ?? [];

    final ayahs = ayahsList
        .map((e) => PageAyahModel.fromJson(e as Map<String, dynamic>))
        .toList();

    String surahName = '';
    int surahNum = 1;
    if (ayahsList.isNotEmpty) {
      final firstAyah = ayahsList[0] as Map<String, dynamic>;
      final surah = firstAyah['surah'] as Map<String, dynamic>?;
      surahName = surah?['name']?.toString() ?? '';
      surahNum = int.tryParse(surah?['number'].toString() ?? '1') ?? 1;
    }

    return QuranPageModel(
      pageNumber: int.tryParse(data['number'].toString()) ?? 1,
      surahNameAr: surahName,
      surahNumber: surahNum,
      juzNumber: ayahs.isNotEmpty ? ayahs.first.juzNumber : 1,
      ayahs: ayahs,
    );
  }
}

class PageAyahModel {
  final int ayahNumber;
  final String text;
  final int juzNumber;
  final bool sajda;

  PageAyahModel({
    required this.ayahNumber,
    required this.text,
    required this.juzNumber,
    required this.sajda,
  });

  factory PageAyahModel.fromJson(Map<String, dynamic> json) {
    return PageAyahModel(
      ayahNumber: int.tryParse(json['numberInSurah'].toString()) ?? 0,
      text: json['text']?.toString() ?? '',
      juzNumber: int.tryParse(json['juz'].toString()) ?? 1,
      sajda: json['sajda'] != null &&
          json['sajda'] != '0' &&
          json['sajda'] != false,
    );
  }
}
