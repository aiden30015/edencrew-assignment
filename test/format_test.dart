import 'package:edencrew_assignment_starter/shared/utils/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Figma 표기 형식', () {
    expect(Format.number(179700), '179,700');
    expect(Format.number(-400), '-400');
    expect(Format.number(1000000), '1,000,000');
    expect(Format.signedNumber(9500), '+9,500');
    expect(Format.signedNumber(0), '0');
    expect(Format.signedPercent(-0.0022), '-0.22%');
    expect(Format.signedPercent(0.0236), '+2.36%');
    expect(Format.signedPercent(0), '0.00%');
    expect(Format.signedPercent(-0.00001), '0.00%');
    expect(Format.volume(29113456), '29,113천');
    expect(Format.marketCap(1063000000000000), '1,063조');
    expect(Format.marketCap(812000000000), '8,120억');
    expect(Format.monthDay('20260910'), '09.10');
  });

  test('등락률은 이진 오차 없이 소수 둘째 자리(%)에서 반올림한다', () {
    // double로 바로 나누면 1.00499…%가 되어 +1.00%로 내려가던 값.
    expect(Format.signedPercent(Format.changeRate(201, 20000)), '+1.01%');
    expect(Format.signedPercent(Format.changeRate(-201, 20000)), '-1.01%');
    expect(Format.signedPercent(Format.changeRate(-400, 180100)), '-0.22%');
    expect(Format.changeRate(5, 0), 0);
  });
}
