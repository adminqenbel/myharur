import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../api_client.dart';
import '../theme.dart';

class ShopRegistrationScreen extends ConsumerStatefulWidget {
  const ShopRegistrationScreen({super.key});

  @override
  ConsumerState<ShopRegistrationScreen> createState() => _ShopRegistrationScreenState();
}

class _ShopRegistrationScreenState extends ConsumerState<ShopRegistrationScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;
  bool _submitted = false;

  // Step 1 — Basic Info
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  int? _selectedCategoryId;
  String? _selectedCategoryName;
  String? _selectedCategoryIcon;

  // Step 2 — Contact & Hours
  final _phoneCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();
  bool _isOpen = true;
  bool _deliveryAvailable = false;

  // Step 3 — Location & Address
  final _addressCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();

  // Categories loaded from API
  List<Map<String, dynamic>> _categories = [];
  bool _categoriesLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _phoneCtrl.dispose();
    _whatsappCtrl.dispose();
    _hoursCtrl.dispose();
    _addressCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final r = await ApiClient.dio.get('/shops/categories');
      if (mounted) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(r.data);
          _categoriesLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _categoriesLoading = false);
    }
  }

  void _nextStep() {
    if (_currentStep == 0 && !_validateStep1()) return;
    if (_currentStep == 1 && !_validateStep2()) return;
    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submit();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateStep1() {
    if (_nameCtrl.text.trim().isEmpty) {
      _showError('Please enter your shop name');
      return false;
    }
    if (_selectedCategoryId == null) {
      _showError('Please select a category');
      return false;
    }
    return true;
  }

  bool _validateStep2() {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      _showError('Please enter a contact phone number');
      return false;
    }
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      _showError('Phone number must be a valid 10-digit Indian number');
      return false;
    }
    return true;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      final payload = {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'category_id': _selectedCategoryId,
        'phone': _phoneCtrl.text.trim(),
        'whatsapp': _whatsappCtrl.text.trim().isEmpty ? null : _whatsappCtrl.text.trim(),
        'opening_hours': _hoursCtrl.text.trim().isEmpty ? null : _hoursCtrl.text.trim(),
        'address': _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        'location_lat': _latCtrl.text.trim().isEmpty ? null : double.tryParse(_latCtrl.text.trim()),
        'location_lng': _lngCtrl.text.trim().isEmpty ? null : double.tryParse(_lngCtrl.text.trim()),
        'is_open': _isOpen,
        'delivery_available': _deliveryAvailable,
      };
      final r = await ApiClient.dio.post('/shops/', data: payload);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _submitted = true;
        });
        final autoApproved = r.data['auto_approved'] == true;
        _showSuccessDialog(autoApproved, r.data['name'] ?? _nameCtrl.text);
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final detail = e.response?.data?['detail'] ?? 'Registration failed. Please try again.';
        _showError(detail.toString());
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Something went wrong. Please try again.');
      }
    }
  }

  void _showSuccessDialog(bool autoApproved, String shopName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: autoApproved ? AppTheme.success.withOpacity(0.1) : AppTheme.accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                autoApproved ? Icons.store_rounded : Icons.hourglass_empty_rounded,
                size: 48,
                color: autoApproved ? AppTheme.success : AppTheme.accent,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              autoApproved ? '🎉 Shop is Live!' : 'Submitted for Review',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              autoApproved
                  ? '$shopName is now live on MyHarur for everyone to discover!'
                  : '$shopName has been submitted. We\'ll notify you once it\'s reviewed by our team.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/market');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Go to Marketplace'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Register Shop'),
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: _prevStep,
              )
            : null,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Step ${_currentStep + 1} of 4',
                style: TextStyle(
                  color: AppTheme.accent,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_currentStep + 1) / 4,
                backgroundColor: AppTheme.accent.withOpacity(0.12),
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accent),
                minHeight: 4,
              ),
            ),
          ),

          // Steps
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(isDark),
                _buildStep2(isDark),
                _buildStep3(isDark),
                _buildStep4(isDark),
              ],
            ),
          ),

          // Bottom Nav
          Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).padding.bottom + 16,
              top: 12,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.bgDark : AppTheme.bgLight,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppTheme.dividerDark : AppTheme.dividerLight,
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _currentStep == 3 ? 'Submit Registration' : 'Continue',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Basic Information', 'Tell us about your shop', Icons.store_rounded),
          const SizedBox(height: 24),
          _label('Shop Name *'),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              hintText: 'e.g. Murugan Bakery',
              prefixIcon: Icon(Icons.storefront_rounded),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 20),
          _label('Description'),
          const SizedBox(height: 8),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(
              hintText: 'What does your shop sell? (optional)',
              prefixIcon: Icon(Icons.description_rounded),
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 20),
          _label('Category *'),
          const SizedBox(height: 8),
          if (_categoriesLoading)
            const Center(child: CircularProgressIndicator())
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = _selectedCategoryId == cat['id'];
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedCategoryId = cat['id'] as int;
                    _selectedCategoryName = cat['name'] as String;
                    _selectedCategoryIcon = cat['icon'] as String?;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.accent : (isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppTheme.accent : (isDark ? AppTheme.dividerDark : AppTheme.dividerLight),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(cat['icon'] ?? '🏪', style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          cat['name'],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildStep2(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Contact & Hours', 'How can customers reach you?', Icons.contact_phone_rounded),
          const SizedBox(height: 24),
          _label('Phone Number *'),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
            decoration: const InputDecoration(
              hintText: '10-digit mobile number',
              prefixIcon: Icon(Icons.phone_rounded),
              prefixText: '+91 ',
            ),
          ),
          const SizedBox(height: 20),
          _label('WhatsApp Number (optional)'),
          const SizedBox(height: 8),
          TextField(
            controller: _whatsappCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
            decoration: const InputDecoration(
              hintText: 'WhatsApp number',
              prefixIcon: Icon(Icons.chat_rounded),
              prefixText: '+91 ',
            ),
          ),
          const SizedBox(height: 20),
          _label('Opening Hours (optional)'),
          const SizedBox(height: 8),
          TextField(
            controller: _hoursCtrl,
            decoration: const InputDecoration(
              hintText: 'e.g. 9:00 AM – 9:00 PM',
              prefixIcon: Icon(Icons.schedule_rounded),
            ),
          ),
          const SizedBox(height: 24),
          _switchTile('Shop is Currently Open', _isOpen, (v) => setState(() => _isOpen = v), Icons.door_front_door_rounded, AppTheme.success, isDark),
          const SizedBox(height: 12),
          _switchTile('Delivery Available', _deliveryAvailable, (v) => setState(() => _deliveryAvailable = v), Icons.delivery_dining_rounded, AppTheme.accent, isDark),
        ],
      ),
    );
  }

  Widget _buildStep3(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Location & Address', 'Help customers find your shop', Icons.location_on_rounded),
          const SizedBox(height: 24),
          _label('Shop Address (optional)'),
          const SizedBox(height: 8),
          TextField(
            controller: _addressCtrl,
            decoration: const InputDecoration(
              hintText: 'e.g. Main Market, Harur, Dharmapuri',
              prefixIcon: Icon(Icons.home_rounded),
            ),
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Latitude'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _latCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(hintText: '12.0628'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Longitude'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _lngCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(hintText: '78.4950'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppTheme.accent, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Tip: Use Google Maps to find your exact coordinates.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Review & Submit', 'Confirm your shop details', Icons.fact_check_rounded),
          const SizedBox(height: 24),
          _reviewCard(isDark),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(children: [
                  Icon(Icons.info_rounded, color: AppTheme.accent, size: 20),
                  const SizedBox(width: 8),
                  const Text('What happens next?', style: TextStyle(fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 8),
                const Text(
                  '• Our team will review your shop registration\n'
                  '• You\'ll receive a notification once approved\n'
                  '• After approval, your shop goes live for all users',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.dividerDark : AppTheme.dividerLight),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.accent, AppTheme.accent.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Text(_selectedCategoryIcon ?? '🏪', style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nameCtrl.text.trim().isEmpty ? 'Your Shop' : _nameCtrl.text.trim(),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      if (_selectedCategoryName != null)
                        Text(_selectedCategoryName!, style: const TextStyle(fontSize: 13, color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_descCtrl.text.trim().isNotEmpty) ...[
                  _reviewRow(Icons.description_rounded, 'Description', _descCtrl.text.trim()),
                  const SizedBox(height: 12),
                ],
                _reviewRow(Icons.phone_rounded, 'Phone', '+91 ${_phoneCtrl.text.trim()}'),
                if (_hoursCtrl.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _reviewRow(Icons.schedule_rounded, 'Hours', _hoursCtrl.text.trim()),
                ],
                if (_addressCtrl.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _reviewRow(Icons.location_on_rounded, 'Address', _addressCtrl.text.trim()),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    _chip(_isOpen ? 'Open' : 'Closed', _isOpen ? AppTheme.success : Colors.orange),
                    const SizedBox(width: 8),
                    if (_deliveryAvailable) _chip('Delivery', AppTheme.accent),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.accent),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
            Text(value, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ],
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _sectionHeader(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.accent, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(subtitle, style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryLight)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    );
  }

  Widget _switchTile(String title, bool value, Function(bool) onChanged, IconData icon, Color color, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppTheme.dividerDark : AppTheme.dividerLight),
      ),
      child: SwitchListTile(
        title: Row(
          children: [
            Icon(icon, color: value ? color : AppTheme.textSecondaryLight, size: 20),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
        value: value,
        onChanged: onChanged,
        activeColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
