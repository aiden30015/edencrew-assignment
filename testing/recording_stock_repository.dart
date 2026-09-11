import 'package:edencrew_assignment_starter/data/dto/daily_price_dto.dart';
import 'package:edencrew_assignment_starter/data/dto/realtime_quote_dto.dart';
import 'package:edencrew_assignment_starter/data/repository/fake_stock_repository.dart';
import 'package:edencrew_assignment_starter/shared/utils/result.dart';

/// 요청을 기록하는 테스트용 저장소. 응답은 [FakeStockRepository]와 같고 지연이 없습니다.
class RecordingStockRepository extends FakeStockRepository {
  RecordingStockRepository() : super(latency: Duration.zero);

  /// 요청된 일별 시세 페이지 번호 (요청 순서)
  final List<int> dailyPages = <int>[];
  int quoteCalls = 0;

  @override
  Future<Result<DailyPricePageDto>> fetchDailyPrices(String symbol, int page) {
    dailyPages.add(page);
    return super.fetchDailyPrices(symbol, page);
  }

  @override
  Future<Result<RealtimeQuotesDto>> fetchQuotes(List<String> symbols) {
    quoteCalls++;
    return super.fetchQuotes(symbols);
  }
}
