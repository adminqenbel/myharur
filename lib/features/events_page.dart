import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  int selectedCategory = 0;
  final categories = ['All', 'Tournaments', 'Festivals', 'Workshops', 'Volunteering'];
  List<Map<String, dynamic>> events = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => isLoading = true);
    final category = categories[selectedCategory];
    final data = await EventsService.fetchEvents(category: category);
    if (mounted) {
      setState(() {
        events = data;
        isLoading = false;
      });
    }
  }

  void _openCreateEventSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _CreateEventSheet(onCreated: _loadEvents),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = selectedCategory == 0
        ? events
        : events.where((e) => e['type'] == categories[selectedCategory]).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Harur Events & Festivals',
          style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1C1C1E), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 46,
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
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    side: BorderSide(
                      color: active ? const Color(0xFF007AFF) : const Color(0xFFE5E5EA),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, i) {
                  final ev = filtered[i];
                  return Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE5E5EA)),
                      boxShadow: const [
                        BoxShadow(color: Color(0x080F2922), blurRadius: 14, offset: Offset(0, 5))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (ev['color'] as Color).withValues(alpha: .12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                ev['type'].toString().toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: ev['color'] as Color,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (ev['isPaid'] == true)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFECEB),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Entry Fee (Google Form)',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFE44545)),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          ev['title'],
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1C1C1E), height: 1.2),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF8E8E93)),
                            const SizedBox(width: 6),
                            Text('${ev['date']} · ${ev['time']}', style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93), fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_pin, size: 14, color: Color(0xFF8E8E93)),
                            const SizedBox(width: 6),
                            Expanded(child: Text(ev['venue'], style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)))),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F2F7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.shield_outlined, size: 16, color: Color(0xFF007AFF)),
                              const SizedBox(width: 6),
                              Text('Organizer: ${ev['head']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1C1C1E))),
                              const Spacer(),
                              Text('${ev['registered']}/${ev['maxSlots']} Registered', style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93), fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF007AFF),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () {
                              if (ev['isPaid'] == true) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Opening external registration form: ${ev['formUrl']}')),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('You are successfully registered for this event!')),
                                );
                              }
                            },
                            child: Text(ev['isPaid'] == true ? 'Register via Google Form' : '1-Tap Free Registration', style: const TextStyle(fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF007AFF),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Host Event / Tournament', style: TextStyle(fontWeight: FontWeight.w800)),
        onPressed: _openCreateEventSheet,
      ),
    );
  }
}

class _CreateEventSheet extends StatefulWidget {
  final VoidCallback? onCreated;
  const _CreateEventSheet({this.onCreated});

  @override
  State<_CreateEventSheet> createState() => _CreateEventSheetState();
}

class _CreateEventSheetState extends State<_CreateEventSheet> {
  final _titleCtrl = TextEditingController();
  final _venueCtrl = TextEditingController();
  final _formCtrl = TextEditingController();
  bool isPaid = false;
  String selectedType = 'Tournaments';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _venueCtrl.dispose();
    _formCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(color: const Color(0xFFE5E5EA), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Create Community Event / Tournament',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Upon admin approval, you are automatically assigned as Event Head with dedicated temporary chat room management.',
              style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: 'Event / Tournament Name',
                filled: true,
                fillColor: const Color(0xFFF2F2F7),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _venueCtrl,
              decoration: InputDecoration(
                labelText: 'Venue / Ground in Harur',
                filled: true,
                fillColor: const Color(0xFFF2F2F7),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Paid Event / Entry Fee', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              subtitle: const Text('Requires external Google Form for payment tracking', style: TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
              value: isPaid,
              activeThumbColor: const Color(0xFF007AFF),
              activeTrackColor: const Color(0xFF007AFF).withValues(alpha: 0.5),
              onChanged: (val) => setState(() => isPaid = val),
            ),
            if (isPaid) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _formCtrl,
                decoration: InputDecoration(
                  labelText: 'Google Form Registration Link',
                  filled: true,
                  fillColor: const Color(0xFFF2F2F7),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () async {
                  final title = _titleCtrl.text.trim();
                  final venue = _venueCtrl.text.trim();

                  if (title.isEmpty || venue.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Color(0xFFE44545),
                        content: Text('Please provide both an event name and venue.'),
                      ),
                    );
                    return;
                  }

                  if (isPaid && _formCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Color(0xFFE44545),
                        content: Text('Please provide the Google Form registration URL for paid events.'),
                      ),
                    );
                    return;
                  }

                  final profanityErr = SecurityFilterService.validateUsernameAndName(username: '', fullName: title);
                  if (profanityErr != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(backgroundColor: const Color(0xFFE44545), content: Text(profanityErr)),
                    );
                    return;
                  }

                  await EventsService.createEvent(
                    title: title,
                    venue: venue,
                    type: selectedType,
                    description: 'Community event organized in Harur.',
                    isPaid: isPaid,
                    formUrl: isPaid ? _formCtrl.text.trim() : null,
                  );
                  widget.onCreated?.call();

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Color(0xFF007AFF),
                        content: Text('✓ Event submitted for Admin verification!'),
                      ),
                    );
                  }
                },
                child: const Text('Submit for Approval', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
