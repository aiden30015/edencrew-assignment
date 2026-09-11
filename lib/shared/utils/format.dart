abstract final class Format {
  static String number(num value) {
    final String digits = value.abs().toStringAsFixed(0);
    final StringBuffer out = StringBuffer(value < 0 ? '-' : '');
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
      out.write(digits[i]);
    }
    return out.toString();
  }

  static String signedNumber(num value) =>
      value > 0 ? '+${number(value)}' : number(value);

  static String signedPercent(double ratio) {
    final String text = '${(ratio * 100).abs().toStringAsFixed(2)}%';
    if (text == '0.00%') return text;
    return ratio > 0 ? '+$text' : '-$text';
  }

  static String volume(int value) =>
      value < 1000 ? number(value) : '${number(value ~/ 1000)}천';

  static String marketCap(int won) {
    const int jo = 1000000000000;
    const int eok = 100000000;
    if (won >= jo) return '${number(won ~/ jo)}조';
    return '${number(won ~/ eok)}억';
  }

  static String monthDay(String yyyyMMdd) =>
      '${yyyyMMdd.substring(4, 6)}.${yyyyMMdd.substring(6, 8)}';
}
