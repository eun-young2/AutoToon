import 'dart:async';

import 'package:dx_project_dev2/screens/history_page.dart';
import 'package:dx_project_dev2/widgets/StatusBar_Reminder.dart';  // 06/11 ++ 추가
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:app_links/app_links.dart';

import 'package:dx_project_dev2/screens/member_info_page.dart';
import 'package:dx_project_dev2/screens/calendar_page.dart';
import 'package:dx_project_dev2/screens/detail_page.dart';
import 'package:dx_project_dev2/screens/intro_page.dart';
import 'package:dx_project_dev2/screens/login_page.dart';
import 'package:dx_project_dev2/screens/home_page.dart';
import 'package:dx_project_dev2/screens/signup_page.dart';
import 'package:dx_project_dev2/screens/write_page.dart';

import 'package:dx_project_dev2/theme/app_theme.dart';
import 'package:dx_project_dev2/widgets/bottom_nav.dart';

import 'package:timezone/data/latest_all.dart' as tz;  // 06/11 ++ 추가
import 'package:timezone/timezone.dart' as tz;   // 06/11 ++ 추가

import 'package:dx_project_dev2/widgets/notification_service.dart';   // 06/11 ++ 추가
import 'package:workmanager/workmanager.dart';    // 06/11 ++ 추가

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'kakao_login_page.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 테스트용: 앱 실행될 때 한 번만 SharedPreferences 초기화
  // final prefs = await SharedPreferences.getInstance();
  // await prefs.remove('lastDiaryCreditDate');
  // await prefs.remove('userCredit');

  // .env 파일을 비동기로 로드 (여기서 환경변수들이 메모리에 올라감)
  await dotenv.load();

  // PathUrlStrategy 적용 (해시 없는 라우팅, 로그인 후 화면 정상 이동)
  usePathUrlStrategy();

  // 카카오 SDK 초기화 (앱/웹 모두 지원)
  // - 네이티브 앱 키: Android/iOS에서 사용
  // - 자바스크립트 앱 키: 웹(Flutter Web)에서 사용
  // - 두 키를 모두 전달하면 플랫폼에 맞게 자동 적용됨
  KakaoSdk.init(
    nativeAppKey: dotenv.env['KAKAO_NATIVE_APP_KEY'],
    javaScriptAppKey: dotenv.env['KAKAO_JAVASCRIPT_APP_KEY'],
  );

    // ──────────────────── 06/11 추가 ────────────────────────────
  // 알림 하기 위한 로직
  // ─────────── Timezone DB 로드 ───────────
  tz.initializeTimeZones();

  // ─────────── 시스템 타임존 찾기 ───────────
  final now = DateTime.now();
  final offsetMs = now.timeZoneOffset.inMilliseconds;
  String? foundKey;
  tz.timeZoneDatabase.locations.forEach((key, loc) {
    if (loc.currentTimeZone.offset == offsetMs && foundKey == null) {
      foundKey = key;
    }
  });
  final deviceTz = tz.getLocation(foundKey ?? 'Asia/Seoul');
  tz.setLocalLocation(deviceTz);

  // ─────────── Notification 초기화 ───────────
  await NotificationService().init();

  // ─────────── Workmanager ───────────
  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false, // debug 모드에서는 true로 바꿔 로깅 확인 가능
  );

  // 앱 시작 직후 현재 시각 찍기
  print('현재 시각: ${DateTime.now().toIso8601String()}');
  // ──────────────────────────────────────────────────────

  final themeNotifier = ThemeNotifier();
  // 앱 시작 전에 미리 팔레트 계산
  themeNotifier.initSentimentPalette();

  runApp(
    ChangeNotifierProvider<ThemeNotifier>.value(
      value: themeNotifier,
      child: const DxApp(),
    ),
  );
}

class DxApp extends StatefulWidget {
  const DxApp({super.key});

  @override
  State<DxApp> createState() => _DxAppState();
}

class _DxAppState extends State<DxApp> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri?>? _uriSub;

  @override
  void initState() {
    super.initState();

    // 앱 실행(콜드 스타트)이든 백그라운드든 항상 uriLinkStream의 첫 이벤트가
    // “앱을 연 링크”를 포함합니다. 별도의 초기 링크 메서드 없이, 여기에 구독만 걸면 됩니다.
    _uriSub = _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _parseAndSaveUserId(uri);
      }
    }, onError: (err) {
      // 필요시 오류 처리
    });
  }

  @override
  void dispose() {
    _uriSub?.cancel();
    super.dispose();
  }

  /// ─── 받은 Uri에서 userId 파라미터를 파싱하여 SharedPreferences에 저장
  Future<void> _parseAndSaveUserId(Uri uri) async {
    // 예: autotoon://login-success?userId=4284707752&nickname=Faker&token=abcd
    final receivedUserId = uri.queryParameters['userId'];
    if (receivedUserId != null && receivedUserId.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', receivedUserId);
      print("저장된 userId: $receivedUserId");
    }
    // nickname, token 등 추가 파라미터가 필요하다면 동일하게 저장
    // final receivedNick = uri.queryParameters['nickname'];
    // final receivedToken = uri.queryParameters['token'];
  }

  @override
  Widget build(BuildContext context) {
    // Provider 로부터 현재 테마 모드 읽기
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DX Project App',

      // 라이트/다크 테마 설정
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.paperTheme,

      // 실제로 사용할 모드 선택
      themeMode: themeNotifier.isPaperMode ? ThemeMode.dark : ThemeMode.light,

      // 최초 진입 라우트
      initialRoute: '/intro',

      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),

        // ─────────────────── 탭으로 진입하는 경로들 ───────────────────
        // '/main'로 들어오면 “홈 탭”이 활성화 된 MainWithTabs
        '/main': (context) => const MainWithTabs(initialIndex: 0),

        // '/calendar'로 들어오면 “캘린더 탭”이 활성화 된 MainWithTabs
        '/calendar': (context) => const MainWithTabs(initialIndex: 1),

        // '/write'를 탭 2(글쓰기 탭)로 재사용하고 싶다면
        '/writeTab': (context) => const MainWithTabs(initialIndex: 2),

        // '/history'로 들어오면 “히스토리 탭”이 활성화 된 MainWithTabs
        '/history': (context) => const MainWithTabs(initialIndex: 3),

        // '/member'로 들어오면 “멤버 탭”이 활성화 된 MainWithTabs
        '/member': (context) => const MainWithTabs(initialIndex: 4),

        // ─────────────────── 탭 외부로 띄우는 경로들 ───────────────────
        '/intro': (context) => const IntroPage(),
        '/detail': (context) => const DetailPage(),

        // 혹시 탭 외부에서 직접 WritePage를 띄우고 싶으면
        '/write': (context) => const WritePage(),
      },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
      ],
      locale: const Locale('ko', 'KR'),
    );
  }
}

/// ─────────────────────────────────────────────
/// /main 루트에서 보여줄 탭 구조
class MainWithTabs extends StatelessWidget {
  final int initialIndex;
  const MainWithTabs({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5, // 탭 개수 (홈, 일정, 게시, 좋아요, 프로필)
      initialIndex: initialIndex, // 시작탭
      child: const Scaffold(
        body: const TabBarView(
          physics: BouncingScrollPhysics(),
          children: [
            MainPage(), // index = 0
            CalendarPage(), // index = 1
            WritePage(), // index = 2
            HistoryPage(), // index = 3
            MemberInfoPage(), // index = 4
          ],
        ),
        bottomNavigationBar: BottomNav(),
      ),
    );
  }
}

/// ─────────────────────────────────────────────
