import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '../../data/dto/daily_price_dto.dart';
import '../../data/dto/realtime_quote_dto.dart';
import '../../data/dto/stock_meta_dto.dart';
import '../../data/repository/daily_price_loader.dart';
import '../../data/repository/stock_repository.dart';
import '../../shared/utils/polling.dart';
import '../../shared/utils/result.dart';
import 'models/candle.dart';
import 'models/chart_period.dart';
import 'models/daily_price_row.dart';
import 'models/stock_detail.dart';

class DetailState {
  const DetailState({
    required this.stock,
    required this.period,
    required this.candles,
    required this.rows,
    this.isPeriodLoading = false,
    this.hasPeriodError = false,
  });

  final StockDetail stock;

  final ChartPeriod period;

  final List<Candle> candles;

  final List<DailyPriceRow> rows;

  final bool isPeriodLoading;
  final bool hasPeriodError;

  DetailState copyWith({
    StockDetail? stock,
    ChartPeriod? period,
    List<Candle>? candles,
    List<DailyPriceRow>? rows,
    bool? isPeriodLoading,
    bool? hasPeriodError,
  }) {
    return DetailState(
      stock: stock ?? this.stock,
      period: period ?? this.period,
      candles: candles ?? this.candles,
      rows: rows ?? this.rows,
      isPeriodLoading: isPeriodLoading ?? this.isPeriodLoading,
      hasPeriodError: hasPeriodError ?? this.hasPeriodError,
    );
  }
}

class DetailViewModel extends AsyncNotifier<DetailState> {
  DetailViewModel(this.symbol);

  final String symbol;

  late StockRepository _repository;
  late DailyPriceLoader _dailyPriceLoader;

  // 현재가 자동 갱신 때 다시 받지 않고 재사용한다(종목명 · 시장은 장중에 바뀌지 않음).
  StockMetaDto? _meta;
  late final Polling _polling = Polling(_refreshQuote);

  @override
  Future<DetailState> build() async {
    _repository = ref.watch(stockRepositoryProvider);
    _dailyPriceLoader = ref.watch(dailyPriceLoaderProvider);
    ref.onDispose(_polling.dispose);
    const ChartPeriod period = ChartPeriod.oneMonth;

    final (
      Result<StockMetaDto> meta,
      Result<RealtimeQuotesDto> quotes,
      Result<List<DailyPriceDto>> daily,
    ) = await (
      _repository.fetchMeta(symbol),
      _repository.fetchQuotes(<String>[symbol]),
      // 들어올 때마다 1페이지는 새로 받아 오늘 행을 갱신한다. 나머지 페이지는 캐시 재사용.
      _dailyPriceLoader.load(symbol, period.tradingDays, refreshLatest: true),
    ).wait;

    // 종목 정보 · 현재가가 없으면 화면을 그릴 수 없어 전체 실패.
    // 일별 시세만 실패하면 헤더 · 요약은 보여주고 차트 자리에 '다시 시도'를 띄운다.
    final List<DailyPriceDto> days = switch (daily) {
      Success<List<DailyPriceDto>>(value: final List<DailyPriceDto> d) => d,
      Failure<List<DailyPriceDto>>() => const <DailyPriceDto>[],
    };
    return switch ((meta, quotes)) {
      (
        Success<StockMetaDto>(value: final StockMetaDto m),
        Success<RealtimeQuotesDto>(value: final RealtimeQuotesDto q),
      )
          when q.quotes[symbol] != null =>
        _start(
          m,
          q,
          DetailState(
            stock: StockDetail.from(m, q.quotes[symbol]!),
            period: period,
            candles: _candles(days),
            rows: _rows(days),
            hasPeriodError: daily is Failure,
          ),
        ),
      (Failure<StockMetaDto>(:final Object error), _) ||
      (_, Failure<RealtimeQuotesDto>(:final Object error)) => throw error,
      _ => throw StateError('no quote: $symbol'),
    };
  }

  Future<void> selectPeriod(ChartPeriod period) async {
    final DetailState? current = state.value;
    if (current == null) return;
    if (current.period == period && !current.hasPeriodError) return;

    state = AsyncData<DetailState>(
      current.copyWith(
        period: period,
        isPeriodLoading: true,
        hasPeriodError: false,
      ),
    );

    final Result<List<DailyPriceDto>> result = await _loadDaily(period);

    if (!ref.mounted) return;
    final DetailState? latest = state.value;
    if (latest == null || latest.period != period) return;

    state = AsyncData<DetailState>(switch (result) {
      Success<List<DailyPriceDto>>(value: final List<DailyPriceDto> daily) =>
        latest.copyWith(
          candles: _candles(daily),
          rows: _rows(daily),
          isPeriodLoading: false,
        ),
      Failure<List<DailyPriceDto>>() => latest.copyWith(
        isPeriodLoading: false,
        hasPeriodError: true,
      ),
    });
  }

  // 상세 화면이 보이는지. 안 보이면 자동 갱신을 멈추고, 다시 보이면 바로 조회한다.
  void setPollingActive(bool active) => _polling.setActive(active);

  DetailState _start(
    StockMetaDto meta,
    RealtimeQuotesDto quotes,
    DetailState state,
  ) {
    _meta = meta;
    _polling.scheduleNext(
      quotes.pollingInterval,
      marketOpen: quotes.isMarketOpen,
    );
    return state;
  }

  // 현재가 · 등락 · 요약 카드만 갱신한다. 실패하면 이전 값을 그대로 두고 다음 주기에 다시 시도한다.
  Future<void> _refreshQuote() async {
    final StockMetaDto? meta = _meta;
    if (meta == null) return;
    final Result<RealtimeQuotesDto> result = await _repository.fetchQuotes(
      <String>[symbol],
    );
    if (!ref.mounted) return;
    switch (result) {
      case Success<RealtimeQuotesDto>(value: final RealtimeQuotesDto dto):
        final RealtimeQuoteDto? quote = dto.quotes[symbol];
        final DetailState? current = state.value;
        if (quote != null && current != null) {
          state = AsyncData<DetailState>(
            current.copyWith(stock: StockDetail.from(meta, quote)),
          );
        }
        _polling.scheduleNext(
          dto.pollingInterval,
          marketOpen: dto.isMarketOpen,
        );
      case Failure<RealtimeQuotesDto>():
        _polling.scheduleNext(
          RealtimeQuotesDto.defaultPollingInterval,
          marketOpen: true,
        );
    }
  }

  Future<Result<List<DailyPriceDto>>> _loadDaily(ChartPeriod period) =>
      _dailyPriceLoader.load(symbol, period.tradingDays);

  static List<Candle> _candles(List<DailyPriceDto> newestFirst) =>
      List<Candle>.unmodifiable(newestFirst.reversed.map(Candle.from));

  static List<DailyPriceRow> _rows(List<DailyPriceDto> newestFirst) =>
      List<DailyPriceRow>.unmodifiable(newestFirst.map(DailyPriceRow.from));
}

final AsyncNotifierProviderFamily<DetailViewModel, DetailState, String>
detailViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<DetailViewModel, DetailState, String>(
      DetailViewModel.new,
      retry: (int retryCount, Object error) => null,
    );
