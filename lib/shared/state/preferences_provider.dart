import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 기기 저장소. 앱 시작 시 main에서 불러와 override한다.
// 테스트처럼 override가 없으면 null이라 저장하지 않고 메모리에만 둔다.
final Provider<SharedPreferences?> preferencesProvider =
    Provider<SharedPreferences?>((Ref ref) => null);
