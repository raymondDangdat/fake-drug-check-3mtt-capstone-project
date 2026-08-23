import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/drug_check_result.dart';
import '../services/history_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/status_badge.dart';

/// Searchable, filterable verification history archive screen.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<DrugCheckResult> _allHistory = [];
  List<DrugCheckResult> _filteredHistory = [];
  String _selectedFilter = 'All'; // 'All', 'Genuine', 'Suspicious'
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final historyService = context.read<HistoryService>();
    final list = await historyService.getHistory();
    if (mounted) {
      setState(() {
        _allHistory = list;
        _isLoading = false;
        _applyFilters();
      });
    }
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredHistory = _allHistory.where((item) {
        final matchesQuery = query.isEmpty ||
            item.drugName.toLowerCase().contains(query) ||
            item.manufacturer.toLowerCase().contains(query) ||
            item.nafdacNumber.toLowerCase().contains(query);

        final matchesStatus = _selectedFilter == 'All' ||
            item.prediction == _selectedFilter;

        return matchesQuery && matchesStatus;
      }).toList();
    });
  }

  Future<void> _confirmClearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
        title: Text('Clear Verification Archive?', style: AppTypography.h3),
        content: Text(
          'This will permanently delete all saved medication check reports from this device.',
          style: AppTypography.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          AppButton.danger(
            label: 'Clear All',
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final historyService = context.read<HistoryService>();
      await historyService.clearHistory();
      _loadHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification archive cleared.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Verification Archive'),
        actions: [
          if (_allHistory.isNotEmpty)
            IconButton(
              onPressed: _confirmClearHistory,
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Clear history',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            )
          : _allHistory.isEmpty
              ? EmptyState(
                  icon: Icons.history_rounded,
                  title: 'No Verification History Yet',
                  description:
                      'When you check medications, your detailed verification reports will be securely stored here for reference.',
                  actionLabel: 'Verify a Medication',
                  onAction: () => Navigator.pushNamed(context, '/check'),
                )
              : SingleChildScrollView(
                  padding: ResponsiveLayout.isDesktop(context)
                      ? AppSpacing.screenPaddingDesktop
                      : AppSpacing.screenPaddingMobile,
                  child: MaxWidthContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search Input
                        TextField(
                          controller: _searchController,
                          style: AppTypography.body.copyWith(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Search by medication, manufacturer, or NAFDAC no...',
                            prefixIcon: const Icon(Icons.search_rounded, size: 20),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () => _searchController.clear(),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Filter Chips Row
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip('All', _allHistory.length),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                'Genuine',
                                _allHistory.where((i) => i.isGenuine).length,
                                label: 'Low Risk',
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                'Suspicious',
                                _allHistory.where((i) => i.isSuspicious).length,
                                label: 'Suspicious',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Results List
                        if (_filteredHistory.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 48),
                            child: Center(
                              child: Text(
                                'No matching verification reports found.',
                                style: TextStyle(color: AppColors.textMuted),
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _filteredHistory.length,
                            separatorBuilder: (_, index) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = _filteredHistory[index];
                              return _buildHistoryCard(item);
                            },
                          ),
                        const SizedBox(height: 36),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildFilterChip(String filterKey, int count, {String? label}) {
    final isSelected = _selectedFilter == filterKey;
    final displayLabel = label ?? filterKey;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = filterKey;
          _applyFilters();
        });
      },
      borderRadius: AppRadius.pill,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: AppRadius.pill,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayLabel,
              style: AppTypography.button.copyWith(
                fontSize: 12,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppColors.surfaceMuted,
                borderRadius: AppRadius.pill,
              ),
              child: Text(
                '$count',
                style: AppTypography.caption.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(DrugCheckResult item) {
    final formattedDate = DateFormat('MMM d, yyyy • h:mm a').format(item.checkedAt);

    return AppCard(
      onTap: () {
        Navigator.pushNamed(context, '/results', arguments: item);
      },
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Risk Icon Box
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: item.isGenuine ? AppColors.genuineSurface : AppColors.suspiciousSurface,
              borderRadius: AppRadius.md,
              border: Border.all(
                color: item.isGenuine ? AppColors.genuineBorder : AppColors.suspiciousBorder,
              ),
            ),
            child: Icon(
              item.isGenuine ? Icons.check_circle_rounded : Icons.warning_rounded,
              color: item.isGenuine ? AppColors.genuine : AppColors.suspicious,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.drugName,
                        style: AppTypography.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    StatusBadge(
                      label: '${item.confidencePercent} ${item.isGenuine ? 'Match' : 'Risk'}',
                      variant: item.isGenuine
                          ? StatusBadgeVariant.genuine
                          : StatusBadgeVariant.suspicious,
                      isCompact: true,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.manufacturer,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'NAFDAC: ${item.nafdacNumber}',
                      style: AppTypography.caption,
                    ),
                    const SizedBox(width: 8),
                    const Text('•', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                    const SizedBox(width: 8),
                    Text(
                      formattedDate,
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textMuted,
            size: 20,
          ),
        ],
      ),
    );
  }
}
