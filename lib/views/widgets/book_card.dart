import 'package:flutter/material.dart';
import '../../models/book.dart';
import '../../models/loan.dart';
import '../../viewmodels/library_view_model.dart';
import 'borrow_dialog.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final LibraryViewModel viewModel;

  const BookCard({
    super.key,
    required this.book,
    required this.viewModel,
  });

  String _formatCurrency(double amount) {
    return amount.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAvailable = book.isAvailable;

    final activeLoan = viewModel.getActiveLoanForBook(book.id);
    LoanStatus? loanStatus;
    if (activeLoan != null) {
      loanStatus = viewModel.getOverdueStatus(activeLoan);
    }

    Color badgeBgColor;
    Color badgeTextColor;
    String badgeText;
    IconData badgeIcon;

    if (isAvailable) {
      badgeBgColor = Colors.green.shade50;
      badgeTextColor = Colors.green.shade800;
      badgeText = 'Available';
      badgeIcon = Icons.check_circle_outline;
    } else if (loanStatus == LoanStatus.missing) {
      badgeBgColor = Colors.red.shade50;
      badgeTextColor = Colors.red.shade900;
      badgeText = 'Missing (6+ Mo)';
      badgeIcon = Icons.error_outline;
    } else if (loanStatus == LoanStatus.overdue) {
      badgeBgColor = Colors.orange.shade50;
      badgeTextColor = Colors.deepOrange.shade800;
      badgeText = 'Overdue';
      badgeIcon = Icons.warning_amber_rounded;
    } else {
      badgeBgColor = Colors.blue.shade50;
      badgeTextColor = Colors.blue.shade800;
      badgeText = 'Borrowed';
      badgeIcon = Icons.bookmark_outlined;
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (book.category != null)
                        Text(
                          book.category!.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        book.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'by ${book.author}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeBgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(badgeIcon, size: 14, color: badgeTextColor),
                      const SizedBox(width: 4),
                      Text(
                        badgeText,
                        style: TextStyle(
                          color: badgeTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
                      'Replacement Price',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    Text(
                      'Rp${_formatCurrency(book.replacementPrice)}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                FilledButton.tonalIcon(
                  onPressed: isAvailable
                      ? () => BorrowDialog.show(
                            context,
                            book: book,
                            viewModel: viewModel,
                          )
                      : null,
                  icon: const Icon(Icons.bookmark_add, size: 18),
                  label: Text(isAvailable ? 'Borrow' : 'Unavailable'),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
