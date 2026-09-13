import 'package:flutter/material.dart';

import '../../theme/theme.dart';

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    super.key,
    required this.isFavorite,
    required this.onTap,
  });

  final bool isFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;
    // 누르는 영역은 48 × 48, 아이콘은 시안 크기(iconMd). 늘어난 만큼 오른쪽으로 옮겨서
    // 아이콘 오른쪽 끝이 시안처럼 화면 여백(space4) 선에 맞는다.
    final double padding = (kMinInteractiveDimension - dimens.iconMd) / 2;

    return Transform.translate(
      offset: Offset(padding, 0),
      child: IconButton(
        iconSize: dimens.iconMd,
        padding: EdgeInsets.all(padding),
        constraints: const BoxConstraints(),
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        tooltip: isFavorite ? '관심 해제' : '관심 등록',
        onPressed: onTap,
        icon: Icon(
          isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
          color: isFavorite ? colors.favoriteActive : colors.favoriteInactive,
        ),
      ),
    );
  }
}
