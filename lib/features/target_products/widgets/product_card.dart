import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wasfy/features/target_products/viewmodel/target_products_viewmodel.dart';
import '../../../core/theme/app_colors.dart';
import '../model/product_model.dart';
import '../view/product_details_screen.dart';
import 'share_product_sheet.dart';

class ProductCard extends StatefulWidget {
  final ProductModel product;

  const ProductCard({super.key, required this.product});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with TickerProviderStateMixin {
  late AnimationController _flashCtrl;
  late Animation<double> _flashAnim;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  String? _lastWatchedId;

  @override
  void initState() {
    super.initState();
    _flashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flashAnim = CurvedAnimation(parent: _flashCtrl, curve: Curves.easeOut);

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(ProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // لو المنتج ده اتحدث دلوقتي، ابدأ الفلاش
    final vm = context.read<TargetProductsViewModel>();
    if (vm.lastUpdatedIds.contains(widget.product.id) && _lastWatchedId != widget.product.id) {
      _lastWatchedId = widget.product.id;
      _flashCtrl.forward(from: 0).then((_) => _flashCtrl.reverse());
    }

    final isRefreshing = vm.currentlyRefreshingIds.contains(widget.product.id);
    if (isRefreshing && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!isRefreshing && _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
      _pulseCtrl.animateTo(0.0);
    }
  }

  @override
  void dispose() {
    _flashCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  ProductModel get product => widget.product;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<TargetProductsViewModel>();
    final isRefreshing = vm.currentlyRefreshingIds.contains(product.id) || product.isAnalyzing;

    return AnimatedBuilder(
      animation: Listenable.merge([_flashCtrl, _pulseCtrl]),
      builder: (context, child) {
        final double flash = _flashAnim.value;
        final double scale = _pulseAnim.value;

        return Transform.scale(
          scale: scale,
          child: Stack(
          children: [
            // الإشعاع الأخضر خلف الكارت
            if (flash > 0)
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withOpacity(flash * 0.35),
                          blurRadius: 18,
                          spreadRadius: 3,
                        ),
                      ],
                      border: Border.all(
                        color: AppColors.success.withOpacity(flash),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailsScreen(product: product),
                  ),
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: flash > 0
                      ? Color.lerp(AppColors.surface, AppColors.successBg, flash * 0.6)!
                      : (isRefreshing ? const Color(0xFFFFFBEB) : AppColors.surface),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isRefreshing ? Colors.orange : AppColors.border.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: isRefreshing ? Colors.orange.withOpacity(0.3) : AppColors.primary.withOpacity(
                        product.isAnalyzing ? 0.15 : 0.05,
                      ),
                      blurRadius: isRefreshing ? 20 : (product.isAnalyzing ? 15 : 10),
                      spreadRadius: isRefreshing ? 2 : 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildImageSection(isRefreshing),
                        const SizedBox(width: 16),
                        _buildDetailsSection(isRefreshing),
                      ],
                    ),
                    if (!product.isAnalyzing && !isRefreshing && product.sellers.isNotEmpty)
                      _buildSellersList(),
                  ],
                ),
              ),
            ),
            _buildDeleteButton(context),
            // بادج "تم التحديث"
            if (flash > 0.3)
              Positioned(
                top: 10,
                right: 20,
                child: Opacity(
                  opacity: (flash - 0.3) / 0.7,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'تم التحديث',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageSection(bool isRefreshing) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
          ),
          child: product.isAnalyzing || isRefreshing
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange))
              : product.imageUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(product.imageUrl, fit: BoxFit.cover),
                )
              : const Icon(
                  Icons.storefront,
                  size: 40,
                  color: AppColors.textLight,
                ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${product.targetPrice.toStringAsFixed(0)} ريال',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection(bool isRefreshing) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: product.error != null
                  ? AppColors.error
                  : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          if (product.isAnalyzing || isRefreshing)
            Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
                ),
                const SizedBox(width: 8),
                Text(
                  product.isAnalyzing ? 'جاري التحليل الذكي...' : 'جاري فحص السعر الآن...',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          else if (product.error != null)
            Text(
              product.error!,
              style: const TextStyle(color: AppColors.error, fontSize: 11),
            )
          else
            Row(
              children: [
                Text(
                  '${product.currentPrice.toStringAsFixed(2)} ريال',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                _buildTrendIcon(product.priceHistory),
              ],
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.storefront,
                size: 14,
                color: AppColors.textLight,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  product.storeName,
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!product.isAnalyzing) ...[
                const SizedBox(width: 8),
                _buildDeliveryBadge(product.deliveryType),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _infoItem(Icons.people_outline, '${product.watchers}'),
              const SizedBox(width: 12),
              _infoItem(Icons.groups_outlined, '${product.sellers.length}'),
              const SizedBox(width: 12),
              _infoItem(Icons.access_time, _formatLastChecked(product.lastChecked ?? product.timeAdded)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSellersList() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Divider(height: 1, thickness: 0.5),
        ),
        Row(
          children: [
            const Icon(Icons.sell_outlined, size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            const Text(
              "أفضل العروض المتاحة الآن:",
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ...product.sellers
            .take(2)
            .map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        s.name,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${s.price.toStringAsFixed(2)} ريال',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Widget _infoItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textLight),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  // بقية الميثودز (Trend, DeliveryBadge, DeleteButton, FormatTime) كما هي في كودك الأصلي...
  Widget _buildTrendIcon(List<double> history) {
    if (history.length < 2) return const SizedBox.shrink();
    final latest = history.last;
    final previous = history[history.length - 2];
    if (latest < previous)
      return const Icon(
        Icons.trending_down,
        color: AppColors.success,
        size: 16,
      );
    if (latest > previous)
      return const Icon(Icons.trending_up, color: AppColors.error, size: 16);
    return const Icon(
      Icons.trending_flat,
      color: AppColors.textLight,
      size: 16,
    );
  }

  Widget _buildDeliveryBadge(DeliveryType type) {
    String text = type == DeliveryType.express
        ? 'اكسبريس'
        : (type == DeliveryType.market ? 'ماركت' : 'عادي');
    Color color = type == DeliveryType.express ? Colors.orange : Colors.teal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return Positioned(
      left: 12,
      top: 12,
      child: IconButton(
        icon: const Icon(
          Icons.delete_outline,
          color: AppColors.error,
          size: 20,
        ),
        onPressed: () =>
            context.read<TargetProductsViewModel>().removeProduct(product.id),
      ),
    );
  }

  // Widget _buildShareButton(BuildContext context) {
  //   return Positioned(
  //     left: 52,
  //     top: 12,
  //     child: IconButton(
  //       icon: const Icon(
  //         Icons.share_rounded,
  //         color: AppColors.primary,
  //         size: 20,
  //       ),
  //       tooltip: 'مشاركة',
  //       onPressed: () {
  //         HapticFeedback.lightImpact();
  //         ShareProductSheet.show(context, product);
  //       },
  //     ),
  //   );
  // }

  String _formatLastChecked(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inDays > 0) return 'منذ ${diff.inDays} ي';
    if (diff.inHours > 0) return 'منذ ${diff.inHours} س';
    return 'منذ ${diff.inMinutes} د';
  }
}
