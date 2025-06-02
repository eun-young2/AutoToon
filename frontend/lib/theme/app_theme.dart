import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import '../utils/constants.dart';

class AppTheme {
// 필요에 따라 추가로 정의 가능
// static const Color background = Color(0xFFE9CFCF);
// static const Color textPrimary = Color(0xFF5B3B3B);
  /// 메인 포인트 컬러
  static const Color primary = Color(0xFFC4455C);

  /// 모든 페이지의 배경색
  static const Color background = Colors.white;

  /// ─────────────────────────────────────────────
  // 라이트 모드
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light, // → 라이트 모드
    primaryColor: const Color(0xFFF6A7C6), // 버튼 등 액센트 색
    scaffoldBackgroundColor: Colors.white,// 화면 배경
    fontFamily: '온글잎 혜련',
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      foregroundColor: Colors.black,
      scrolledUnderElevation: 0,    // 스크롤 시에도 그림자 안 생기게
    ),
    textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.black)),
  );

  /// ─────────────────────────────────────────────
  // 페이퍼 모드
  static final ThemeData paperTheme = ThemeData(
    brightness: Brightness.light,                      // → 라이트 모드 기반
    primaryColor: Colors.grey.shade700,                // 버튼 등 액센트 색
    scaffoldBackgroundColor: const Color(0xFFF3F3F3),  // 화면 배경
    canvasColor: const Color(0xFFF3F3F3),              // Drawer, BottomSheet 등
    cardColor: const Color(0xFFF3F3F3),                // Card 위젯 배경
    dividerColor: Colors.grey.shade400,                       // 구분선 색상
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFFF3F3F3),                     // BottomSheet 배경
    ),
    fontFamily: '온글잎 혜련',
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFFF3F3F3),        // → AppBar 배경
      foregroundColor: Colors.grey.shade800,        // → 버튼·타이틀 색상
      elevation: 0,                                  // → 약간의 그림자
      scrolledUnderElevation: 0,    // 스크롤 시에도 그림자 안 생기게
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.grey.shade900),
      bodyMedium: TextStyle(color: Colors.grey.shade900),
      bodySmall: TextStyle(color: Colors.grey.shade900),
    ),
  );
}
/// ─────────────────────────────────────────────
class ThemeNotifier extends ChangeNotifier {
  bool _isPaperMode = false;
  String _characterTheme = 'default'; // 'default', 'cat', 'dog' 등

  // ▶ 여기 추가: 감정 패널용 색상 리스트
  final List<Color> sentimentColors =
  List<Color>.filled(kSentimentStampAssets.length, Colors.grey.shade300);

  bool get isPaperMode => _isPaperMode;
  String get characterTheme => _characterTheme;
  List<Color> get palette  => sentimentColors;

  void togglePaperMode() {
    _isPaperMode = !_isPaperMode;
    notifyListeners();
  }

  void setCharacterTheme(String theme) {
    _characterTheme = theme;
    notifyListeners();
  }
  /// ──────────── 사전 팔레트 생성 ────────────
  Future<void> initSentimentPalette() async {
    for (var i = 0; i < kSentimentStampAssets.length; i++) {
      final gen = await PaletteGenerator.fromImageProvider(
        AssetImage(kSentimentStampAssets[i]),
        size: const Size(200,200), // 이미지 크키 조절(픽셀조절)
      );
      sentimentColors[i] = gen.dominantColor?.color ?? Colors.grey.shade300;
    }
    notifyListeners();
  }
/// ─────────────────────────────────────────────
}
