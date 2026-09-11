import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/utils/result.dart';
import '../dto/autocomplete_item_dto.dart';
import '../dto/daily_price_dto.dart';
import '../dto/realtime_quote_dto.dart';
import '../dto/stock_meta_dto.dart';
import 'naver_stock_repository.dart';

// 네이버 주식 API 4개에 대응하는 저장소. 앱은 NaverStockRepository, 테스트는 test/mocks의 FakeStockRepository를 쓴다.
// 실패는 예외로 던지지 않고 Failure로 돌려준다.
abstract interface class StockRepository {
  // 국내 주식 · 6자리 종목코드만 남긴 검색 결과.
  Future<Result<List<AutocompleteItemDto>>> search(String query);

  // 여러 종목의 실시간 시세를 한 번의 요청으로 조회한다.
  Future<Result<RealtimeQuotesDto>> fetchQuotes(List<String> symbols);

  // 종목 기본 정보(이름 · 시장).
  Future<Result<StockMetaDto>> fetchMeta(String symbol);

  // 일별 시세 한 페이지(10거래일). [page]는 1부터.
  Future<Result<DailyPricePageDto>> fetchDailyPrices(String symbol, int page);
}

final Provider<StockRepository> stockRepositoryProvider =
    Provider<StockRepository>((Ref ref) {
      final NaverStockRepository repository = NaverStockRepository();
      ref.onDispose(repository.close);
      return repository;
    });
