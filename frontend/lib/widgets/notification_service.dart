// 06/11 ++ 추가된 페이지 : 리마인더 상단바, 푸쉬알림 and 오토툰 생성중 상단바 알림
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class DateTimeUtil {
  /// 기기 타임존 이름 (main.dart에서 초기화)
  static String timezone = 'Asia/Seoul';

  static void initDeviceTimeZone(String tzName) {
    timezone = tzName;
  }
}

extension DateTimeExtension on DateTime {
  /// DateTime을 현지 TZDateTime으로 변환
  tz.TZDateTime toLocalTZ() {
    final loc = tz.getLocation(DateTimeUtil.timezone);
    return tz.TZDateTime(loc, year, month, day, hour, minute, second);
  }
}

/// NotificationService: 싱글톤으로 구현
class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static const String _dailyChannelId = 'daily_reminder';
  static const String _progressChannelId = 'progress_channel';

  /// 앱 시작 시 한 번만 호출
  Future<void> init() async {
    _initializeTimezone();
    await _initializePlugin();
    await askNotificationPermission();
    await _createAndroidChannels();
  }

  // ───────────── Android 13+ 알림 권한 요청 ────────────
  Future<void> askNotificationPermission() async {
    if (!Platform.isAndroid) return;
    // Android 13(API 33) 이상 기기에서만 POST_NOTIFICATIONS 권한 요청
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      final result = await Permission.notification.request();
      // 사용자가 ‘거부(PermanentlyDenied)’ 했다면
      if (result.isPermanentlyDenied) {
        // 설정으로 유도하거나 토스트로 안내
        debugPrint('알림 권한이 거부되어 있습니다. 설정에서 허용해주세요.');
      }
    }
  }

  Future<void> _initializePlugin() async {
    tz.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestAlertPermission: true,
      requestBadgePermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(initSettings);
  }
  /// Timezone 초기화
  void _initializeTimezone() {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
  }

    // Android 채널 생성 (8.0 이상)
    Future<void> _createAndroidChannels() async {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _dailyChannelId,
          'Daily Reminder Channel',
          description: '매일 사용자에게 보낼 알림 채널',
          importance: Importance.high,
        ),
      );
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _progressChannelId,
          'Progress Updates',
          description: '오토툰 생성 중 상단바 알림 채널',
          importance: Importance.low,
        ),
      );
    }

  /// ────────── 매일 정해진 시각에 알림 예약 ──────────
  ///
  /// [id]     : 알림 고유 ID
  /// [title]  : 알림 제목
  /// [body]   : 알림 내용
  /// [hour]   : 24시간 기준 시
  /// [minute] : 분
  /// [payload]: (선택) 클릭 시 전달할 payload
  Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    // 1) 현지 TZ 기준 현재 시각
    final now = DateTime.now().toLocalTZ();

    // 2) 오늘 hour:minute 시점도 TZ 변환
    var scheduled = DateTime(
        now.year, now.month, now.day, hour, minute
    ).toLocalTZ();

    // 3) 시·분 비교 (초단위 제외)
    if (scheduled.hour < now.hour ||
        (scheduled.hour == now.hour && scheduled.minute <= now.minute)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    print('🔔 [TZ] now=$now, scheduled=$scheduled');

    // 4) 알림 예약 (exact)
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _dailyChannelId,
          'Daily Reminder Channel',
          channelDescription: '매일 알림 채널',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  // 만약 오늘 시각이 이미 지났다면, 내일 같은 시각으로 예약
  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// 예약된 알림 취소
  Future<void> cancelScheduledNotification(int id) =>
      _plugin.cancel(id);

  /// ─────────────────────────────────────────────
  /// 2) “오토툰 생성 중” 상단바 알림 띄우기
  ///
  /// [id]    : 알림 고유 ID
  /// [title] : 알림 제목
  /// [body]  : 알림 내용
  Future<void> showCreationInProgressNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _progressChannelId,
          'Progress Updates',
          channelDescription: '오토툰 진행 알림',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          autoCancel: false,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// 진행 중 알림 취소
  Future<void> cancelCreationInProgressNotification(int id) =>
      _plugin.cancel(id);
}
