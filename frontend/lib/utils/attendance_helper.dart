import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/home_pill_banner.dart';
import '../widgets/modal.dart'; // AttendanceModal import
import 'package:http/http.dart' as http;
import 'dart:convert';

///──────────────────────────────────────────
// 리워드 관련해서는 여기에 다 넣어놓겠습니다.
///──────────────────────────────────────────
class AttendanceHelper {
  /// SharedPreferences에 저장된 출석 데이터를 불러와서,
  /// 1) 처음 로그인 시 환영 모달 띄우고 300 크레딧 적립
  /// 2) 오늘 처음 접속 시 AttendanceModal
  /// 3) 오늘 이미 출석했으면 PillBanner
  static const String _baseUrl = "http://211.188.62.213:8000";
  static Future<void> checkAttendance(
    BuildContext context,
    String userId, // 로그인 완료 후 로컬 또는 Provider 등에 저장해둔 userId를 넘겨주세요
  ) async {
    try {
      // 1) FastAPI 서버의 /attendance/check/{userId} 엔드포인트에 POST 요청을 보냅니다.
      final uri = Uri.parse("$_baseUrl/attendance/check/$userId");
      final response = await http.post(uri);

      if (response.statusCode != 200) {
        // 500, 404 등 오류가 날 경우 예외 처리
        debugPrint("출석 체크 API 오류: ${response.statusCode} / ${response.body}");
        // 사용자에게 간단히 토스트나 다이얼로그를 띄우고 싶으면 여기에 추가하세요.
        return;
      }

      // 2) 서버로부터 받은 JSON을 파싱합니다.
      final Map<String, dynamic> data = json.decode(response.body);

      // 서버 응답 예시:
      // {
      //   "is_new_attendance": true,
      //   "streak": 3,
      //   "reward": 10,
      //   "total_days": 7,
      //   "current_credit": 415
      // }
      final bool isNew = data["is_new_attendance"] as bool;
      final int streak = data["streak"] as int;
      final int reward = data["reward"] as int;
      final int totalDays = data["total_days"] as int;
      final int currentCredit = data["current_credit"] as int;

      // 3) 서버에서 “처음 출석”이라고 내려오면 모달을 띄우고
      if (isNew) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AttendanceModal(
            totalDays: totalDays,
            reward: reward,
          ),
        );
      } else {
        // 4) 이미 오늘 출석했으면 배너를 띄웁니다.
        _showTopBanner(context, "연속 방문 ${streak}일차");
      }

      // 5) 마이페이지 등에서 보여줄 크레딧(currentCredit)은 서버 응답을 그대로 사용하세요.
      //    예를 들어 Provider나 setState 등을 통해 화면 상단에 크레딧을 갱신해 줄 수 있습니다.
      debugPrint("서버에서 갱신된 크레딧: $currentCredit");
    } catch (e) {
      // 네트워크 에러 또는 파싱 에러 등 예외 처리
      debugPrint("출석 체크 중 에러 발생: $e");
      // 원한다면 사용자에게 에러 다이얼로그나 SnackBar를 띄워줄 수 있습니다.
    }
  }

  /// 상단에서 슬라이드-다운하여 2초간 머물렀다가 사라지는 배너를 보여주는 함수
  static void _showTopBanner(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return PillBanner(message: message);
      },
    );

    // 배너 띄우기
    overlay.insert(entry);

    // 2초 뒤 자동으로 지우기
    Future.delayed(const Duration(seconds: 2), () {
      entry.remove();
    });
  }
}
