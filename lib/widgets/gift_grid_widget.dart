import 'package:flutter/material.dart';
import '../models/gift_model.dart';
import 'gift_card_widget.dart';

class GiftGridWidget extends StatefulWidget {
  final List<Gift> gifts;
  final bool showSender;
  final bool showPrice;
  final VoidCallback? onRefresh;
  final Function(Gift)? onGiftTap;
  final String emptyTitle;
  final String emptySubtitle;
  final Widget? emptyIcon;

  const GiftGridWidget({
    super.key,
    required this.gifts,
    this.showSender = true,
    this.showPrice = true,
    this.onRefresh,
    this.onGiftTap,
    this.emptyTitle = 'No gifts yet',
    this.emptySubtitle = 'Start sharing some love! 💝',
    this.emptyIcon,
  });

  @override
  State<GiftGridWidget> createState() => _GiftGridWidgetState();
}

class _GiftGridWidgetState extends State<GiftGridWidget> {
  bool _isRefreshing = false;

  Future<void> _handleRefresh() async {
    if (widget.onRefresh == null) return;
    
    setState(() {
      _isRefreshing = true;
    });

    try {
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
      widget.onRefresh!();
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            widget.emptyIcon ??
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    Icons.card_giftcard,
                    size: 50,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
                  ),
                ),
            const SizedBox(height: 24),
            Text(
              widget.emptyTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.emptySubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (widget.onRefresh != null)
              ElevatedButton.icon(
                onPressed: _isRefreshing ? null : _handleRefresh,
                icon: _isRefreshing
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      )
                    : Icon(
                        Icons.refresh,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                label: Text(
                  _isRefreshing ? 'Refreshing...' : 'Refresh',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGiftsList() {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: widget.gifts.length,
        itemBuilder: (context, index) {
          final gift = widget.gifts[index];
          return AnimationWrapper(
            index: index,
            child: GiftCardWidget(
              gift: gift,
              showSender: widget.showSender,
              showPrice: widget.showPrice,
              onTap: () => widget.onGiftTap?.call(gift),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.gifts.isEmpty) {
      return _buildEmptyState();
    }

    return _buildGiftsList();
  }
}

class AnimationWrapper extends StatefulWidget {
  final Widget child;
  final int index;

  const AnimationWrapper({
    super.key,
    required this.child,
    required this.index,
  });

  @override
  State<AnimationWrapper> createState() => _AnimationWrapperState();
}

class _AnimationWrapperState extends State<AnimationWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300 + (widget.index * 100)),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // Start animation after a slight delay based on index
    Future.delayed(Duration(milliseconds: widget.index * 50), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: widget.child,
          ),
        );
      },
    );
  }
}