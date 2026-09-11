// 검색 자동완성 API(ac.stock.naver.com/ac) 응답의 항목 하나.
class AutocompleteItemDto {
  const AutocompleteItemDto({
    required this.code,
    required this.name,
    required this.typeCode,
    required this.typeName,
    required this.nationCode,
    required this.category,
    this.url,
  });

  factory AutocompleteItemDto.fromJson(Map<String, dynamic> json) {
    return AutocompleteItemDto(
      code: json['code'] as String,
      name: json['name'] as String,
      typeCode: json['typeCode'] as String? ?? '',
      typeName: json['typeName'] as String? ?? '',
      nationCode: json['nationCode'] as String? ?? '',
      category: json['category'] as String? ?? '',
      url: json['url'] as String?,
    );
  }

  final String code;
  final String name;
  final String typeCode;
  final String typeName;
  final String nationCode;
  final String category;
  final String? url;
}
