
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grofery_user/screens/wishlist_page/model/user_wishlist_model.dart';
import 'package:grofery_user/screens/wishlist_page/repo/wishlist_repo.dart';
import 'get_user_wishlist_state.dart';
part 'get_user_wishlist_event.dart';

class UserWishlistBloc extends Bloc<UserWishlistEvent, UserWishlistState> {
  UserWishlistBloc() : super(UserWishlistInitial()) {
    on<GetUserWishlistRequest>(_onGetUserWishlistRequest);
    on<GetMoreUserWishlistRequest>(_onGetMoreUserWishlistRequest);
    on<CreateNewWishlist>(_onCreateNewWishlist);
    on<AddItemInWishlist>(_onAddItemInWishlist);
    on<UpdateUserWishlist>(_onUpdateUserWishlist);
    on<DeleteWishlist>(_onDeleteWishlist);
    on<RemoveItemFromWishlist>(_onRemoveItemFromWishlist);
    on<MoveItemToAnotherWishlist>(_onMoveItemToAnotherWishlist);
    on<OptimisticAddToWishlist>(_onOptimisticAddToWishlist);
    on<OptimisticRemoveFromWishlist>(_onOptimisticRemoveFromWishlist);

  }

  final UserWishlistRepository repository = UserWishlistRepository();
  int currentPage = 0;
  int perPage = 48;
  int? lastPage;
  bool hasReachedMax = false;
  bool isLoadingMore = false;
  bool loadMore = false;
  
  // Local cache for optimistic updates: Map<productId_productVariantId_storeId, wishlistItemId>
  // If value is null, product is not wishlisted. If value is non-null, product is wishlisted.
  final Map<String, int?> _localWishlistCache = {};
  
  // Track pending operations: Set of cache keys for add operations, Set of itemIds for remove operations
  final Set<String> _pendingAddOperations = {}; // Format: "productId_productVariantId_storeId_wishlistTitle"
  final Set<int> _pendingRemoveOperations = {}; // itemIds
  
  // Track operation IDs per product to handle race conditions
  final Map<String, int> _productOperationId = {};
  
  int _getNextOperationId(int productId, int productVariantId, int storeId) {
    final key = _getCacheKey(productId, productVariantId, storeId);
    final nextId = (_productOperationId[key] ?? 0) + 1;
    _productOperationId[key] = nextId;
    return nextId;
  }

  bool _isOperationStale(int productId, int productVariantId, int storeId, int operationId) {
    final key = _getCacheKey(productId, productVariantId, storeId);
    return (_productOperationId[key] ?? 0) > operationId;
  }
  
  // Check if an add operation is pending for a product in a specific wishlist
  bool isAddOperationPending(int productId, int productVariantId, int storeId, String wishlistTitle) {
    final key = '${_getCacheKey(productId, productVariantId, storeId)}_$wishlistTitle';
    return _pendingAddOperations.contains(key);
  }
  
  // Check if a remove operation is pending for an item
  bool isRemoveOperationPending(int itemId) {
    return _pendingRemoveOperations.contains(itemId);
  }
  
  // Helper method to generate cache key
  String _getCacheKey(int productId, int productVariantId, int storeId) {
    return '${productId}_${productVariantId}_$storeId';
  }
  
  // Public method to check if product is wishlisted (checks both server state and local cache)
  bool isProductWishlisted(int productId, int productVariantId, int storeId) {
    final cacheKey = _getCacheKey(productId, productVariantId, storeId);
    
    // Check local cache (O(1) lookup)
    // If it's in the cache and NOT null, it's wishlisted
    return _localWishlistCache[cacheKey] != null;
  }
  
  // Get wishlist item ID for a product
  int? getWishlistItemId(int productId, int productVariantId, int storeId) {
    final cacheKey = _getCacheKey(productId, productVariantId, storeId);
    return _localWishlistCache[cacheKey];
  }
  
  // Check if bloc has data for this product (either from cache or server state)
  bool hasProductData(int productId, int productVariantId, int storeId) {
    final cacheKey = _getCacheKey(productId, productVariantId, storeId);
    // If in cache, we have data (even if value is null, it means we know it's not wishlisted)
    if (_localWishlistCache.containsKey(cacheKey)) {
      return true;
    }
    // If state is loaded, we have server data
    return state is UserWishlistLoaded;
  }

