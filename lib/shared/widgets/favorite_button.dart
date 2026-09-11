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

    return Transform.translate(
      offset: Offset(dimens.space2, 0),
      child: IconButton(
        iconSize: dimens.iconMd,
        padding: EdgeInsets.all(dimens.space2),
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
