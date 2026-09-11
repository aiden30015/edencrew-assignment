import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '../../data/dto/daily_price_dto.dart';
import '../../data/dto/realtime_quote_dto.dart';
import '../../data/dto/stock_meta_dto.dart';
import '../../data/repository/daily_price_loader.dart';
import '../../data/repository/stock_repository.dart';
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
    ChartPeriod? period,
    List<Candle>? candles,
    List<DailyPriceRow>? rows,
    bool? isPeriodLoading,
    bool? hasPeriodError,
  }) {
    return DetailState(
      stock: stock,
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

  @override
  Future<DetailState> build() async {
    _repository = ref.watch(stockRepositoryProvider);
    _dailyPriceLoader = ref.watch(dailyPriceLoaderProvider);
    const ChartPeriod period = ChartPeriod.oneMonth;

    final (
      Result<StockMetaDto> meta,
      Result<Map<String, RealtimeQuoteDto>> quotes,
      Result<List<DailyPriceDto>> daily,
    ) = await (
      _repository.fetchMeta(symbol),
      _repository.fetchQuotes(<String>[symbol]),
      _loadDaily(period),
    ).wait;

    // 종목 정보 · 현재가가 없으면 화면을 그릴 수 없어 전체 실패.
    // 일별 시세만 실패하면 헤더 · 요약은 보여주고 차트 자리에 '다시 시도'를 띄운다.
    final List<DailyPriceDto> days = switch (daily) {
      Success(value: final d) => d,
      Failure() => const <DailyPriceDto>[],
    };
    return switch ((meta, quotes)) {
      (Success(value: final m), Success(value: final q))
          when q[symbol] != null =>
        DetailState(
          stock: StockDetail.from(m, q[symbol]!),
          period: period,
          candles: _candles(days),
          rows: _rows(days),
          hasPeriodError: daily is Failure,
        ),
      (Failure(:final error), _) || (_, Failure(:final error)) => throw error,
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
      Success(value: final daily) => latest.copyWith(
        candles: _candles(daily),
        rows: _rows(daily),
        isPeriodLoading: false,
      ),
      Failure() => latest.copyWith(
        isPeriodLoading: false,
        hasPeriodError: true,
      ),
    });
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
