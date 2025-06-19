// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../pages/gift_selection_page.dart' show ImageUploadHelper;

// Helper Class
class GiftUploadHelper {
  static void calculatePricing(
    TextEditingController priceController,
    Function setState,
  ) {
    setState(() {
      // سيتم تحديث الحسابات هنا لاحقًا
    });
  }

  static Future<Uint8List?> selectImage({required bool fromCamera}) async {
    try {
      return fromCamera
          ? await ImageUploadHelper.captureImage()
          : await ImageUploadHelper.pickImageFromGallery();
    } catch (e) {
      throw Exception('Error selecting image: $e');
    }
  }
}

// Provider for State Management
class GiftUploadProvider with ChangeNotifier {
  Uint8List? _selectedImage;
  double _currentPrice = 0.0;
  double _platformFee = 0.0;
  double _finalPrice = 0.0;
  String _message = "";

  Uint8List? get selectedImage => _selectedImage;
  double get currentPrice => _currentPrice;
  double get platformFee => _platformFee;
  double get finalPrice => _finalPrice;
  String get message => _message;

  void updateImage(Uint8List? image) {
    _selectedImage = image;
    notifyListeners();
  }

  void updatePrice(double price) {
    _currentPrice = price;
    _platformFee = price * 0.1; // 10% platform fee
    _finalPrice = price + _platformFee;
    notifyListeners();
  }

  void updateMessage(String message) {
    _message = message;
    notifyListeners();
  }
}

class UploadGiftPage extends StatelessWidget {
  const UploadGiftPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GiftUploadProvider(),
      child: const UploadGiftPageContent(),
    );
  }
}

class UploadGiftPageContent extends StatefulWidget {
  const UploadGiftPageContent({super.key});

  @override
  State<UploadGiftPageContent> createState() =>
      _UploadGiftPageContentState();
}

