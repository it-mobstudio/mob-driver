import 'package:m_o_b_demand_side/core/errors/app_failure.dart';
import 'package:m_o_b_demand_side/features/cart/domain/entities/cart_entity.dart';

abstract interface class CartRepository {
  Future<(CartSummaryEntity?, AppFailure?)> getCart({bool outOfStock = false});

  Future<(CartSummaryEntity?, AppFailure?)> addToCart({
    required String vendorProductId,
    required int quantity,
  });

  Future<(CartSummaryEntity?, AppFailure?)> removeFromCart({
    required String cartItemId,
    String? vendorProductId,
  });

  Future<(CartSummaryEntity?, AppFailure?)> updateCartRedeem({
    required String cartId,
    required bool useWallet,
    required double walletAmount,
    required bool usePoints,
    required int points,
  });
}
