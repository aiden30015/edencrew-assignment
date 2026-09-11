import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/empty_state.dart';
import '../detail/detail_screen.dart';
import 'models/watchlist_sort.dart';
import 'watchlist_view_model.dart';
import 'widgets/watchlist_app_bar.dart';
import 'widgets/watchlist_list.dart';
import 'widgets/watchlist_sort_sheet.dart';

class WatchlistScreen extends ConsumerStatefulWidget {
  const WatchlistScreen({super.key});

  @override
  ConsumerState<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends ConsumerState<WatchlistScreen> {
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  Widget build(BuildContext context) {
    final WatchlistState state = ref.watch(watchlistViewModelProvider);

    return Scaffold(
      appBar: WatchlistAppBar(
        sort: state.sort,
        reversed: state.reversed,
        onSortTap: () => _openSortSheet(state.sort),
        onRefresh: _refresh,
      ),
      body: state.items.isEmpty
          ? const EmptyState(
              icon: Icons.star_outline_rounded,
              title: '관심 종목이 없습니다',
              message: '검색 탭에서 종목을 찾아\n별 아이콘을 눌러 추가해 주세요.',
            )
          : WatchlistList(
              items: state.items,
              hasError: state.hasError,
              refreshIndicatorKey: _refreshKey,
              onRefresh: ref.read(watchlistViewModelProvider.notifier).refresh,
              onRetry: _refresh,
              onItemTap: (String symbol) =>
                  Navigator.of(context).push(DetailScreen.route(symbol)),
            ),
    );
  }

  void _refresh() {
    final RefreshIndicatorState? indicator = _refreshKey.currentState;
    if (indicator != null) {
      indicator.show();
      return;
    }
    ref.read(watchlistViewModelProvider.notifier).refresh();
  }

  Future<void> _openSortSheet(WatchlistSort current) async {
    final WatchlistSort? selected = await showWatchlistSortSheet(
      context,
      selected: current,
    );
    if (selected == null || !mounted) return;
    ref.read(watchlistViewModelProvider.notifier).changeSort(selected);
  }
}
