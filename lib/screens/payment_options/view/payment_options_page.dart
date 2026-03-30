import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:grofery_user/screens/user_profile/bloc/user_profile_bloc/user_profile_bloc.dart';
import 'package:grofery_user/config/constant.dart';
import 'package:grofery_user/config/payment_config.dart';
import 'package:grofery_user/config/theme.dart';
import 'package:grofery_user/utils/widgets/custom_scaffold.dart';
import 'package:grofery_user/l10n/app_localizations.dart';

class PaymentOptionsPage extends StatefulWidget {
  final double totalAmount;
  final bool? isFromAddMoney;

  const PaymentOptionsPage({
    super.key,
    required this.totalAmount,
    this.isFromAddMoney = false
  });

  @override
  State<PaymentOptionsPage> createState() => _PaymentOptionsPageState();
}

class _PaymentOptionsPageState extends State<PaymentOptionsPage> {

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      showViewCart: false,
      appBar: AppBar(
        title: Text(
          'Payment Options',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            size: 20.sp,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Payment Summary
          _buildPaymentSummary(),
          // Payment Options
          Expanded(
            child: BlocBuilder<UserProfileBloc, UserProfileState>(
              builder: (context, profileState) {
                String? walletBalance;
                if (profileState is UserProfileLoaded) {
                  walletBalance = profileState.userData.data?.walletBalance?.toString();
                }

                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Online Payment Methods
                      _buildPaymentSection(
                        title: AppLocalizations.of(context)!.paymentMethod,
                        methods: PaymentConfig.allPaymentMethods,
                        showAddIcon: false,
                        walletBalance: walletBalance,
                      ),
                      SizedBox(height: 16.h),
                      // Unavailable payment method message
                      // _buildUnavailableMessage(),
                      SizedBox(height: 20.h), // Bottom spacing
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary() {
    return Container(
      margin: EdgeInsets.only(
        bottom: 16.w
      ),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            AppLocalizations.of(context)!.toPay,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 10.w,),
          Text(
            '${AppConstant.currency}${widget.totalAmount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection({
    required String title,
    required List<PaymentMethod> methods,
    required bool showAddIcon,
    String? walletBalance,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onPrimary,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: methods.asMap().entries.map((entry) {
              final index = entry.key;
              final method = entry.value;
              final isLast = index == methods.length - 1;

              return _buildPaymentOption(
                method: method,
                showAddIcon: showAddIcon,
                isLast: isLast,
                walletBalance: walletBalance,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption({
    required PaymentMethod method,
    required bool showAddIcon,
    required bool isLast,
    String? walletBalance,
  }) {
    final isEnabled = PaymentConfig.isPaymentMethodEnabledInSettings(method.id);
    final isFromAddMoney = widget.isFromAddMoney ?? false;

    // Filter out COD when adding money to wallet
    if (method.type == PaymentMethodType.cod && isFromAddMoney) {
      return const SizedBox.shrink();
    }

    String? subtitleText;
    if (method.type == PaymentMethodType.wallet && walletBalance != null) {
      subtitleText = '${AppLocalizations.of(context)!.balance}: ${AppConstant.currency}$walletBalance';
    } else if (!isEnabled) {
      subtitleText = AppLocalizations.of(context)!.currentlyUnavailable;
    }

    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        leading: SizedBox(
          width: 35.w,
          height: 35.w,
          child: Opacity(
            opacity: isEnabled ? 1.0 : 0.5,
            child: method.getDisplayWidget(size: 20.sp),
          ),
        ),
        title: Text(
          method.name,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: isEnabled ? Theme.of(context).colorScheme.tertiary : Colors.grey[600],
          ),
        ),
        subtitle: subtitleText != null
            ? Text(
          subtitleText,
          style: TextStyle(
            fontSize: 12.sp,
            color: isEnabled ? AppTheme.primaryColor : Colors.grey[500],
            fontStyle: isEnabled ? FontStyle.normal : FontStyle.italic,
            fontWeight: isEnabled && method.type == PaymentMethodType.wallet ? FontWeight.w600 : FontWeight.normal,
          ),
        )
            : null,
        trailing: showAddIcon
            ? Container(
          width: 24.w,
          height: 24.w,
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(
            Icons.add,
            color: Colors.white,
            size: 16.sp,
          ),
        )
            : isEnabled
            ? Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey[400],
          size: 16.sp,
        )
            : Icon(
          Icons.block,
          color: Colors.grey[400],
          size: 16.sp,
        ),
        onTap: isEnabled && !showAddIcon
            ? () {
          Navigator.pop(context, method.type);
        }
            : null,
      ),
    );
  }
}