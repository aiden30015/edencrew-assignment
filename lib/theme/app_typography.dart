import 'package:flutter/material.dart';

/// Figma `Typography` 컬렉션을 옮긴 서체 토큰입니다.
///
/// Figma는 서체와 굵기만 변수로 정의해 두었습니다.
/// **글자 크기와 행간은 각 화면의 텍스트 레이어에서 직접 확인해서 쓰세요.**
abstract final class AppTypography {
  /// `pubspec.yaml`의 `flutter.fonts`에 등록한 family 이름과 일치해야 합니다.
  static const String fontFamily = 'NotoSansKR';

  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight bold = FontWeight.w700;

  // 앱 전용 추가 토큰 (Figma 변수 아님)
  //
  // 과제 1 화면의 텍스트 레이어에서 두 곳 이상 반복되는 조합만 모았습니다.
  // 의미 기반 타입 스케일(title/body 등)은 Figma에 없으므로 이름은 `굵기 + 크기`로만 붙입니다.
  // 색상은 쓰는 곳마다 달라서 넣지 않았습니다. `copyWith(color: ...)`로 지정하세요.
  // 한 곳에서만 쓰는 스타일(현재가 Bold 30)은 여기에 올리지 않고 그 위젯에 둡니다.
  //
  // - 행간: Flutter의 `height`는 글자 크기에 곱하는 배수라서 `행간px / 크기`로 적습니다. (22px → 22 / 19)
  // - 행간 여백은 Figma처럼 글자 위아래에 고르게 나눕니다(even). 기본값이면 글자가 1px가량 위로 뜹니다.
  // - 자간: px 그대로 적습니다.

  /// 종목코드 · 시장, 등락, 탭 라벨, 빈 상태 설명, 표 셀
  static const TextStyle regular11 = TextStyle(
    fontSize: 11,
    fontWeight: regular,
    height: 14 / 11,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// 기간 칩
  static const TextStyle regular13 = TextStyle(
    fontSize: 13,
    fontWeight: regular,
    height: 18 / 13,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// 종목명, 가격, 검색어, 정렬 옵션
  static const TextStyle medium15 = TextStyle(
    fontSize: 15,
    fontWeight: medium,
    height: 20 / 15,
    letterSpacing: -0.1,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// 정렬 버튼, 섹션 제목, 토스트
  static const TextStyle bold13 = TextStyle(
    fontSize: 13,
    fontWeight: bold,
    height: 18 / 13,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// 헤더 제목 · 빈 상태 제목 · 바텀시트 제목
  static const TextStyle bold19 = TextStyle(
    fontSize: 19,
    fontWeight: bold,
    height: 22 / 19,
    letterSpacing: -0.2,
    leadingDistribution: TextLeadingDistribution.even,
  );
}
