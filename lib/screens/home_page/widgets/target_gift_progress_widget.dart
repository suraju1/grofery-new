import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:grofery_user/config/theme.dart';
import '../bloc/target_gift/target_gift_bloc.dart';
import '../bloc/target_gift/target_gift_state.dart';

class TargetGiftProgressWidget extends StatelessWidget {
  const TargetGiftProgressWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TargetGiftBloc, TargetGiftState>(
      builder: (context, state) {
        if (state is TargetGiftLoaded) {
          final data = state.targetGiftData;
          if (data.nextGift == null && data.eligibleGift == null) {
            return const SizedBox.shrink();
          }

          final nextGift = data.nextGift;
          final totalSpent = data.totalSpent ?? 0;
          final targetAmount = nextGift?.targetAmount ?? 0;
          final giftImage =
              nextGift?.giftImage ?? data.eligibleGift?.giftImage ?? '';
          final giftName =
              nextGift?.giftName ?? data.eligibleGift?.giftName ?? '';

          double progress = 0;
          if (targetAmount > 0) {
            progress = (totalSpent / targetAmount).clamp(0.0, 1.0);
          } else if (data.eligibleGift != null) {
            progress = 1.0;
          }

          final bool isUnlocked = progress >= 1.0;

          return Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(
                color: isUnlocked
                    ? Colors.orange.withOpacity(0.3)
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(6.w),
                          decoration: BoxDecoration(
                            color: (isUnlocked
                                    ? Colors.orange
                                    : AppTheme.primaryColor)
                                .withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isUnlocked
                                ? Icons.card_giftcard
                                : Icons.auto_awesome,
                            size: 16.sp,
                            color: isUnlocked
                                ? Colors.orange
                                : AppTheme.primaryColor,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isUnlocked
                                  ? "Congratulations!"
                                  : "Get a Free Gift",
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              isUnlocked
                                  ? "You've earned a $giftName"
                                  : "Add ₹${(targetAmount - totalSpent).toInt()} more to unlock",
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: (isUnlocked ? Colors.green : Colors.orange)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        "${(progress * 100).toInt()}%",
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: isUnlocked ? Colors.green : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15.h),
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.centerLeft,
                  children: [
                    // Background Track
                    Container(
                      height: 10.h,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 2,
                            //inset: true,
                          ),
                        ],
                      ),
                    ),
                    // Progress Fill
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.elasticOut,
                      height: 10.h,
                      width:
                          (MediaQuery.of(context).size.width - 60.w) * progress,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isUnlocked
                              ? [Colors.orange, Colors.deepOrangeAccent]
                              : [
                                  AppTheme.primaryColor.withOpacity(0.8),
                                  AppTheme.primaryColor
                                ],
                        ),
                        borderRadius: BorderRadius.circular(10.r),
                        boxShadow: [
                          BoxShadow(
                            color: (isUnlocked
                                    ? Colors.orange
                                    : AppTheme.primaryColor)
                                .withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: !isUnlocked
                          ? Center(
                              child: Container(
                                height: 1.5.h,
                                width: double.infinity,
                                margin: EdgeInsets.symmetric(horizontal: 10.w),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            )
                          : null,
                    ),
                    // Gift Icon floating at the end
                    Positioned(
                      right: -5.w,
                      top: -15.h,
                      child: Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color:
                                isUnlocked ? Colors.orange : Colors.grey[200]!,
                            width: 2,
                          ),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: giftImage,
                          height: 36.h,
                          width: 36.w,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                          errorWidget: (context, url, error) => Icon(
                            Icons.card_giftcard,
                            color:
                                isUnlocked ? Colors.orange : Colors.grey[400],
                            size: 20.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 5.h),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
