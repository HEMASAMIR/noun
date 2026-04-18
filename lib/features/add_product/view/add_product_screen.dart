import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../viewmodel/add_product_viewmodel.dart';
import '../../target_products/viewmodel/target_products_viewmodel.dart';

class AddProductScreen extends StatelessWidget {
  const AddProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AddProductViewModel(),
      child: const _AddProductView(),
    );
  }
}

class _AddProductView extends StatelessWidget {
  const _AddProductView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AddProductViewModel>();

    // Auto-check clipboard on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (viewModel.products.isNotEmpty &&
          viewModel.products[0].linkController.text.isEmpty) {
        viewModel.checkClipboard(0);
      }
    });
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            titleSpacing: 0,
            backgroundColor: AppColors.primary,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Column(
            children: [
              // Header Section
              Container(
                width: double.infinity,
                color: AppColors.primary,
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        'إضافة منتج جديد',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: const [
                        Icon(
                          Icons.add_shopping_cart,
                          color: Colors.white,
                          size: 28,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'أضف منتج للبحث عنه',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'اكتب اسم المنتج أو رابطه وسنجيب أقل سعر من Google Shopping',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Product Form List
                    ...List.generate(viewModel.products.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'المنتج ${index + 1}',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (viewModel.products.length > 1)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: AppColors.error,
                                      ),
                                      splashRadius: 20,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () =>
                                          viewModel.removeProduct(index),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'اسم المنتج أو رابطه *',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller:
                                    viewModel.products[index].linkController,
                                decoration: InputDecoration(
                                  hintText: 'مثال: iPhone 15 Pro أو https://...',
                                  hintStyle: const TextStyle(
                                    color: AppColors.textLight,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: AppColors.textSecondary,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.background,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'السعر المستهدف *',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller:
                                    viewModel.products[index].priceController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'مثال: 500',
                                  hintStyle: const TextStyle(
                                    color: AppColors.textLight,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.attach_money,
                                    color: AppColors.textSecondary,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.background,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'اقتراحات السعر المستهدف:',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildSuggestionChip(
                                      context,
                                      viewModel,
                                      index,
                                      0.05,
                                      'خصم 5%',
                                    ),
                                    const SizedBox(width: 8),
                                    _buildSuggestionChip(
                                      context,
                                      viewModel,
                                      index,
                                      0.10,
                                      'خصم 10%',
                                    ),
                                    const SizedBox(width: 8),
                                    _buildSuggestionChip(
                                      context,
                                      viewModel,
                                      index,
                                      0.20,
                                      'خصم 20%',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    OutlinedButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        viewModel.addProduct();
                      },
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: AppColors.primary,
                      ),
                      label: const Text(
                        'إضافة منتج آخر',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: AppColors.primary.withOpacity(0.5),
                          width: 1.5,
                        ),
                        backgroundColor: AppColors.primary.withOpacity(0.05),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.infoBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.info.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.lightbulb_outline,
                            color: AppColors.info,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'نصائح للتتبع',
                                  style: TextStyle(
                                    color: AppColors.info,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      size: 14,
                                      color: AppColors.info,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '🛒 يمكنك كتابة اسم المنتج مباشرة (مثال: iPhone 15 Pro Max) أو لصق رابطه من أي متجر. سنبحث عنه في Google Shopping تلقائياً ونجيب أقل سعر متاح.',
                                        style: TextStyle(
                                          color: AppColors.info.withOpacity(
                                            0.9,
                                          ),
                                          fontSize: 12,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                          ),
                          child: const Text(
                            'إلغاء',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              HapticFeedback.mediumImpact();
                              final targetViewModel = context
                                  .read<TargetProductsViewModel>();
                              await viewModel.submitProducts(targetViewModel);

                              if (!context.mounted) return;

                              if (viewModel.errorMessage != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(viewModel.errorMessage!),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                                return;
                              }

                              Navigator.pop(context);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: const [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'تمت إضافة المنتج بنجاح!',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: AppColors.success,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 20,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                  elevation: 6,
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                              HapticFeedback.heavyImpact(); // Success haptic
                            },
                            icon: const Icon(
                              Icons.check_circle_outline,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'إضافة المنتج',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionChip(
    BuildContext context,
    AddProductViewModel viewModel,
    int index,
    double discount,
    String label,
  ) {
    return InkWell(
      onTap: () => viewModel.setSuggestedPrice(
        index,
        1000,
        discount,
      ), // Using 1000 as a mock base price for now
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
