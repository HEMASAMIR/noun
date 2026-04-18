import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../model/product_model.dart';
import '../viewmodel/target_products_viewmodel.dart';

class ProductDetailsScreen extends StatelessWidget {
  final ProductModel product;

  const ProductDetailsScreen({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<TargetProductsViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('تفاصيل المنتج', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              _showDeleteDialog(context, viewModel);
            },
            tooltip: 'حذف المنتج',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Hero(
              tag: 'product_image_${product.id}',
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: product.imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(product.imageUrl, fit: BoxFit.contain),
                      )
                    : const Icon(Icons.phone_android, size: 100, color: AppColors.textLight),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              product.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('السعر الحالي (الأقل)', style: TextStyle(color: AppColors.textSecondary)),
                    Text(
                      '${product.currentPrice.toStringAsFixed(2)} ريال',
                      style: const TextStyle(color: AppColors.success, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('السعر المستهدف', style: TextStyle(color: AppColors.textSecondary)),
                    Text(
                      '${product.targetPrice.toStringAsFixed(2)} ريال',
                      style: const TextStyle(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(height: 32, thickness: 1),
            _buildDetailRow(Icons.storefront, 'المتجر الرئيسي', product.storeName),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.local_shipping, 'نوع التوصيل', _getDeliveryTypeName(product.deliveryType)),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.people, 'عدد المتابعين للسعر', '${product.watchers} مستخدمين'),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.link, 'الرابط الأصلي', product.originalUrl, isLink: true),
            const SizedBox(height: 32),
            
          const SizedBox(height: 32),
          
          ElevatedButton.icon(
            onPressed: () {
              Share.share(
                'شاهد هذا المنتج على Wasfy: ${product.title}\nالسعر الحالي: ${product.currentPrice} ريال\nالرابط: ${product.originalUrl}',
                subject: 'مشاركة منتج من تطبيق Wasfy',
              );
            },
            icon: const Icon(Icons.share, color: Colors.white),
            label: const Text('مشاركة المنتج مع الأصدقاء', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.open_in_browser, color: Colors.white),
              label: const Text('فتح في الموقع الأصلي', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _showDeleteDialog(BuildContext context, TargetProductsViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المنتج'),
        content: const Text('هل أنت متأكد من رغبتك في حذف هذا المنتج من قائمة المتابعة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              viewModel.removeProduct(product.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to list
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {bool isLink = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: isLink ? Colors.blueAccent : AppColors.textPrimary,
              decoration: isLink ? TextDecoration.underline : TextDecoration.none,
            ),
          ),
        ),
      ],
    );
  }

  String _getDeliveryTypeName(DeliveryType type) {
    switch (type) {
      case DeliveryType.express: return 'اكسبريس';
      case DeliveryType.market: return 'ماركت';
      case DeliveryType.superMall: return 'سوبر مول';
      default: return 'عادي';
    }
  }
}
