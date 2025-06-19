import 'package:flutter/material.dart';
import 'home_page.dart'; // ✅ لإضافة الرجوع لصفحة HomePage

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isSilentModeEnabled = false;
  String? _selectedNotificationType = 'Popup';

  String _phoneNumber = '+123-456-7890';
  String _userName = '@reallygreatsite';
  String _email = 'hello@reallygreatsite.com';
  String _address = '123 Anywhere St., Any City, ST 12345';

  void _showEditDialog({
    required String title,
    required String initialValue,
    required Function(String) onSave,
    bool isEmail = false,
  }) {
    final controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Enter new email',
                  hintStyle: TextStyle(color: Colors.black87),
                ),
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BFA6),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  onSave(controller.text);

                  if (isEmail) {
                    _showCodeVerificationDialog();
                  }
                },
                child: const Text('Send Code'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCodeVerificationDialog() {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter the verification code'),
              const SizedBox(height: 12),
              TextField(
                controller: codeController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: 'Enter 6-digit code',
                  filled: true,
                  fillColor: Color(0xFFF0F0F0),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BFA6),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Verify'),
              )
            ],
          ),
        );
      },
    );
  }

  void _showNotificationTypeDialog() {
    String? tempSelection = _selectedNotificationType;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Notification Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Popup', 'On Notification Bar'].map((type) {
            return RadioListTile(
              title: Text(type),
              value: type,
              groupValue: tempSelection,
              onChanged: (value) {
                setState(() => tempSelection = value.toString());
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _selectedNotificationType = tempSelection);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Function() onTap,
  }) {
    return Card(
      color: Colors.white,
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF00BFA6)),
        title: Text(title, style: const TextStyle(color: Color(0xFF333333))),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600])),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          ),
        ),
        title: const Text('My Profile', style: TextStyle(color: Colors.black)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            _buildInfoTile(
              icon: Icons.person,
              title: _userName,
              subtitle: 'Username',
              onTap: () => _showEditDialog(
                title: 'Change Username',
                initialValue: _userName,
                onSave: (value) => setState(() => _userName = value),
              ),
            ),
            _buildInfoTile(
              icon: Icons.email,
              title: _email,
              subtitle: 'Email',
              onTap: () => _showEditDialog(
                title: 'Change Email',
                initialValue: _email,
                onSave: (value) => setState(() => _email = value),
                isEmail: true,
              ),
            ),
            _buildInfoTile(
              icon: Icons.phone,
              title: _phoneNumber,
              subtitle: 'Phone Number',
              onTap: () => _showEditDialog(
                title: 'Change Phone Number',
                initialValue: _phoneNumber,
                onSave: (value) => setState(() => _phoneNumber = value),
              ),
            ),
            _buildInfoTile(
              icon: Icons.location_on,
              title: _address,
              subtitle: 'Address',
              onTap: () => _showEditDialog(
                title: 'Change Address',
                initialValue: _address,
                onSave: (value) => setState(() => _address = value),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SwitchListTile(
              title: const Text('Silent Mode'),
              subtitle: const Text('Notifications & Messages'),
              value: _isSilentModeEnabled,
              onChanged: (value) => setState(() => _isSilentModeEnabled = value),
              activeColor: const Color(0xFF00BFA6),
            ),
            ListTile(
              title: const Text('Notification Type'),
              subtitle: Text(_selectedNotificationType ?? ''),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _showNotificationTypeDialog,
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BFA6),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                onPressed: () {},
                child: const Text('Save Settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
