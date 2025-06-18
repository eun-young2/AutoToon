import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:eventsource/eventsource.dart';
import '../models/diary_model.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  //static const _base = String.fromEnvironment('API_BASE_URL');
  static final _base = dotenv.env['API_BASE_URL']!;
  static final _baseImage = _base;

  static String fullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$_baseImage$path';

  }

  /// 1) 신규 일기 저장 (POST /diaries/)
  static Future<Diary> createDiary({
    required String userId,
    required int styleId,
    required String diaryDate,
    required String content,
  }) async {
    final uri = Uri.parse('$_base/diaries/');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id':    userId,
        'style_id':   styleId,
        'diary_date': diaryDate,
        'content':    content,
      }),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return Diary.fromJson(jsonDecode(res.body));
    }
    throw Exception('createDiary failed: ${res.statusCode}');
  }

  /// 2) 기존 일기 수정 (PATCH /diaries/{diaryNum})
  static Future<Diary> updateDiary({
    required int diaryNum,
    required int styleId,
    required String content,
  }) async {
    final uri = Uri.parse('$_base/diaries/$diaryNum');
    final res = await http.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'style_id': styleId,
        'content':  content,
      }),
    );
    if (res.statusCode == 200) {
      return Diary.fromJson(jsonDecode(res.body));
    }
    throw Exception('updateDiary failed: ${res.statusCode}');
  }

  /// 3) SSE 스트림 구독 (POST /diaries/stream)
  static Future<EventSource> createDiaryWithStream({
    required String userId,
    required int styleId,
    required String diaryDate,
    required String content,
  }) {
    final uri = Uri.parse('$_base/diaries/stream');
    return EventSource.connect(
      uri.toString(),
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id':    userId,
        'style_id':   styleId,
        'diary_date': diaryDate,
        'content':    content,
      }),
    );
  }

  /// 4) 수정용 SSE 구독 (PATCH /diaries/{diaryNum}/stream)
  static Future<EventSource> updateDiaryWithStream({
    required int diaryNum,
    required int styleId,
    required String diaryDate,
    required String content,
  }) {
    final uri = Uri.parse('$_base/diaries/$diaryNum/stream');
    return EventSource.connect(
      uri.toString(),
      method: 'PATCH',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'style_id':   styleId,
        'diary_date': diaryDate,
        'content':    content,
      }),
    );
  }


  /// (추가) 특정 일기 조회
  static Future<Diary> readDiary(int diaryNum) async {
    final uri = Uri.parse('$_base/diaries/$diaryNum');
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      return Diary.fromJson(jsonDecode(res.body));
    }
    throw Exception('readDiary failed: ${res.statusCode}');
  }

  /// 오늘(또는 원하는 날짜) 일기 목록 가져오기
  static Future<List<Diary>> fetchDiariesForDate(
      int userId, DateTime date) async {
    final today = DateFormat('yyyy-MM-dd').format(date);
    final url = Uri.parse('$_base/diaries/user/$userId?date=$today');

    final res = await http.get(url);
    if (res.statusCode != 200) {
      throw Exception('일기 조회 실패: ${res.statusCode} ${res.body}');
    }
    final list = (jsonDecode(res.body) as List)
        .map((e) => Diary.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }

  /// 특정 사용자의 모든 일기(최신순) 가져오기
  static Future<List<Diary>> fetchUserDiaries(int userId,
      {int skip = 0, int limit = 100}) async {
    final uri = Uri.parse('$_base/diaries/user/$userId?skip=$skip&limit=$limit');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('user diaries 실패: ${res.statusCode} ${res.body}');
    }
    return (jsonDecode(res.body) as List)
        .map((e) => Diary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 5) 일기 삭제 (DELETE /diaries/{diary_id})
  static Future<void> deleteDiary(int diaryNum) async {
    final uri = Uri.parse('$_base/diaries/$diaryNum');
    final res = await http.delete(uri);
    if (res.statusCode != 200) {
      throw Exception('deleteDiary failed: ${res.statusCode}');
    }
  }

  /// 6) 월별 작성된 날짜 목록 조회
  static Future<List<DateTime>> fetchMonthlyDates({
    required int userId,
    required int year,
    required int month,
  }) async {
    final uri = Uri.parse('$_base/diaries/$userId/dates/$year/$month');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('fetchMonthlyDates failed: ${res.statusCode}');
    }
    // server returns `{"dates": ["2025-06-01", "2025-06-05", …]}`
    final data = jsonDecode(res.body) as Map<String,dynamic>;
    return (data['dates'] as List)
        .map((s) => DateTime.parse(s as String))
        .toList();
  }

  /// 7) 월별 감정 통계 조회 (optional)
  static Future<Map<String, dynamic>> fetchMonthlyStats({
    required int userId,
    required int year,
    required int month,
  }) async {
    final uri = Uri.parse('$_base/diaries/$userId/stats/$year/$month');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('fetchMonthlyStats failed: ${res.statusCode}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // 질문 램덤 1개 가져오기
  static Future<String> getRandomQuestion({required String userId}) async {
    // userId는 안 쓰지만, 나중에 커스터마이징 원하면 쓸 수 있음
    final url = Uri.parse('$_base/questions/random-one');
    final res = await http.get(url);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      // API 응답: { "question_num": 1, "question": "오늘 가장 행복했던 순간은?", ... }
      return data['question'];
    } else {
      throw Exception('질문을 불러오지 못했습니다');
    }
  }
  // 질문 커스터마이즈 (POST)
  static Future<String> getCustomizedQuestion({required String userId}) async {
    final url = Uri.parse('$_base/tagging/generate-question');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId}),
    );

    if (res.statusCode == 200) {
      // 한글 깨짐 방지: bodyBytes로 받아서 utf8로 디코딩
      final decoded = utf8.decode(res.bodyBytes);
      final data = jsonDecode(decoded);
      return data['customized_question'];
    } else {
      // 실패시, 에러 메시지
      throw Exception('질문을 불러오지 못했습니다: ${res.body}');
    }
  }
}