class _UploadGiftPageContentState extends State<UploadGiftPageContent>
    with TickerProviderStateMixin {
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _priceFocusNode = FocusNode();
  final FocusNode _messageFocusNode = FocusNode();

  late AnimationController _uploadAnimationController;
  late AnimationController _priceAnimationController;
  late Animation<double> _uploadAnimation;
  late Animation<double> _priceAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _priceController.addListener(_calculatePricing);
  }

  void _initializeAnimations() {
    _uploadAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _priceAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _uploadAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _uploadAnimationController,
        curve: Curves.elasticOut,
      ),
    );
    _priceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _priceAnimationController,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    _messageController.dispose();
    _priceFocusNode.dispose();
    _messageFocusNode.dispose();
    _uploadAnimationController.dispose();
    _priceAnimationController.dispose();
    super.dispose();
  }

  void _calculatePricing() {
    final price = double.tryParse(_priceController.text) ?? 0.0;
    context.read<GiftUploadProvider>().updatePrice(price);
    if (price > 0) {
      _priceAnimationController.forward();
    } else {
      _priceAnimationController.reverse();
    }
  }

  Future<void> _selectImage({required bool fromCamera}) async {
    final provider = context.read<GiftUploadProvider>();
    try {
      final imageBytes = await GiftUploadHelper.selectImage(fromCamera: fromCamera);
      if (imageBytes != null) {
        provider.updateImage(imageBytes);
        _uploadAnimationController.forward();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    }
  }

  void _uploadGift() {
    final provider = context.read<GiftUploadProvider>();
    if (provider.selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first')),
      );
      return;
    }
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message')),
      );
      return;
    }
    if (provider.currentPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid price')),
      );
      return;
    }

    _showSuccessDialog(
      message: _messageController.text,
      price: provider.finalPrice,
    );
  }

  void _showSuccessDialog({required String message, required double price}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.cloud_upload,
                size: 50,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Gift Uploaded! 🎉',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '"$message"',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Available for ${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(price)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Return to previous page
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Done',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSelector() {
    final provider = context.watch<GiftUploadProvider>();
    return AnimatedBuilder(
      animation: _uploadAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * _uploadAnimation.value),
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: provider.selectedImage != null
                  ? Colors.transparent
                  : Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: provider.selectedImage != null
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.primary.withOpacity(0.3),
                width: provider.selectedImage != null ? 2 : 1,
              ),
            ),
            child: provider.selectedImage != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.memory(
                          provider.selectedImage!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            provider.updateImage(null);
                            _uploadAnimationController.reverse();
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.error,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.close,
                              size: 20,
                              color: Theme.of(context).colorScheme.onError,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Select Image',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary,
                                fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to choose from gallery or camera',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6)),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildImageOptions() {
    final provider = context.watch<GiftUploadProvider>();
    if (provider.selectedImage != null) return const SizedBox.shrink();
    return Row(
      children: [
        Expanded(
          child: _buildImageOption(
            icon: Icons.photo_library,
            title: 'Gallery',
            onTap: () => _selectImage(fromCamera: false),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildImageOption(
            icon: Icons.camera_alt,
            title: 'Camera',
            onTap: () => _selectImage(fromCamera: true),
          ),
        ),
      ],
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingBreakdown() {
    final provider = context.watch<GiftUploadProvider>();
    return AnimatedBuilder(
      animation: _priceAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * _priceAnimation.value),
          child: Opacity(
            opacity: _priceAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
                    Theme.of(context).colorScheme.tertiary.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .tertiary
                        .withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calculate,
                          color: Theme.of(context).colorScheme.tertiary,
                          size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Price Breakdown',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .tertiary,
                                fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildPriceRow(
                      'Gift Price', '\$${provider.currentPrice.toStringAsFixed(2)}'),
                  _buildPriceRow('Platform Fee (10%)',
                      '\$${provider.platformFee.toStringAsFixed(2)}'),
                  const Divider(),
                  _buildPriceRow(
                      'Final Price',
                      '\$${provider.finalPrice.toStringAsFixed(2)}',
                      isTotal: true),
                  const SizedBox(height: 8),
                  Text(
                    'You receive: \$${provider.currentPrice.toStringAsFixed(2)} (90%)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isTotal
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight:
                      isTotal ? FontWeight.w700 : FontWeight.w500,
                  color: isTotal
                      ? Theme.of(context).colorScheme.tertiary
                      : null,
                ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GiftUploadProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Custom Gift'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Custom Gift Upload',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                    fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Upload your own images as premium gifts. Set your price and earn 90% of each sale!',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.7)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Image Selection
              GestureDetector(
                onTap: provider.selectedImage == null
                    ? () => _selectImage(fromCamera: false)
                    : null,
                child: _buildImageSelector(),
              ),
              const SizedBox(height: 16),
              _buildImageOptions(),
              const SizedBox(height: 24),
              // Message Input
              Text(
                'Your Message',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _messageController,
                focusNode: _messageFocusNode,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Write a personal message...',
                  prefixIcon: Icon(Icons.message,
                      color: Theme.of(context).colorScheme.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2),
                  ),
                  filled: true,
                  fillColor:
                      Theme.of(context).colorScheme.surface,
                ),
              ),
              const SizedBox(height: 24),
              // Price Input
              Text(
                'Set Price',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _priceController,
                focusNode: _priceFocusNode,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))
                ],
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefixIcon: Icon(Icons.attach_money,
                      color: Theme.of(context).colorScheme.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2),
                  ),
                  filled: true,
                  fillColor:
                      Theme.of(context).colorScheme.surface,
                ),
              ),
              const SizedBox(height: 16),
              // Pricing Breakdown
              if (provider.currentPrice > 0) ...[
                _buildPricingBreakdown(),
                const SizedBox(height: 24),
              ],
              // Upload Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: provider.selectedImage != null &&
                          _messageController.text.trim().isNotEmpty &&
                          provider.currentPrice > 0
                      ? _uploadGift
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    disabledBackgroundColor: Theme.of(context)
                        .colorScheme
                        .outline
                        .withOpacity(0.2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload,
                        color: provider.selectedImage != null &&
                                _messageController.text.trim().isNotEmpty &&
                                provider.currentPrice > 0
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.4),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Upload Gift',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              color: provider.selectedImage != null &&
                                      _messageController.text.trim().isNotEmpty &&
                                      provider.currentPrice > 0
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.4),
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