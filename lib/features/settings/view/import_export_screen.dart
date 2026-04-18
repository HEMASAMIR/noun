import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
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
              description: 'حفظ نسخة احتياطية من جميع المنتجات',
              icon: Icons.upload_file,
              buttonLabel: 'تصدير الآن',
              buttonColor: AppColors.success,
              onPressed: () => _handleExport(context, targetViewModel),
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              title: 'استيراد البيانات',
              description: 'استرجاع المنتجات من ملف تم تصديره',
              icon: Icons.download_for_offline,
              buttonLabel: 'اختيار ملف',
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.info_outline, color: AppColors.info, size: 28),
          const SizedBox(height: 12),
          const Text(
            'البيانات الحالية',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'منتج $count 📦',
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
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
    required Color buttonColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.textLight, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.arrow_upward, size: 18),
            label: Text(buttonLabel),
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomInfoBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
      ),
      child: Row(
        children: const [
          Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'لم يتم اختيار ملف!',
              style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          Icon(Icons.close, color: AppColors.error, size: 16),
        ],
      ),
    );
  }

  Future<void> _handleExport(
    BuildContext context,
    TargetProductsViewModel viewModel,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final jsonStr = viewModel.exportToJson();
      final directory = await getTemporaryDirectory();
      final file = File(
        '${directory.path}/wasfy_export_${DateTime.now().millisecondsSinceEpoch}.json',
      );
      await file.writeAsString(jsonStr);

      if (context.mounted) {
        Navigator.pop(context); // Close loading
        final box = context.findRenderObject() as RenderBox?;
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'بيانات تطيبق وصفي (المنتجات المستهدفة)',
          sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'حدث خطأ أثناء التصدير, يرجى المحاولة مرة أخرى.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleImport(
    BuildContext context,
    TargetProductsViewModel viewModel,
  ) async {
    bool isDialogOpen = false; // ضيف العلم ده (Flag)

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null) {
        if (context.mounted) {
          isDialogOpen = true; // حدد إننا فتحنا ديالوج
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(color: AppColors.success),
            ),
          );
        }

        File file = File(result.files.single.path!);
        String fileContent = await file.readAsString();
        final success = await viewModel.importFromJson(fileContent);

        if (context.mounted) {
          if (isDialogOpen) {
            Navigator.pop(context); // اقفل الديالوج فقط لو كان مفتوح
            isDialogOpen = false;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? 'تم استيراد البيانات بنجاح!'
                    : 'حدث خطأ في قراءة ملف البيانات...',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // هنا الفكرة: اتأكد إن الـ context لسه موجود وكمان إن فيه Dialog مفتوح فعلاً
      if (context.mounted) {
        if (isDialogOpen) {
          Navigator.of(context).pop();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء الاستيراد.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  //   Future<void> _handleImport(BuildContext context, TargetProductsViewModel viewModel) async {
  //     try {
  //       FilePickerResult? result = await FilePicker.platform.pickFiles(
  //         type: FileType.any,
  //       );

  //       if (result != null) {
  //         // Show loading
  //         if (context.mounted) {
  //           showDialog(
  //             context: context,
  //             barrierDismissible: false,
  //             builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.success)),
  //           );
  //         }

  //         File file = File(result.files.single.path!);
  //         String fileContent = await file.readAsString();
  //         final success = await viewModel.importFromJson(fileContent);

  //         if (context.mounted) {
  //           Navigator.pop(context); // Close loading
  //           ScaffoldMessenger.of(context).showSnackBar(
  //             SnackBar(
  //               content: Text(
  //                 success ? 'تم استيراد البيانات بنجاح!' : 'حدث خطأ في قراءة ملف البيانات، يرجى التأكد من الملف.',
  //                 style: const TextStyle(color: Colors.white),
  //               ),
  //               backgroundColor: success ? Colors.green : Colors.red,
  //             ),
  //           );
  //         }
  //       }
  //     } catch (e) {
  //       if (context.mounted) {
  //         // Hide loading if showing (might crash if dialog isn't showing, try/finally better)
  //         Navigator.of(context, rootNavigator: true).pop();
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(content: Text('حدث خطأ أثناء الاستيراد.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
  //         );
  //       }
  //     }
  //   }
  // }
}
