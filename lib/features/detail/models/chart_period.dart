// 상세 화면의 기간 탭.
// tradingDays는 달력 날짜가 아니라 거래일 수이고, 차트와 일별 시세 표에 같이 쓴다.
enum ChartPeriod {
  oneMonth('1개월', 20),
  threeMonths('3개월', 60),
  sixMonths('6개월', 120),
  oneYear('1년', 245);

  const ChartPeriod(this.label, this.tradingDays);

  final String label;

  final int tradingDays;
}