  Future<void> _onGetUserWishlistRequest(GetUserWishlistRequest event, Emitter<UserWishlistState> emit) async {
    emit(UserWishlistLoading());
    try{
      List<WishlistData> wishlistData = [];
      currentPage = 1;
      hasReachedMax = false;
      isLoadingMore = false;
      final response = await repository.getUserWishlist(perPage: perPage, currentPage: currentPage);
      wishlistData = List<WishlistData>.from(response['data']['data'].map((data) => WishlistData.fromJson(data)));

      final currentTotal = int.parse(response['data']['current_page'].toString());
      final lastPageNum = int.parse(response['data']['last_page'].toString());
      hasReachedMax = currentTotal >= lastPageNum || wishlistData.length < perPage;
      if(response['success'] == true){
        // Clear old cache on full refresh to ensure sync with server
        _localWishlistCache.clear();
        // Update local cache with server data
        _updateLocalCacheFromWishlistData(wishlistData);
        emit(UserWishlistLoaded(
            message: response['message'],
            wishlistData: wishlistData,
            hasReachedMax: hasReachedMax
        ));
      } else if (response['error'] == true){
        emit(UserWishlistFailed(message: response['message']));
      }
    }catch(e) {
      emit(UserWishlistFailed(message: e.toString()));
    }
  }
  
  // Helper method to update local cache from wishlist data
  void _updateLocalCacheFromWishlistData(List<WishlistData> wishlistData) {
    for (final wishlist in wishlistData) {
      if (wishlist.items != null) {
        for (final item in wishlist.items!) {
          if (item.product?.id != null && item.variant?.id != null && item.store?.id != null) {
            final cacheKey = _getCacheKey(item.product!.id!, item.variant!.id!, item.store!.id!);
            _localWishlistCache[cacheKey] = item.id;
          }
        }
      }
    }
  }

  Future<void> _onGetMoreUserWishlistRequest(GetMoreUserWishlistRequest event, Emitter<UserWishlistState> emit) async {
    if (hasReachedMax || isLoadingMore) return;
    final currentState = state;
    if(currentState is UserWishlistLoaded) {
      isLoadingMore = true;
      try{
        List<WishlistData> newWishlistData = [];
        currentPage += 1;

        final response = await repository.getUserWishlist(perPage: perPage, currentPage: currentPage);
        newWishlistData = List<WishlistData>.from(response['data']['data'].map((data) => WishlistData.fromJson(data)));

        final currentTotal = int.parse(response['data']['current_page'].toString());
        final lastPageNum = int.parse(response['data']['last_page'].toString());
        hasReachedMax = currentTotal >= lastPageNum || newWishlistData.length < perPage;
        final updatedWishlistData = List<WishlistData>.from(currentState.wishlistData);
        for (final newWishlist in newWishlistData) {
          if (!updatedWishlistData.any((existing) => existing.id == newWishlist.id)) {
            updatedWishlistData.add(newWishlist);
          }
        }
        // Update local cache with new wishlist data
        _updateLocalCacheFromWishlistData(newWishlistData);
        emit(UserWishlistLoaded(
            message: response['message'],
            wishlistData: updatedWishlistData,
            hasReachedMax: hasReachedMax
        ));

      } catch(e) {
        currentPage -= 1;
        emit(UserWishlistFailed(message: e.toString()));
      } finally {
        isLoadingMore = false;
      }
    }

  }

  Future<void> _onCreateNewWishlist(CreateNewWishlist event, Emitter<UserWishlistState> emit) async {
    // Check if this creation is already pending
    final pendingKey = 'create_${event.title}';
    if (_pendingAddOperations.contains(pendingKey)) return;
    _pendingAddOperations.add(pendingKey);

    // Optimistically update cache if product info provided
    if (event.productId != null && event.productVariantId != null && event.storeId != null) {
      final cacheKey = _getCacheKey(event.productId!, event.productVariantId!, event.storeId!);
      _localWishlistCache[cacheKey] = -1; // Temporary ID
      
      // If we are in loading or initial state, emit a minimal loaded state to trigger UI update
      if (state is UserWishlistLoading || state is UserWishlistInitial) {
        emit(UserWishlistLoaded(
          message: '',
          wishlistData: [],
          hasReachedMax: true,
        ));
      } else if (state is UserWishlistLoaded) {
        emit((state as UserWishlistLoaded).copyWith(timestamp: DateTime.now())); // Trigger rebuild
      }
    } else {
      emit(UserWishlistLoading());
    }

    try{
      final response = await repository.createWishlist(title: event.title);
      _pendingAddOperations.remove(pendingKey);

      if(response['success'] == true || (response['message']?.toString().contains('already exists') ?? false)){
        if (event.productId != null && event.productVariantId != null && event.storeId != null) {
          // If product info is provided, add the item to the newly created wishlist
          add(AddItemInWishlist(
            wishlistTitle: event.title,
            productId: event.productId!,
            productVariantId: event.productVariantId!,
            storeId: event.storeId!,
          ));
        } else {
          add(GetUserWishlistRequest());
        }
      } else if (response['error'] == true || response['success'] == false){
        if (event.productId != null && event.productVariantId != null && event.storeId != null) {
          // If it failed but we have product info, try adding anyway (maybe wishlist exists but repo check failed)
          add(AddItemInWishlist(
            wishlistTitle: event.title,
            productId: event.productId!,
            productVariantId: event.productVariantId!,
            storeId: event.storeId!,
          ));
        } else {
          emit(UserWishlistFailed(message: response['message'] ?? 'Creation failed'));
        }
      }
    }catch(e) {
      _pendingAddOperations.remove(pendingKey);
      if (event.productId != null && event.productVariantId != null && event.storeId != null) {
        // If it failed, try adding anyway!
        add(AddItemInWishlist(
          wishlistTitle: event.title,
          productId: event.productId!,
          productVariantId: event.productVariantId!,
          storeId: event.storeId!,
        ));
      } else {
        emit(UserWishlistFailed(message: e.toString()));
      }
    }
  }

