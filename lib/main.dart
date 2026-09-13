import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/main_shell.dart';
import 'shared/state/preferences_provider.dart';
import 'theme/theme.dart';

// 저장된 관심 목록을 첫 화면 전에 읽어 둬서, 빈 상태가 잠깐 보였다가 목록으로 바뀌는 깜빡임이 없게 한다.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final SharedPreferences preferences = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: <Override>[preferencesProvider.overrideWithValue(preferences)],
      child: const EdencrewAssignmentApp(),
    ),
  );
}

class EdencrewAssignmentApp extends StatelessWidget {
  const EdencrewAssignmentApp({super.key});

  static const double maxTextScale = 1.3;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '이든크루 평가 과제',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      // 기기 글자 크기 설정은 따르되 1.3배까지만. 헤더 · 기간 탭 · 입력창이 시안 높이로 고정이라
      // 그보다 커지면 글자가 잘리거나 레이아웃이 넘친다.
      builder: (BuildContext context, Widget? child) =>
          MediaQuery.withClampedTextScaling(
            maxScaleFactor: maxTextScale,
            child: child!,
          ),
      home: const MainShell(),
    );
  }
}
