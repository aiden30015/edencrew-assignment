import 'dart:async';
import 'dart:ui' show TextRange;

import 'package:edencrew_assignment_starter/data/dto/autocomplete_item_dto.dart';
import 'package:edencrew_assignment_starter/data/dto/daily_price_dto.dart';
import 'package:edencrew_assignment_starter/data/dto/realtime_quote_dto.dart';
import 'package:edencrew_assignment_starter/data/dto/stock_meta_dto.dart';
import 'package:edencrew_assignment_starter/data/repository/stock_repository.dart';
import 'package:edencrew_assignment_starter/features/search/models/search_result_item.dart';
import 'package:edencrew_assignment_starter/features/search/search_view_model.dart';
import 'package:edencrew_assignment_starter/shared/utils/result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/misc.dart';

class _ManualSearchRepository implements StockRepository {
  final Map<String, Completer<Result<List<AutocompleteItemDto>>>> pending =
      <String, Completer<Result<List<AutocompleteItemDto>>>>{};

  void respond(String query, List<AutocompleteItemDto> items) =>
      pending[query]!.complete(Success<List<AutocompleteItemDto>>(items));

  @override
  Future<Result<List<AutocompleteItemDto>>> search(String query) =>
      (pending[query] = Completer<Result<List<AutocompleteItemDto>>>()).future;

  @override
  Future<Result<RealtimeQuotesDto>> fetchQuotes(List<String> symbols) =>
      throw UnimplementedError();

  @override
  Future<Result<StockMetaDto>> fetchMeta(String symbol) =>
      throw UnimplementedError();

  @override
  Future<Result<DailyPricePageDto>> fetchDailyPrices(String symbol, int page) =>
      throw UnimplementedError();
}

AutocompleteItemDto _dto(String code, String name) => AutocompleteItemDto(
  code: code,
  name: name,
  typeCode: 'KOSPI',
  typeName: '코스피',
  nationCode: 'KOR',
  category: 'stock',
);

void main() {
  test('하이라이트 구간: 대소문자 무시, 일치하지 않으면 null', () {
    expect(findHighlight('삼성전자', '성전'), const TextRange(start: 1, end: 3));
    expect(findHighlight('SK하이닉스', 'sk'), const TextRange(start: 0, end: 2));
    expect(findHighlight('삼성전자', '005930'), isNull);
  });

  test('늦게 도착한 이전 검색어의 응답은 최신 결과를 덮어쓰지 않는다', () async {
    final _ManualSearchRepository repository = _ManualSearchRepository();
    final ProviderContainer container = ProviderContainer.test(
      overrides: <Override>[
        stockRepositoryProvider.overrideWithValue(repository),
        searchViewModelProvider.overrideWith(
          () => SearchViewModel(debounce: Duration.zero),
        ),
      ],
    );
    final SearchViewModel viewModel = container.read(
      searchViewModelProvider.notifier,
    );

    viewModel.onQueryChanged('삼');
    await Future<void>.delayed(Duration.zero);
    viewModel.onQueryChanged('삼성전자');
    await Future<void>.delayed(Duration.zero);

    repository.respond('삼성전자', <AutocompleteItemDto>[_dto('005930', '삼성전자')]);
    await Future<void>.delayed(Duration.zero);
    repository.respond('삼', <AutocompleteItemDto>[
      _dto('005930', '삼성전자'),
      _dto('000810', '삼성화재'),
    ]);
    await Future<void>.delayed(Duration.zero);

    final SearchState state = container.read(searchViewModelProvider);
    expect(state.query, '삼성전자');
    expect(state.status, SearchStatus.success);
    expect(state.results.map((SearchResultItem e) => e.id), <String>[
      'domestic:005930',
    ]);
  });

  test('디바운스 대기 중에 도착한 이전 검색어 응답은 버리고, 이전 결과를 둔 채 새 검색을 기다린다', () async {
    const Duration debounce = Duration(milliseconds: 20);
    Future<void> afterDebounce() =>
        Future<void>.delayed(debounce + const Duration(milliseconds: 10));

    final _ManualSearchRepository repository = _ManualSearchRepository();
    final ProviderContainer container = ProviderContainer.test(
      overrides: <Override>[
        stockRepositoryProvider.overrideWithValue(repository),
        searchViewModelProvider.overrideWith(
          () => SearchViewModel(debounce: debounce),
        ),
      ],
    );
    final SearchViewModel viewModel = container.read(
      searchViewModelProvider.notifier,
    );
    SearchState state() => container.read(searchViewModelProvider);
    List<String> ids() => <String>[
      for (final SearchResultItem e in state().results) e.id,
    ];

    // '삼' 결과가 화면에 있다.
    viewModel.onQueryChanged('삼');
    await afterDebounce();
    repository.respond('삼', <AutocompleteItemDto>[
      _dto('005930', '삼성전자'),
      _dto('000810', '삼성화재'),
    ]);
    await Future<void>.delayed(Duration.zero);
    expect(ids(), <String>['domestic:005930', 'domestic:000810']);

    // '삼성' 요청이 나간 뒤 '삼성전'을 입력했고, 디바운스 대기 중에 '삼성' 응답이 도착한다.
    viewModel.onQueryChanged('삼성');
    await afterDebounce();
    viewModel.onQueryChanged('삼성전');
    repository.respond('삼성', <AutocompleteItemDto>[_dto('000810', '삼성화재')]);
    await Future<void>.delayed(Duration.zero);

    // 늦은 '삼성' 응답은 버리고, 이전('삼') 결과를 둔 채 '삼성전'을 기다린다.
    expect(state().query, '삼성전');
    expect(state().status, SearchStatus.loading);
    expect(ids(), <String>['domestic:005930', 'domestic:000810']);

    // 백스페이스로 '삼성'이 되면 '삼성전' 검색은 취소되고 '삼성'을 다시 검색한다.
    viewModel.onQueryChanged('삼성');
    await afterDebounce();
    expect(repository.pending.containsKey('삼성전'), isFalse);
    repository.respond('삼성', <AutocompleteItemDto>[_dto('005930', '삼성전자')]);
    await Future<void>.delayed(Duration.zero);

    expect(state().query, '삼성');
    expect(state().status, SearchStatus.success);
    expect(ids(), <String>['domestic:005930']);
  });
}
