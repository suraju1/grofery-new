import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:grofery_user/model/user_cart_model/user_cart.dart';
import 'package:grofery_user/model/tiered_pricing.dart';
import '../../model/user_cart_model/cart_sync_action.dart';

class CartLocalRepository {
  final Box<UserCart> box;

  CartLocalRepository(this.box);

  Object _resolveBoxKey(String cartKey) {
    if (box.containsKey(cartKey)) return cartKey;

    for (final key in box.keys) {
      final item = box.get(key);
      if (item?.cartKey == cartKey) return key;
    }

    return cartKey;
  }

  List<UserCart> getAllItems() {
    log('[LOCAL] Fetching all cart items ${box.values.length}');
    final items = box.values.toList();
    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  List<UserCart> getPendingSyncItems() {
    final pending = <UserCart>[];
    for (var key in box.keys) {
      final item = box.get(key, defaultValue: null);
      if (item != null && item.syncAction != CartSyncAction.none) {
        pending.add(item);
      }
    }
    debugPrint('[LOCAL] Pending sync items: ${pending.length}');
    return pending;
  }

  void addItem(UserCart item) {
    debugPrint(
        '[LOCAL] ADD → ${item.productId}-${item.variantId} qty:${item.quantity}');
    box.put(
      item.cartKey,
      item.copyWith(
        syncAction: CartSyncAction.add,
        price: _calculateEffectivePrice(
            item.quantity, item.tieredPricing, item.price),
      ),
    );
  }

  double _calculateEffectivePrice(
      int quantity, List<TieredPricing>? tieredPricing, double fallbackPrice) {
    if (tieredPricing == null || tieredPricing.isEmpty) return fallbackPrice;

    TieredPricing? applicableTier;
    for (var tier in tieredPricing) {
      if (quantity >= tier.minQty) {
        applicableTier = tier;
      } else {
        break;
      }
    }
    return applicableTier != null
        ? (applicableTier.price / applicableTier.minQty)
        : fallbackPrice;
  }

  void updateQuantity(String cartKey, int quantity) {
    final boxKey = _resolveBoxKey(cartKey);
    final item = box.get(boxKey);
    if (item == null) {
      debugPrint('[LOCAL] updateQuantity → Item not found: $cartKey');
      return;
    }

    debugPrint(
        '[LOCAL] BEFORE UPDATE → serverCartItemId: ${item.serverCartItemId}');

    CartSyncAction syncAction;
    if (item.serverCartItemId != null) {
      syncAction = CartSyncAction.update;
    } else if (item.syncAction == CartSyncAction.none) {
      syncAction = CartSyncAction.add;
    } else {
      syncAction = item.syncAction;
    }

    final newPrice =
        _calculateEffectivePrice(quantity, item.tieredPricing, item.price);

    final updatedItem = item.copyWith(
      quantity: quantity,
      price: newPrice,
      syncAction: syncAction,
      serverCartItemId: item.serverCartItemId,
    );

    box.put(item.cartKey, updatedItem);
    if (boxKey != item.cartKey) {
      box.delete(boxKey);
    }

    final verify = box.get(item.cartKey);
    debugPrint(
        '[LOCAL] AFTER UPDATE → $cartKey → qty: $quantity, syncAction: $syncAction, serverCartItemId: ${verify?.serverCartItemId}');
  }

  void addItemGuest(UserCart item) {
    debugPrint('[LOCAL] GUEST ADD → ${item.productId}-${item.variantId}');
    box.put(
      item.cartKey,
      item.copyWith(
        syncAction: CartSyncAction.none,
        isSynced: false,
        price: _calculateEffectivePrice(
            item.quantity, item.tieredPricing, item.price),
      ),
    );
  }

  void updateQuantityGuest(String cartKey, int quantity) {
    final boxKey = _resolveBoxKey(cartKey);
    final item = box.get(boxKey);
    if (item == null) return;

    final newPrice =
        _calculateEffectivePrice(quantity, item.tieredPricing, item.price);
    final updatedItem = item.copyWith(
      quantity: quantity,
      syncAction: CartSyncAction.none,
    );
    updatedItem.price = newPrice;

    box.put(item.cartKey, updatedItem);
    if (boxKey != item.cartKey) {
      box.delete(boxKey);
    }
  }

  void removeItemGuest(String cartKey) {
    box.delete(_resolveBoxKey(cartKey));
  }

  void markForUpdate(String cartKey) {
    printAllHiveData();
    final boxKey = _resolveBoxKey(cartKey);
    final item = box.get(boxKey);
    if (item == null) {
      debugPrint('[LOCAL] markForUpdate → Item not found: $cartKey');
      return;
    }

    if (item.serverCartItemId == null) {
      debugPrint(
          '[LOCAL] markForUpdate → Skipping (not yet added to server): $cartKey');
      return;
    }

    box.put(
      item.cartKey,
      item.copyWith(syncAction: CartSyncAction.update),
    );
    if (boxKey != item.cartKey) {
      box.delete(boxKey);
    }
    debugPrint(
        '[LOCAL] MARKED FOR UPDATE → $cartKey (qty: ${item.quantity}, serverCartItemId: ${item.serverCartItemId})');
  }

  void markForDelete(String cartKey) {
    final boxKey = _resolveBoxKey(cartKey);
    final item = box.get(boxKey);
    if (item == null) {
      debugPrint('[LOCAL] markForDelete → Item not found: $cartKey');
      return;
    }

    if (item.serverCartItemId != null ||
        item.syncAction == CartSyncAction.add ||
        item.syncAction == CartSyncAction.update) {
      box.put(
        item.cartKey,
        item.copyWith(syncAction: CartSyncAction.delete),
      );
      if (boxKey != item.cartKey) {
        box.delete(boxKey);
      }
      debugPrint(
          '🛒 LOCAL MARKED FOR DELETE → $cartKey (pending state or server ID present)');
    } else {
      box.delete(boxKey);
      debugPrint('🛒 LOCAL DELETE (no server sync needed) → $cartKey');
    }
  }

  void deleteLocally(String cartKey) {
    final boxKey = _resolveBoxKey(cartKey);
    final item = box.get(boxKey);
    if (item == null) {
      debugPrint('[LOCAL] deleteLocally → Item not found: $cartKey');
      return;
    }
    box.delete(boxKey);
    debugPrint('🛒 LOCAL DELETE (no server sync needed) → $cartKey');
  }

  void clearLocalCart() {
    debugPrint('🧹 LOCAL CLEAR CART → before: ${box.length} items');
    box.clear();
    box.flush();
    debugPrint('🧹 LOCAL CLEAR CART → after: ${box.length} items');
  }

  void clearSyncedItems() {
    debugPrint('🧹 LOCAL CLEAR SYNCED ITEMS → before: ${box.length} items');
    final keysToDelete = <dynamic>[];
    for (var key in box.keys) {
      final item = box.get(key);
      if (item != null && item.syncAction == CartSyncAction.none) {
        keysToDelete.add(key);
      }
    }
    for (var key in keysToDelete) {
      box.delete(key);
    }
    box.flush();
    debugPrint('🧹 LOCAL CLEAR SYNCED ITEMS → after: ${box.length} items');
  }

  void markAllForDelete() {
    debugPrint('🧹 LOCAL MARK ALL FOR DELETE');
    final allItems = box.values.toList();

    for (final item in allItems) {
      final boxKey = _resolveBoxKey(item.cartKey);
      if (item.serverCartItemId != null) {
        box.put(
          item.cartKey,
          item.copyWith(syncAction: CartSyncAction.delete),
        );
        if (boxKey != item.cartKey) {
          box.delete(boxKey);
        }
      } else {
        box.delete(boxKey);
      }
    }

    debugPrint(
        '🧹 Marked ${allItems.where((i) => i.serverCartItemId != null).length} items for server deletion');
    debugPrint(
        '🧹 Deleted ${allItems.where((i) => i.serverCartItemId == null).length} local-only items');
  }

  void markSynced(String cartKey, {int? serverCartItemId}) {
    log('Server Cart Item Id $serverCartItemId');
    final boxKey = _resolveBoxKey(cartKey);
    final item = box.get(boxKey);
    if (item == null) {
      debugPrint('[LOCAL] markSynced → Item not found: $cartKey');
      return;
    }

    CartSyncAction currentAction = item.syncAction;
    CartSyncAction newAction = CartSyncAction.none;
    if (currentAction == CartSyncAction.delete) {
      newAction = CartSyncAction.delete;
    } else if (currentAction == CartSyncAction.update) {
      newAction = CartSyncAction.update;
    }

    final updatedItem = item.copyWith(
      serverCartItemId: serverCartItemId ?? item.serverCartItemId,
      syncAction: newAction,
    );

    box.put(item.cartKey, updatedItem);
    if (boxKey != item.cartKey) {
      box.delete(boxKey);
    }
    final verify = box.get(item.cartKey);
    debugPrint(
        '[VERIFY SAVE] serverCartItemId after put: ${verify?.serverCartItemId}');
  }

  void removeLocal(String cartKey) {
    debugPrint('[LOCAL] REMOVED → $cartKey');
    box.delete(_resolveBoxKey(cartKey));
  }

  List<Map<String, dynamic>> createSyncPayload() {
    final items = box.values.toList();
    final payload = items.map((item) {
      return {
        'store_id': int.tryParse(item.vendorId) ?? 0,
        'product_variant_id': int.tryParse(item.variantId) ?? 0,
        'quantity': item.quantity,
      };
    }).toList();
    debugPrint('[LOCAL] Created sync payload with ${payload.length} items');
    return payload;
  }

  UserCart? getItemByKey(String cartKey) {
    return box.get(_resolveBoxKey(cartKey));
  }

  void printAllHiveData() {
    debugPrint('=== HIVE CART DATA START ===');
    if (box.isEmpty) {
      debugPrint('Box is EMPTY');
    } else {
      for (final key in box.keys) {
        final item = box.get(key);
        debugPrint('Key: $key');
        debugPrint('Value: ${item?.serverCartItemId}');
        debugPrint('---');
      }
    }
    debugPrint('Total items: ${box.length}');
    debugPrint('=== HIVE CART DATA END ===');
  }

  void syncServerCartToLocal(List<dynamic> serverCartItems) {
    try {
      debugPrint('🔄 SYNCING SERVER CART TO LOCAL');
      debugPrint('📦 Server items count: ${serverCartItems.length}');
      debugPrint('📦 Local items count BEFORE sync: ${box.length}');

      if (!box.isOpen) {
        debugPrint('❌ Hive box is not open! Cannot sync.');
        return;
      }

      final serverItemsMap = <String, dynamic>{};
      for (final serverItem in serverCartItems) {
        final variantId = serverItem['product_variant_id']?.toString() ?? '';
        final storeId = serverItem['store_id']?.toString() ?? '';
        final productId = serverItem['product_id']?.toString() ?? '';

        if (variantId.isNotEmpty &&
            storeId.isNotEmpty &&
            productId.isNotEmpty) {
          final cartKey = '${productId}_${variantId}_$storeId';
          serverItemsMap[cartKey] = serverItem;
          debugPrint('🔑 Server item mapped: $cartKey');
        } else {
          debugPrint(
              '⚠️ Skipping server item with missing IDs: productId=$productId, variantId=$variantId, storeId=$storeId');
        }
      }

      debugPrint('📊 Server items mapped: ${serverItemsMap.length}');

      final localItems = box.values.toList();
      debugPrint('📊 Local items found: ${localItems.length}');

      int updated = 0;
      int added = 0;
      int removed = 0;
      int skipped = 0;

      for (final entry in serverItemsMap.entries) {
        final cartKey = entry.key;
        final serverItem = entry.value;

        final serverCartItemId = serverItem['id'] as int?;
        final serverQuantity = serverItem['quantity'] as int? ?? 1;

        final boxKey = _resolveBoxKey(cartKey);
        final localItem = box.get(boxKey);

        if (localItem != null) {
          debugPrint(
              '📍 Found local item: $cartKey (serverCartItemId: ${localItem.serverCartItemId}, qty: ${localItem.quantity}, syncAction: ${localItem.syncAction})');

          if (localItem.syncAction != CartSyncAction.none) {
            debugPrint(
                '⏭️ SKIPPED: $cartKey (has pending sync action: ${localItem.syncAction})');
            skipped++;
            continue;
          }

          if (localItem.serverCartItemId != serverCartItemId ||
              localItem.quantity != serverQuantity) {
            box.put(
              cartKey,
              localItem.copyWith(
                quantity: serverQuantity,
                serverCartItemId: serverCartItemId,
                syncAction: CartSyncAction.none,
              ),
            );
            if (boxKey != cartKey) {
              box.delete(boxKey);
            }
            updated++;
            debugPrint(
                '✏️ UPDATED: $cartKey → qty: $serverQuantity, serverId: $serverCartItemId');
          } else {
            if (boxKey != cartKey) {
              box.put(cartKey, localItem);
              box.delete(boxKey);
            }
            debugPrint('✓ NO CHANGE: $cartKey (already in sync)');
          }
        } else {
          debugPrint('🆕 Creating new local item: $cartKey');
          final newItem = _createUserCartFromServer(serverItem);
          if (newItem != null) {
            box.put(cartKey, newItem);
            added++;
            debugPrint(
                '➕ ADDED: $cartKey → qty: $serverQuantity, serverId: $serverCartItemId');
          } else {
            debugPrint('❌ Failed to create item: $cartKey');
          }
        }
      }

      for (final localItem in localItems) {
        if (!serverItemsMap.containsKey(localItem.cartKey)) {
          if (localItem.syncAction != CartSyncAction.none) {
            debugPrint(
                '⏭️ KEEPING: ${localItem.cartKey} (has pending action: ${localItem.syncAction})');
            skipped++;
          } else if (localItem.serverCartItemId != null) {
            // Removed TEMP FIX to ensure items deleted on server are deleted locally
            debugPrint(
                '🗑️ SERVER ITEM MISSING, REMOVING LOCAL ITEM → ${localItem.cartKey}');
            box.delete(_resolveBoxKey(localItem.cartKey));
            removed++;
          } else {
            // ✅ Naya unsynced item → KEEP karo, delete mat karo
            debugPrint(
                '⏭️ KEEPING new unsynced item: ${localItem.cartKey} (not yet sent to server)');
            skipped++;
          }
        }
      }

      debugPrint(
          '✅ SYNC COMPLETE → Added: $added, Updated: $updated, Removed: $removed, Skipped: $skipped');
      debugPrint('📊 Total local items AFTER sync: ${box.length}');

      printAllHiveData();
    } catch (e, stackTrace) {
      debugPrint('❌ CRITICAL ERROR in syncServerCartToLocal: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  UserCart? _createUserCartFromServer(dynamic serverItem) {
    try {
      List<TieredPricing> tiers = [];
      if (serverItem['tiered_pricing'] != null) {
        serverItem['tiered_pricing'].forEach((v) {
          tiers.add(TieredPricing.fromJson(v));
        });
        tiers.sort((a, b) => a.minQty.compareTo(b.minQty));
      }

      final specialPrice =
          (serverItem['special_price'] as num?)?.toDouble() ?? 0.0;
      final originalPrice =
          (serverItem['price'] as num?)?.toDouble() ?? specialPrice;
      final stock = int.tryParse(serverItem['stock']?.toString() ?? '0') ?? 0;

      return UserCart(
        productId: serverItem['product_id']?.toString() ?? '',
        variantId: serverItem['product_variant_id']?.toString() ?? '',
        variantName: serverItem['variant_name']?.toString() ?? '',
        vendorId: serverItem['store_id']?.toString() ?? '',
        name: serverItem['product_name']?.toString() ?? '',
        image: serverItem['image']?.toString() ?? '',
        price: specialPrice,
        originalPrice: originalPrice,
        quantity: serverItem['quantity'] as int? ?? 1,
        minQty: 1,
        maxQty: 25,
        isOutOfStock: stock <= 0,
        isSynced: true,
        serverCartItemId:
            serverItem['id'] as int?, // ✅ FIX: 'cart_item_id' → 'id'
        syncAction: CartSyncAction.none,
        updatedAt: DateTime.now(),
        tieredPricing: tiers.isNotEmpty ? tiers : null,
      );
    } catch (e) {
      debugPrint('❌ Error creating UserCart from server: $e');
      return null;
    }
  }
}
