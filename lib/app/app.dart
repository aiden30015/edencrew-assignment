import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'main_shell.dart';

// 앱 조립: 테마, 글자 크기 제한, 첫 화면(하단 탭 셸).
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
