import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../model/product_model.dart';

class ShareProductSheet extends StatelessWidget {
  final ProductModel product;

  const ShareProductSheet({Key? key, required this.product}) : super(key: key);

  /// يبني نص المشاركة الكامل
  String _buildShareText() {
    final savings = product.currentPrice > 0 && product.targetPrice > 0
        ? (product.targetPrice - product.currentPrice).abs()
        : null;
    final buffer = StringBuffer();
    buffer.writeln('🛍️ ${product.title}');
    buffer.writeln('');
    buffer.writeln('💰 السعر الحالي (الأقل): ${product.currentPrice.toStringAsFixed(2)} ريال');
    buffer.writeln('🎯 السعر المستهدف: ${product.targetPrice.toStringAsFixed(2)} ريال');
    if (savings != null && savings > 0) {
      buffer.writeln('✂️ وفّر: ${savings.toStringAsFixed(2)} ريال!');
    }
    if (product.storeName.isNotEmpty) {
      buffer.writeln('🏪 المتجر: ${product.storeName}');
    }
    buffer.writeln('');
    buffer.writeln('🔗 ${product.originalUrl}');
    buffer.writeln('');
    buffer.writeln('تابعني على تطبيق Wasfy لأفضل عروض الأسعار 🚀');
    return buffer.toString();
  }

  static void show(BuildContext context, ProductModel product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ShareProductSheet(product: product),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shareText = _buildShareText();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.share_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مشاركة المنتج',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'اختر طريقة المشاركة',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Product mini-preview
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                if (product.imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      product.imageUrl,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.storefront,
                        size: 36,
                        color: AppColors.textLight,
                      ),
                    ),
                  )
                else
                  const Icon(Icons.storefront, size: 36, color: AppColors.textLight),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${product.currentPrice.toStringAsFixed(2)} ريال',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Share options grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ShareOption(
                icon: Icons.share_rounded,
                label: 'مشاركة عامة',
                color: AppColors.primary,
                onTap: () {
                  Navigator.pop(context);
                  Share.share(shareText, subject: 'مشاركة منتج من تطبيق Wasfy');
                },
              ),
              _ShareOption(
                icon: Icons.copy_rounded,
                label: 'نسخ الرابط',
                color: Colors.teal,
                onTap: () {
                  Clipboard.setData(ClipboardData(text: product.originalUrl));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8),
                          Text('تم نسخ الرابط بنجاح!'),
                        ],
                      ),
                      backgroundColor: Colors.teal,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
              ),
              _ShareOption(
                icon: Icons.message_rounded,
                label: 'مشاركة النص',
                color: Colors.deepPurple,
                onTap: () {
                  Clipboard.setData(ClipboardData(text: shareText));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8),
                          Text('تم نسخ تفاصيل المنتج!'),
                        ],
                      ),
                      backgroundColor: Colors.deepPurple,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
              ),
              _ShareOption(
                icon: Icons.share_location_rounded,
                label: 'مشاركة الكل',
                color: Colors.orange,
                onTap: () {
                  Navigator.pop(context);
                  Share.shareUri(Uri.parse(product.originalUrl));
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Cancel button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: AppColors.border.withOpacity(0.2),
              ),
              child: const Text(
                'إلغاء',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.25)),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
