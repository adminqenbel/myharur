import 'package:flutter/material.dart';
import '../../core/services/alerts_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_components.dart';

// ==============================================================================
// SUBMIT ALERT PAGE — Community alert submission
// ==============================================================================
class SubmitAlertPage extends StatefulWidget {
  const SubmitAlertPage({super.key});

  @override
  State<SubmitAlertPage> createState() => _SubmitAlertPageState();
}

class _SubmitAlertPageState extends State<SubmitAlertPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _selectedCategory = 'road';
  bool _emergencyTagged = false;
  bool _submitting = false;
  String? _error;

  final _categories = ['road', 'electricity', 'water', 'govt'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final profile = AuthService.currentProfile;

    // Emergency tag rate limit check
    if (_emergencyTagged && !profile.hasEmergencyPrivilege) {
      setState(() => _error = 'Your emergency tag privilege has been revoked due to prior misuse.');
      return;
    }

    setState(() { _submitting = true; _error = null; });

    final success = await AlertsService.submitCommunityAlert(
      category: _selectedCategory,
      title: _titleCtrl.text.trim(),
      body: _bodyCtrl.text.trim(),
      wardId: profile.wardId,
      emergencyTagged: _emergencyTagged,
      createdByUid: profile.id,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Alert submitted — visible in feed while under review.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      setState(() => _error = 'Submission failed. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.systemBackground,
      appBar: AppBar(
        title: const Text('Report an Alert'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Category', style: AppTextStyles.footnote),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final selected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: selected ? cat.categoryColor : cat.categoryColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: cat.categoryColor.withValues(alpha: selected ? 1 : 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(cat.categoryIcon),
                        const SizedBox(width: 6),
                        Text(
                          cat.categoryLabel,
                          style: TextStyle(
                            color: selected ? Colors.white : cat.categoryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text('Title', style: AppTextStyles.footnote),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleCtrl,
              maxLength: 100,
              decoration: const InputDecoration(hintText: 'Brief description of the issue'),
              validator: (v) => (v == null || v.trim().length < 5) ? 'Please provide a title (min 5 chars)' : null,
            ),
            const SizedBox(height: 16),
            Text('Details', style: AppTextStyles.footnote),
            const SizedBox(height: 8),
            TextFormField(
              controller: _bodyCtrl,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'Describe the issue in detail — location, severity, etc.',
              ),
              validator: (v) => (v == null || v.trim().length < 10) ? 'Please add more detail (min 10 chars)' : null,
            ),
            const SizedBox(height: 16),
            SurfaceCard(
              child: Row(
                children: [
                  const Icon(Icons.emergency_rounded, color: AppColors.danger, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mark as Emergency', style: AppTextStyles.subheadline),
                        Text(
                          'Publishes immediately — misuse revokes this privilege',
                          style: AppTextStyles.caption2,
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _emergencyTagged,
                    onChanged: (v) => setState(() => _emergencyTagged = v),
                    activeThumbColor: AppColors.danger,
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.20)),
                ),
                child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Submit Alert'),
            ),
          ],
        ),
      ),
    );
  }
}
