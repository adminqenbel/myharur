import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api_client.dart';
import '../theme.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final response = await ApiClient.dio.get('/notifications');
      if (mounted) {
        setState(() {
          _notifications = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markAsRead(int id, int index) async {
    try {
      await ApiClient.dio.put('/notifications/$id/read');
      setState(() {
        _notifications[index]['is_read'] = true;
      });
    } catch (e) {
      // Handle error implicitly
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 64, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text("No new notifications", style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: _notifications.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final n = _notifications[index];
                    final isRead = n['is_read'] == true;
                    
                    IconData icon = Icons.notifications;
                    Color iconColor = AppTheme.info;
                    
                    if (n['priority'] == 'critical' || n['priority'] == 'high') {
                      icon = Icons.warning_rounded;
                      iconColor = AppTheme.danger;
                    }

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isRead ? Colors.transparent : iconColor.withOpacity(0.1),
                        child: Icon(icon, color: isRead ? Colors.grey : iconColor),
                      ),
                      title: Text(
                        n['title'],
                        style: TextStyle(
                          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(n['message']),
                          const SizedBox(height: 4),
                          Text(
                            timeago.format(DateTime.parse(n['created_at']).toLocal()),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      onTap: () {
                        if (!isRead) _markAsRead(n['id'], index);
                      },
                    );
                  },
                ),
    );
  }
}
