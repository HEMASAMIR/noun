import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../viewmodel/settings_viewmodel.dart';
import 'import_export_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const _SettingsView();
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SettingsViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الإعدادات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildThemeCard(context, viewModel),
            const SizedBox(height: 16),
            _buildCheckIntervalCard(context, viewModel),
            const SizedBox(height: 16),
            _buildReportCard(context, viewModel),
            const SizedBox(height: 16),
            _buildImportExportCard(context, viewModel),
            const SizedBox(height: 16),
            _buildConcurrentProductsCard(context, viewModel),
            const SizedBox(height: 16),
            _buildForegroundServiceCard(context, viewModel),
            const SizedBox(height: 16),
            _buildVersionCard(viewModel),
            const SizedBox(height: 16),
            _buildCheckAllButton(context, viewModel),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeCard(BuildContext context, SettingsViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                viewModel.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: AppColors.primary,
              ),
              const SizedBox(width: 12),
              const Text(
                'الوضع الليلي',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
              ),
            ],
          ),
          Switch(
            value: viewModel.isDarkMode,
            onChanged: (value) => viewModel.toggleDarkMode(value),
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildCheckIntervalCard(BuildContext context, SettingsViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timer_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'فترة الفحص الدوري',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: viewModel.checkIntervalUnit,
                    icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                    items: ['دقائق', 'ساعات', 'أيام']
                        .map((unit) => DropdownMenuItem(
                              value: unit,
                              child: Text(unit, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) viewModel.setCheckIntervalUnit(val);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primaryLight.withOpacity(0.3),
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withOpacity(0.1),
              trackHeight: 6.0,
            ),
            child: Slider(
              value: viewModel.checkIntervalValue,
              min: 1,
              max: 60,
              divisions: 59,
              label: '${viewModel.checkIntervalValue.toInt()} ${viewModel.checkIntervalUnit}',
              onChanged: (val) => viewModel.setCheckIntervalValue(val),
            ),
          ),
          Center(
            child: Text(
              '${viewModel.checkIntervalValue.toInt()} ${viewModel.checkIntervalUnit}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.infoBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.info.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.info_outline, color: AppColors.info, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'الفحص المتكرر يستهلك بطارية أكثر، لكنه يعطيك تحديثات أسرع للأسعار',
                    style: TextStyle(fontSize: 12, color: AppColors.info),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, SettingsViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.bar_chart, color: AppColors.warning),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'تقرير الفحص الدوري',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'شاهد نتائج آخر فحص مباشر',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => viewModel.openPeriodicReport(context),
            icon: const Icon(Icons.bar_chart, color: Colors.white),
            label: const Text('عرض التقرير', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportExportCard(BuildContext context, SettingsViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.swap_vert, color: AppColors.success),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'الاستيراد والتصدير',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'نقل البيانات بين الأجهزة',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ImportExportScreen()),
              );
            },
            icon: const Icon(Icons.swap_horiz, color: Colors.white),
            label: const Text('إدارة البيانات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConcurrentProductsCard(BuildContext context, SettingsViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.sync, color: AppColors.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'عدد المنتجات المتزامنة',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'كم منتج يمكن فحصه في نفس الوقت',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Text(
            'الحد الأقصى: ${viewModel.selectedConcurrentProducts} منتج في وقت واحد',
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSelectionButton(1, viewModel),
              const SizedBox(width: 12),
              _buildSelectionButton(2, viewModel),
              const SizedBox(width: 12),
              _buildSelectionButton(3, viewModel),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warningBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.warning.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.lightbulb_outline, color: AppColors.warning, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'كلما زاد العدد، زادت السرعة لكن قد يؤدي لحظر مؤقت من الموقع. نوصي بـ 2 منتجات',
                    style: TextStyle(fontSize: 12, color: AppColors.warning),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionButton(int number, SettingsViewModel viewModel) {
    final isSelected = viewModel.selectedConcurrentProducts == number;
    return Expanded(
      child: GestureDetector(
        onTap: () => viewModel.setConcurrentProducts(number),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                : [],
          ),
          child: Column(
            children: [
              Text(
                number.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
              Text(
                'منتجات',
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForegroundServiceCard(BuildContext context, SettingsViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.flash_on, color: AppColors.warning),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Foreground Service وضع',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'للحصول على فحص دوري موثوق وبدون انقطاع',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    viewModel.isForegroundServiceEnabled ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: viewModel.isForegroundServiceEnabled ? AppColors.success : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    viewModel.isForegroundServiceEnabled ? 'مفعل' : 'غير مفعل',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: viewModel.isForegroundServiceEnabled ? AppColors.success : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Switch(
                value: viewModel.isForegroundServiceEnabled,
                onChanged: (value) => viewModel.toggleForegroundService(value),
                activeColor: AppColors.primary,
                activeTrackColor: AppColors.primaryLight,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.successBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.security, color: AppColors.success, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'المميزات المدعومة:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildFeatureListItem('فحص كامل بدون توقف'),
                _buildFeatureListItem('يعمل حتى مع الشاشة المغلقة'),
                _buildFeatureListItem('إشعار دائم مع تحديثات مباشرة'),
                _buildFeatureListItem('يحافظ على نشاط الجهاز WakeLock'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureListItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, right: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildVersionCard(SettingsViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Icon(Icons.info_outline, color: AppColors.primary),
              SizedBox(width: 8),
              Text('إصدار التطبيق', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
            ],
          ),
          Text(viewModel.appVersion, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCheckAllButton(BuildContext context, SettingsViewModel viewModel) {
    return ElevatedButton.icon(
      onPressed: () => viewModel.checkAllProductsNow(context),
      icon: const Icon(Icons.refresh, color: Colors.white),
      label: const Text(
        'فحص جميع المنتجات الآن',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
      ),
    );
  }
}
