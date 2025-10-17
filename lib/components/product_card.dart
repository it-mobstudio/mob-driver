import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/backend/api_requests/api_calls.dart';
import '../flutter_flow/flutter_flow_theme.dart';

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback? onTap;

  const ProductCard({Key? key, required this.product, this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vendorPricing = product['vendorPricings'] ?? {};
    final name = product['item_name_title'] ?? '';
    final price = vendorPricing['vendor_selling_price'] ?? 0;
    final oldPrice = product['maximum_retail_price'] ?? 0;
    final priceStr = double.tryParse(price.toString())?.toStringAsFixed(2) ??
        price.toString();
    final oldPriceStr =
        double.tryParse(oldPrice.toString())?.toStringAsFixed(2) ??
            oldPrice.toString();
    final discount = vendorPricing['discount'] ?? 0;
    final delivery = vendorPricing['fullfillment_latency'] ?? '';
    final imageUrl = (product['images'] != null && product['images'].isNotEmpty)
        ? product['images'][0]['image']
        : null;

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
                  (discount != null &&
                          discount != 0 &&
                          discount.toString().isNotEmpty)
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context).secondary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('${discount}% OFF',
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
                  child: imageUrl != null && imageUrl.isNotEmpty
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
                            "product": product['vendorPricings']
                                    ?['vendor_product_id'] ??
                                product['id'],
                            "quantity": 1
                          }
                        ],
                      );
                      // Parse the response and show a snackbar with the message
                      final message = response.jsonBody?['message'] ??
                          response.jsonBody?['detail'] ??
                          'Something went wrong';
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
                                .withOpacity(0.2),
                            blurRadius: 6,
                            offset: Offset(0, 2),
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
                  if (oldPrice != null && oldPrice != 0)
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
