import 'dart:convert';
import 'dart:io';

import 'package:edencrew_assignment_starter/data/dto/autocomplete_item_dto.dart';
import 'package:edencrew_assignment_starter/data/dto/daily_price_dto.dart';
import 'package:edencrew_assignment_starter/data/dto/stock_meta_dto.dart';
import 'package:edencrew_assignment_starter/data/repository/naver_stock_repository.dart';
import 'package:edencrew_assignment_starter/shared/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// assets/mock에 저장한 실제 네이버 응답(2026-09-11)을 서버가 준 content-type 그대로 흘려보낸다.
NaverStockRepository _serving(String file, String contentType) =>
    NaverStockRepository(
      client: MockClient(
        (http.Request request) async => http.Response.bytes(
          File('assets/mock/$file').readAsBytesSync(),
          200,
          headers: <String, String>{'content-type': contentType},
        ),
      ),
    );

void main() {
  test('일별 시세 실제 HTML: 10거래일, 전일비 부호가 종가 차이와 맞는다', () async {
    final Result<DailyPricePageDto> result = await _serving(
      'sise_day_005930_p1.html',
      'text/html;charset=EUC-KR',
    ).fetchDailyPrices('005930', 1);

    final DailyPricePageDto page = (result as Success<DailyPricePageDto>).value;
    expect(page.items, hasLength(10));
    expect(page.lastPage, greaterThan(100));
    for (final DailyPriceDto day in page.items) {
      expect(day.localDate, matches(RegExp(r'^\d{8}$')));
      expect(day.closePrice, greaterThan(0));
      expect(day.highPrice, greaterThanOrEqualTo(day.lowPrice));
    }
    // 최신이 앞이므로 오늘 전일비 = 오늘 종가 - 어제 종가
    for (int i = 0; i < page.items.length - 1; i++) {
      expect(
        page.items[i].changePrice,
        page.items[i].closePrice - page.items[i + 1].closePrice,
        reason: page.items[i].localDate,
      );
    }
    // 날짜는 하루씩 과거로 간다
    for (int i = 0; i < page.items.length - 1; i++) {
      expect(
        page.items[i].localDate.compareTo(page.items[i + 1].localDate),
        greaterThan(0),
      );
    }
  });

  test('일별 시세 실제 HTML: 마지막 페이지에서도 행과 마지막 페이지 번호를 읽는다', () {
    final DailyPricePageDto page = DailyPricePageDto.fromHtml(
      File(
        'assets/mock/sise_day_005930_last.html',
      ).readAsStringSync(encoding: latin1),
    );
    expect(page.items, isNotEmpty);
    expect(page.lastPage, greaterThan(100));
  });

  test('검색 실제 응답: 국내 주식만 남고 시장명이 들어 있다', () async {
    final Result<List<AutocompleteItemDto>> result = await _serving(
      'autocomplete_samsung.json',
      'application/json; charset=utf-8',
    ).search('삼성');

    final List<AutocompleteItemDto> items =
        (result as Success<List<AutocompleteItemDto>>).value;
    expect(items, isNotEmpty);
    expect(items.first.code, '005930');
    expect(items.first.name, '삼성전자');
    expect(items.first.typeName, '코스피');
  });

  test('메타데이터 실제 응답: 종목명과 거래소명', () async {
    final Result<StockMetaDto> result = await _serving(
      'meta_005930.json',
      'application/json;charset=UTF-8',
    ).fetchMeta('005930');

    final StockMetaDto meta = (result as Success<StockMetaDto>).value;
    expect(meta.stockName, '삼성전자');
    expect(meta.stockExchangeNameKor, '코스피');
  });
}
