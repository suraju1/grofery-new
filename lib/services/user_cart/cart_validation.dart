import 'package:flutter/material.dart';
import '../../config/settings_data_instance.dart';
import '../../config/constant.dart';
import '../../l10n/app_localizations.dart';

class CartValidation {
  CartValidation._();

  /// PRODUCT-LEVEL VALIDATIONS
  /// Used when adding/updating a single product in cart
  static String? validateProductAddToCart({
    required BuildContext context,
    required int requestedQuantity,
    required int minQty,
    required int maxQty,
    required int stock,
    bool isStoreOpen = true,
  }) {
    final l10n = AppLocalizations.of(context)!;

    // Out of stock (stock < 0 means truly unavailable; stock == 0 means unlimited/not tracked)
    if (stock < 0) {
      return l10n.outOfStock;
    }

    // Store closed
    if (!isStoreOpen) {
      return l10n.looksLikeTheStoreCatchingSomeRest;
    }

    // Below minimum quantity
    if (requestedQuantity < minQty) {
      return l10n.minimumQuantityRequired(minQty);
    }

    // Exceeds max allowed per product (skip check if maxQty is 0 = no limit set)
    if (maxQty > 0 && requestedQuantity > maxQty) {
      return l10n.maximumQuantityAllowed(maxQty);
    }

    // Exceeds available stock (skip check if stock is 0 = unconstrained)
    if (stock > 0 && requestedQuantity > stock) {
      return l10n.onlyXItemsInStock(stock);
    }

    return null; // Valid
  }

  static String? validateBeforeAddToCart({
    required BuildContext context,
    required int currentUniqueItemsCount,     // count of unique products already in cart
    required bool isNewItem,                  // true if this product is not already in the cart
    required Set<int> currentStoreIdsInCart,  // set of store IDs already present in cart
    required int thisProductStoreId,          // store ID of the product being added
  }) {
    final l10n = AppLocalizations.of(context)!;
    final system = SettingsData.instance.system!;

    // 1. Check maximum items allowed in cart (global limit on unique products)
    if (isNewItem) {
      final newTotalUniqueCount = currentUniqueItemsCount + 1;
      if (newTotalUniqueCount > system.maximumItemsAllowedInCart) {
        final remaining = system.maximumItemsAllowedInCart - currentUniqueItemsCount;
        if (remaining <= 0) {
          return l10n.youHaveReachedMaximumLimitOfTheCart;
        }
        return l10n.cannotAddMoreThanXItems(remaining);
      }
    }

    if (currentStoreIdsInCart.isNotEmpty) {
      if (system.checkoutType == 'single_store' &&
          currentStoreIdsInCart.first != thisProductStoreId) {
        return l10n.onlyOneStoreAtATime;
      }
    }

    return null;
  }

  /// CART-LEVEL VALIDATIONS
  /// Used before checkout or when showing warnings
  static String? validateCartForCheckout({
    required BuildContext context,
    required double cartTotal,
    required int uniqueItemsCount,            // count of unique products in cart
    required Set<int> storeIds,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final system = SettingsData.instance.system!;

    // Minimum cart amount
    const double minAmount = AppConstant.minimumOrderValue;
    if (cartTotal < minAmount) {
      return l10n.minimumCartAmountRequired(minAmount - cartTotal, minAmount);
    }

    // Maximum items in cart (unique line items)
    if (uniqueItemsCount > system.maximumItemsAllowedInCart) {
      return l10n.youHaveReachedMaximumLimitOfTheCart;
    }

    // Multi-store restriction (if your app supports only single store)
    if (system.checkoutType == 'single_store' && storeIds.length > 1) {
      return l10n.onlyOneStoreAtATime;
    }

    return null;
  }

  /// Helper: Get user-friendly stock message (not error, just info)
  static String getStockMessage({
    required int stock,
    required BuildContext context,
  }) {
    final l10n = AppLocalizations.of(context)!;

    if (stock <= 0) {
      return l10n.outOfStock;
    } else if (stock <= 5) {
      return l10n.onlyFewLeft(stock);
    }
    return l10n.inStock;
  }
}