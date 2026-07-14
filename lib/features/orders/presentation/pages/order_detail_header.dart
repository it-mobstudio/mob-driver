part of 'order_detail_page.dart';

class _OrderDetailHeader extends StatelessWidget {
  const _OrderDetailHeader({this.order});

  final OrderEntity? order;

  @override
  Widget build(BuildContext context) {
    final orderLabel =
        order != null ? 'Order #${order!.orderNumber}' : 'Order details';
    final itemCount = order?.items.length ?? 0;

    return Container(
      height: 68,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/homepage');
              }
            },
            icon: const AppBackIcon(),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  orderLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF0A243F),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 20 / 13,
                  ),
                ),
                if (itemCount > 0)
                  Text(
                    '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF596378),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      height: 16 / 11,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFDEDEDE),
                width: 1,
              ),
            ),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: SvgPicture.asset(
                  'assets/images/supportagent.svg',
                  fit: BoxFit.contain,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF0A243F),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
