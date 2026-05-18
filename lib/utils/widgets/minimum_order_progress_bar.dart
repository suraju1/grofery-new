import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../config/constant.dart';
import '../../config/theme.dart';

class MinimumOrderProgressBar extends StatelessWidget {
  final double currentTotal;
  final bool isSmall;
  final bool isBottomAttached;

  const MinimumOrderProgressBar({
    super.key,
    required this.currentTotal,
    this.isSmall = false,
    this.isBottomAttached = true,
  });

  @override
  Widget build(BuildContext context) {
    final double minAmount = AppConstant.minimumOrderValue;
    final double remaining = (minAmount - currentTotal).clamp(0.0, minAmount);
    final double progress = (currentTotal / minAmount).clamp(0.0, 1.0);
    final bool isGoalReached = progress >= 1.0;

    if ((currentTotal <= 0 && !isSmall) || isGoalReached) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isBottomAttached ? 16.w : 16.w, 
        vertical: 12.h
      ),
      decoration: BoxDecoration(
        color: isGoalReached ? AppTheme.successColor.withValues(alpha: 0.1) : const Color(0xFFFFF3E0),
        borderRadius: isBottomAttached 
            ? BorderRadius.only(
                topLeft: Radius.circular(20.r),
                topRight: Radius.circular(20.r),
              )
            : BorderRadius.circular(20.r),
        border: isBottomAttached 
            ? null 
            : Border.all(
                color: isGoalReached ? AppTheme.successColor.withValues(alpha: 0.3) : Colors.orange.shade200,
              ),
      ),
      child: Row(
        children: [
          Icon(
            isGoalReached ? Icons.check_circle_outline : Icons.error_outline,
            color: isGoalReached ? AppTheme.successColor : Colors.deepOrange,
            size: 20.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              isGoalReached 
                  ? "Minimum order reached!" 
                  : "Add ${AppConstant.currency}${remaining.toInt()} more for minimum order of ${AppConstant.currency}${minAmount.toInt()}",
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: isGoalReached ? AppTheme.successColor : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