  Future<void> _onAddItemInWishlist(AddItemInWishlist event, Emitter<UserWishlistState> emit) async {
    // Check if an operation for this product is already pending
    final cacheKey = _getCacheKey(event.productId, event.productVariantId, event.storeId);
    final pendingKey = '${cacheKey}_${event.wishlistTitle}';
    
    // If already wishlisted or pending, don't add again
    if (_localWishlistCache[cacheKey] != null && _localWishlistCache[cacheKey] != -1) return;
    if (_pendingAddOperations.contains(pendingKey)) return;
    
    _pendingAddOperations.add(pendingKey);
    
    // Store original state to revert if API fails
    WishlistData? originalWishlist;
    
    // Capture operation ID to detect race conditions
    final opId = _getNextOperationId(event.productId, event.productVariantId, event.storeId);
    
    // Emit current state to trigger UI update with loading indicator
    if (state is UserWishlistLoaded) {
      emit((state as UserWishlistLoaded).copyWith(timestamp: DateTime.now()));
    } else if (state is UserWishlistInitial || state is UserWishlistLoading) {
      // If not loaded yet, emit a minimal loaded state to allow optimistic updates to show
      emit(UserWishlistLoaded(
        message: '',
        wishlistData: [],
        hasReachedMax: true,
      ));
    }
    
    // Optimistically update ONLY item count and cache (for icon state)
    if (state is UserWishlistLoaded) {
      final currentState = state as UserWishlistLoaded;
      
      // Find the wishlist to update
      final wishlistIndex = currentState.wishlistData.indexWhere(
        (wishlist) => wishlist.title == event.wishlistTitle,
      );
      
      if (wishlistIndex != -1) {
        originalWishlist = currentState.wishlistData[wishlistIndex];
        
        // Create a temporary item for optimistic search/removal
        final tempItem = Items(
          id: -1, // Temporary identifier
          wishlistId: originalWishlist.id,
          product: WishlistProduct(id: event.productId),
          variant: WishlistVariant(id: event.productVariantId),
          store: Store(id: event.storeId),
        );

        final updatedItems = List<Items>.from(originalWishlist.items ?? []);
        // Avoid duplicate temp items
        if (!updatedItems.any((i) => i.id == -1 && i.product?.id == event.productId)) {
           updatedItems.add(tempItem);
        }

        final updatedWishlist = originalWishlist.copyWith(
          items: updatedItems,
          itemsCount: (originalWishlist.itemsCount ?? 0) + 1,
        );
        
        final updatedWishlistData = List<WishlistData>.from(currentState.wishlistData);
        updatedWishlistData[wishlistIndex] = updatedWishlist;
        
        // Update local cache for icon state
        _localWishlistCache[cacheKey] = -1; // Temporary ID for icon state
        
        emit(UserWishlistLoaded(
          message: currentState.message,
          wishlistData: updatedWishlistData,
          hasReachedMax: currentState.hasReachedMax,
          timestamp: DateTime.now(),
        ));
      } else {
        // If wishlist not found, create a temp one
        final tempItem = Items(
          id: -1,
          wishlistId: -1,
          product: WishlistProduct(id: event.productId),
          variant: WishlistVariant(id: event.productVariantId),
          store: Store(id: event.storeId),
        );

        final tempWishlist = WishlistData(
          id: -1,
          title: event.wishlistTitle,
          items: [tempItem],
          itemsCount: 1,
        );

        final updatedWishlistData = List<WishlistData>.from(currentState.wishlistData);
        updatedWishlistData.add(tempWishlist);

        // Update local cache
        _localWishlistCache[cacheKey] = -1;

        emit(UserWishlistLoaded(
          message: currentState.message,
          wishlistData: updatedWishlistData,
          hasReachedMax: currentState.hasReachedMax,
          timestamp: DateTime.now(),
        ));
      }
    }
    
    // Call API in background
    try{
      final response = await repository.addItemInWishlist(
         wishlistTitle : event.wishlistTitle,
         productId : event.productId,
         productVariantId : event.productVariantId,
         storeId : event.storeId,
      );

      // Remove from pending operations
      _pendingAddOperations.remove(pendingKey);

      // Check if this operation is still valid
      if (_isOperationStale(event.productId, event.productVariantId, event.storeId, opId)) {
        return;
      }

      if(response['success'] == true){
        int? serverItemId;
        if (response['data'] != null && response['data']['id'] != null) {
          serverItemId = int.tryParse(response['data']['id'].toString());
        }

        if (state is UserWishlistLoaded) {
          final currentState = state as UserWishlistLoaded;
          final wishlistIndex = currentState.wishlistData.indexWhere(
            (wishlist) => wishlist.title == event.wishlistTitle,
          );
          
          if (wishlistIndex != -1) {
            final updatedWishlistData = List<WishlistData>.from(currentState.wishlistData);
            final wishlist = updatedWishlistData[wishlistIndex];
            final updatedItems = List<Items>.from(wishlist.items ?? []);
            
            final tempItemIndex = updatedItems.indexWhere((item) => 
                item.id == -1 && 
                item.product?.id == event.productId && 
                item.variant?.id == event.productVariantId);
            
            if (tempItemIndex != -1) {
              if (serverItemId != null) {
                updatedItems[tempItemIndex] = updatedItems[tempItemIndex].copyWith(id: serverItemId);
                _localWishlistCache[cacheKey] = serverItemId;
              } else {
                add(GetUserWishlistRequest()); 
                return;
              }
            }
            
            updatedWishlistData[wishlistIndex] = wishlist.copyWith(items: updatedItems);
            
            emit(UserWishlistLoaded(
              message: currentState.message,
              wishlistData: updatedWishlistData,
              hasReachedMax: currentState.hasReachedMax,
              timestamp: DateTime.now(),
            ));
          }
        }
      } else if (response['error'] == true || response['success'] == false){
        // Revert optimistic update on error
        if (state is UserWishlistLoaded && originalWishlist != null) {
          final currentState = state as UserWishlistLoaded;
          final wishlistIndex = currentState.wishlistData.indexWhere(
            (wishlist) => wishlist.id == originalWishlist!.id,
          );
          
          if (wishlistIndex != -1) {
            final revertedWishlistData = List<WishlistData>.from(currentState.wishlistData);
            revertedWishlistData[wishlistIndex] = originalWishlist;
            
            // Revert cache if no other wishlist has this item
            _localWishlistCache.remove(cacheKey);
            
            emit(UserWishlistLoaded(
              message: response['message'] ?? 'Add failed',
              wishlistData: revertedWishlistData,
              hasReachedMax: currentState.hasReachedMax,
              timestamp: DateTime.now(),
            ));
          }
        }
      }
    }catch(e) {
      _pendingAddOperations.remove(pendingKey);
      
      if (state is UserWishlistLoaded && originalWishlist != null) {
        final currentState = state as UserWishlistLoaded;
        final wishlistIndex = currentState.wishlistData.indexWhere(
          (wishlist) => wishlist.id == originalWishlist!.id,
        );
        
        if (wishlistIndex != -1) {
          final revertedWishlistData = List<WishlistData>.from(currentState.wishlistData);
          revertedWishlistData[wishlistIndex] = originalWishlist;
          _localWishlistCache.remove(cacheKey);
          
          emit(UserWishlistLoaded(
            message: e.toString(),
            wishlistData: revertedWishlistData,
            hasReachedMax: currentState.hasReachedMax,
            timestamp: DateTime.now(),
          ));
        }
      }
    }
  }

