class ReciterModel {
  final String reciterId;
  final String reciterName;
  final String reciterShortName;

  ReciterModel({
    required this.reciterId,
    required this.reciterName,
    required this.reciterShortName,
  });

  factory ReciterModel.fromJson(Map<String, dynamic> json) {
    return ReciterModel(
      reciterId: json['reciter_id']?.toString() ?? '',
      reciterName: json['reciter_name']?.toString() ?? '',
      reciterShortName: json['reciter_short_name']?.toString() ?? '',
    );
  }
}

class ReciterAudioModel {
  final String surahId;
  final String surahNameAr;
  final String audioUrl;

  ReciterAudioModel({
    required this.surahId,
    required this.surahNameAr,
    required this.audioUrl,
  });

  factory ReciterAudioModel.fromJson(Map<String, dynamic> json) {
    return ReciterAudioModel(
      surahId: json['surah_id']?.toString() ?? '',
      surahNameAr: json['surah_name_ar']?.toString() ?? '',
      audioUrl: json['audio_url']?.toString() ?? '',
    );
  }
}
