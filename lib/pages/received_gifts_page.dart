import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/gift_service.dart';
import '../models/gift_model.dart';
import '../widgets/gift_grid_widget.dart';

class ReceivedGiftsPage extends StatefulWidget {
  const ReceivedGiftsPage({super.key});

  @override
  State<ReceivedGiftsPage> createState() => _ReceivedGiftsPageState();
}

class _ReceivedGiftsPageState extends State<ReceivedGiftsPage>
    with SingleTickerProviderStateMixin {
  final GiftService _giftService = GiftService();
  List<Gift> _receivedGifts = [];
  List<Gift> _filteredGifts = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _filterOptions = ['All', 'Today', 'This Week', 'Free', 'Premium'];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadGifts();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadGifts() async {
    setState(() => _isLoading = true);
    
    try {
      final currentUser = await _giftService.getCurrentUser();
      if (currentUser != null) {
        final gifts = await _giftService.getReceivedGifts(currentUser);
        setState(() {
          _receivedGifts = gifts;
          _filteredGifts = gifts;
        });
        _animationController.forward();
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) {
          print('Error loading gifts: $e');
        }
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      final now = DateTime.now();
      
      switch (filter) {
        case 'All':
          _filteredGifts = _receivedGifts;
          break;
        case 'Today':
          final today = DateTime(now.year, now.month, now.day);
          _filteredGifts = _receivedGifts.where((gift) {
            final giftDate = DateTime(
              gift.timestamp.year,
              gift.timestamp.month,
              gift.timestamp.day,
            );
            return giftDate.isAtSameMomentAs(today);
          }).toList();
          break;
        case 'This Week':
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
          _filteredGifts = _receivedGifts.where((gift) {
            return gift.timestamp.isAfter(weekStartDate);
          }).toList();
          break;
        case 'Free':
          _filteredGifts = _receivedGifts.where((gift) => gift.isFree).toList();
          break;
        case 'Premium':
          _filteredGifts = _receivedGifts.where((gift) => !gift.isFree).toList();
          break;
      }
    });
  }

  void _showGiftDetails(Gift gift) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GiftDetailsSheet(gift: gift),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filterOptions.length,
        itemBuilder: (context, index) {
          final filter = _filterOptions[index];
          final isSelected = _selectedFilter == filter;
          
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                filter,
                style: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => _applyFilter(filter),
              selectedColor: Theme.of(context).colorScheme.primary,
              backgroundColor: Theme.of(context).colorScheme.surface,
              side: BorderSide(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsHeader() {
    final totalGifts = _receivedGifts.length;
    final freeGifts = _receivedGifts.where((g) => g.isFree).length;
    final premiumGifts = totalGifts - freeGifts;
    final totalValue = _receivedGifts
        .where((g) => !g.isFree)
        .fold(0.0, (sum, gift) => sum + gift.price);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.card_giftcard,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Gift Summary',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  title: 'Total Gifts',
                  value: totalGifts.toString(),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  title: 'Free Gifts',
                  value: freeGifts.toString(),
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  title: 'Premium',
                  value: premiumGifts.toString(),
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ),
            ],
          ),
          if (totalValue > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Total Value: \$${totalValue.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.tertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Received Gifts'),
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
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: _loadGifts,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading your gifts...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  if (_receivedGifts.isNotEmpty) _buildStatsHeader(),
                  _buildFilterChips(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: GiftGridWidget(
                      gifts: _filteredGifts,
                      showSender: true,
                      showPrice: true,
                      onRefresh: _loadGifts,
                      onGiftTap: _showGiftDetails,
                      emptyTitle: _selectedFilter == 'All'
                          ? 'No gifts received yet'
                          : 'No \${_selectedFilter.toLowerCase()} gifts',
                      emptySubtitle: _selectedFilter == 'All'
                          ? 'Ask friends to send you some gifts! 💝'
                          : 'Try a different filter to see more gifts',
                      emptyIcon: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Icon(
                          _selectedFilter == 'All' ? Icons.inbox : Icons.filter_alt,
                          size: 50,
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class GiftDetailsSheet extends StatelessWidget {
  final Gift gift;

  const GiftDetailsSheet({super.key, required this.gift});

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.8,
        minChildSize: 0.4,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Gift Display
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              gift.content,
                              style: const TextStyle(fontSize: 60),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Gift Title
                        Text(
                          'Gift from @${gift.sender}',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),

                        // Gift Type Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: gift.isFree
                                ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1)
                                : Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            gift.isFree ? 'Free Gift 💝' : 'Premium Gift (\$${gift.price.toStringAsFixed(2)})',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: gift.isFree
                                  ? Theme.of(context).colorScheme.secondary
                                  : Theme.of(context).colorScheme.tertiary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Details
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow(
                                context,
                                'Received',
                                _formatDateTime(gift.timestamp),
                                Icons.schedule,
                              ),
                              const SizedBox(height: 12),
                              _buildDetailRow(
                                context,
                                'From',
                                '@${gift.sender}',
                                Icons.person,
                              ),
                              const SizedBox(height: 12),
                              _buildDetailRow(
                                context,
                                'Type',
                                gift.type.name.toUpperCase(),
                                Icons.category,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Close Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Close',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}