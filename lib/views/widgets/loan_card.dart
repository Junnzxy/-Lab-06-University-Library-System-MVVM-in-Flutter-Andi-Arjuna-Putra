import 'package:flutter/material.dart';
import '../../models/loan.dart';
import '../../viewmodels/library_view_model.dart';

class LoanCard extends StatelessWidget {
  final Loan loan;
  final LibraryViewModel viewModel;

  const LoanCard({
    super.key,
    required this.loan,
    required this.viewModel,
  });

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatCurrency(double amount) {
    return amount.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  void _onReturn(BuildContext context) {
    final result = viewModel.returnBook(loan.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? Colors.green.shade800 : Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final book = viewModel.getBookById(loan.bookId);

    final status = viewModel.getOverdueStatus(loan);
    final fine = viewModel.calculateFine(loan);
    final completedWeeks = viewModel.getCompletedOverdueWeeks(loan);
    final daysOverdue = viewModel.getDaysOverdue(loan);

    Color badgeBgColor;
    Color badgeTextColor;
    String badgeText;
    IconData badgeIcon;

    switch (status) {
      case LoanStatus.active:
        badgeBgColor = Colors.blue.shade50;
        badgeTextColor = Colors.blue.shade800;
        badgeText = 'Active Loan';
        badgeIcon = Icons.timelapse;
        break;
      case LoanStatus.overdue:
        badgeBgColor = Colors.orange.shade50;
        badgeTextColor = Colors.deepOrange.shade800;
        badgeText = 'Overdue ($daysOverdue d / $completedWeeks wk)';
        badgeIcon = Icons.warning_amber_rounded;
        break;
      case LoanStatus.missing:
        badgeBgColor = Colors.red.shade50;
        badgeTextColor = Colors.red.shade900;
        badgeText = 'Missing (6+ Mo)';
        badgeIcon = Icons.error_outline;
        break;
      case LoanStatus.returned:
        badgeBgColor = Colors.green.shade50;
        badgeTextColor = Colors.green.shade800;
        badgeText = 'Returned';
        badgeIcon = Icons.check_circle_outline;
        break;
    }

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.badge, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      loan.studentId,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(badgeIcon, size: 13, color: badgeTextColor),
                      const SizedBox(width: 4),
                      Text(
                        badgeText,
                        style: TextStyle(
                          color: badgeTextColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              book?.title ?? 'Book ID: ${loan.bookId}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (book != null) ...[
              const SizedBox(height: 2),
              Text(
                'by ${book.author}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Borrowed On',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    Text(
                      _formatDate(loan.borrowDate),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Due Date',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    Text(
                      _formatDate(loan.dueDate),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: status == LoanStatus.overdue || status == LoanStatus.missing
                            ? Colors.red.shade700
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                if (loan.isReturned && loan.returnDate != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Returned On',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      Text(
                        _formatDate(loan.returnDate!),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loan.isReturned ? 'Assessed Fine' : 'Current Overdue Fine',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      Text(
                        fine > 0 ? 'Rp${_formatCurrency(fine)}' : 'Rp0 (No Fine)',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: fine > 0 ? Colors.red.shade700 : Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                  if (!loan.isReturned)
                    FilledButton.icon(
                      onPressed: () => _onReturn(context),
                      icon: const Icon(Icons.assignment_return, size: 16),
                      label: const Text('Return Book'),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Icon(Icons.check_circle, size: 16, color: Colors.green.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Settled',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
