import 'dart:convert';
import 'dart:io';

import 'package:charset/charset.dart';
import 'package:edencrew_assignment_starter/data/dto/autocomplete_item_dto.dart';
import 'package:edencrew_assignment_starter/data/dto/daily_price_dto.dart';
import 'package:edencrew_assignment_starter/data/dto/realtime_quote_dto.dart';
import 'package:edencrew_assignment_starter/data/dto/stock_meta_dto.dart';
import 'package:edencrew_assignment_starter/data/repository/naver_stock_repository.dart';
import 'package:edencrew_assignment_starter/shared/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// sise_day.naver 표 구조를 그대로 옮긴 샘플. 상승 · 하락 · 보합 행이 하나씩 있다.
const String _dailyHtml = '''
<html><head><meta http-equiv="Content-Type" content="text/html; charset=euc-kr"></head><body>
<table cellspacing="0" class="type2">
<tr><th>날짜</th><th>종가</th><th>전일비</th><th>시가</th><th>고가</th><th>저가</th><th>거래량</th></tr>
<tr><td colspan="7" height="8"></td></tr>
<tr onmouseover="mouseOver(this)" onmouseout="mouseOut(this)">
<td align="center"><span class="tah p10 gray03">2026.09.10</span></td>
<td class="num"><span class="tah p11">269,000</span></td>
<td class="num"><em class="bu_p bu_pup"><span class="blind">상승</span></em><span class="tah p11 red02">
 4,500
 </span></td>
<td class="num"><span class="tah p11">265,000</span></td>
<td class="num"><span class="tah p11">270,500</span></td>
<td class="num"><span class="tah p11">264,000</span></td>
<td class="num"><span class="tah p11">12,345,678</span></td>
</tr>
<tr onmouseover="mouseOver(this)" onmouseout="mouseOut(this)">
<td align="center"><span class="tah p10 gray03">2026.09.09</span></td>
<td class="num"><span class="tah p11">264,500</span></td>
<td class="num"><em class="bu_p bu_pdn"><span class="blind">하락</span></em><span class="tah p11 nv01">
 1,500
 </span></td>
<td class="num"><span class="tah p11">266,000</span></td>
<td class="num"><span class="tah p11">267,000</span></td>
<td class="num"><span class="tah p11">263,000</span></td>
<td class="num"><span class="tah p11">9,876,543</span></td>
</tr>
<tr onmouseover="mouseOver(this)" onmouseout="mouseOut(this)">
<td align="center"><span class="tah p10 gray03">2026.09.08</span></td>
<td class="num"><span class="tah p11">266,000</span></td>
<td class="num"><span class="tah p11">0</span></td>
<td class="num"><span class="tah p11">266,000</span></td>
<td class="num"><span class="tah p11">268,000</span></td>
<td class="num"><span class="tah p11">265,000</span></td>
<td class="num"><span class="tah p11">7,000,000</span></td>
</tr>
<tr><td colspan="7" height="8"></td></tr>
</table>
<table summary="페이지 네비게이션 리스트" class="Nnavi" align="center"><tr>
<td class="on"><a href="/item/sise_day.naver?code=005930&amp;page=1">1</a></td>
<td><a href="/item/sise_day.naver?code=005930&amp;page=2">2</a></td>
<td class="pgR"><a href="/item/sise_day.naver?code=005930&amp;page=11">다음</a></td>
<td class="pgRR"><a href="/item/sise_day.naver?code=005930&amp;page=680">맨뒤</a></td>
</tr></table>
</body></html>
''';

http.Response _eucKr(String body, String contentType) => http.Response.bytes(
  eucKr.encode(body),
  200,
  headers: <String, String>{'content-type': contentType},
);

http.Response _json(Object body) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  200,
  headers: <String, String>{'content-type': 'application/json;charset=UTF-8'},
);

