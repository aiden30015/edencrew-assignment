import 'package:flutter/material.dart';

import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/favorite_button.dart';
import '../../../theme/theme.dart';

class DetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DetailAppBar({
    super.key,
    required this.name,
    required this.subtitle,
    required this.isFavorite,
    required this.onFavoriteTap,
  });

  static const double _height = 55;

  final String? name;

  final String? subtitle;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;
    final String? name = this.name;

    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colors.borderSubtle,
            width: dimens.borderHairline,
          ),
        ),
      ),
      child: AppHeader(
        height: _height,
        // 뒤로 가기는 왼쪽 여백(space4)과 종목명까지의 간격(space3)을 누르는 영역에 포함한다.
        padding: EdgeInsets.only(right: dimens.space4),
        child: Row(
          children: [
            HeaderIconButton(
              icon: Icons.arrow_back,
              color: colors.textSecondary,
              onTap: () => Navigator.of(context).maybePop(),
              tooltip: '뒤로 가기',
              padding: EdgeInsets.only(
                left: dimens.space4,
                right: dimens.space3,
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (name == null)
                    Container(
                      width: 96,
                      height: 16,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        color: colors.feedbackSkeleton,
                        borderRadius: BorderRadius.circular(dimens.radiusSm),
                      ),
                    )
                  else
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.medium15.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  if (subtitle case final String subtitle)
                    Text(
                      subtitle,
                      maxLines: 1,
                      style: AppTypography.regular11.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: dimens.space3),
            FavoriteButton(isFavorite: isFavorite, onTap: onFavoriteTap),
          ],
        ),
      ),
    );
  }
}