  Future<void> _onUpdateUserWishlist(UpdateUserWishlist event, Emitter<UserWishlistState> emit) async {
    // Store original wishlist to revert if API fails
    WishlistData? originalWishlist;
    
    // Optimistically update the wishlist in state without showing loading
    if (state is UserWishlistLoaded) {
      final currentState = state as UserWishlistLoaded;
      originalWishlist = currentState.wishlistData.firstWhere(
        (wishlist) => wishlist.id == event.wishlistId,
        orElse: () => WishlistData(),
      );
      
      final updatedWishlistData = currentState.wishlistData.map((wishlist) {
        if (wishlist.id == event.wishlistId) {
          // Create updated wishlist with new title
          return WishlistData(
            id: wishlist.id,
            title: event.title,
            slug: wishlist.slug,
            itemsCount: wishlist.itemsCount,
            items: wishlist.items,
            createdAt: wishlist.createdAt,
            updatedAt: wishlist.updatedAt,
          );
        }
        return wishlist;
      }).toList();
      
      // Emit updated state immediately
      emit(UserWishlistLoaded(
        message: currentState.message,
        wishlistData: updatedWishlistData,
        hasReachedMax: currentState.hasReachedMax,
      ));
    }
    
    // Call API in background
    try{
      final response = await repository.updateWishlist(title: event.title, wishlistId: event.wishlistId);

      if(response['success'] == true){
        // API succeeded - state already updated optimistically, no need to refresh
        // The optimistic update is already in place, so we're done
      } else if (response['error'] == true){
        // Revert optimistic update on error
        if (state is UserWishlistLoaded && originalWishlist != null && originalWishlist.id != null) {
          final currentState = state as UserWishlistLoaded;
          final revertedWishlistData = currentState.wishlistData.map((wishlist) {
            if (wishlist.id == originalWishlist!.id) {
              return originalWishlist;
            }
            return wishlist;
          }).toList();
          
          emit(UserWishlistLoaded(
            message: response['message'] ?? 'Update failed',
            wishlistData: revertedWishlistData,
            hasReachedMax: currentState.hasReachedMax,
          ));
        } else {
          // If we can't revert, just refresh silently
          add(GetUserWishlistRequest());
        }
      }
    }catch(e) {
      // Revert optimistic update on error
      if (state is UserWishlistLoaded && originalWishlist != null && originalWishlist.id != null) {
        final currentState = state as UserWishlistLoaded;
        final revertedWishlistData = currentState.wishlistData.map((wishlist) {
          if (wishlist.id == originalWishlist!.id) {
            return originalWishlist;
          }
          return wishlist;
        }).toList();
        
        emit(UserWishlistLoaded(
          message: e.toString(),
          wishlistData: revertedWishlistData,
          hasReachedMax: currentState.hasReachedMax,
        ));
      } else {
        // If we can't revert, just refresh silently
        add(GetUserWishlistRequest());
      }
    }
  }

