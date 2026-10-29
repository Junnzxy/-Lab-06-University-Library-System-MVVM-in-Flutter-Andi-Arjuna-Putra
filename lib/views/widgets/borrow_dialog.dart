import 'package:flutter/material.dart';

import '../../models/book.dart';
import '../../viewmodels/library_view_model.dart';

class BorrowDialog extends StatefulWidget {
  final Book book;
  final LibraryViewModel viewModel;

  const BorrowDialog({super.key, required this.book, required this.viewModel});

  static Future<void> show(
    BuildContext context, {
    required Book book,
    required LibraryViewModel viewModel,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => BorrowDialog(book: book, viewModel: viewModel),
    );
  }

  @override
  State<BorrowDialog> createState() => _BorrowDialogState();
}

class _BorrowDialogState extends State<BorrowDialog> {
  final _studentIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _studentIdController.dispose();
    super.dispose();
  }

  void _onBorrow() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final studentId = _studentIdController.text.trim();
    final result = widget.viewModel.borrowBook(
      bookId: widget.book.id,
      studentId: studentId,
    );

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success
            ? Colors.green.shade800
            : Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Borrow Book'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.book.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'by ${widget.book.author}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              TextFormField(
                controller: _studentIdController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Student ID',
                  hintText: 'e.g., STD-2026-001',
                  prefixIcon: Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a valid Student ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Standard loan period: ${LibraryViewModel.defaultLoanDurationDays} days',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _onBorrow,
          icon: const Icon(Icons.bookmark_add),
          label: const Text('Confirm Borrow'),
        ),
      ],
    );
  }
}
