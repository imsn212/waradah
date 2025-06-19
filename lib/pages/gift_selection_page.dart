import 'package:flutter/material.dart';
import '../models/gift_model.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class GiftSelectionPage extends StatefulWidget {
  const GiftSelectionPage({super.key});

  @override
  State<GiftSelectionPage> createState() => _GiftSelectionPageState();
}

class ImageUploadHelper {
  static Future<Uint8List?> pickImageFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      return await pickedFile.readAsBytes();
    }
    return null;
  }

  static Future<Uint8List?> captureImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (pickedFile != null) {
      return await pickedFile.readAsBytes();
    }
    return null;
  }
}

class _GiftSelectionPageState extends State<GiftSelectionPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedGift;
  GiftType? _selectedGiftType;
  late AnimationController _selectionAnimController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();

  final List<String> _emojiGifts = [
    '🎁', '🌹', '💎', '🍰', '🎈', '🌟', '💝', '🎉',
    '🌺', '🦋', '🌙', '⭐', '🎀', '💐', '🌻', '🌈',
    '🍎', '🍓', '🍯', '🧸', '🎯', '🎨', '🎵', '💫',
    '🦄', '👑', '🔮', '🌸', '🌺', '🌷', '🌊', '🏆',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Initialize animation controller
    _selectionAnimController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticIn)),
        weight: 50,
      ),
    ]).animate(_selectionAnimController);

    _rotationAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 0.17) // ~10 degrees
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.17, end: 0)
            .chain(CurveTween(curve: Curves.elasticIn)),
        weight: 50,
      ),
    ]).animate(_selectionAnimController);
  }

  @override
  void dispose() {
    _selectionAnimController.dispose();
    _messageController.dispose();
    _messageFocusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _selectEmoji(String emoji) {
    setState(() {
      _selectedGift = emoji;
      _selectedGiftType = GiftType.emoji;
    });
  }

  Future<void> _selectImage() async {
    try {
      final imageBytes = await ImageUploadHelper.pickImageFromGallery();
      if (imageBytes != null) {
        final base64Image = base64Encode(imageBytes);
        setState(() {
          _selectedGift = base64Image;
          _selectedGiftType = GiftType.image;
        });
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: \${e.toString()}'),
          // ignore: use_build_context_synchronously
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _confirmSelection() {
    if (_selectedGift != null && _selectedGiftType != null) {
      Navigator.pop(context, {
        'content': _selectedGift,
        'type': _selectedGiftType,
        'message': _messageController.text,
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a gift first'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Widget _buildEmojiGrid() {
    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: _emojiGifts.length,
            itemBuilder: (context, index) {
              final emoji = _emojiGifts[index];
              final isSelected = _selectedGift == emoji;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: GestureDetector(
                  onTap: () => _selectEmoji(emoji),
                  child: AnimatedBuilder(
                    animation: _selectionAnimController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: isSelected ? _scaleAnimation.value : 1.0,
                        child: Transform.rotate(
                          angle: isSelected ? _rotationAnimation.value : 0,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 32),
                            ),
                          ),
                          if (isSelected)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (_selectedGift != null && _selectedGiftType == GiftType.emoji) ...[
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _selectionAnimController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Text(
                        _selectedGift!,
                        style: const TextStyle(fontSize: 48),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _messageController,
                  focusNode: _messageFocusNode,
                  maxLength: 100,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: 'Write your message here...',
                    hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImageSelector() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_selectedGift != null && _selectedGiftType == GiftType.image) ...[
            Container(
              width: double.infinity,
              height: 200,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.memory(
                  base64Decode(_selectedGift!),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Theme.of(context).colorScheme.surface,
                      child: Icon(
                        Icons.error,
                        size: 50,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    );
                  },
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Custom image selected',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Image selection options
          Row(
            children: [
              Expanded(
                child: _buildImageOption(
                  icon: Icons.photo_library,
                  title: 'Gallery',
                  subtitle: 'Choose from photos',
                  onTap: _selectImage,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildImageOption(
                  icon: Icons.camera_alt,
                  title: 'Camera',
                  subtitle: 'Take a photo',
                  onTap: () async {
                    try {
                      final imageBytes = await ImageUploadHelper.captureImage();
                      if (imageBytes != null) {
                        final base64Image = base64Encode(imageBytes);
                        setState(() {
                          _selectedGift = base64Image;
                          _selectedGiftType = GiftType.image;
                        });
                      }
                    } catch (e) {
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error capturing image: \${e.toString()}'),
                          // ignore: use_build_context_synchronously
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                // ignore: deprecated_member_use
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Custom Images',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Upload personal photos as gifts\n• Images are compressed for better performance\n• Supported formats: JPG, PNG',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    // ignore: deprecated_member_use
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String title,
    required String subtitle,
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
            // ignore: deprecated_member_use
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                // ignore: deprecated_member_use
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Gift'),
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          // ignore: deprecated_member_use
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: const [
            Tab(
              icon: Icon(Icons.emoji_emotions),
              text: 'Emojis',
            ),
            Tab(
              icon: Icon(Icons.image),
              text: 'Images',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEmojiGrid(),
                _buildImageSelector(),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedGift != null ? _confirmSelection : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    // ignore: deprecated_member_use
                    disabledBackgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_selectedGift != null) ...[
                        if (_selectedGiftType == GiftType.emoji)
                          Text(
                            _selectedGift!,
                            style: const TextStyle(fontSize: 20),
                          )
                        else
                          Icon(
                            Icons.image,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                      ],
                      const SizedBox(width: 8),
                      Text(
                        'Confirm Selection',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}