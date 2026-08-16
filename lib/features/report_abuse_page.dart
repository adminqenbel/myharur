import 'package:flutter/material.dart';

class ReportAbusePage extends StatefulWidget {
  final String? targetItem;
  const ReportAbusePage({super.key, this.targetItem});

  @override
  State<ReportAbusePage> createState() => _ReportAbusePageState();
}

class _ReportAbusePageState extends State<ReportAbusePage> {
  final _descCtrl = TextEditingController();
  String selectedReason = 'Fraud or Scam Activity';
  bool isSubmitting = false;

  final reasons = [
    'Fraud or Scam Activity',
    'Offensive / Abusive Language',
    'Fake Information / False Alert',
    'Commercial Spam / Unverified Merchant',
    'Privacy Violation / Personal Details',
  ];

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    final remarks = _descCtrl.text.trim();
    if (remarks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFE44545),
          content: Text('Please describe the issue or reason for reporting.'),
        ),
      );
      return;
    }

    setState(() => isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() => isSubmitting = false);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF007AFF),
          content: Text('✓ Report submitted! Case #${DateTime.now().millisecondsSinceEpoch.toString().substring(8)} sent to Harur Moderator Queue.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Report Content or User', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E))),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1C1C1E), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.targetItem != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.flag_rounded, color: Color(0xFFE44545), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Reporting: ${widget.targetItem}',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1C1C1E)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              const Text('Select Violation Reason', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF8E8E93))),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedReason,
                    isExpanded: true,
                    items: reasons.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => selectedReason = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Detailed Explanation', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF8E8E93))),
              const SizedBox(height: 8),
              TextField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Please provide context, witness details, or evidence description...',
                  filled: true,
                  fillColor: const Color(0xFFF2F2F7),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE44545),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: isSubmitting ? null : _submitReport,
                  child: isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Submit Report to Moderation', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