  Future<void> _onDeleteWishlist(DeleteWishlist event, Emitter<UserWishlistState> emit) async {
    // Store the deleted wishlist to revert if API fails
    WishlistData? deletedWishlist;
    
    // Optimistically remove the wishlist from state without showing loading
    if (state is UserWishlistLoaded) {
      final currentState = state as UserWishlistLoaded;
      deletedWishlist = currentState.wishlistData.firstWhere(
        (wishlist) => wishlist.id == event.wishlistId,
        orElse: () => WishlistData(),
      );
      
      final updatedWishlistData = currentState.wishlistData
          .where((wishlist) => wishlist.id != event.wishlistId)
          .toList();
      
      // Also remove items from local cache if this wishlist had any
      if (deletedWishlist.items != null) {
        for (final item in deletedWishlist.items!) {
          if (item.product?.id != null && item.variant?.id != null && item.store?.id != null) {
            final cacheKey = _getCacheKey(item.product!.id!, item.variant!.id!, item.store!.id!);
            _localWishlistCache.remove(cacheKey);
          }
        }
      }
      
      // Emit updated state immediately
      emit(UserWishlistLoaded(
        message: currentState.message,
        wishlistData: updatedWishlistData,
        hasReachedMax: currentState.hasReachedMax,
      ));
    }
    
    // Call API in background
    try{
      final response = await repository.deleteWishlist(wishlistId: event.wishlistId);

      if(response['success'] == true){
        // API succeeded - state already updated optimistically, no need to refresh
        // The optimistic update already removed the wishlist from state
      } else if (response['error'] == true){
        // Revert optimistic update on error
        if (state is UserWishlistLoaded && deletedWishlist != null && deletedWishlist.id != null) {
          final currentState = state as UserWishlistLoaded;
          final revertedWishlistData = List<WishlistData>.from(currentState.wishlistData);
          revertedWishlistData.add(deletedWishlist);
          
          // Restore cache entries
          if (deletedWishlist.items != null) {
            for (final item in deletedWishlist.items!) {
              if (item.product?.id != null && item.variant?.id != null && item.store?.id != null && item.id != null) {
                final cacheKey = _getCacheKey(item.product!.id!, item.variant!.id!, item.store!.id!);
                _localWishlistCache[cacheKey] = item.id;
              }
            }
          }
          
          emit(UserWishlistLoaded(
            message: response['message'] ?? 'Delete failed',
            wishlistData: revertedWishlistData,
            hasReachedMax: currentState.hasReachedMax,
          ));
        } else {
          // If we can't revert, just refresh
          add(GetUserWishlistRequest());
        }
      }
    }catch(e) {
      // Revert optimistic update on error
      if (state is UserWishlistLoaded && deletedWishlist != null && deletedWishlist.id != null) {
        final currentState = state as UserWishlistLoaded;
        final revertedWishlistData = List<WishlistData>.from(currentState.wishlistData);
        revertedWishlistData.add(deletedWishlist);
        
        // Restore cache entries
        if (deletedWishlist.items != null) {
          for (final item in deletedWishlist.items!) {
            if (item.product?.id != null && item.variant?.id != null && item.store?.id != null && item.id != null) {
              final cacheKey = _getCacheKey(item.product!.id!, item.variant!.id!, item.store!.id!);
              _localWishlistCache[cacheKey] = item.id;
            }
          }
        }
        
        emit(UserWishlistLoaded(
          message: e.toString(),
          wishlistData: revertedWishlistData,
          hasReachedMax: currentState.hasReachedMax,
        ));
      } else {
        // If we can't revert, just refresh
        add(GetUserWishlistRequest());
      }
    }
  }

