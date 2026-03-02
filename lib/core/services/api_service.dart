import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  Future<dynamic> get(String url, {Map<String, dynamic>? params}) async {
    try {
      final response = await _dio.get(url, queryParameters: params);
      return response.data;
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    } catch (e) {
      throw Exception('خطأ غير متوقع: $e');
    }
  }

  Future<dynamic> getSurahs() async => await get(ApiConstants.surahs);
  Future<dynamic> getAyahs(int surahNumber) async =>
      await get(ApiConstants.ayahs, params: {'number': surahNumber});
  Future<dynamic> getQuranPageText(int pageNumber) async =>
      await get(ApiConstants.quranPagesText, params: {'page': pageNumber});
  Future<dynamic> getAzkar() async => await get(ApiConstants.azkar);
  Future<dynamic> getDuas() async => await get(ApiConstants.duas);
  Future<dynamic> getPrayerTimes() async => await get(ApiConstants.prayerTimes);
  Future<dynamic> getReciters() async => await get(ApiConstants.reciters);
  Future<dynamic> getReciterAudio(String reciterId) async =>
      await get(ApiConstants.reciterAudio, params: {'reciter_id': reciterId});

  String _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'انتهت مهلة الاتصال';
      case DioExceptionType.receiveTimeout:
        return 'انتهت مهلة الاستجابة';
      case DioExceptionType.connectionError:
        return 'لا يوجد اتصال بالإنترنت';
      default:
        return 'خطأ: ${e.message}';
    }
  }
}
