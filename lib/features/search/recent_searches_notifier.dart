import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/state/preferences_provider.dart';

// 최근 검색어. 최신이 앞이고 최대 5개, 같은 검색어는 맨 앞으로 올린다.
// 입력 중인 글자('삼', '삼성')가 쌓이지 않도록 검색 결과를 눌렀을 때만 기록한다.
class RecentSearchesNotifier extends Notifier<List<String>> {
  static const String storageKey = 'recent_searches';
  static const int maxCount = 5;

  @override
  List<String> build() {
    final List<String>? saved = ref
        .watch(preferencesProvider)
        ?.getStringList(storageKey);
    return List<String>.unmodifiable(saved ?? const <String>[]);
  }

  void add(String query) {
    final String q = query.trim();
    if (q.isEmpty) return;
    _save(<String>[q, ...state.where((String s) => s != q)].take(maxCount));
  }

  void remove(String query) => _save(state.where((String s) => s != query));

  void _save(Iterable<String> next) {
    state = List<String>.unmodifiable(next);
    ref.read(preferencesProvider)?.setStringList(storageKey, state);
  }
}

final NotifierProvider<RecentSearchesNotifier, List<String>>
recentSearchesProvider = NotifierProvider<RecentSearchesNotifier, List<String>>(
  RecentSearchesNotifier.new,
);
