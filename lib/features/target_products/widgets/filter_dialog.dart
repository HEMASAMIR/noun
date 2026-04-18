import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../viewmodel/target_products_viewmodel.dart';
import '../model/product_model.dart';

class FilterDialogWidget extends StatelessWidget {
  const FilterDialogWidget({Key? key}) : super(key: key);

  void _showChicSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TargetProductsViewModel>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'الفرز',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              _buildFilterItem(
                context,
                'الأحدث أولاً',
                Icons.info_outline,
                selected: viewModel.currentSortOption == ProductSortOption.newest,
                onTap: () {
                  viewModel.updateSortOption(ProductSortOption.newest);
                  _showChicSnackBar(context, 'ترتيب: الأحدث أولاً');
                  Navigator.pop(context);
                },
              ),
              _buildFilterItem(
                context,
                'الأقدم أولاً',
                Icons.history,
                selected: viewModel.currentSortOption == ProductSortOption.oldest,
                onTap: () {
                  viewModel.updateSortOption(ProductSortOption.oldest);
                  _showChicSnackBar(context, 'ترتيب: الأقدم أولاً');
                  Navigator.pop(context);
                },
              ),
              _buildFilterItem(
                context,
                'السعر: الأعلى - الأقل',
                Icons.arrow_downward,
                selected: viewModel.currentSortOption == ProductSortOption.priceHighToLow,
                onTap: () {
                  viewModel.updateSortOption(ProductSortOption.priceHighToLow);
                  _showChicSnackBar(context, 'ترتيب: السعر من الأعلى');
                  Navigator.pop(context);
                },
              ),
              _buildFilterItem(
                context,
                'السعر: الأقل - الأعلى',
                Icons.arrow_upward,
                selected: viewModel.currentSortOption == ProductSortOption.priceLowToHigh,
                onTap: () {
                  viewModel.updateSortOption(ProductSortOption.priceLowToHigh);
                  _showChicSnackBar(context, 'ترتيب: السعر من الأقل');
                  Navigator.pop(context);
                },
              ),
              _buildFilterItem(
                context,
                'الاسم: أ - ي',
                Icons.sort_by_alpha,
                selected: viewModel.currentSortOption == ProductSortOption.nameAZ,
                onTap: () {
                  viewModel.updateSortOption(ProductSortOption.nameAZ);
                  _showChicSnackBar(context, 'ترتيب: الاسم أ - ي');
                  Navigator.pop(context);
                },
              ),
              _buildFilterItem(
                context,
                'الاسم: ي - أ',
                Icons.sort_by_alpha,
                selected: viewModel.currentSortOption == ProductSortOption.nameZA,
                onTap: () {
                  viewModel.updateSortOption(ProductSortOption.nameZA);
                  _showChicSnackBar(context, 'ترتيب: الاسم ي - أ');
                  Navigator.pop(context);
                },
              ),
              _buildFilterItem(
                context,
                'آخر فحص',
                Icons.update,
                selected: viewModel.currentSortOption == ProductSortOption.lastChecked,
                onTap: () {
                  viewModel.updateSortOption(ProductSortOption.lastChecked);
                  _showChicSnackBar(context, 'ترتيب: آخر فحص');
                  Navigator.pop(context);
                },
              ),
              _buildFilterItem(
                context,
                'غير متوفر',
                Icons.close,
                color: AppColors.error,
                selected: viewModel.currentSortOption == ProductSortOption.notAvailable,
                onTap: () {
                  viewModel.updateSortOption(ProductSortOption.notAvailable);
                  _showChicSnackBar(context, 'ترتيب: غير متوفر');
                  Navigator.pop(context);
                },
              ),
              const Divider(color: AppColors.divider, thickness: 1),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'نوع التوصيل',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              _buildFilterItem(
                context,
                'الكل',
                Icons.all_inclusive,
                selected: viewModel.currentDeliveryFilter == null,
                onTap: () {
                  viewModel.updateDeliveryFilter(null);
                  _showChicSnackBar(context, 'تصفية: الكل');
                  Navigator.pop(context);
                },
              ),
              _buildFilterItem(
                context,
                'نون إكسبرس',
                Icons.flash_on,
                color: AppColors.warning,
                selected: viewModel.currentDeliveryFilter == DeliveryType.express,
                onTap: () {
                  viewModel.updateDeliveryFilter(DeliveryType.express);
                  _showChicSnackBar(context, 'تصفية: نون إكسبرس');
                  Navigator.pop(context);
                },
              ),
              _buildFilterItem(
                context,
                'سوبر مول',
                Icons.store,
                color: Colors.purple,
                selected: viewModel.currentDeliveryFilter == DeliveryType.superMall,
                onTap: () {
                  viewModel.updateDeliveryFilter(DeliveryType.superMall);
                  _showChicSnackBar(context, 'تصفية: سوبر مول');
                  Navigator.pop(context);
                },
              ),
              _buildFilterItem(
                context,
                'ماركت بليس',
                Icons.shopping_bag,
                color: AppColors.info,
                selected: viewModel.currentDeliveryFilter == DeliveryType.market,
                onTap: () {
                  viewModel.updateDeliveryFilter(DeliveryType.market);
                  _showChicSnackBar(context, 'تصفية: ماركت بليس');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterItem(BuildContext context, String title, IconData icon,
      {required VoidCallback onTap, bool selected = false, Color? color}) {
    return Container(
      color: selected ? AppColors.infoBg : Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: color ?? (selected ? AppColors.primary : AppColors.textSecondary), size: 20),
        title: Text(
          title,
          style: TextStyle(
            color: selected ? AppColors.primary : AppColors.textPrimary,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: selected ? const Icon(Icons.check, color: AppColors.primary) : null,
        dense: true,
        onTap: onTap,
      ),
    );
  }
}
