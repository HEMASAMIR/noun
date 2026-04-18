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

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<NotificationsViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الإشعارات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (viewModel.hasNotifications)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: viewModel.clearAll,
              tooltip: 'مسح الكل',
            ),
        ],
      ),
      body: viewModel.hasNotifications
          ? _buildNotificationsList(viewModel)
          : _buildEmptyState(),
    );
  }

  Widget _buildNotificationsList(NotificationsViewModel viewModel) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: viewModel.notifications.length,
      itemBuilder: (context, index) {
        final notification = viewModel.notifications[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 0,
          color: notification.isRead ? AppColors.surface : AppColors.infoBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: notification.isRead ? AppColors.border : AppColors.info.withOpacity(0.3),
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Stack(
              children: [
                CircleAvatar(
                  backgroundColor: notification.isRead ? AppColors.border : AppColors.primaryLight.withOpacity(0.2),
                  child: Icon(Icons.notifications_active, color: notification.isRead ? AppColors.textLight : AppColors.primary),
                ),
                if (!notification.isRead)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(
              notification.title,
              style: TextStyle(
                fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                notification.body,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
            trailing: Text(
              '${notification.time.hour}:${notification.time.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(color: AppColors.textLight, fontSize: 12),
            ),
            onTap: () => viewModel.markAsRead(index),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.warningBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              size: 64,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'لا توجد إشعارات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'سيظهر هنا إشعار عندما يصل أي منتج للسعر المستهدف',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
