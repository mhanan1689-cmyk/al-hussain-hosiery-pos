import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settingsRef = FirebaseFirestore.instance
      .collection('settings')
      .doc('store');

  final _shopNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _ntnCtrl = TextEditingController();
  final _footerCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final doc = await _settingsRef.get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _shopNameCtrl.text = data['shopName'] ?? '';
          _addressCtrl.text = data['address'] ?? '';
          _phoneCtrl.text = data['phone'] ?? '';
          _ntnCtrl.text = data['ntn'] ?? '';
          _footerCtrl.text = data['receiptFooter'] ?? '';
          _loading = false;
        });
      } else {
        
        _shopNameCtrl.text = 'Al Hussain Hosiery Company';
        _addressCtrl.text = 'Haram Gate, Multan';
        _phoneCtrl.text = '';
        _ntnCtrl.text = '';
        _footerCtrl.text = 'Thank You! Visit Again';
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _saving = true);
    try {
      await _settingsRef.set({
        'shopName': _shopNameCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'ntn': _ntnCtrl.text.trim(),
        'receiptFooter': _footerCtrl.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully!'),
            backgroundColor: Color(0xFF1D9E75),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
    setState(() => _saving = false);
  }

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _ntnCtrl.dispose();
    _footerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _saveSettings,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined, size: 18),
              label: Text(_saving ? 'Saving...' : 'Save Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D9E75),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Store Settings
                  _SectionCard(
                    icon: Icons.store_outlined,
                    title: 'Store Information',
                    color: const Color(0xFF1D9E75),
                    children: [
                      _SettingsField(
                        ctrl: _shopNameCtrl,
                        label: 'Shop Name',
                        hint: 'Al Hussain Hosiery Company',
                        icon: Icons.store_outlined,
                      ),
                      const SizedBox(height: 16),
                      _SettingsField(
                        ctrl: _addressCtrl,
                        label: 'Address',
                        hint: 'Haram Gate, Multan',
                        icon: Icons.location_on_outlined,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _SettingsField(
                              ctrl: _phoneCtrl,
                              label: 'Phone Number',
                              hint: '0300-1234567',
                              icon: Icons.phone_outlined,
                              isNumber: true,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _SettingsField(
                              ctrl: _ntnCtrl,
                              label: 'NTN Number (Optional)',
                              hint: '1234567-8',
                              icon: Icons.numbers_outlined,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  
                  _SectionCard(
                    icon: Icons.receipt_long_outlined,
                    title: 'Receipt Settings',
                    color: const Color(0xFF3B82F6),
                    children: [
                      _SettingsField(
                        ctrl: _footerCtrl,
                        label: 'Receipt Footer Message',
                        hint: 'Thank You! Visit Again',
                        icon: Icons.message_outlined,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F7FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFF3B82F6).withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Color(0xFF3B82F6), size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'These settings will appear on every receipt you print.',
                                style: TextStyle(
                                    fontSize: 12, color: Color(0xFF1E3A5F)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  
                  _SectionCard(
                    icon: Icons.info_outlined,
                    title: 'Software Information',
                    color: const Color(0xFF8B5CF6),
                    children: [
                      _InfoRow(
                          label: 'Software Name',
                          value: 'Al Hussain Hosiery POS'),
                      const Divider(height: 24),
                      _InfoRow(label: 'Version', value: 'Version 1.0'),
                      const Divider(height: 24),
                      _InfoRow(
                        label: 'License Status',
                        value: 'Active ',
                        valueColor: const Color(0xFF1D9E75),
                      ),
                      const Divider(height: 24),
                      _InfoRow(
                        label: 'License Type',
                        value: 'Lifetime License',
                        valueColor: const Color(0xFF1D9E75),
                      ),
                      const Divider(height: 24),
                      _InfoRow(
                          label: 'Expiry Date', value: 'Never Expires '),
                      const Divider(height: 24),
                      _InfoRow(label: 'Release Year', value: '2026'),
                      const Divider(height: 24),
                      _InfoRow(
                          label: 'Database',
                          value: 'Firebase'),
                      const Divider(height: 24),
                      _InfoRow(
                          label: 'Developed By',
                          value: 'Muhammad Hanan'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  
                  _SectionCard(
                    icon: Icons.security_outlined,
                    title: 'Account & Security',
                    color: const Color(0xFFEF4444),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Change Password',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(height: 2),
                                Text(
                                    'Send a password reset email to your registered email',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final user =
                                  await FirebaseFirestore.instance
                                      .collection('settings')
                                      .doc('store')
                                      .get();
                              if (mounted) {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                    title:
                                        const Text('Change Password'),
                                    content: const Text(
                                        'A password reset link will be sent to your registered email address. Check your inbox.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(context),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF1D9E75),
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Send Email'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.lock_reset, size: 16),
                            label: const Text('Reset Password'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  
                  const Center(
                    child: Text(
                      'Version 1.0  •  2026  •  Al Hussain Hosiery Company',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final List<Widget> children;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _SettingsField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final bool isNumber;

  const _SettingsField({
    required this.ctrl,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.isNumber = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E))),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType:
              isNumber ? TextInputType.phone : TextInputType.text,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            prefixIcon: Icon(icon, color: Colors.grey, size: 18),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: Color(0xFF1D9E75), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? const Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }
}