  Future<void> _onRemoveItemFromWishlist(RemoveItemFromWishlist event, Emitter<UserWishlistState> emit) async {
    int actualItemId = event.itemId;
    int? productId = event.productId;
    int? productVariantId = event.productVariantId;
    int? storeId = event.storeId;

    // If itemId is unknown (0), try to find it in the current state using product info
    if (actualItemId == 0 && productId != null) {
      if (state is UserWishlistLoaded) {
        final currentState = state as UserWishlistLoaded;
        for (final wishlist in currentState.wishlistData) {
          if (wishlist.items != null) {
            final item = wishlist.items!.firstWhere(
              (i) => i.product?.id == productId && 
                     (productVariantId == null || i.variant?.id == productVariantId),
              orElse: () => Items(),
            );
            if (item.id != null) {
              actualItemId = item.id!;
              productVariantId ??= item.variant?.id;
              storeId ??= item.store?.id;
              break;
            }
          }
        }
      }
    }
    
    // If still unknown, we can't remove it from the server, but we can clear local cache
    if (actualItemId == 0) {
      if (productId != null && productVariantId != null && storeId != null) {
        final key = _getCacheKey(productId, productVariantId, storeId);
        _localWishlistCache[key] = null;
        if (state is UserWishlistLoaded) {
          emit((state as UserWishlistLoaded).copyWith(timestamp: DateTime.now()));
        }
      } else {
        // Last resort: refresh everything
        add(GetUserWishlistRequest());
      }
      return;
    }

    // Store original state to revert if API fails
    WishlistData? originalWishlist;
    Items? removedItem;
    int? wishlistIndex;
    
    // Mark operation as pending
    _pendingRemoveOperations.add(actualItemId);
    
    // Find product info for operation tracking if not provided
    if (productId == null || productVariantId == null || storeId == null) {
      if (state is UserWishlistLoaded) {
        final currentState = state as UserWishlistLoaded;
        for (final wishlist in currentState.wishlistData) {
          final item = wishlist.items?.firstWhere((i) => i.id == actualItemId, orElse: () => Items());
          if (item != null && item.id != null) {
            productId = item.product?.id;
            productVariantId = item.variant?.id;
            storeId = item.store?.id;
            break;
          }
        }
      }
    }

    final opId = (productId != null && productVariantId != null && storeId != null) 
        ? _getNextOperationId(productId, productVariantId, storeId) 
        : null;
    
    // Emit current state to trigger UI update with loading indicator
    if (state is UserWishlistLoaded) {
      emit((state as UserWishlistLoaded).copyWith(timestamp: DateTime.now()));
    }
    
    // Optimistically update the wishlist in state without showing loading
    if (state is UserWishlistLoaded) {
      final currentState = state as UserWishlistLoaded;
      
      // Find the item and its wishlist
      for (int i = 0; i < currentState.wishlistData.length; i++) {
        final wishlist = currentState.wishlistData[i];
        if (wishlist.items != null) {
          final itemIndex = wishlist.items!.indexWhere((item) => item.id == event.itemId);
          if (itemIndex != -1) {
            originalWishlist = wishlist;
            removedItem = wishlist.items![itemIndex];
            wishlistIndex = i;
            break;
          }
        }
      }
      
      if (originalWishlist != null && removedItem != null && wishlistIndex != null) {
        // Create updated wishlist with item removed
        final updatedItems = List<Items>.from(originalWishlist.items ?? []);
        updatedItems.removeWhere((item) => item.id == actualItemId);
        
        final updatedWishlist = originalWishlist.copyWith(
          items: updatedItems,
          itemsCount: (originalWishlist.itemsCount ?? 1) > 0 
              ? (originalWishlist.itemsCount ?? 1) - 1 
              : 0,
        );
        
        final updatedWishlistData = List<WishlistData>.from(currentState.wishlistData);
        updatedWishlistData[wishlistIndex] = updatedWishlist;
        
        // Update local cache - only clear if product is not in any other wishlist
        if (removedItem.product?.id != null && 
            removedItem.variant?.id != null && 
            removedItem.store?.id != null) {
          final cacheKey = _getCacheKey(
            removedItem.product!.id!, 
            removedItem.variant!.id!, 
            removedItem.store!.id!
          );
          
          // Check if product still exists in other wishlists
          bool foundInOtherWishlist = false;
          int? itemIdFromOtherWishlist;
          
          for (final wishlist in updatedWishlistData) {
            if (wishlist.items != null) {
              for (final item in wishlist.items!) {
                if (item.product?.id == removedItem.product!.id &&
                    item.variant?.id == removedItem.variant!.id &&
                    item.store?.id == removedItem.store!.id) {
                  foundInOtherWishlist = true;
                  itemIdFromOtherWishlist = item.id;
                  break;
                }
              }
              if (foundInOtherWishlist) break;
            }
          }
          
          // Only clear cache if product is not in any other wishlist
          if (!foundInOtherWishlist) {
            _localWishlistCache[cacheKey] = null;
          } else if (itemIdFromOtherWishlist != null) {
            // Update cache with ID from another wishlist
            _localWishlistCache[cacheKey] = itemIdFromOtherWishlist;
          }
        }
        
        // Emit updated state immediately
        emit(UserWishlistLoaded(
          message: currentState.message,
          wishlistData: updatedWishlistData,
          hasReachedMax: currentState.hasReachedMax,
        ));
      }
    }
    
    // If item ID is -1 (temporary), it was optimistically added and not yet confirmed by API
    // OR if actualItemId is -1 for any reason, don't call API.
    if (actualItemId == -1 || (removedItem != null && removedItem.id == -1)) {
      // Remove from pending operations
      _pendingRemoveOperations.remove(actualItemId);
      // Item was optimistically added, already removed from state (if found in loop)
      // No API call needed, but emit state to remove loading indicator
      if (state is UserWishlistLoaded) {
        emit((state as UserWishlistLoaded).copyWith(timestamp: DateTime.now()));
      }
      return;
    }
    
    // Call API in background for real items
    try{
      final response = await repository.removeItemFromWishlist(itemId: actualItemId);
      
      // Check if this operation is stale
      if (opId != null && productId != null && productVariantId != null && storeId != null) {
        if (_isOperationStale(productId, productVariantId, storeId, opId)) {
          return;
        }
      }
      
      // Remove from pending operations
      _pendingRemoveOperations.remove(actualItemId);
      
      if(response['success'] == true){
        // API succeeded - state already updated optimistically
        // Update cache to reflect current state
        if (state is UserWishlistLoaded && removedItem != null &&
            removedItem.product?.id != null && 
            removedItem.variant?.id != null && 
            removedItem.store?.id != null) {
          final currentState = state as UserWishlistLoaded;
          final cacheKey = _getCacheKey(
            removedItem.product!.id!, 
            removedItem.variant!.id!, 
            removedItem.store!.id!
          );
          
          // Check if product still exists in other wishlists
          bool foundInOtherWishlist = false;
          int? itemIdFromOtherWishlist;
          
          for (final wishlist in currentState.wishlistData) {
            if (wishlist.items != null) {
              for (final item in wishlist.items!) {
                if (item.product?.id == removedItem.product!.id &&
                    item.variant?.id == removedItem.variant!.id &&
                    item.store?.id == removedItem.store!.id) {
                  foundInOtherWishlist = true;
                  itemIdFromOtherWishlist = item.id;
                  break;
                }
              }
              if (foundInOtherWishlist) break;
            }
          }
          
          // Update cache
          if (!foundInOtherWishlist) {
            _localWishlistCache[cacheKey] = null;
          } else if (itemIdFromOtherWishlist != null) {
            _localWishlistCache[cacheKey] = itemIdFromOtherWishlist;
          }
        }
        
        if (state is UserWishlistLoaded) {
          emit((state as UserWishlistLoaded).copyWith(timestamp: DateTime.now()));
        }
      } else if (response['error'] == true || response['success'] == false){
        // Revert optimistic update on error
        if (state is UserWishlistLoaded && originalWishlist != null && wishlistIndex != null) {
          final currentState = state as UserWishlistLoaded;
          final revertedWishlistData = List<WishlistData>.from(currentState.wishlistData);
          revertedWishlistData[wishlistIndex] = originalWishlist;
          
          // Restore cache with the removed item's ID
          if (removedItem != null && 
              removedItem.product?.id != null && 
              removedItem.variant?.id != null && 
              removedItem.store?.id != null &&
              removedItem.id != null) {
            final cacheKey = _getCacheKey(
              removedItem.product!.id!, 
              removedItem.variant!.id!, 
              removedItem.store!.id!
            );
            // Check if product exists in other wishlists first
            bool foundInOtherWishlist = false;
            int? itemIdFromOtherWishlist;
            
            if (state is UserWishlistLoaded) {
              final currentState = state as UserWishlistLoaded;
              for (final wishlist in currentState.wishlistData) {
                if (wishlist.items != null) {
                  for (final item in wishlist.items!) {
                    if (item.product?.id == removedItem.product!.id &&
                        item.variant?.id == removedItem.variant!.id &&
                        item.store?.id == removedItem.store!.id) {
                      foundInOtherWishlist = true;
                      itemIdFromOtherWishlist = item.id;
                      break;
                    }
                  }
                  if (foundInOtherWishlist) break;
                }
              }
            }
            
            // Use ID from other wishlist if found, otherwise use removed item's ID
            _localWishlistCache[cacheKey] = itemIdFromOtherWishlist ?? removedItem.id;
          }
          
          emit(UserWishlistLoaded(
            message: response['message'] ?? 'Remove failed',
            wishlistData: revertedWishlistData,
            hasReachedMax: currentState.hasReachedMax,
          ));
        }
      }
    }catch(e) {
      // Remove from pending operations
      _pendingRemoveOperations.remove(actualItemId);
      
      // Revert optimistic update on error
      if (state is UserWishlistLoaded && originalWishlist != null && wishlistIndex != null) {
        final currentState = state as UserWishlistLoaded;
        final revertedWishlistData = List<WishlistData>.from(currentState.wishlistData);
        revertedWishlistData[wishlistIndex] = originalWishlist;
        
        // Restore cache - check if product exists in other wishlists first
        if (removedItem != null && 
            removedItem.product?.id != null && 
            removedItem.variant?.id != null && 
            removedItem.store?.id != null &&
            removedItem.id != null) {
          final cacheKey = _getCacheKey(
            removedItem.product!.id!, 
            removedItem.variant!.id!, 
            removedItem.store!.id!
          );
          
          // Check if product exists in other wishlists
          bool foundInOtherWishlist = false;
          int? itemIdFromOtherWishlist;
          
          if (state is UserWishlistLoaded) {
            final currentState = state as UserWishlistLoaded;
            for (final wishlist in currentState.wishlistData) {
              if (wishlist.items != null) {
                for (final item in wishlist.items!) {
                  if (item.product?.id == removedItem.product!.id &&
                      item.variant?.id == removedItem.variant!.id &&
                      item.store?.id == removedItem.store!.id) {
                    foundInOtherWishlist = true;
                    itemIdFromOtherWishlist = item.id;
                    break;
                  }
                }
                if (foundInOtherWishlist) break;
              }
            }
          }
          
          // Use ID from other wishlist if found, otherwise use removed item's ID
          _localWishlistCache[cacheKey] = itemIdFromOtherWishlist ?? removedItem.id;
        }
        
        emit(UserWishlistLoaded(
          message: e.toString(),
          wishlistData: revertedWishlistData,
          hasReachedMax: currentState.hasReachedMax,
        ));
      }
    }
  }
  
