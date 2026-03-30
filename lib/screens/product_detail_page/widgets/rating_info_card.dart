import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../config/theme.dart';
import '../model/product_review_model.dart';
import '../view/product_detail_page.dart';

class RatingInfoCard extends StatelessWidget {
  final ProductReviewData reviewModel;
  const RatingInfoCard({super.key, required this.reviewModel});

  @override
  Widget build(BuildContext context) {
    final reviewData = reviewModel.data;

    // Safe parsing with fallbacks
    final rating = double.tryParse(reviewData.averageRating) ?? 0.0;
    final totalReviews = reviewData.totalReviews;

    // Safe rating breakdown parsing
    final ratingsMap = {
      5: double.tryParse(reviewData.ratingsBreakdown.star5) ?? 0.0,
      4: double.tryParse(reviewData.ratingsBreakdown.star4) ?? 0.0,
      3: double.tryParse(reviewData.ratingsBreakdown.star3) ?? 0.0,
      2: double.tryParse(reviewData.ratingsBreakdown.star2) ?? 0.0,
      1: double.tryParse(reviewData.ratingsBreakdown.star1) ?? 0.0,
    };

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          // Left side - Rating display
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Text(
                  rating.toStringAsFixed(1),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.tertiary,
                    fontSize: 48.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _buildDynamicStarRating(rating),
                ),
                SizedBox(height: 4.h),
                Text(
                  '$totalReviews ${totalReviews == 1 ? 'review' : 'reviews'}',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 24.w),

          // Right side - Rating breakdown
          Expanded(
            flex: 3,
            child: Column(
              children: [
                for (int i = 5; i >= 1; i--)
                  RatingBarWidget(
                    score: i,
                    percentage: totalReviews > 0
                        ? (ratingsMap[i]! / totalReviews) * 100
                        : 0.0,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDynamicStarRating(double rating) {
    List<Widget> stars = [];
    for (int i = 1; i <= 5; i++) {
      if (i <= rating) {
        stars.add(Icon(AppTheme.ratingStarIconFilled, color: AppTheme.ratingStarColor, size: 18.sp));
      } else if (i - 0.5 <= rating) {
        stars.add(Icon(AppTheme.ratingStarIconHalfFilled, color: AppTheme.ratingStarColor, size: 18.sp));
      } else {
        stars.add(Icon(AppTheme.ratingStarIconFilled, color:Colors.grey, size: 18.sp));
      }
    }
    return stars;
  }
}

class RatingBarWidget extends StatelessWidget {
  final int score;
  final double percentage;

  const RatingBarWidget({
    super.key,
    required this.score,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        children: [
          Text(
            score.toString(),
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(width: 4.w),
          Icon(Icons.star, size: 12.sp, color: Colors.grey.shade400),
          SizedBox(width: 8.w),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4.r),
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: Colors.grey.shade200,
                color: _getRatingColor(score),
                minHeight: 6.h,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          SizedBox(
            width: 30.w,
            child: Text(
              "${percentage.toInt()}%",
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRatingColor(int score) {
    if (score >= 4) return Colors.green;
    if (score >= 3) return Colors.orange;
    return Colors.red;
  }
}
