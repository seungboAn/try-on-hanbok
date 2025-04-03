import 'package:flutter/material.dart';
import 'package:test02/constants/exports.dart';

class Header extends StatelessWidget {
  const Header({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 수평 패딩은 AppSizes에서 가져오고, 수직 패딩은 직접 설정
    final horizontalPadding = AppSizes.getScreenPadding(context);
    final padding = EdgeInsets.symmetric(
      horizontal: horizontalPadding.horizontal / 2,
      vertical: 10,
    );

    return Container(
      width: double.infinity,
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo with click action
          InkWell(
            onTap: () {
              Navigator.pushNamed(context, AppConstants.homeRoute);
            },
            child: Text(
              AppConstants.appName,
              style: AppTextStyles.appBarTitle(
                context,
              ).copyWith(letterSpacing: 3, fontFamily: 'Times'),
            ),
          ),

          // 언어 아이콘
          SizedBox(
            width: 21,
            height: 21,
            child: Image.asset(
              'assets/images/lang/en.png',
              width: 21,
              height: 21,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}