  // Optimistic update handlers
  Future<void> _onOptimisticAddToWishlist(OptimisticAddToWishlist event, Emitter<UserWishlistState> emit) async {
    final cacheKey = _getCacheKey(event.productId, event.productVariantId, event.storeId);
    _localWishlistCache[cacheKey] = event.wishlistItemId ?? -1; // Use -1 as temporary ID
    
    // Emit current state to trigger UI update
    if (state is UserWishlistLoaded) {
      emit((state as UserWishlistLoaded).copyWith(timestamp: DateTime.now()));
    } else if (state is UserWishlistInitial) {
      // If no state loaded yet, emit a minimal loaded state
      emit(UserWishlistLoaded(
        message: '',
        wishlistData: [],
        hasReachedMax: true,
      ));
    }
  }
  
  Future<void> _onOptimisticRemoveFromWishlist(OptimisticRemoveFromWishlist event, Emitter<UserWishlistState> emit) async {
    final cacheKey = _getCacheKey(event.productId, event.productVariantId, event.storeId);
    _localWishlistCache[cacheKey] = null;
    
    // Emit current state to trigger UI update
    if (state is UserWishlistLoaded) {
      emit((state as UserWishlistLoaded).copyWith(timestamp: DateTime.now()));
    } else if (state is UserWishlistInitial) {
      emit(UserWishlistLoaded(
        message: '',
        wishlistData: [],
        hasReachedMax: true,
      ));
    }
  }

  Future<void> _onMoveItemToAnotherWishlist(MoveItemToAnotherWishlist event, Emitter<UserWishlistState> emit) async {
    emit(UserWishlistLoading());
    try{
      final response = await repository.moveItemToAnotherWishlist(itemId: event.itemId, wishlistId: event.wishlistId);

      if(response['success'] == true){
        add(GetUserWishlistRequest());
      } else if (response['error'] == true){
        emit(UserWishlistFailed(message: response['message']));
      }
    }catch(e) {
      emit(UserWishlistFailed(message: e.toString()));
    }
  }
}