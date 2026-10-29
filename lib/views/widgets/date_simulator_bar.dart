import 'package:flutter/material.dart';
import '../../viewmodels/library_view_model.dart';

class DateSimulatorBar extends StatelessWidget {
  final LibraryViewModel viewModel;

  const DateSimulatorBar({
    super.key,
    required this.viewModel,
  });

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: viewModel.currentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      viewModel.setSimulatedDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCustomDate = !_isSameDay(viewModel.currentDate, DateTime.now());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isCustomDate
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 16,
                color: isCustomDate ? theme.colorScheme.primary : theme.colorScheme.outline,
              ),
              const SizedBox(width: 6),
              Text(
                'Reference Date (Time Simulation):',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isCustomDate ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => _pickDate(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCustomDate
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _formatDate(viewModel.currentDate),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isCustomDate
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.edit_calendar, size: 14),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ActionChip(
                  avatar: const Icon(Icons.today, size: 14),
                  label: const Text('Today', style: TextStyle(fontSize: 11)),
                  onPressed: () => viewModel.resetToToday(),
                ),
                const SizedBox(width: 6),
                ActionChip(
                  avatar: const Icon(Icons.forward_5, size: 14),
                  label: const Text('+7 Days (1 Wk)', style: TextStyle(fontSize: 11)),
                  onPressed: () => viewModel.advanceDays(7),
                ),
                const SizedBox(width: 6),
                ActionChip(
                  avatar: const Icon(Icons.fast_forward, size: 14),
                  label: const Text('+14 Days (2 Wks)', style: TextStyle(fontSize: 11)),
                  onPressed: () => viewModel.advanceDays(14),
                ),
                const SizedBox(width: 6),
                ActionChip(
                  avatar: const Icon(Icons.hourglass_bottom, size: 14),
                  label: const Text('+6 Months (Missing)', style: TextStyle(fontSize: 11)),
                  onPressed: () => viewModel.advanceMonths(6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
