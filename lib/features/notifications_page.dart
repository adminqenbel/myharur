import 'package:flutter/material.dart';
import 'phase_two_pages.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  int selectedCategory = 0;
  final categories = ['All', 'Emergency', 'Govt Orders', 'Civic', 'Market & Jobs'];

  List<Map<String, dynamic>> notifications = [
    {
      'id': 1,
      'title': 'Emergency SOS Alert Broadcast',
      'body': 'Medical rescue unit dispatched to Harur Bus Stand area. Responders active.',
      'category': 'Emergency',
      'time': '10 mins ago',
      'isRead': false,
      'icon': Icons.emergency_rounded,
      'color': const Color(0xFFE44545),
    },
    {
      'id': 2,
      'title': 'New Government Order (G.O.) Published',
      'body': 'Morappur - Harur broad gauge rail route survey and soil test clearance approved.',
      'category': 'Govt Orders',
      'time': '1 hour ago',
      'isRead': false,
      'icon': Icons.account_balance_rounded,
      'color': const Color(0xFF267AF4),
    },
    {
      'id': 3,
      'title': 'Civic Grievance Status Update',
      'body': 'Ticket #HR-482910 regarding Streetlight Repair on Bazaar Street has been resolved.',
      'category': 'Civic',
      'time': '3 hours ago',
      'isRead': true,
      'icon': Icons.task_alt_rounded,
      'color': const Color(0xFF007AFF),
    },
    {
      'id': 4,
      'title': 'Agri Mandi Price Advisory',
      'body': 'Sugarcane rate touched ₹3,150/Ton at Harur Sugar Mills cooperative today.',
      'category': 'Market & Jobs',
      'time': 'Yesterday',
      'isRead': true,
      'icon': Icons.trending_up_rounded,
      'color': const Color(0xFFF59E0B),
    },
  ];

  void _markAllAsRead() {
    setState(() {
      for (var n in notifications) {
        n['isRead'] = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications marked as read.')),
    );
  }

  void _clearAll() {
    setState(() {
      notifications.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications cleared.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = selectedCategory == 0
        ? notifications
        : notifications.where((n) => n['category'] == categories[selectedCategory]).toList();

    final unreadCount = notifications.where((n) => n['isRead'] == false).length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Notifications & Alerts',
          style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1C1C1E), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Mark all read', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF007AFF), fontSize: 12)),
            ),
          if (notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFF8E8E93)),
              tooltip: 'Clear All',
              onPressed: _clearAll,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Category Chips
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final active = selectedCategory == i;
                  return ChoiceChip(
                    label: Text(categories[i]),
                    selected: active,
                    onSelected: (_) => setState(() => selectedCategory = i),
                    selectedColor: const Color(0xFF007AFF),
                    backgroundColor: const Color(0xFFF2F2F7),
                    labelStyle: TextStyle(
                      color: active ? Colors.white : const Color(0xFF1C1C1E),
                      fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    side: BorderSide(color: active ? const Color(0xFF007AFF) : const Color(0xFFE5E5EA)),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none_rounded, size: 48, color: const Color(0xFF8E8E93).withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          const Text('No notifications in this category', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF8E8E93))),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final item = filtered[i];
                        final isRead = item['isRead'] as bool;
                        final color = item['color'] as Color;

                        return InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            setState(() => item['isRead'] = true);
                            // Navigate based on category
                            if (item['category'] == 'Emergency') {
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EmergencySosPage()));
                            } else if (item['category'] == 'Govt Orders') {
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GovtOrdersPage()));
                            } else if (item['category'] == 'Civic') {
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GrievanceSubmissionPage()));
                            } else if (item['category'] == 'Market & Jobs') {
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AgriMandiPage()));
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isRead ? Colors.white : const Color(0xFFF6FBF9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isRead ? const Color(0xFFE5E5EA) : const Color(0xFF9DD8C5),
                                width: isRead ? 1.0 : 1.5,
                              ),
                              boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 8, offset: Offset(0, 3))],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(item['icon'] as IconData, color: color, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item['title'] as String,
                                              style: TextStyle(
                                                fontWeight: isRead ? FontWeight.w700 : FontWeight.w900,
                                                fontSize: 14,
                                                color: const Color(0xFF1C1C1E),
                                              ),
                                            ),
                                          ),
                                          if (!isRead)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF007AFF),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item['body'] as String,
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93), height: 1.35),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        item['time'] as String,
                                        style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
