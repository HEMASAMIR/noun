import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../viewmodel/notifications_viewmodel.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const _NotificationsView();
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView({Key? key}) : super(key: key);

  /// يحدد أيقونة الإشعار بناءً على العنوان
  IconData _iconForNotification(String title) {
    final t = title.toLowerCase();
    if (t.contains('هدف') || t.contains('نزل') || t.contains('سعر'))
      return Icons.price_check_rounded;
    if (t.contains('إضافة') || t.contains('أضفت') || t.contains('تحليل'))
      return Icons.add_shopping_cart_rounded;
    if (t.contains('تحديث') || t.contains('تم تحديث'))
      return Icons.sync_rounded;
    if (t.contains('استيراد')) return Icons.download_rounded;
    if (t.contains('تصدير')) return Icons.upload_rounded;
    if (t.contains('حذف')) return Icons.delete_outline_rounded;
    if (t.contains('مرحباً') || t.contains('أهلاً'))
      return Icons.waving_hand_rounded;
    return Icons.notifications_rounded;
  }

  /// يحدد لون الإشعار بناءً على العنوان
  Color _colorForNotification(String title) {
    final t = title.toLowerCase();
    if (t.contains('هدف') || t.contains('نزل')) return AppColors.success;
    if (t.contains('إضافة') || t.contains('أضفت')) return AppColors.primary;
    if (t.contains('تحديث')) return Colors.teal;
    if (t.contains('استيراد')) return Colors.deepPurple;
    if (t.contains('تصدير')) return Colors.orange;
    if (t.contains('حذف')) return AppColors.error;
    if (t.contains('مرحباً') || t.contains('أهلاً')) return Colors.amber;
    return AppColors.info;
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    return '${time.day}/${time.month}/${time.year}';
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<NotificationsViewModel>();
    final unreadCount =
        viewModel.notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'الإشعارات',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (viewModel.hasNotifications) ...[
            if (unreadCount > 0)
              IconButton(
                icon: const Icon(Icons.done_all_rounded),
                onPressed: () {
                  for (int i = 0;
                      i < viewModel.notifications.length;
                      i++) {
                    viewModel.markAsRead(i);
                  }
                },
                tooltip: 'تحديد الكل كمقروء',
              ),
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: viewModel.clearAll,
              tooltip: 'مسح الكل',
            ),
          ],
        ],
      ),
      body:
          viewModel.hasNotifications
              ? _buildNotificationsList(viewModel)
              : _buildEmptyState(),
    );
  }

  Widget _buildNotificationsList(NotificationsViewModel viewModel) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: viewModel.notifications.length,
      itemBuilder: (context, index) {
        final notification = viewModel.notifications[index];
        final color = _colorForNotification(notification.title);
        final icon = _iconForNotification(notification.title);

        return Dismissible(
          key: ValueKey('${notification.title}_${notification.time}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete_outline_rounded,
                color: AppColors.error),
          ),
          onDismissed: (_) => viewModel.removeNotification(index),
          child: GestureDetector(
            onTap: () => viewModel.markAsRead(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: notification.isRead
                    ? AppColors.surface
                    : color.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: notification.isRead
                      ? AppColors.border.withOpacity(0.4)
                      : color.withOpacity(0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: notification.isRead
                        ? Colors.transparent
                        : color.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Stack(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 22),
                      ),
                      if (!notification.isRead)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 11,
                            height: 11,
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.surface, width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontWeight: notification.isRead
                                      ? FontWeight.w500
                                      : FontWeight.bold,
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatTime(notification.time),
                              style: const TextStyle(
                                color: AppColors.textLight,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          notification.body,
                          style: TextStyle(
                            color: notification.isRead
                                ? AppColors.textSecondary
                                : AppColors.textPrimary.withOpacity(0.8),
                            fontSize: 13,
                            height: 1.5,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!notification.isRead)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'جديد',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'لا توجد إشعارات حتى الآن',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'ستصلك إشعارات فور حدوث أي تحديث في التطبيق',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 28),
            // Types preview
            _buildNotificationTypeTile(
              icon: Icons.price_check_rounded,
              color: AppColors.success,
              label: 'وصول المنتج للسعر المستهدف',
            ),
            _buildNotificationTypeTile(
              icon: Icons.add_shopping_cart_rounded,
              color: AppColors.primary,
              label: 'إضافة منتج جديد للمتابعة',
            ),
            _buildNotificationTypeTile(
              icon: Icons.sync_rounded,
              color: Colors.teal,
              label: 'تحديث أسعار المنتجات',
            ),
            _buildNotificationTypeTile(
              icon: Icons.download_rounded,
              color: Colors.deepPurple,
              label: 'استيراد وتصدير البيانات',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTypeTile({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
