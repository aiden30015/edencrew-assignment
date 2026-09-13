import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  static const double _height = 40;

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Container(
      height: _height,
      padding: EdgeInsets.only(left: dimens.space3),
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        borderRadius: BorderRadius.circular(dimens.radiusMd),
        border: Border.all(
          color: colors.borderStrong,
          width: dimens.borderHairline,
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.search, size: dimens.iconSm, color: colors.textTertiary),
          SizedBox(width: dimens.space2),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              cursorColor: colors.accentDefault,
              style: AppTypography.medium15.copyWith(color: colors.textPrimary),
              decoration: InputDecoration.collapsed(
                hintText: '종목명 또는 종목코드',
                hintStyle: AppTypography.medium15.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            ),
          ),
          Tooltip(
            message: '검색어 지우기',
            child: InkResponse(
              onTap: onClear,
              radius: 20,
              child: SizedBox.square(
                dimension: _height,
                child: Icon(
                  Icons.close,
                  size: dimens.iconSm,
                  color: colors.textTertiary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
