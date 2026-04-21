import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import '../../../core/theme/app_colors.dart';
import '../../target_products/viewmodel/target_products_viewmodel.dart';

class ImportExportScreen extends StatelessWidget {
  const ImportExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final targetViewModel = context.watch<TargetProductsViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'الاستيراد والتصدير',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
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
            _buildStatsCard(targetViewModel.allProducts.length),
            const SizedBox(height: 16),
            _buildActionCard(
              title: 'تصدير البيانات',
              description: 'احفظ نسخة احتياطية من جميع منتجاتك وشاركها بسهولة',
              icon: Icons.upload_file_rounded,
              buttonLabel: 'تصدير الآن',
              buttonIcon: Icons.upload_file_rounded,
              buttonColor: AppColors.success,
              onPressed: () => _handleExport(context, targetViewModel),
              onShare: () => _handleExport(context, targetViewModel),
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              title: 'استيراد البيانات',
              description: 'استعد منتجاتك من ملف تم تصديره مسبقاً (.json)',
              icon: Icons.download_for_offline_rounded,
              buttonLabel: 'اختيار ملف',
              buttonIcon: Icons.folder_open_rounded,
              buttonColor: AppColors.info,
              onPressed: () => _handleImport(context, targetViewModel),
            ),
            const SizedBox(height: 24),
            _buildBottomInfoBox(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(int count) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.08),
            AppColors.primaryLight.withOpacity(0.04),
          ],
        ),
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'بياناتك الحالية',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$count منتج محفوظ',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String description,
    required IconData icon,
    required String buttonLabel,
    required IconData buttonIcon,
    required Color buttonColor,
    required VoidCallback onPressed,
    VoidCallback? onShare,
  }) {
    return Stack(
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(20, 20, onShare != null ? 56 : 20, 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: buttonColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: buttonColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onPressed,
                icon: Icon(buttonIcon, size: 18, color: Colors.white),
                label: Text(
                  buttonLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
        if (onShare != null)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: buttonColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.share_rounded, color: buttonColor, size: 18),
                onPressed: onShare,
                tooltip: 'مشاركة',
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomInfoBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.infoBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.info_outline_rounded, color: AppColors.info, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'يمكنك استخدام هذه الخاصية لنقل بياناتك بين الأجهزة أو حفظ نسخة احتياطية منها. تأكد من اختيار ملف بصيغة JSON تم تصديره من التطبيق.',
              style: TextStyle(
                color: AppColors.info,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// -----------  تصدير  -----------
  Future<void> _handleExport(
    BuildContext context,
    TargetProductsViewModel viewModel,
  ) async {
    if (viewModel.allProducts.isEmpty) {
      _showFriendlySnackBar(
        context,
        icon: Icons.inbox_rounded,
        message: 'لا توجد منتجات لتصديرها حتى الآن — أضف منتجاً أولاً!',
        color: AppColors.warning,
      );
      return;
    }

    _showLoadingDialog(context, 'جاري تجهيز البيانات...');

    try {
      final jsonStr = viewModel.exportToJson();
      final directory = await getTemporaryDirectory();
      final file = File(
        '${directory.path}/wasfy_export_${DateTime.now().millisecondsSinceEpoch}.json',
      );
      await file.writeAsString(jsonStr);

      if (context.mounted) {
        Navigator.pop(context); // close loading
        final box = context.findRenderObject() as RenderBox?;
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'بيانات تطبيق Wasfy — المنتجات المستهدفة',
          sharePositionOrigin: box != null
              ? box.localToGlobal(Offset.zero) & box.size
              : null,
        );
      }
    } catch (_) {
      if (context.mounted) {
        Navigator.pop(context); // close loading
        _showFriendlySnackBar(
          context,
          icon: Icons.cloud_off_rounded,
          message: 'تعذّر تصدير البيانات، يرجى المحاولة مرة أخرى.',
          color: AppColors.error,
        );
      }
    }
  }

  /// -----------  استيراد  -----------
  Future<void> _handleImport(
    BuildContext context,
    TargetProductsViewModel viewModel,
  ) async {
    try {
      // 1️⃣ فتح منتقي الملفات
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true, // مهم جداً لدعم Flutter Web
      );

      // المستخدم لم يختر ملفاً (ألغى العملية)
      if (result == null || result.files.isEmpty) return;

      final pickedFile = result.files.single;

      // 2️⃣ تحميل محتوى الملف (يدعم Web + Mobile)
      String fileContent;
      if (kIsWeb) {
        // على الويب نستخدم bytes مباشرة
        final bytes = pickedFile.bytes;
        if (bytes == null || bytes.isEmpty) {
          if (context.mounted) {
            _showFriendlySnackBar(
              context,
              icon: Icons.file_open_rounded,
              message: 'تعذّر قراءة الملف، جرب ملفاً آخر.',
              color: AppColors.warning,
            );
          }
          return;
        }
        fileContent = utf8.decode(bytes);
      } else {
        final path = pickedFile.path;
        if (path == null) {
          if (context.mounted) {
            _showFriendlySnackBar(
              context,
              icon: Icons.file_open_rounded,
              message: 'تعذّر العثور على الملف على هذا الجهاز.',
              color: AppColors.warning,
            );
          }
          return;
        }
        fileContent = await File(path).readAsString();
      }

      // 3️⃣ تحقق مبدئي من صيغة JSON
      try {
        jsonDecode(fileContent); // just to validate
      } catch (_) {
        if (context.mounted) {
          _showFriendlySnackBar(
            context,
            icon: Icons.description_rounded,
            message:
                'الملف المختار غير صالح. يرجى اختيار ملف JSON تم تصديره من التطبيق.',
            color: AppColors.warning,
          );
        }
        return;
      }

      // 4️⃣ عرض loading
      if (context.mounted)
        _showLoadingDialog(context, 'جاري استيراد البيانات...');

      final success = await viewModel.importFromJson(fileContent);

      if (context.mounted) {
        Navigator.pop(context); // close loading
        if (success) {
          _showFriendlySnackBar(
            context,
            icon: Icons.check_circle_rounded,
            message: 'تم استيراد بياناتك بنجاح! 🎉',
            color: AppColors.success,
          );
        } else {
          _showFriendlySnackBar(
            context,
            icon: Icons.description_rounded,
            message:
                'الملف لا يحتوي على بيانات صالحة، تأكد من اختيار الملف الصحيح.',
            color: AppColors.warning,
          );
        }
      }
    } catch (_) {
      // أي خطأ غير متوقع — رسالة ودية بدون تفاصيل تقنية
      if (context.mounted) {
        // حاول إغلاق loading لو كان مفتوحاً
        try {
          Navigator.pop(context);
        } catch (_) {}
        _showFriendlySnackBar(
          context,
          icon: Icons.wifi_off_rounded,
          message: 'حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى.',
          color: AppColors.error,
        );
      }
    }
  }

  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(width: 20),
              Text(
                message,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFriendlySnackBar(
    BuildContext context, {
    required IconData icon,
    required String message,
    required Color color,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
