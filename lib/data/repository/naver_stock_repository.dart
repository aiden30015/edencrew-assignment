import 'dart:async';
import 'dart:convert';

import 'package:charset/charset.dart';
import 'package:http/http.dart' as http;

import '../../shared/utils/result.dart';
import '../dto/autocomplete_item_dto.dart';
import '../dto/daily_price_dto.dart';
import '../dto/realtime_quote_dto.dart';
import '../dto/stock_meta_dto.dart';
import 'stock_repository.dart';

// 네이버 endpoint 4개를 실제로 호출하는 저장소.
class NaverStockRepository implements StockRepository {
  NaverStockRepository({
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;

  // User-Agent가 없으면 일별 시세 페이지가 정상 응답을 주지 않는다.
  static const Map<String, String> _headers = <String, String>{
    'User-Agent': 'Mozilla/5.0',
  };

  static final RegExp _symbolPattern = RegExp(r'^\d{6}$');

  void close() => _client.close();

  @override
  Future<Result<List<AutocompleteItemDto>>> search(String query) {
    final Uri uri = Uri.https('ac.stock.naver.com', '/ac', <String, String>{
      'q': query,
      'target': 'stock,ipo,index,marketindicator',
    });
    return _get(uri, (String body) {
      final List<dynamic> items =
          (jsonDecode(body) as Map<String, dynamic>)['items'] as List<dynamic>;
      return items
          .map(
            (dynamic json) =>
                AutocompleteItemDto.fromJson(json as Map<String, dynamic>),
          )
          .where(
            (AutocompleteItemDto item) =>
                item.nationCode == 'KOR' &&
                item.category == 'stock' &&
                _symbolPattern.hasMatch(item.code),
          )
          .toList();
    });
  }

  @override
  Future<Result<RealtimeQuotesDto>> fetchQuotes(List<String> symbols) async {
    if (symbols.isEmpty) {
      return const Success<RealtimeQuotesDto>(
        RealtimeQuotesDto(quotes: <String, RealtimeQuoteDto>{}),
      );
    }
    final Uri uri = Uri.https(
      'polling.finance.naver.com',
      '/api/realtime',
      <String, String>{'query': 'SERVICE_ITEM:${symbols.join(',')}'},
    );
    return _get(uri, (String body) {
      final Map<String, dynamic> result =
          (jsonDecode(body) as Map<String, dynamic>)['result']
              as Map<String, dynamic>;
      final List<RealtimeQuoteDto> quotes = <RealtimeQuoteDto>[
        for (final dynamic area in result['areas'] as List<dynamic>)
          for (final dynamic json
              in (area as Map<String, dynamic>)['datas'] as List<dynamic>)
            RealtimeQuoteDto.fromJson(json as Map<String, dynamic>),
      ];
      final int? intervalMs = (result['pollingInterval'] as num?)?.toInt();
      return RealtimeQuotesDto(
        quotes: <String, RealtimeQuoteDto>{
          for (final RealtimeQuoteDto quote in quotes) quote.symbolCode: quote,
        },
        pollingInterval: intervalMs == null || intervalMs <= 0
            ? RealtimeQuotesDto.defaultPollingInterval
            : Duration(milliseconds: intervalMs),
      );
    });
  }

  @override
  Future<Result<StockMetaDto>> fetchMeta(String symbol) {
    final Uri uri = Uri.https(
      'stock.naver.com',
      '/api/securityFe/api/fchart/domestic/stock/$symbol',
    );
    return _get(
      uri,
      (String body) =>
          StockMetaDto.fromJson(jsonDecode(body) as Map<String, dynamic>),
    );
  }

  @override
  Future<Result<DailyPricePageDto>> fetchDailyPrices(String symbol, int page) {
    final Uri uri = Uri.https(
      'finance.naver.com',
      '/item/sise_day.naver',
      <String, String>{'code': symbol, 'page': '$page'},
    );
    return _get(uri, DailyPricePageDto.fromHtml);
  }

  // 요청 · 디코딩 · 파싱 중 어디서 실패하든 Failure로 돌려준다.
  Future<Result<T>> _get<T>(Uri uri, T Function(String body) parse) async {
    try {
      final http.Response response = await _client
          .get(uri, headers: _headers)
          .timeout(timeout);
      if (response.statusCode != 200) {
        return Failure<T>(
          StateError('HTTP ${response.statusCode}: ${uri.path}'),
        );
      }
      return Success<T>(parse(_decode(response)));
    } on Object catch (error) {
      return Failure<T>(error);
    }
  }

  // 실시간 시세와 일별 시세는 EUC-KR로 온다. http 패키지는 EUC-KR을 몰라서 latin1로 읽기 때문에 직접 디코딩한다.
  static String _decode(http.Response response) {
    final String contentType =
        response.headers['content-type']?.toLowerCase() ?? '';
    return contentType.contains('euc-kr')
        ? eucKr.decode(response.bodyBytes)
        : utf8.decode(response.bodyBytes, allowMalformed: true);
  }
}
