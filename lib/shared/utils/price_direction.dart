import 'package:flutter/widgets.dart';

import '../../theme/theme.dart';

enum PriceDirection {
  up,
  down,
  flat;

  static PriceDirection of(num change) => change > 0
      ? PriceDirection.up
      : change < 0
      ? PriceDirection.down
      : PriceDirection.flat;

  Color textColor(AppColors colors) => switch (this) {
    PriceDirection.up => colors.priceUpText,
    PriceDirection.down => colors.priceDownText,
    PriceDirection.flat => colors.priceFlatText,
  };

  Color bgColor(AppColors colors) => switch (this) {
    PriceDirection.up => colors.priceUpBg,
    PriceDirection.down => colors.priceDownBg,
    PriceDirection.flat => colors.priceFlatBg,
  };

  Color candleColor(AppColors colors) => switch (this) {
    PriceDirection.up => colors.chartLineUp,
    PriceDirection.down => colors.chartLineDown,
    PriceDirection.flat => colors.chartLineFlat,
  };
}
