import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/home_pill_banner.dart';
import '../widgets/modal.dart'; // AttendanceModal import
///──────────────────────────────────────────
// 리워드 관련해서는 여기에 다 넣어놓겠습니다.
///──────────────────────────────────────────
class AttendanceHelper {
  /// SharedPreferences에 저장된 출석 데이터를 불러와서,
  /// 1) 처음 로그인 시 환영 모달 띄우고 300 크레딧 적립
  /// 2) 오늘 처음 접속 시 AttendanceModal
  /// 3) 오늘 이미 출석했으면 PillBanner
  static Future<void> checkAttendance(BuildContext context) async {
    print('출첵 디버그 시작: ${DateTime.now()}');
    final prefs = await SharedPreferences.getInstance();
    print('출첵 인스턴스 획득');

    // ── 1) “첫 로그인” 여부 검사 ──
    // hasSeenWelcome 키가 없으면(=처음 로그인) 환영 모달 띄우고 300 크레딧 지급
    final hasSeenWelcome = prefs.getBool('hasSeenWelcome') ?? false;
    if (!hasSeenWelcome) {
      // 1-1) SharedPreferences에 표시해 두기
      await prefs.setBool('hasSeenWelcome', true);

      // 1-2) 첫 로그인 시 사용자 크레딧을 300으로 세팅
      //     → 이미 어떤 초기값이 들어가 있다면 그대로 두거나, 강제로 300으로 덮어쓰세요.
      //     아래는 “기존 크레딧이 있더라도 300으로 설정”하는 예시입니다.
      await prefs.setInt('userCredit', 300);

      // 1-3) 환영 모달 띄우기
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const WelcomeModal(),
      );
      // → 여기서 사용자가 “확인했어요”를 누를 때까지 대기했다가 다음 로직으로 넘어갑니다.
    }

    // ── 2) 기존 출석 체크 로직 ──

    // 오늘 날짜 키 (yyyy-MM-dd 형식)
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // SharedPreferences에서 마지막 출석 날짜, 연속 출석일, 총 누적 일수 가져오기
    final lastDateKey = prefs.getString('lastAttendanceDate');
    int streak = prefs.getInt('attendanceStreak') ?? 0;
    int totalDays = prefs.getInt('attendanceTotalDays') ?? 0;

    if (lastDateKey != todayKey) {
      // "어제" 날짜 키
      final yesterdayKey = DateFormat('yyyy-MM-dd')
          .format(DateTime.now().subtract(const Duration(days: 1)));

      // 어제 출석했으면 연속 출석 카운트 +1, 아니면 1로 리셋
      if (lastDateKey == yesterdayKey) {
        streak += 1;
      } else {
        streak = 1;
      }

      // 총 누적 출석 일수 증가
      totalDays += 1;

      // 오늘의 보상 크레딧 계산
      int reward = 10;
      if (streak == 5) {
        reward = 30;
      } else if (streak == 15) {
        reward = 60;
      } else if (streak == 30) {
        reward = 90;
      }

      // SharedPreferences에 업데이트
      await prefs.setString('lastAttendanceDate', todayKey);
      await prefs.setInt('attendanceStreak', streak);
      await prefs.setInt('attendanceTotalDays', totalDays);

      // 사용자 크레딧에 보상 크레딧 추가
      final currentCredit = prefs.getInt('userCredit') ?? 0;
      await prefs.setInt('userCredit', currentCredit + reward);

      // 모달 띄우기
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AttendanceModal(
          totalDays: totalDays,
          reward: reward,
        ),
      );
    } else {
      // SharedPreferences에 이미 저장된 streak 값 가져오기
      final currentStreak = streak;
      print('출첵: 오늘 이미 출석함. 현재 연속 방문 $currentStreak 일차');

      // 아래 _showTopBanner 코드를 그대로 호출
      _showTopBanner(context, '연속 방문 ${currentStreak}일차');
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
