import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/state/favorites_notifier.dart';
import '../../shared/widgets/app_toast.dart';
import '../../theme/theme.dart';
import '../detail/detail_screen.dart';
import 'recent_searches_notifier.dart';
import 'search_view_model.dart';
import 'widgets/search_field.dart';
import 'widgets/search_results.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    ref.read(searchViewModelProvider.notifier).onQueryChanged('');
  }

  void _openDetail(String symbol) {
    ref
        .read(recentSearchesProvider.notifier)
        .add(ref.read(searchViewModelProvider).query);
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(DetailScreen.route(symbol));
  }

  void _searchRecent(String query) {
    _controller.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
    ref.read(searchViewModelProvider.notifier).onQueryChanged(query);
  }

  void _toggleFavorite(String symbol) {
    final bool added = ref
        .read(searchViewModelProvider.notifier)
        .toggleFavorite(symbol);

    showAppToast(
      context,
      message: added ? '관심이 등록되었습니다' : '관심이 해제되었습니다',
      icon: added ? Icons.star_rounded : Icons.star_outline_rounded,
      iconColor: added ? context.colors.favoriteActive : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppDimens dimens = context.dimens;
    final SearchState state = ref.watch(searchViewModelProvider);
    final List<String> favorites = ref.watch(favoritesProvider);
    final List<String> recentSearches = ref.watch(recentSearchesProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                dimens.space4,
                dimens.space2,
                dimens.space4,
                dimens.space3,
              ),
              child: SearchField(
                controller: _controller,
                onChanged: ref
                    .read(searchViewModelProvider.notifier)
                    .onQueryChanged,
                onClear: _clear,
              ),
            ),
            Expanded(
              child: SearchResults(
                state: state,
                favoriteSymbols: favorites,
                onTap: _openDetail,
                onFavoriteTap: _toggleFavorite,
                onRetry: ref.read(searchViewModelProvider.notifier).retry,
                recentSearches: recentSearches,
                onRecentTap: _searchRecent,
                onRecentRemove: ref
                    .read(recentSearchesProvider.notifier)
                    .remove,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
