import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:grofery_user/router/app_routes.dart';
import 'package:grofery_user/screens/my_orders/bloc/get_my_order/get_my_order_bloc.dart';
import 'package:grofery_user/screens/my_orders/bloc/get_my_order/get_my_order_event.dart';
import 'package:grofery_user/screens/my_orders/bloc/get_my_order/get_my_order_state.dart';
import 'package:grofery_user/screens/my_orders/model/my_order_model.dart';
import 'package:grofery_user/screens/my_orders/repo/order_repo.dart';
import 'package:grofery_user/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:grofery_user/utils/widgets/custom_refresh_indicator.dart';
import 'package:grofery_user/utils/widgets/custom_scaffold.dart';
import 'package:grofery_user/utils/widgets/empty_states_page.dart';
import 'package:grofery_user/config/constant.dart';
import 'package:grofery_user/l10n/app_localizations.dart';
import 'package:grofery_user/bloc/user_cart_bloc/user_cart_bloc.dart';
import 'package:grofery_user/bloc/user_cart_bloc/user_cart_event.dart';
import 'package:grofery_user/model/user_cart_model/user_cart.dart';
import 'package:grofery_user/model/user_cart_model/cart_sync_action.dart';
import 'package:grofery_user/services/address/selected_address_hive.dart';
import '../widgets/my_order_card.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  @override
  void initState() {
    super.initState();
    context.read<GetMyOrderBloc>().add(FetchMyOrder());
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: CustomScaffold(
        showViewCart: false,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        appBar: AppBar(
          title: Text(
            'Orders',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontSize: isTablet(context) ? 26 : 22.sp,
            ),
          ),
          automaticallyImplyLeading: true,
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(48.h),
            child: Container(
              color: Colors.white,
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: const Color(0xFFE91E63),
                labelColor: const Color(0xFFE91E63),
                unselectedLabelColor: Colors.grey[600],
                indicatorSize: TabBarIndicatorSize.label,
                indicatorWeight: 3.h,
                labelStyle: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(text: "All"),
                  Tab(text: "Paid Orders"),
                  Tab(text: "Unpaid Orders"),
                ],
              ),
            ),
          ),
        ),
        body: BlocBuilder<GetMyOrderBloc, GetMyOrderState>(
          builder: (context, state) {
            if (state is GetMyOrderLoading) {
              return const Center(
                child: CustomCircularProgressIndicator(),
              );
            } else if (state is GetMyOrderLoaded) {
              final allOrders = state.myOrderData;
              final paidOrders = state.myOrderData
                  .where((o) => o.paymentStatus?.toLowerCase() == 'paid')
                  .toList();
              final unpaidOrders = state.myOrderData
                  .where((o) => o.paymentStatus?.toLowerCase() != 'paid')
                  .toList();

              return TabBarView(
                children: [
                  _buildOrderList(allOrders, state),
                  _buildOrderList(paidOrders, state),
                  _buildOrderList(unpaidOrders, state),
                ],
              );
            } else if (state is GetMyOrderFailed) {
              return NoOrderPage(
                onRetry: () {
                  context.read<GetMyOrderBloc>().add(FetchMyOrder());
                },
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildOrderList(List<MyOrdersData> orders, GetMyOrderLoaded state) {
    final l10n = AppLocalizations.of(context);
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              l10n?.noOrdersYet ?? 'No orders yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    return CustomRefreshIndicator(
      onRefresh: () async {
        context.read<GetMyOrderBloc>().add(FetchMyOrder());
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (scrollInfo is ScrollUpdateNotification &&
              !state.hasReachedMax &&
              scrollInfo.metrics.pixels >=
                  scrollInfo.metrics.maxScrollExtent - 50) {
            context.read<GetMyOrderBloc>().add(
                  FetchMoreMyOrder(),
                );
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: state.hasReachedMax ? orders.length : orders.length + 1,
          itemBuilder: (context, index) {
            if (index >= orders.length) {
              return SizedBox(
                height: 80,
                child: CustomCircularProgressIndicator(),
              );
            }
            final order = orders[index];
            return GestureDetector(
              onTap: () {
                GoRouter.of(context).push(
                  AppRoutes.orderDetail,
                  extra: {'order-slug': order.slug},
                );
              },
              child: OrderDeliveryCard(
                order: order,
                onRateOrder: () {
                  final storeMap = {
                    "orderSlug": order.slug,
                    "orderId": order.id,
                  };

                  GoRouter.of(context).push(
                    AppRoutes.rateYourExp,
                    extra: storeMap,
                  );
                },
                onTrackOrder: () {
                  GoRouter.of(context).push(AppRoutes.deliveryTracking,
                      extra: {'order-slug': order.slug});
                },
                onReorder: () async {
                  if (order.id == null) return;

                  final selectedAddress = HiveSelectedAddressHelper.getSelectedAddress();
                  if (selectedAddress == null || selectedAddress.id == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select a delivery address first.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CustomCircularProgressIndicator(),
                    ),
                  );

                  try {
                    final repo = OrderRepository();
                    final res = await repo.reorder(
                      orderSlug: order.slug!,
                      addressId: selectedAddress.id!,
                      paymentType: order.paymentMethod ?? 'cod',
                      useWallet: false,
                      rushDelivery: order.fulfillmentType?.toLowerCase().contains('express') ?? false,
                    );
                    
                    if (context.mounted) {
                      Navigator.pop(context); // Close dialog
                      
                      if (res['success'] == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(res['message'] ?? 'Items added to cart successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        // Refresh the cart
                        context.read<CartBloc>().add(LoadCart());
                        
                        // Navigate to the cart screen
                        GoRouter.of(context).push(AppRoutes.cart);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(res['message'] ?? 'Failed to reorder'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context); // Close dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }
}