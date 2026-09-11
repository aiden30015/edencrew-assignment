import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/dto/autocomplete_item_dto.dart';
import '../../data/repository/stock_repository.dart';
import '../../shared/state/favorites_notifier.dart';
import '../../shared/utils/result.dart';
import 'models/search_result_item.dart';

enum SearchStatus { idle, loading, success, failure }

class SearchState {
  const SearchState({
    this.query = '',
    this.results = const <SearchResultItem>[],
    this.status = SearchStatus.idle,
  });

  final String query;

  final List<SearchResultItem> results;
  final SearchStatus status;

  bool get isLoading => status == SearchStatus.loading;

  SearchState copyWith({
    String? query,
    List<SearchResultItem>? results,
    SearchStatus? status,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      status: status ?? this.status,
    );
  }
}

class SearchViewModel extends Notifier<SearchState> {
  SearchViewModel({this.debounce = const Duration(milliseconds: 300)});

  final Duration debounce;

  late StockRepository _repository;

  Timer? _debounceTimer;
  int _requestId = 0;

  @override
  SearchState build() {
    _repository = ref.watch(stockRepositoryProvider);
    ref.onDispose(() => _debounceTimer?.cancel());
    return const SearchState();
  }

  void onQueryChanged(String text) {
    final String query = text.trim();
    if (query == state.query) return;

    _debounceTimer?.cancel();
    if (query.isEmpty) {
      _requestId++;
      state = const SearchState();
      return;
    }

    state = state.copyWith(query: query, status: SearchStatus.loading);
    _debounceTimer = Timer(debounce, () => _search(query));
  }

  void retry() {
    if (state.query.isEmpty) return;
    state = state.copyWith(status: SearchStatus.loading);
    _search(state.query);
  }

  bool toggleFavorite(String symbol) =>
      ref.read(favoritesProvider.notifier).toggle(symbol);

  Future<void> _search(String query) async {
    final int requestId = ++_requestId;
    final Result<List<AutocompleteItemDto>> result = await _repository.search(
      query,
    );
    if (!ref.mounted || requestId != _requestId) return;

    state = switch (result) {
      Success(value: final items) => SearchState(
        query: query,
        results: List<SearchResultItem>.unmodifiable(<SearchResultItem>[
          for (final AutocompleteItemDto dto in items) _toItem(dto, query),
        ]),
        status: SearchStatus.success,
      ),
      Failure() => state.copyWith(
        results: const <SearchResultItem>[],
        status: SearchStatus.failure,
      ),
    };
  }

  SearchResultItem _toItem(AutocompleteItemDto dto, String query) {
    return SearchResultItem(
      symbol: dto.code,
      name: dto.name,
      market: dto.typeName,
      highlight: findHighlight(dto.name, query),
    );
  }
}

final NotifierProvider<SearchViewModel, SearchState> searchViewModelProvider =
    NotifierProvider<SearchViewModel, SearchState>(SearchViewModel.new);
