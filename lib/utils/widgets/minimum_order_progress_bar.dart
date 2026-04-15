import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../config/constant.dart';
import '../../config/theme.dart';

class MinimumOrderProgressBar extends StatelessWidget {
  final double currentTotal;
  final bool isSmall;

  const MinimumOrderProgressBar({
    super.key,
    required this.currentTotal,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final double minAmount = AppConstant.minimumOrderValue;
    final double remaining = (minAmount - currentTotal).clamp(0.0, minAmount);
    final double progress = (currentTotal / minAmount).clamp(0.0, 1.0);
    final bool isGoalReached = progress >= 1.0;

    if (currentTotal <= 0 && !isSmall) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isSmall) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isGoalReached 
                    ? "Minimum order reached!" 
                    : "Add ${AppConstant.currency}${remaining.toStringAsFixed(0)} more to order",
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: isGoalReached ? AppTheme.successColor : Colors.grey.shade700,
                ),
              ),
              if (!isGoalReached)
                Text(
                  "${(progress * 100).toInt()}%",
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
            ],
          ),
          SizedBox(height: 6.h),
        ],
        Container(
          height: isSmall ? 4.h : 8.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isSmall ? Colors.black.withValues(alpha: 0.1) : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                width: MediaQuery.of(context).size.width * progress,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isGoalReached
                        ? [AppTheme.successColor, AppTheme.successColor.withValues(alpha: 0.7)]
                        : [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(10.r),
                  boxShadow: [
                    if (!isSmall)
                      BoxShadow(
                        color: (isGoalReached ? AppTheme.successColor : AppTheme.primaryColor)
                            .withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
