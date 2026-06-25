import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:grofery_user/config/theme.dart';
import 'package:grofery_user/screens/cart_page/bloc/get_user_cart/get_user_cart_bloc.dart';
import 'package:grofery_user/screens/wallet_page/bloc/user_wallet/user_wallet_bloc.dart';
import 'package:grofery_user/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:grofery_user/config/constant.dart';

class WalletUsageWidget extends StatefulWidget {
  final bool isWalletEnabled;
  final Function(bool) onWalletToggle;
  final bool isLoading;
  final double? walletAmountUsed;
  final double? remainingBalance;

  const WalletUsageWidget({
    super.key,
    required this.isWalletEnabled,
    required this.onWalletToggle,
    this.isLoading = false,
    this.walletAmountUsed,
    this.remainingBalance,
  });

  @override
  State<WalletUsageWidget> createState() => _WalletUsageWidgetState();
}

class _WalletUsageWidgetState extends State<WalletUsageWidget> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserWalletBloc, UserWalletState>(
      builder: (context, walletState) {
        double balance = 0.00;
        if (walletState is UserWalletLoaded && walletState.userWallet.isNotEmpty) {
          final wallet = walletState.userWallet.first;
          balance = double.tryParse(wallet.balance ?? '0.00') ?? 0.00;
        }

        return Container(
          padding: EdgeInsets.only(
            left: 12.0.w,
            right: 12.0.w,
            top: 12.h,
            bottom: 12.h,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: BlocBuilder<GetUserCartBloc, GetUserCartState>(
            builder: (context, cartState) {
              double usedBalance = 0.00;
              double remainingBalance = 0.00;

              if (cartState is GetUserCartLoaded) {
                usedBalance = widget.walletAmountUsed ??
                    double.parse(cartState.cartData.first.data!.paymentSummary!.walletAmountUsed!.toStringAsFixed(2));
                remainingBalance = widget.remainingBalance ??
                    (double.parse(cartState.cartData.first.data!.paymentSummary!.walletBalance!.toStringAsFixed(2)) -
                        usedBalance);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Use Wallet Balance',
                        style: TextStyle(
                          fontSize: isTablet(context) ? 24 : 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      cartState is GetUserCartLoading
                          ? const CustomCircularProgressIndicator()
                          : SizedBox(
                              height: 25,
                              child: Switch(
                                value: widget.isWalletEnabled,
                                onChanged: balance > 0.0
                                    ? (value) {
                                        widget.onWalletToggle(value);
                                      }
                                    : null,
                                materialTapTargetSize: MaterialTapTargetSize.padded,
                                activeThumbColor: AppTheme.primaryColor,
                              ),
                            ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Available Balance',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        '${AppConstant.currency}${balance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Wallet Amount Used',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        '${AppConstant.currency}${usedBalance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Remaining Wallet Balance',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        '${AppConstant.currency}${remainingBalance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  if (balance <= 0) ...[
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16.r,
                            color: Colors.orange[700],
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              'Insufficient wallet balance',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.orange[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }
}

