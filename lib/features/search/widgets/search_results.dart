import 'package:flutter/material.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/favorite_button.dart';
import '../../../theme/theme.dart';
import '../models/search_result_item.dart';
import '../search_view_model.dart';

class SearchResults extends StatelessWidget {
  const SearchResults({
    super.key,
    required this.state,
    required this.favoriteSymbols,
    required this.onTap,
    required this.onFavoriteTap,
    required this.onRetry,
    required this.recentSearches,
    required this.onRecentTap,
    required this.onRecentRemove,
  });

  static const int _maxQueryLength = 20;

  final SearchState state;

  final List<String> favoriteSymbols;
  final ValueChanged<String> onTap;
  final ValueChanged<String> onFavoriteTap;
  final VoidCallback onRetry;

  final List<String> recentSearches;
  final ValueChanged<String> onRecentTap;
  final ValueChanged<String> onRecentRemove;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    // 검색 전: 최근 검색어가 있으면 목록, 없으면 시안의 빈 상태.
    if (state.query.isEmpty && recentSearches.isNotEmpty) {
      return _RecentSearches(
        queries: recentSearches,
        onTap: onRecentTap,
        onRemove: onRecentRemove,
      );
    }
    if (state.query.isEmpty) {
      return const EmptyState(
        icon: Icons.search,
        title: '종목을 검색해 보세요',
        message: '종목명 또는 종목코드 6자리로\n검색하실 수 있습니다.',
      );
    }

    if (state.status == SearchStatus.failure) {
      return _ErrorView(onRetry: onRetry);
    }

    if (state.results.isEmpty) {
      if (state.isLoading) {
        return Center(
          child: SizedBox.square(
            dimension: context.dimens.iconMd,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.accentDefault,
            ),
          ),
        );
      }
      return EmptyState(
        icon: Icons.search_off,
        title: '검색 결과가 없습니다',
        message: "'${_shortQuery(state.query)}'와\n일치하는 검색 결과를 찾지 못했습니다.",
      );
    }

    return Stack(
      children: <Widget>[
        ListView.builder(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          itemCount: state.results.length,
          itemBuilder: (BuildContext context, int index) {
            final SearchResultItem item = state.results[index];
            return _ResultRow(
              key: ValueKey<String>(item.id),
              item: item,
              isFavorite: favoriteSymbols.contains(item.symbol),
              onTap: () => onTap(item.symbol),
              onFavoriteTap: () => onFavoriteTap(item.symbol),
            );
          },
        ),
        if (state.isLoading)
          LinearProgressIndicator(
            minHeight: 2,
            color: colors.accentDefault,
            backgroundColor: colors.borderSubtle,
          ),
      ],
    );
  }

  static String _shortQuery(String query) {
    final Characters chars = query.characters;
    if (chars.length <= _maxQueryLength) return query;
    return '${chars.take(_maxQueryLength)}…';
  }
}

class _RecentSearches extends StatelessWidget {
  const _RecentSearches({
    required this.queries,
    required this.onTap,
    required this.onRemove,
  });

  static const double _rowHeight = 48;

  final List<String> queries;
  final ValueChanged<String> onTap;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.fromLTRB(
            dimens.space4,
            dimens.space2,
            dimens.space4,
            dimens.space1,
          ),
          child: Text(
            '최근 검색어',
            style: AppTypography.bold13.copyWith(color: colors.textSecondary),
          ),
        ),
        for (final String query in queries)
          InkWell(
            key: ValueKey<String>(query),
            onTap: () => onTap(query),
            child: SizedBox(
              height: _rowHeight,
              child: Padding(
                padding: EdgeInsets.only(left: dimens.space4),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.search,
                      size: dimens.iconSm,
                      color: colors.textTertiary,
                    ),
                    SizedBox(width: dimens.space3),
                    Expanded(
                      child: Text(
                        query,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.regular13.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: '최근 검색어 삭제',
                      onPressed: () => onRemove(query),
                      iconSize: dimens.iconSm,
                      icon: Icon(Icons.close, color: colors.textTertiary),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const EmptyState(
            icon: Icons.error_outline,
            title: '검색하지 못했습니다',
            message: '네트워크 연결을 확인한 뒤\n다시 시도해 주세요.',
          ),
          SizedBox(height: context.dimens.space2),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: colors.accentDefault),
            child: const Text('다시 시도', style: AppTypography.bold13),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    super.key,
    required this.item,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteTap,
  });

  static const double _minHeight = 60;

  final SearchResultItem item;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: _minHeight),
        padding: EdgeInsets.symmetric(horizontal: dimens.space4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colors.borderSubtle,
              width: dimens.borderHairline,
            ),
          ),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _HighlightedName(name: item.name, highlight: item.highlight),
                  Text(
                    '${item.symbol} · ${item.market}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.regular11.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: dimens.space3),
            FavoriteButton(isFavorite: isFavorite, onTap: onFavoriteTap),
          ],
        ),
      ),
    );
  }
}

class _HighlightedName extends StatelessWidget {
  const _HighlightedName({required this.name, required this.highlight});

  final String name;
  final TextRange? highlight;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final TextRange? range = highlight;

    return Text.rich(
      TextSpan(
        children: range == null
            ? <InlineSpan>[TextSpan(text: name)]
            : <InlineSpan>[
                TextSpan(text: range.textBefore(name)),
                TextSpan(
                  text: range.textInside(name),
                  style: TextStyle(color: colors.searchHighlight),
                ),
                TextSpan(text: range.textAfter(name)),
              ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.medium15.copyWith(color: colors.textPrimary),
    );
  }
}