void main() {
  test('일별 시세: EUC-KR HTML에서 날짜 · 가격 · 부호 있는 전일비 · 마지막 페이지를 뽑는다', () async {
    late http.Request sent;
    final NaverStockRepository repository = NaverStockRepository(
      client: MockClient((http.Request request) async {
        sent = request;
        return _eucKr(_dailyHtml, 'text/html;charset=euc-kr');
      }),
    );

    final Result<DailyPricePageDto> result = await repository.fetchDailyPrices(
      '005930',
      1,
    );

    expect(sent.url.host, 'finance.naver.com');
    expect(sent.url.queryParameters, <String, String>{
      'code': '005930',
      'page': '1',
    });
    expect(sent.headers['User-Agent'], isNotNull);

    final DailyPricePageDto page = (result as Success<DailyPricePageDto>).value;
    expect(page.lastPage, 680);
    expect(page.items.map((DailyPriceDto d) => d.localDate), <String>[
      '20260910',
      '20260909',
      '20260908',
    ]);
    expect(page.items.map((DailyPriceDto d) => d.changePrice), <int>[
      4500,
      -1500,
      0,
    ]);
    final DailyPriceDto first = page.items.first;
    expect(
      <int>[
        first.closePrice,
        first.openPrice,
        first.highPrice,
        first.lowPrice,
        first.accumulatedTradingVolume,
      ],
      <int>[269000, 265000, 270500, 264000, 12345678],
    );
  });

  test('일별 시세: 맨뒤 링크가 없으면 페이지 링크 중 가장 큰 값이 마지막 페이지', () {
    final String html = _dailyHtml.replaceAll(
      RegExp(r'<td class="pgR{1,2}">.*?</td>'),
      '',
    );
    expect(DailyPricePageDto.fromHtml(html).lastPage, 2);
    expect(DailyPricePageDto.fromHtml('<html></html>').lastPage, 1);
  });

  test('실시간 시세: 여러 종목을 한 번에 요청하고 종목코드로 찾을 수 있게 정리한다', () async {
    final List<int> bytes = File(
      'assets/mock/realtime_005930_000660.json',
    ).readAsBytesSync();
    final List<Uri> requests = <Uri>[];
    final NaverStockRepository repository = NaverStockRepository(
      client: MockClient((http.Request request) async {
        requests.add(request.url);
        return http.Response.bytes(
          bytes,
          200,
          headers: <String, String>{
            'content-type': 'text/plain;charset=EUC-KR',
          },
        );
      }),
    );

    final Result<Map<String, RealtimeQuoteDto>> result = await repository
        .fetchQuotes(<String>['005930', '000660']);

    expect(requests, hasLength(1));
    expect(
      requests.single.queryParameters['query'],
      'SERVICE_ITEM:005930,000660',
    );
    final Map<String, RealtimeQuoteDto> quotes =
        (result as Success<Map<String, RealtimeQuoteDto>>).value;
    expect(quotes.keys, containsAll(<String>['005930', '000660']));
    final RealtimeQuoteDto samsung = quotes['005930']!;
    expect(samsung.currentPrice, greaterThan(0));
    expect(samsung.previousClose, greaterThan(0));
    expect(samsung.countOfListedStock, greaterThan(0));
  });

  test('실시간 시세: 종목이 없으면 요청하지 않는다', () async {
    int calls = 0;
    final NaverStockRepository repository = NaverStockRepository(
      client: MockClient((http.Request request) async {
        calls++;
        return http.Response('', 200);
      }),
    );

    final Result<Map<String, RealtimeQuoteDto>> result = await repository
        .fetchQuotes(<String>[]);

    expect(calls, 0);
    expect((result as Success<Map<String, RealtimeQuoteDto>>).value, isEmpty);
  });

  test('검색: 국내 주식 · 6자리 종목코드만 남긴다', () async {
    final NaverStockRepository repository = NaverStockRepository(
      client: MockClient(
        (http.Request request) async => _json(<String, Object>{
          'query': '삼성',
          'items': <Map<String, String>>[
            <String, String>{
              'code': '005930',
              'name': '삼성전자',
              'typeCode': 'KOSPI',
              'typeName': '코스피',
              'nationCode': 'KOR',
              'category': 'stock',
            },
            <String, String>{
              'code': 'SSNLF',
              'name': '삼성전자 ADR',
              'typeCode': 'OTC',
              'typeName': '장외',
              'nationCode': 'USA',
              'category': 'stock',
            },
            <String, String>{
              'code': 'KPI200',
              'name': '코스피 200',
              'typeCode': 'INDEX',
              'typeName': '지수',
              'nationCode': 'KOR',
              'category': 'index',
            },
            <String, String>{
              'code': '0126Z0',
              'name': '삼성 신규',
              'typeCode': 'KOSPI',
              'typeName': '코스피',
              'nationCode': 'KOR',
              'category': 'stock',
            },
          ],
        }),
      ),
    );

    final Result<List<AutocompleteItemDto>> result = await repository.search(
      '삼성',
    );

    expect(
      (result as Success<List<AutocompleteItemDto>>).value.map(
        (AutocompleteItemDto item) => item.code,
      ),
      <String>['005930'],
    );
  });

  test('메타데이터: 종목명과 거래소명을 읽는다', () async {
    final NaverStockRepository repository = NaverStockRepository(
      client: MockClient(
        (http.Request request) async => _json(<String, String>{
          'symbolCode': '005930',
          'stockName': '삼성전자',
          'stockExchangeNameKor': '코스피',
        }),
      ),
    );

    final Result<StockMetaDto> result = await repository.fetchMeta('005930');

    final StockMetaDto meta = (result as Success<StockMetaDto>).value;
    expect(meta.stockName, '삼성전자');
    expect(meta.stockExchangeNameKor, '코스피');
  });

  test('HTTP 오류, 깨진 응답, 네트워크 예외는 예외 대신 Failure로 돌려준다', () async {
    Future<Result<StockMetaDto>> metaWith(MockClientHandler handler) =>
        NaverStockRepository(client: MockClient(handler)).fetchMeta('005930');

    expect(
      await metaWith((http.Request r) async => http.Response('', 500)),
      isA<Failure<StockMetaDto>>(),
    );
    expect(
      await metaWith((http.Request r) async => http.Response('<html>', 200)),
      isA<Failure<StockMetaDto>>(),
    );
    expect(
      await metaWith(
        (http.Request r) async => throw const SocketException('offline'),
      ),
      isA<Failure<StockMetaDto>>(),
    );
  });
}
