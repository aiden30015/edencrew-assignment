import 'package:flutter_riverpod/flutter_riverpod.dart';

class FavoritesNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    return const <String>['005930', '000660', '035720', '247540', '373220'];
  }

  bool isFavorite(String symbol) => state.contains(symbol);

  bool toggle(String symbol) {
    final bool added = !state.contains(symbol);
    state = List<String>.unmodifiable(<String>[
      for (final String s in state)
        if (s != symbol) s,
      if (added) symbol,
    ]);
    return added;
  }
}

final NotifierProvider<FavoritesNotifier, List<String>> favoritesProvider =
    NotifierProvider<FavoritesNotifier, List<String>>(FavoritesNotifier.new);
