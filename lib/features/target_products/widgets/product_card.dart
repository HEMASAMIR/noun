import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wasfy/features/target_products/viewmodel/target_products_viewmodel.dart';
import '../../../core/theme/app_colors.dart';
import '../model/product_model.dart';
import '../view/product_details_screen.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
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
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(
                    product.isAnalyzing ? 0.15 : 0.05,
                  ),
                  blurRadius: product.isAnalyzing ? 15 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // الجزء الأيسر: الصورة والسعر المستهدف
                    _buildImageSection(),
                    const SizedBox(width: 16),
                    // الجزء الأيمن: التفاصيل
                    _buildDetailsSection(),
                  ],
                ),
                // جديد: عرض قائمة أفضل البائعين
                if (!product.isAnalyzing && product.sellers.isNotEmpty)
                  _buildSellersList(),
              ],
            ),
          ),
        ),
        _buildDeleteButton(context),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      children: [
        Hero(
          tag: 'product_image_${product.id}',
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border.withOpacity(0.5)),
            ),
            child: product.isAnalyzing
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
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

  Widget _buildDetailsSection() {
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
          if (product.isAnalyzing)
            const Text(
              'جاري التحليل الذكي...',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
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
              _infoItem(Icons.access_time, _formatTimeAdded(product.timeAdded)),
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

  String _formatTimeAdded(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inDays > 0) return 'منذ ${diff.inDays} ي';
    if (diff.inHours > 0) return 'منذ ${diff.inHours} س';
    return 'منذ ${diff.inMinutes} د';
  }
}
