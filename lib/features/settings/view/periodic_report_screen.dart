import 'package:flutter/material.dart';
import '../../target_products/viewmodel/target_products_viewmodel.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class PeriodicReportScreen extends StatefulWidget {
  const PeriodicReportScreen({Key? key}) : super(key: key);

  @override
  State<PeriodicReportScreen> createState() => _PeriodicReportScreenState();
}

class _PeriodicReportScreenState extends State<PeriodicReportScreen> {
  List<dynamic> _history = [];
  String? _lastCheckTime;
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final timeStr = prefs.getString('last_periodic_check');
    final String? data = prefs.getString('notifications_history');
    
    if (mounted) {
      setState(() {
        _lastCheckTime = timeStr;
        if (data != null) {
          try {
            _history = jsonDecode(data);
          } catch (_) {}
        }
        _isLoadingHistory = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetViewModel = context.watch<TargetProductsViewModel>();
    final totalProducts = targetViewModel.allProducts.length;
    final reachedTarget = targetViewModel.reachedTargetProducts.length;
    final failed = targetViewModel.allProducts.where((p) => p.error != null).length;
    
    String statusText = 'انتظار الفحص القادم';
    if (_lastCheckTime != null) {
      statusText = 'آخر فحص: ${_formatTime(DateTime.parse(_lastCheckTime!))}';
    }

    final isRefreshing = targetViewModel.isRefreshing;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('تقرير الفحص الدوري', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.success,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث الآن',
            onPressed: isRefreshing ? null : () async {
              await targetViewModel.refreshAllProducts();
              _loadHistory(); // Reload history after manual refresh
            },
          ),
        ],
      ),
      body: Column(
        children: [
              Container(
                color: AppColors.success,
                padding: const EdgeInsets.only(bottom: 24),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isRefreshing)
                          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        else
                          const Icon(Icons.check_circle, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          isRefreshing ? 'جاري الفحص الآن...' : (_lastCheckTime != null ? 'اكتمل الفحص' : 'لا يوجد سجل'),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  statusText,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatBadge('الكل', totalProducts.toString(), AppColors.info),
                    _buildStatBadge('وصل للهدف', reachedTarget.toString(), AppColors.success),
                    _buildStatBadge('فشل', failed.toString(), AppColors.error),
                  ],
                ),
              ),
              Expanded(
                child: _isLoadingHistory
                    ? const Center(child: CircularProgressIndicator())
                    : _history.isEmpty
                        ? _buildEmptyHistory()
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _history.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = _history[index];
                              final time = DateTime.parse(item['time']);
                              return ListTile(
                                leading: Icon(
                                  item['title'].toString().contains('مبروك') ? Icons.celebration : Icons.info_outline,
                                  color: item['title'].toString().contains('مبروك') ? AppColors.success : AppColors.primary,
                                ),
                                title: Text(item['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                subtitle: Text(item['body'] ?? '', style: const TextStyle(fontSize: 12)),
                                trailing: Text(_formatTime(time), style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
                                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
  }

  Widget _buildEmptyHistory() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Opacity(
          opacity: 0.5,
          child: const Icon(Icons.inventory_2_outlined, size: 80, color: AppColors.textLight),
        ),
        const SizedBox(height: 16),
        const Text(
          'لا يوجد نشاطات أو إشعارات سابقة',
          style: TextStyle(color: AppColors.textLight, fontSize: 16),
        ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  Widget _buildStatBadge(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 30,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Center(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
