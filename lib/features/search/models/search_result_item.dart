import 'dart:ui' show TextRange;

class SearchResultItem {
  const SearchResultItem({
    required this.symbol,
    required this.name,
    required this.market,
    this.highlight,
  });

  final String symbol;
  final String name;

  final String market;

  final TextRange? highlight;

  String get id => 'domestic:$symbol';
}

TextRange? findHighlight(String text, String query) {
  if (query.isEmpty) return null;
  final int start = text.toLowerCase().indexOf(query.toLowerCase());
  if (start < 0) return null;
  return TextRange(start: start, end: start + query.length);
}
