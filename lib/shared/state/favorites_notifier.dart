import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'preferences_provider.dart';

// 관심 종목코드 목록. 등록한 순서대로 두고, 바뀔 때마다 기기에 저장한다.
class FavoritesNotifier extends Notifier<List<String>> {
  static const String storageKey = 'favorites';

  @override
  List<String> build() {
    final List<String>? saved = ref
        .watch(preferencesProvider)
        ?.getStringList(storageKey);
    return List<String>.unmodifiable(saved ?? const <String>[]);
  }

  bool isFavorite(String symbol) => state.contains(symbol);

  bool toggle(String symbol) {
    final bool added = !state.contains(symbol);
    state = List<String>.unmodifiable(<String>[
      for (final String s in state)
        if (s != symbol) s,
      if (added) symbol,
    ]);
    ref.read(preferencesProvider)?.setStringList(storageKey, state);
    return added;
  }
}

final NotifierProvider<FavoritesNotifier, List<String>> favoritesProvider =
    NotifierProvider<FavoritesNotifier, List<String>>(FavoritesNotifier.new);
