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

  Future<void> _markAllRead() async {
    // In a real app, you would hit an endpoint like /notifications/read-all
    // For now, we update local state
    setState(() {
      for (var n in _notifications) {
        n['is_read'] = true;
      }
    });
  }

  Future<void> _deleteNotification(int id, int index) async {
    try {
      await ApiClient.dio.delete('/notifications/$id');
      setState(() {
        _notifications.removeAt(index);
      });
    } catch (e) {
      // Handle error
    }
  }

  // Group notifications
  Map<String, List<dynamic>> _groupNotifications(List<dynamic> notifs) {
    final Map<String, List<dynamic>> grouped = {
      'Today': [],
      'Yesterday': [],
      'Earlier': []
    };

    final now = DateTime.now();
    for (var n in notifs) {
      final dt = DateTime.tryParse(n['created_at'])?.toLocal() ?? now;
      final diff = now.difference(dt).inDays;
      
      if (diff == 0 && now.day == dt.day) {
        grouped['Today']!.add(n);
      } else if (diff == 1 || (diff == 0 && now.day != dt.day)) {
        grouped['Yesterday']!.add(n);
      } else {
        grouped['Earlier']!.add(n);
      }
    }
    
    // Remove empty groups
    grouped.removeWhere((key, value) => value.isEmpty);
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupNotifications(_notifications);
    final hasUnread = _notifications.any((n) => n['is_read'] != true);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                'Mark All Read',
                style: TextStyle(
                  color: hasUnread ? AppTheme.accent : Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
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
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: grouped.length,
                  itemBuilder: (context, groupIndex) {
                    final key = grouped.keys.elementAt(groupIndex);
                    final items = grouped[key]!;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8, bottom: 8, top: 16),
                          child: Text(
                            key,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 6))
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: items.length,
                              separatorBuilder: (ctx, i) => Divider(height: 1, indent: 64),
                              itemBuilder: (ctx, itemIndex) {
                                final n = items[itemIndex];
                                final originalIndex = _notifications.indexOf(n);
                                final isRead = n['is_read'] == true;
                                
                                IconData icon = Icons.notifications;
                                Color iconColor = AppTheme.info;
                                
                                if (n['priority'] == 'critical' || n['priority'] == 'high') {
                                  icon = Icons.warning_rounded;
                                  iconColor = AppTheme.danger;
                                }

                                return Dismissible(
                                  key: Key(n['id'].toString()),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    color: AppTheme.danger,
                                    child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                                  ),
                                  onDismissed: (_) {
                                    _deleteNotification(n['id'], originalIndex);
                                  },
                                  child: Material(
                                    color: isRead ? Colors.transparent : iconColor.withOpacity(0.05),
                                    child: InkWell(
                                      onTap: () {
                                        if (!isRead) _markAsRead(n['id'], originalIndex);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color: iconColor.withOpacity(0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(icon, color: iconColor, size: 22),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    n['title'],
                                                    style: TextStyle(
                                                      fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                                                      fontSize: 15,
                                                      color: Theme.of(context).colorScheme.onSurface,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    n['message'],
                                                    style: TextStyle(
                                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                                      fontSize: 14,
                                                      height: 1.3,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    timeago.format(DateTime.parse(n['created_at']).toLocal()),
                                                    style: TextStyle(
                                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (!isRead)
                                              Container(
                                                margin: const EdgeInsets.only(top: 6),
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  color: AppTheme.accent,
                                                  shape: BoxShape.circle,
                                                ),
                                              )
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
    );
  }
}
