import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'shared/state/preferences_provider.dart';

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
