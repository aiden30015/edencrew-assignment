import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

class DetailSkeleton extends StatelessWidget {
  const DetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final AppDimens dimens = context.dimens;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        dimens.space4,
        dimens.space2,
        dimens.space4,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 46,
            child: Center(child: _Block(width: 200, height: 32)),
          ),
          SizedBox(height: dimens.space3),
          const _Block(height: 28),
          SizedBox(height: dimens.space4),
          const _Block(height: 200),
          SizedBox(height: dimens.space4),
          for (int row = 0; row < 2; row++) ...[
            if (row > 0) SizedBox(height: dimens.space2),
            Row(
              spacing: dimens.space2,
              children: [
                for (int i = 0; i < 3 - row; i++)
                  const Expanded(child: _Block(height: 56)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({this.width, required this.height});

  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: context.colors.feedbackSkeleton,
        borderRadius: BorderRadius.circular(context.dimens.radiusMd),
      ),
    );
  }
}
