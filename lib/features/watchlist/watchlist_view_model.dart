import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/dto/realtime_quote_dto.dart';
import '../../data/dto/stock_meta_dto.dart';
import '../../data/repository/stock_repository.dart';
import '../../shared/state/favorites_notifier.dart';
import '../../shared/state/preferences_provider.dart';
import '../../shared/utils/polling.dart';
import '../../shared/utils/result.dart';
import 'models/watchlist_item.dart';
import 'models/watchlist_sort.dart';

@immutable
class WatchlistState {
  const WatchlistState({
    required this.items,
    required this.sort,
    this.reversed = false,
    this.hasError = false,
  });

  final List<WatchlistItem> items;

  final WatchlistSort sort;

  final bool reversed;

  final bool hasError;
}

class WatchlistViewModel extends Notifier<WatchlistState> {
  late StockRepository _repository;

  List<String> _symbols = <String>[];

  final Map<String, StockMetaDto> _metas = <String, StockMetaDto>{};
  final Map<String, RealtimeQuoteDto> _quotes = <String, RealtimeQuoteDto>{};

  WatchlistSort _sort = WatchlistSort.name;
  bool _reversed = false;

  // 메타를 받지 못한 종목과 받는 중인 종목.
  final Set<String> _metaFailures = <String>{};
  final Set<String> _metaInFlight = <String>{};
  bool _quoteFailed = false;

  int _quoteRequestId = 0;

  late final Polling _polling = Polling(_fetchQuotes);

  static const String sortKey = 'watchlistSort';
  static const String reversedKey = 'watchlistSortReversed';

  @override
  WatchlistState build() {
    _repository = ref.watch(stockRepositoryProvider);
    ref.onDispose(_polling.dispose);

    // 마지막으로 고른 정렬 기준과 방향을 불러온다. 저장값이 없거나 모르는 값이면 기본값.
    final SharedPreferences? preferences = ref.read(preferencesProvider);
    _sort =
        WatchlistSort.values.asNameMap()[preferences?.getString(sortKey)] ??
        WatchlistSort.name;
    _reversed = preferences?.getBool(reversedKey) ?? false;

    ref.listen<List<String>>(
      favoritesProvider,
      (List<String>? previous, List<String> next) => _onFavoritesChanged(next),
    );
    _symbols = ref.read(favoritesProvider);

    _load();
    return _buildState();
  }

  Future<void> refresh() => _load();

  // 관심 탭이 보이는지. 안 보이면 자동 갱신을 멈추고, 다시 보이면 바로 조회한다.
  void setPollingActive(bool active) => _polling.setActive(active);

  void changeSort(WatchlistSort sort) {
    _reversed = sort == _sort && !_reversed;
    _sort = sort;
    ref.read(preferencesProvider)
      ?..setString(sortKey, sort.name)
      ..setBool(reversedKey, _reversed);
    _emit();
  }

  void _onFavoritesChanged(List<String> next) {
    final bool added = next.any((String s) => !_symbols.contains(s));
    _symbols = next;
    _quotes.removeWhere((String symbol, _) => !next.contains(symbol));
    _metas.removeWhere((String symbol, _) => !next.contains(symbol));
    _metaFailures.removeWhere((String symbol) => !next.contains(symbol));
    _emit();
    if (added) _load();
  }

  Future<void> _load() async {
    await Future.wait(<Future<void>>[_fetchMissingMetas(), _fetchQuotes()]);
  }

  // 받는 중인 종목은 다시 요청하지 않는다. 별을 연달아 눌러 여러 번 불려도 종목마다 한 번만 받는다.
  Future<void> _fetchMissingMetas() async {
    final List<String> missing = <String>[
      for (final String symbol in _symbols)
        if (!_metas.containsKey(symbol) && !_metaInFlight.contains(symbol))
          symbol,
    ];
    if (missing.isEmpty) return;

    _metaInFlight.addAll(missing);
    final List<Result<StockMetaDto>> results = await Future.wait(
      <Future<Result<StockMetaDto>>>[
        for (final String symbol in missing) _repository.fetchMeta(symbol),
      ],
    );
    _metaInFlight.removeAll(missing);
    if (!ref.mounted) return;

    for (int i = 0; i < missing.length; i++) {
      switch (results[i]) {
        case Success(:final value):
          _metas[missing[i]] = value;
          _metaFailures.remove(missing[i]);
        case Failure():
          _metaFailures.add(missing[i]);
      }
    }
    _emit();
  }

  Future<void> _fetchQuotes() async {
    final int requestId = ++_quoteRequestId;
    final List<String> symbols = _symbols;
    if (symbols.isEmpty) return;

    final Result<RealtimeQuotesDto> result = await _repository.fetchQuotes(
      symbols,
    );
    if (!ref.mounted || requestId != _quoteRequestId) return;

    switch (result) {
      case Success(value: final dto):
        _quotes.addAll(dto.quotes);
        _quoteFailed = false;
        _polling.scheduleNext(
          dto.pollingInterval,
          marketOpen: dto.isMarketOpen,
        );
      case Failure():
        _quoteFailed = true;
        // 실패해도 화면이 보이는 동안은 같은 간격으로 다시 시도한다.
        _polling.scheduleNext(
          RealtimeQuotesDto.defaultPollingInterval,
          marketOpen: true,
        );
    }
    _emit();
  }

  void _emit() => state = _buildState();

  WatchlistState _buildState() {
    return WatchlistState(
      items: List<WatchlistItem>.unmodifiable(
        sortWatchlistItems(
          <WatchlistItem>[
            for (final String symbol in _symbols)
              WatchlistItem.fromDto(
                symbol: symbol,
                meta: _metas[symbol],
                quote: _quotes[symbol],
              ),
          ],
          _sort,
          reversed: _reversed,
        ),
      ),
      sort: _sort,
      reversed: _reversed,
      // 메타 실패는 지금 목록에 남아 있는 종목만 본다. 실패한 종목을 해제하면 배너도 사라진다.
      hasError: _quoteFailed || _symbols.any(_metaFailures.contains),
    );
  }
}

final NotifierProvider<WatchlistViewModel, WatchlistState>
watchlistViewModelProvider =
    NotifierProvider<WatchlistViewModel, WatchlistState>(
      WatchlistViewModel.new,
    );
