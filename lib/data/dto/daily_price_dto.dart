import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

// 일별 시세 한 페이지(최대 10거래일, 최신 날짜가 앞). 상세 화면의 차트 · 표에 쓴다.
class DailyPricePageDto {
  const DailyPricePageDto({required this.items, required this.lastPage});

  // finance.naver.com/item/sise_day.naver 응답(HTML)을 파싱한다.
  // 표의 칸 순서: 날짜, 종가, 전일비, 시가, 고가, 저가, 거래량.
  factory DailyPricePageDto.fromHtml(String html) {
    final Document document = html_parser.parse(html);

    // 표가 없으면 차단 · 안내 페이지이거나 형식이 바뀐 것이다. 빈 페이지로 두면 성공으로 캐시되어
    // 오류 없이 빈 차트가 남으므로 파싱 실패로 처리한다.
    final Element? table = document.querySelector('table.type2');
    if (table == null) {
      throw const FormatException('sise_day: table.type2가 없습니다');
    }

    final List<DailyPriceDto> items = <DailyPriceDto>[
      for (final Element row in table.querySelectorAll('tr'))
        if (_parseRow(row) case final DailyPriceDto item) item,
    ];

    // 마지막 페이지는 '맨뒤' 링크에 있고, 페이지가 적어 '맨뒤'가 없으면 페이지 링크 중 가장 큰 값.
    final Iterable<int> pages = document
        .querySelectorAll('table.Nnavi a')
        .map((Element a) => _pageOf(a.attributes['href']))
        .whereType<int>();
    final int lastPage = pages.isEmpty
        ? 1
        : pages.reduce((int a, int b) => a > b ? a : b);

    return DailyPricePageDto(items: items, lastPage: lastPage);
  }

  final List<DailyPriceDto> items;
  final int lastPage;

  static final RegExp _datePattern = RegExp(r'^\d{4}\.\d{2}\.\d{2}$');

  // 날짜 칸이 없는 행(헤더, 구분선)은 null.
  static DailyPriceDto? _parseRow(Element row) {
    final List<Element> cells = row.querySelectorAll('td');
    if (cells.length != 7) return null;
    final String date = cells[0].text.trim();
    if (!_datePattern.hasMatch(date)) return null;

    int number(Element cell) =>
        int.tryParse(cell.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    return DailyPriceDto(
      localDate: date.replaceAll('.', ''),
      closePrice: number(cells[1]),
      changePrice: number(cells[2]) * _changeSign(cells[2]),
      openPrice: number(cells[3]),
      highPrice: number(cells[4]),
      lowPrice: number(cells[5]),
      accumulatedTradingVolume: number(cells[6]),
    );
  }

  // 전일비 칸은 숫자에 부호가 없고, 방향은 아이콘(em.bu_pup / bu_pdn)과 숨김 글자(상승 · 하락)로만 나온다.
  static int _changeSign(Element cell) {
    final String icon = cell.querySelector('em')?.className ?? '';
    final String label = cell.querySelector('.blind')?.text ?? '';
    return icon.contains('dn') || label.contains('하락') || label.contains('하한')
        ? -1
        : 1;
  }

  static int? _pageOf(String? href) {
    if (href == null) return null;
    return int.tryParse(Uri.parse(href).queryParameters['page'] ?? '');
  }
}

class DailyPriceDto {
  const DailyPriceDto({
    required this.localDate,
    required this.closePrice,
    required this.changePrice,
    required this.openPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.accumulatedTradingVolume,
  });

  final String localDate;
  final int closePrice;

  final int changePrice;
  final int openPrice;
  final int highPrice;
  final int lowPrice;
  final int accumulatedTradingVolume;
}
