import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/backend/api_requests/api_calls.dart';
import 'package:m_o_b_demand_side/features/products/models/product_models.dart';
import '../core/app_runtime/flutter_flow_theme.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;

  const ProductCard({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = product.title;
    final price = product.vendorPricing.vendorSellingPrice;
    final oldPrice = product.maximumRetailPrice;
    final priceStr = price.toStringAsFixed(2);
    final oldPriceStr = oldPrice.toStringAsFixed(2);
    final discount = product.vendorPricing.discount;
    final delivery = product.vendorPricing.fullfillmentLatency;
    final imageUrl = product.primaryImageUrl;

    return SizedBox(
      width: 164,
      height: 320,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            border: Border.all(color: FlutterFlowTheme.of(context).border),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  (discount != 0 && discount.toString().isNotEmpty)
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context).secondary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('$discount% OFF',
                              style: FlutterFlowTheme.of(context)
                                  .typography
                                  .labelSmall
                                  .copyWith(
                                      color: FlutterFlowTheme.of(context)
                                          .graysWhite,
                                      fontWeight: FontWeight.bold)),
                        )
                      : Opacity(
                          opacity: 0.0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context).secondary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('00% OFF',
                                style: FlutterFlowTheme.of(context)
                                    .typography
                                    .labelSmall
                                    .copyWith(
                                        color: FlutterFlowTheme.of(context)
                                            .graysWhite,
                                        fontWeight: FontWeight.bold)),
                          ),
                        ),
                  const Spacer(),
                  // No rating in API, so skip rating UI
                ],
              ),
              const SizedBox(height: 6),
              Center(
                child: SizedBox(
                  width: 132,
                  height: 132,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: 132,
                          height: 132,
                          fit: BoxFit.contain,
                        )
                      : Image.asset(
                          'assets/images/Image-coming-soon.png',
                          width: 132,
                          height: 132,
                          fit: BoxFit.contain,
                        ),
                ),
              ),
              const SizedBox(height: 6),
              // Plus button below image, right aligned, circular background
              Row(
                children: [
                  const Spacer(),
                  GestureDetector(
                    onTap: () async {
                      final response = await AddToCartCall.call(
                        items: [
                          {
                            "product": product.addToCartProductId,
                            "quantity": 1
                          }
                        ],
                      );
                      if (!context.mounted) {
                        return;
                      }
                      // Parse the response and show a snackbar with the message
                      final message =
                          (response.jsonBody?['message'] ??
                                  response.jsonBody?['detail'] ??
                                  'Something went wrong')
                              .toString();
                      final isSuccess = response.jsonBody?['status'] == true;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(message),
                          backgroundColor:
                              isSuccess ? Colors.green : Colors.red,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).primaryBackground,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: FlutterFlowTheme.of(context)
                                .alternate
                                .withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Image.asset(
                        'assets/images/plus.png',
                        height: 16,
                        width: 16,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: FlutterFlowTheme.of(context)
                      .typography
                      .bodyMedium
                      .copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text('₹$priceStr',
                      style: FlutterFlowTheme.of(context)
                          .typography
                          .bodyLarge
                          .copyWith(
                              color: FlutterFlowTheme.of(context).primaryText,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                  const SizedBox(width: 6),
                  if (oldPrice != 0)
                    Text('₹$oldPriceStr',
                        style: FlutterFlowTheme.of(context)
                            .typography
                            .bodySmall
                            .copyWith(
                                fontSize: 12,
                                color:
                                    FlutterFlowTheme.of(context).secondaryText,
                                decoration: TextDecoration.lineThrough)),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.flash_on,
                      size: 12, color: FlutterFlowTheme.of(context).tertiary),
                  const SizedBox(width: 4),
                  Text(delivery,
                      style: FlutterFlowTheme.of(context)
                          .typography
                          .labelSmall
                          .copyWith(
                              fontSize: 10,
                              color:
                                  FlutterFlowTheme.of(context).secondaryText)),
                ],
              ),
              // ...existing code...
            ],
          ),
        ),
      ),
    );
  }
}
