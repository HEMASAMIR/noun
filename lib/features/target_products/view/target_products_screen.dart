import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/filter_dialog.dart';
import '../widgets/product_card.dart';
import '../model/product_model.dart';
import '../viewmodel/target_products_viewmodel.dart';
import '../../add_product/view/add_product_screen.dart';
import '../../notifications/view/notifications_screen.dart';
import '../../settings/view/settings_screen.dart';
class TargetProductsScreen extends StatelessWidget {
  const TargetProductsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const _TargetProductsView();
  }
}

class _TargetProductsView extends StatefulWidget {
  const _TargetProductsView({Key? key}) : super(key: key);

  @override
  State<_TargetProductsView> createState() => _TargetProductsViewState();
}

class _TargetProductsViewState extends State<_TargetProductsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateToAddProduct(BuildContext context) {
    final viewModel = context.read<TargetProductsViewModel>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: viewModel,
          child: const AddProductScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TargetProductsViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: TextField(
          onChanged: (val) => viewModel.setSearchQuery(val),
          decoration: const InputDecoration(
            hintText: '...ابحث في Wasfy',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16),
          ),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          cursorColor: Colors.white,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {},
        ),
        actions: [
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, child) {
              if (_tabController.index == 2) {
                return IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _navigateToAddProduct(context);
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () {
              HapticFeedback.lightImpact();
              showDialog(
                context: context,
                builder: (context) => const FilterDialogWidget(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'وصل للهدف'),
            Tab(text: 'المعالجة'),
            Tab(text: 'الكل'),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Refresh Banner ──────────────────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            child: viewModel.isRefreshing
                ? _RefreshBanner()
                : const SizedBox.shrink(),
          ),
          // ── Tab Content ─────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                RefreshIndicator(
                  onRefresh: () => viewModel.refreshAllProducts(),
                  child: _buildTabContent(viewModel.reachedTargetProducts, showAddButton: false),
                ),
                RefreshIndicator(
                  onRefresh: () => viewModel.refreshAllProducts(),
                  child: _buildTabContent(viewModel.processingProducts, showAddButton: false),
                ),
                RefreshIndicator(
                  onRefresh: () => viewModel.refreshAllProducts(),
                  child: _buildTabContent(viewModel.allProducts, showAddButton: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(List<ProductModel> products, {bool showAddButton = false}) {
    if (products.isEmpty) {
      return _buildEmptyState(showAddButton: showAddButton);
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return ProductCard(
                key: ValueKey(products[index].id),
                product: products[index],
              );

            },
          ),
        ),
        if (showAddButton) ...[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                _navigateToAddProduct(context);
              },
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              label: const Text(
                'إضافة منتج آخر',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ]
      ],
    );
  }

  Widget _buildEmptyState({bool showAddButton = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.05),
                    blurRadius: 20,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 80,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'لا توجد منتجات حتى الآن',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'قم بإضافة رابط المنتج من المتجر وسنتابع لك السعر لنبلغك متى يصل للهدف!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            if (showAddButton) ...[
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.heavyImpact();
                  _navigateToAddProduct(context);
                },
                icon: const Icon(Icons.add_shopping_cart, color: Colors.white, size: 24),
                label: const Text(
                  'أضف منتجك الأول',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  elevation: 4,
                  shadowColor: AppColors.primary.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Refresh Banner Widget ────────────────────────────────────────────────────

class _RefreshBanner extends StatefulWidget {
  @override
  State<_RefreshBanner> createState() => _RefreshBannerState();
}

class _RefreshBannerState extends State<_RefreshBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TargetProductsViewModel>();

    final int checked = vm.refreshCheckedCount;
    final int total   = vm.refreshTotalCount;
    final String name = vm.refreshCurrentName;

    final double progress = total > 0 ? checked / total : 0.0;
    final int pct = (progress * 100).round();

    return Container(
      width: double.infinity,
      color: const Color(0xFFFFFBEB),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // أيقونة دوارة
                RotationTransition(
                  turns: _spin,
                  child: const Icon(Icons.sync, color: Color(0xFFF59E0B), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // العنوان + العداد + النسبة
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'الفحص الدوري',
                              style: TextStyle(
                                color: Color(0xFF92400E),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Text(
                            '$checked/$total ($pct%)',
                            style: const TextStyle(
                              color: Color(0xFF92400E),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      // اسم المنتج الحالي
                      if (name.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'جاري الفحص (على: $name)',
                          style: const TextStyle(
                            color: Color(0xFFB45309),
                            fontSize: 11.5,
                            fontStyle: FontStyle.italic,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // شريط تقدم محدد القيمة
          LinearProgressIndicator(
            value: progress > 0 ? progress : null,
            minHeight: 4,
            backgroundColor: const Color(0xFFFDE68A),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
          ),
        ],
      ),
    );
  }
}
