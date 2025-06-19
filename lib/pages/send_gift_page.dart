import 'package:flutter/material.dart';
import '../services/gift_service.dart';
import '../models/gift_model.dart';
import '../models/user_model.dart';
import 'gift_selection_page.dart';

class SendGiftPage extends StatefulWidget {
  const SendGiftPage({super.key});

  @override
  State<SendGiftPage> createState() => _SendGiftPageState();
}

class _SendGiftPageState extends State<SendGiftPage>
    with TickerProviderStateMixin {
  final GiftService _giftService = GiftService();
  final TextEditingController _recipientController = TextEditingController();
  final FocusNode _recipientFocusNode = FocusNode();

  String? _selectedGift;
  GiftType? _selectedGiftType;
  bool _isLoading = false;
  bool _canSendFree = true;
  List<UserModel> _availableUsers = [];
  List<UserModel> _filteredUsers = [];

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
    _recipientController.addListener(_filterUsers);
  }

  void _initializeAnimations() {
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _recipientFocusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final currentUser = await _giftService.getCurrentUser();
    if (currentUser != null) {
      final canSend = await _giftService.canSendFreeGift(currentUser);
      final users = await _giftService.getAllUsers();
      
      setState(() {
        _canSendFree = canSend;
        _availableUsers = users.where((u) => u.username != currentUser).toList();
        _filteredUsers = _availableUsers;
      });
    }
  }

  void _filterUsers() {
    final query = _recipientController.text.toLowerCase();
    setState(() {
      _filteredUsers = _availableUsers
          .where((user) => user.username.toLowerCase().contains(query))
          .toList();
    });
  }

  void _shakeField() {
    _shakeController.forward().then((_) {
      _shakeController.reverse();
    });
  }

  Future<void> _selectGift() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => const GiftSelectionPage(),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedGift = result['content'];
        _selectedGiftType = result['type'];
      });
    }
  }

  Future<void> _sendGift() async {
    if (_recipientController.text.trim().isEmpty) {
      _shakeField();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a recipient username'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (_selectedGift == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a gift to send'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final recipient = _recipientController.text.trim();
    final recipientUser = await _giftService.getUser(recipient);
    
    if (recipientUser == null) {
      _shakeField();
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Recipient user not found'),
          // ignore: use_build_context_synchronously
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = await _giftService.getCurrentUser();
      if (currentUser == null) return;

      final gift = Gift(
        id: _giftService.generateGiftId(),
        type: _selectedGiftType!,
        content: _selectedGift!,
        sender: currentUser,
        recipient: recipient,
        timestamp: DateTime.now(),
        isFree: _canSendFree,
        price: _canSendFree ? 0.0 : 5.0, // Demo price for paid gifts
      );

      final success = await _giftService.sendGift(gift);

      if (success) {
        // Show success animation and message
        _showSuccessDialog();
      } else {
        throw Exception('Failed to send gift');
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending gift: \${e.toString()}'),
          // ignore: use_build_context_synchronously
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withAlpha((255 * 0.1).toInt()),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.check_circle,
                size: 50,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Gift Sent! 🎉',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your gift has been successfully sent to @${_recipientController.text}',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(true); // Return to home with success
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Done',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGiftPreview() {
    if (_selectedGift == null) {
      return GestureDetector(
        onTap: _selectGift,
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withAlpha((255 * 0.1).toInt()),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withAlpha((255 * 0.3).toInt()),
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                'Select a Gift',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Tap to choose',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha((255 * 0.6).toInt()),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _selectGift,
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withAlpha((255 * 0.3).toInt()),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withAlpha((255 * 0.1).toInt()),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha((255 * 0.1).toInt()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  _selectedGift!,
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Selected Gift',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _canSendFree ? 'Free Daily Gift 💝' : 'Premium Gift (\$5.00)',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _canSendFree
                          ? Theme.of(context).colorScheme.secondary
                          : Theme.of(context).colorScheme.tertiary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to change',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withAlpha((255 * 0.6).toInt()),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.edit,
              color: Theme.of(context).colorScheme.primary.withAlpha((255 * 0.6).toInt()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSuggestions() {
    if (_recipientController.text.isEmpty || _filteredUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha((255 * 0.2).toInt()),
        ),
      ),
      child: Column(
        children: _filteredUsers.take(3).map((user) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary.withAlpha((255 * 0.1).toInt()),
              child: Icon(
                Icons.person,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            title: Text(
              '@${user.username}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            subtitle: Text(
              '${user.totalGiftsReceived} gifts received',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha((255 * 0.6).toInt()),
              ),
            ),
            onTap: () {
              _recipientController.text = user.username;
              _recipientFocusNode.unfocus();
            },
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Gift'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Daily Limit Status
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _canSendFree
                      ? Theme.of(context).colorScheme.secondary.withAlpha((255 * 0.1).toInt())
                      : Theme.of(context).colorScheme.tertiary.withAlpha((255 * 0.1).toInt()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      _canSendFree ? Icons.favorite : Icons.monetization_on,
                      color: _canSendFree
                          ? Theme.of(context).colorScheme.secondary
                          : Theme.of(context).colorScheme.tertiary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _canSendFree
                            ? 'You can send 1 free gift today! 🎉'
                            : 'Daily free gift used. Additional gifts cost \$5.00',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _canSendFree
                              ? Theme.of(context).colorScheme.secondary
                              : Theme.of(context).colorScheme.tertiary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Recipient Input
              Text(
                'Send to',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_shakeAnimation.value, 0),
                    child: TextField(
                      controller: _recipientController,
                      focusNode: _recipientFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Enter username (e.g., alice_wonder)',
                        prefixIcon: Icon(
                          Icons.alternate_email,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                  );
                },
              ),
              _buildUserSuggestions(),
              const SizedBox(height: 24),

              // Gift Selection
              Text(
                'Choose Gift',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildGiftPreview(),
              
              const Spacer(),

              // Send Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendGift,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.send,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _canSendFree ? 'Send Free Gift' : 'Send Gift (\$5.00)',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}