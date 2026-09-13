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
    // 입력이 바뀌면 진행 중인 이전 검색어의 응답은 버린다. 지금 입력 중인 검색어가 우선이다.
    // 요청을 보낼 때(디바운스 후)만 번호를 올리면, 디바운스 동안 도착한 이전 응답이 새 입력을 덮어쓴다.
    _requestId++;
    if (query.isEmpty) {
      state = const SearchState();
      return;
    }

    // 새 결과가 올 때까지 이전 결과는 그대로 두고 진행 막대만 띄운다(화면이 깜빡이지 않게).
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
      Success<List<AutocompleteItemDto>>(
        value: final List<AutocompleteItemDto> items,
      ) =>
        SearchState(
          query: query,
          results: List<SearchResultItem>.unmodifiable(<SearchResultItem>[
            for (final AutocompleteItemDto dto in items) _toItem(dto, query),
          ]),
          status: SearchStatus.success,
        ),
      Failure<List<AutocompleteItemDto>>() => state.copyWith(
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
