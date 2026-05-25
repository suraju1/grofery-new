import 'dart:io' as io;
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:grofery_user/config/constant.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:developer';
import 'bloc/settings_bloc/settings_bloc.dart';
import 'bloc/theme_bloc/theme_bloc.dart';
import 'bloc/language_bloc/language_bloc.dart';
import 'bloc/cart_state_bloc/cart_state_bloc.dart';
import 'model/user_cart_model/user_cart.dart';
import 'router/app_routes.dart';
import 'screens/address_list_page/bloc/check_delivery_zone_bloc/check_delivery_zone_bloc.dart';
import 'screens/address_list_page/bloc/get_address_list_bloc/get_address_list_bloc.dart';
import 'screens/auth/bloc/forgot_password/forgot_password_bloc.dart';
import 'screens/auth/bloc/user_verification/user_verification_bloc.dart';
import 'screens/cart_page/bloc/attachment/attachment_bloc.dart';
import 'screens/cart_page/bloc/cart_ui_bloc/cart_ui_bloc.dart';
import 'screens/cart_page/bloc/clear_cart/clear_cart_bloc.dart';
import 'screens/cart_page/bloc/get_user_cart/get_user_cart_bloc.dart';
import 'screens/cart_page/bloc/promo_code/promo_code_bloc.dart';
import 'screens/cart_page/bloc/remove_item_from_cart/remove_item_from_cart_bloc.dart';
import 'screens/cart_page/bloc/update_item_quantity/update_item_quantity_bloc.dart';
import 'screens/cart_page/bloc/validate_promo_code/validate_promo_code_bloc.dart';
import 'screens/category_list_page/bloc/all_category_bloc/all_category_bloc.dart';
import 'screens/my_orders/bloc/create_order/create_order_bloc.dart';
import 'screens/my_orders/bloc/delivery_boy_feedback/delivery_boy_feedback_bloc.dart';
import 'screens/my_orders/bloc/delivery_tracking/delivery_tracking_bloc.dart';
import 'screens/my_orders/bloc/download_invoice/download_invoice_bloc.dart';
import 'screens/my_orders/bloc/get_my_order/get_my_order_bloc.dart';
import 'screens/my_orders/bloc/order_detail/order_detail_bloc.dart';
import 'screens/my_orders/bloc/return_order_item/return_order_item_bloc.dart';
import 'screens/near_by_stores/bloc/near_by_store/near_by_store_bloc.dart';
import 'screens/near_by_stores/bloc/store_detail/store_detail_bloc.dart';
import 'screens/payment_options/bloc/payment_bloc.dart';
import 'screens/payment_options/repo/payment_repository.dart';
import 'screens/product_detail_page/bloc/product_faq_bloc/product_faq_bloc.dart';
import 'screens/product_detail_page/bloc/product_feedback/product_feedback_bloc.dart';
import 'screens/product_detail_page/bloc/product_review_bloc/product_review_bloc.dart';
import 'screens/product_detail_page/bloc/similar_product_bloc/similar_product_bloc.dart';
import 'screens/product_listing_page/bloc/filter/filter_bloc.dart';
import 'screens/product_listing_page/bloc/nested_category/nested_category_bloc.dart';
import 'screens/product_listing_page/bloc/product_listing/product_listing_bloc.dart';
import 'screens/save_for_later_page/bloc/save_for_later_bloc/save_for_later_bloc.dart';
import 'screens/seller_page/bloc/seller_feedback/seller_feedback_bloc.dart';
import 'screens/shopping_list_page/bloc/shopping_list_bloc/shopping_list_bloc.dart';
import 'screens/user_profile/bloc/user_profile_bloc/user_profile_bloc.dart';
import 'screens/wallet_page/bloc/prepare_wallet_recharge/prepare_recharge_bloc.dart';
import 'screens/wallet_page/bloc/user_wallet/user_wallet_bloc.dart';
import 'screens/wallet_page/bloc/wallect_transactions/wallet_transactions_bloc.dart';
import 'screens/wishlist_page/bloc/get_user_wishlist_bloc/get_user_wishlist_bloc.dart';
import 'screens/wishlist_page/bloc/wishlist_product_bloc/wishlist_product_bloc.dart';
import 'services/address/selected_address_hive.dart';
import 'services/location/user_location_hive.dart';
import 'services/shopping_list_hive.dart';
import 'services/user_cart/user_cart_local.dart';
import 'services/user_cart/user_cart_remote.dart';
import 'widgets/cart_state_listener.dart';
import 'screens/auth/bloc/auth/auth_bloc.dart';
import 'screens/cart_page/bloc/add_to_cart/add_to_cart_bloc.dart';
import 'screens/home_page/bloc/banner/banner_bloc.dart';
import 'screens/home_page/bloc/brands/brands_bloc.dart';
import 'screens/home_page/bloc/category/category_bloc.dart';
import 'screens/home_page/bloc/feature_section_product/feature_section_product_bloc.dart';
import 'screens/home_page/bloc/sub_category/sub_category_bloc.dart';
import 'screens/home_page/bloc/explore/explore_bloc.dart';
import 'screens/home_page/bloc/explore/explore_event.dart';
import 'screens/home_page/bloc/recommended_products/recommended_products_bloc.dart';
import 'screens/home_page/repo/recommended_products_repo.dart';
import 'screens/home_page/bloc/target_gift/target_gift_bloc.dart';
import 'screens/home_page/bloc/target_gift/target_gift_event.dart';
import 'screens/home_page/repo/target_gift_repo.dart';
import 'screens/product_detail_page/bloc/product_detail_bloc/product_detail_bloc.dart';
import 'bloc/user_cart_bloc/user_cart_bloc.dart';
import 'bloc/user_details_bloc/user_details_bloc.dart';
import 'config/global.dart';
import 'config/notification_service.dart';
import 'config/theme.dart';
import 'l10n/app_localizations.dart';
import 'model/tiered_pricing.dart';
import 'model/recent_product_model/recent_product_model.dart';
import 'model/user_cart_model/cart_sync_action.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  CachedNetworkImage.logLevel =
      CacheManagerLogLevel.none; // Suppress HTTP error logs
  await FastCachedImageConfig.init();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    if (!e.toString().contains('duplicate-app')) {
      rethrow;
    }
  }
  await Hive.initFlutter();

  Hive.registerAdapter(CartSyncActionAdapter());
  Hive.registerAdapter(UserCartAdapter());
  Hive.registerAdapter(RecentProductAdapter());
  Hive.registerAdapter(TieredPricingAdapter());
  await Hive.openBox<UserCart>('cartBox');

  await HiveLocationHelper.init();
  await HiveSelectedAddressHelper.init();
  await ShoppingListHiveHelper.init();
  await Global.initialize();
  await Global.initializePrefs();
  await Hive.openBox('themebox');

  // Initialize Google Sign-In (exactly once as required by the package)
  try {
    await GoogleSignIn.instance.initialize(
      serverClientId: AppConstant.serverClientId,
    );
    log('✅ Google Sign-In initialized');
  } catch (e) {
    log('❌ Google Sign-In initialization failed: $e');
  }

  if (kDebugMode) {
    io.HttpClient.enableTimelineLogging = true;
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Defer notification init until after the first frame so context is fully mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotification();
    });
  }

  Future<void> _initializeNotification() async {
    if (!mounted) return;
    // initFirebaseMessaging handles both permission request AND FCM token retrieval internally.
    // Do NOT call getFcmToken() here separately — it causes a concurrent requestPermission() crash.
    await NotificationService(context: context).initFirebaseMessaging(context);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => AuthBloc(UserDataBloc())),
        BlocProvider(
          create: (context) => CartBloc(
            CartLocalRepository(Hive.box<UserCart>('cartBox')),
            CartRemoteRepository(),
          ),
        ),
        BlocProvider(create: (context) => ThemeBloc()),
        BlocProvider(
          create: (context) => CategoryBloc(),
        ),
        BlocProvider(
          create: (context) => BannerBloc(),
        ),
        BlocProvider(
          create: (context) => LanguageBloc()..add(const LoadLanguage()),
        ),
        BlocProvider(
          create: (context) => FeatureSectionProductBloc(),
        ),
        BlocProvider(
          create: (context) => SubCategoryBloc(),
        ),
        BlocProvider(
          create: (context) =>
              RecommendedProductsBloc(RecommendedProductsRepository()),
        ),
        BlocProvider(
          create: (context) =>
              TargetGiftBloc(TargetGiftRepository())..add(FetchTargetGift()),
        ),
        BlocProvider(create: (context) => UserDataBloc()),
        BlocProvider(
          create: (context) => BrandsBloc(),
        ),
        BlocProvider(create: (context) => ProductDetailBloc()),
        BlocProvider(create: (context) => ProductListingBloc()),
        BlocProvider(create: (context) => NestedCategoryBloc()),
        BlocProvider(create: (context) => AddToCartBloc()),
        BlocProvider(
          create: (context) =>
              GetUserCartBloc(context.read<CartBloc>())..add(FetchUserCart()),
        ),
        BlocProvider(create: (context) => CartStateBloc()),
        BlocProvider(create: (context) => ProductReviewBloc()),
        BlocProvider(create: (context) => ProductFAQBloc()),
        BlocProvider(create: (context) => RemoveItemFromCartBloc()),
        BlocProvider(create: (context) => ClearCartBloc()),
        BlocProvider(create: (context) => UpdateItemQuantityBloc()), 
        BlocProvider(create: (context) => SimilarProductBloc()),
        BlocProvider(create: (context) => CheckDeliveryZoneBloc()),
        BlocProvider(create: (context) => GetAddressListBloc()),
        BlocProvider(
          create: (context) =>
              SettingsBloc()..add(FetchSettingsData(context: context)),
        ),
        BlocProvider(create: (context) => CreateOrderBloc()),
        BlocProvider(
          create: (context) => UserProfileBloc()..add(FetchUserProfile()),
        ),
        BlocProvider(create: (context) => PromoCodeBloc()),
        BlocProvider(create: (context) => GetMyOrderBloc()),
        BlocProvider(create: (context) => OrderDetailBloc()),
        BlocProvider(create: (context) => DeliveryBoyFeedbackBloc()),
        BlocProvider(
          create: (context) => PaymentBloc(
            paymentRepository: PaymentRepository(),
            context: context,
          ),
        ),
        BlocProvider(create: (context) => DownloadInvoiceBloc()),
        BlocProvider(create: (context) => PrepareRechargeBloc()),
        BlocProvider(create: (context) => UserWalletBloc()),
        BlocProvider(create: (context) => WalletTransactionsBloc()),
        BlocProvider(create: (context) => UserVerificationBloc()),
        BlocProvider(create: (context) => ShoppingListBloc()),
        BlocProvider(create: (context) => UserWishlistBloc()),
        BlocProvider(create: (context) => WishlistProductBloc()),
        BlocProvider(create: (context) => SaveForLaterBloc()),
        BlocProvider(create: (context) => NearByStoreBloc()),
        BlocProvider(create: (context) => ProductFeedbackBloc()),
        BlocProvider(create: (context) => SellerFeedbackBloc()),
        BlocProvider(create: (context) => ReturnOrderItemBloc()),
        BlocProvider(create: (context) => DeliveryTrackingBloc()),
        BlocProvider(create: (context) => StoreDetailBloc()),
        BlocProvider(create: (context) => ForgotPasswordBloc()),
        BlocProvider(create: (context) => CartUIBloc()),
        BlocProvider(create: (context) => AllCategoriesBloc()),
        BlocProvider(create: (context) => ValidatePromoCodeBloc()),
        BlocProvider(create: (context) => AttachmentBloc()),
        BlocProvider(create: (context) => FilterBloc()),
        BlocProvider(
          create: (context) => ExploreBloc()..add(const FetchExplores()),
        ),
      ],
      child: CartStateListener(
        child: BlocBuilder<ThemeBloc, ThemeMode>(
          builder: (BuildContext context, themeMode) {
            return BlocBuilder<LanguageBloc, LanguageState>(
              builder: (context, languageState) {
                return GestureDetector(
                  onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                  child: ScreenUtilInit(
                    child: SafeArea(
                      top: false,
                      bottom: Platform.isIOS ? false : true,
                      left: false,
                      right: false,
                      child: MaterialApp.router(
                        debugShowCheckedModeBanner: false,
                        theme: AppTheme.lightTheme,
                        darkTheme: AppTheme.darkTheme,
                        themeMode: themeMode,
                        builder: FToastBuilder(),
                        routerConfig: MyAppRoute.router,
                        localizationsDelegates:
                            AppLocalizations.localizationsDelegates,
                        supportedLocales: AppLocalizations.supportedLocales,
                        locale: languageState is LanguageLoaded
                            ? languageState.locale
                            : const Locale('en'),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
