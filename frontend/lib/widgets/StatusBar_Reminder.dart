// 06/11 ++ 추가된 페이지
// 원래 alert_dialogs에 들어가도 되는데 여기로 따로 분리했습니다.
// 리마인더 설정하는 다이얼로그 and 오토툰 상단바 콜백 코드 총2가지 로직이 들어있습니다.
// 리마인더 설정하는 다이얼로그 위치 : 내정보 페이지 -> 톱니바퀴 -> 리마인더에서 '>' 버튼 누르면 뜨는 다이얼로그
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:dx_project_dev2/widgets/notification_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// 별도 분리된 리마인더 다이얼로그
Future<void> showNotificationSettingsDialog(
    BuildContext context,
    bool initialEnabled,
    TimeOfDay initialTime,
    VoidCallback onUpdate,
    ) async {
  final prefs = await SharedPreferences.getInstance();
  bool notifEnabled = initialEnabled;
  TimeOfDay notifTime = initialTime;

  await showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (dCtx, dSet) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF5F5F5),
          title: const Text('리마인더 설정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1) 알림 온/오프 토글
              SwitchListTile(
                title: const Text('매일 리마인더'),
                value: notifEnabled,
                onChanged: (v) => dSet(() => notifEnabled = v),
              ),
              const SizedBox(height: 8),
              // 2) 시간 선택 (끄면 비활성화)
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('리마인더 시간'),
                subtitle: Text(notifTime.format(context)),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: notifEnabled
                      ? () async {
                    final picked = await showTimePicker(
                      context: dCtx,
                      initialTime: notifTime,
                    );
                    if (picked != null) dSet(() => notifTime = picked);
                  }
                      : null,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: const Text('취소',
                style: TextStyle(
                  color: Colors.black87,),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD6C7A6),
                // 기존 배경색 유지
                foregroundColor: Colors.black, // 텍스트 색상을 검정으로
              ),
              onPressed: () async {
                // 3) SharedPreferences에 설정 저장
                await prefs.setBool('dailyNotifEnabled', notifEnabled);
                await prefs.setInt('dailyNotifHour', notifTime.hour);
                await prefs.setInt('dailyNotifMinute', notifTime.minute);

                // 4) 알림 예약 또는 해제
                if (notifEnabled) {
                  // 1) 알림 채널 보장
                  await NotificationService().scheduleDailyReminder(
                    id: 200,
                    title: '오늘 하루는 어땠나요?',
                    body: '오늘 하루 일기를 작성해 보세요.',
                    hour: notifTime.hour,
                    minute: notifTime.minute,
                    payload: 'daily_reminder_payload',
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('매일 리마인더가 설정되었습니다.')),
                  );
                } else {
                  await NotificationService().cancelScheduledNotification(200);
                }

                Navigator.pop(dCtx);
                // 5) 상위 위젯 갱신 콜백
                onUpdate();
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    ),
  );
}

/// 백그라운드에서 실행될 콜백
@pragma('vm:entry-point')
void callbackDispatcher() {
  // ◆ 반드시 가장 먼저 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // ◆ 알림 채널(Provider) 재초기화
  NotificationService().init();

  Workmanager().executeTask((task, inputData) async {
    // 타임존 보장
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    // 작업 시작 알림
    await NotificationService().showCreationInProgressNotification(
      id: 999,
      title: '오토툰 생성 중…',
      body: '잠시만 기다려주세요.',
    );

    // (여기에 실제 서버 호출 등 로직을 넣으세요)
    await Future.delayed(const Duration(seconds: 20));

    // 작업 완료 알림 취소
    await NotificationService().cancelCreationInProgressNotification(999);

    return Future.value(true);
  });
}