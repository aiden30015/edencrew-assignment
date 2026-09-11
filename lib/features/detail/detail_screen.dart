import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/state/favorites_notifier.dart';
import '../../shared/widgets/retry_view.dart';
import '../../shared/widgets/visibility_listener.dart';
import '../../theme/theme.dart';
import 'detail_view_model.dart';
import 'models/chart_period.dart';
import 'models/daily_price_row.dart';
import 'widgets/candle_chart.dart';
import 'widgets/daily_price_table.dart';
import 'widgets/detail_app_bar.dart';
import 'widgets/detail_skeleton.dart';
import 'widgets/price_header.dart';
import 'widgets/summary_section.dart';

class DetailScreen extends ConsumerWidget {
  const DetailScreen({super.key, required this.symbol});

  static Route<void> route(String symbol) =>
      MaterialPageRoute<void>(builder: (_) => DetailScreen(symbol: symbol));

  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<DetailState> detail = ref.watch(
      detailViewModelProvider(symbol),
    );
    final bool isFavorite = ref.watch(
      favoritesProvider.select((List<String> s) => s.contains(symbol)),
    );
    final DetailState? data = detail.value;

    return VisibilityListener(
      onChanged: ref
          .read(detailViewModelProvider(symbol).notifier)
          .setPollingActive,
      child: Scaffold(
        appBar: DetailAppBar(
          name: data?.stock.name ?? (detail.isLoading ? null : symbol),
          subtitle: data?.stock.subtitle ?? (detail.isLoading ? symbol : null),
          isFavorite: isFavorite,
          onFavoriteTap: () =>
              ref.read(favoritesProvider.notifier).toggle(symbol),
        ),
        body: switch (detail) {
          AsyncValue<DetailState>(:final DetailState value?) => _DetailBody(
            state: value,
            onSelectPeriod: ref
                .read(detailViewModelProvider(symbol).notifier)
                .selectPeriod,
          ),
          AsyncValue<DetailState>(isLoading: true) => const DetailSkeleton(),
          _ => RetryView(
            message: '종목 정보를 불러오지 못했습니다.\n네트워크 상태를 확인한 뒤 다시 시도해 주세요.',
            onRetry: () => ref.invalidate(detailViewModelProvider(symbol)),
          ),
        },
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.state, required this.onSelectPeriod});

  final DetailState state;
  final ValueChanged<ChartPeriod> onSelectPeriod;

  @override
  Widget build(BuildContext context) {
    final AppDimens dimens = context.dimens;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            dimens.space4,
            dimens.space3,
            dimens.space4,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PriceHeader(
                  stock: state.stock,
                  selected: state.period,
                  onSelect: onSelectPeriod,
                ),
                SizedBox(height: dimens.space4),
                CandleChart(
                  candles: state.candles,
                  isLoading: state.isPeriodLoading,
                  hasError: state.hasPeriodError,
                  onRetry: () => onSelectPeriod(state.period),
                ),
                SizedBox(height: dimens.space4),
                SummarySection(stock: state.stock),
                SizedBox(height: dimens.space6),
              ],
            ),
          ),
        ),
        DailyPriceTable(
          rows: state.hasPeriodError ? const <DailyPriceRow>[] : state.rows,
          isLoading: state.isPeriodLoading,
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: dimens.space6 + MediaQuery.paddingOf(context).bottom,
          ),
        ),
      ],
    );
  }
}
