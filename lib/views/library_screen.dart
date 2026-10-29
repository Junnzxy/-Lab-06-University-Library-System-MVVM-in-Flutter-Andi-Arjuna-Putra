import 'package:flutter/material.dart';
import '../viewmodels/library_view_model.dart';
import 'widgets/book_card.dart';
import 'widgets/date_simulator_bar.dart';
import 'widgets/empty_state.dart';
import 'widgets/fine_summary_card.dart';
import 'widgets/loan_card.dart';

class LibraryScreen extends StatefulWidget {
  final LibraryViewModel viewModel;

  const LibraryScreen({
    super.key,
    required this.viewModel,
  });

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int _selectedTabIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = widget.viewModel;

    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            scrolledUnderElevation: 2,
            title: Row(
              children: [
                Icon(Icons.local_library_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                const Text(
                  'University Library',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              if (vm.overdueLoans.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.shade400),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning, size: 14, color: Colors.red.shade800),
                          const SizedBox(width: 4),
                          Text(
                            '${vm.overdueLoans.length} Overdue',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              DateSimulatorBar(viewModel: vm),
              Expanded(
                child: IndexedStack(
                  index: _selectedTabIndex,
                  children: [
                    _buildCatalogueTab(context, vm),
                    _buildActiveLoansTab(context, vm),
                    _buildHistoryTab(context, vm),
                    _buildSummaryTab(context, vm),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedTabIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedTabIndex = index;
              });
            },
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book),
                label: 'Catalogue',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: vm.activeLoans.isNotEmpty,
                  label: Text('${vm.activeLoans.length}'),
                  child: const Icon(Icons.bookmark_border),
                ),
                selectedIcon: Badge(
                  isLabelVisible: vm.activeLoans.isNotEmpty,
                  label: Text('${vm.activeLoans.length}'),
                  child: const Icon(Icons.bookmark),
                ),
                label: 'Active Loans',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: vm.returnedLoans.isNotEmpty,
                  label: Text('${vm.returnedLoans.length}'),
                  child: const Icon(Icons.history),
                ),
                selectedIcon: const Icon(Icons.history_toggle_off),
                label: 'History',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: vm.totalOutstandingFines > 0,
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.analytics_outlined),
                ),
                selectedIcon: const Icon(Icons.analytics),
                label: 'Fines & Summary',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCatalogueTab(BuildContext context, LibraryViewModel vm) {
    final books = vm.filteredBooks;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search books by title, author, or ISBN...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: vm.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        vm.setSearchQuery('');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onChanged: (value) => vm.setSearchQuery(value),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              _buildFilterChip('All Books', BookFilter.all, vm),
              const SizedBox(width: 8),
              _buildFilterChip('Available', BookFilter.available, vm),
              const SizedBox(width: 8),
              _buildFilterChip('Borrowed', BookFilter.borrowed, vm),
              const SizedBox(width: 8),
              _buildFilterChip('Overdue', BookFilter.overdue, vm),
              const SizedBox(width: 8),
              _buildFilterChip('Missing', BookFilter.missing, vm),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: books.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.search_off,
                  title: 'No books found',
                  subtitle: vm.searchQuery.isNotEmpty
                      ? 'No titles or authors match "${vm.searchQuery}".'
                      : 'No books match the selected status filter.',
                  actionLabel: 'Reset Filters',
                  onAction: () {
                    _searchController.clear();
                    vm.setSearchQuery('');
                    vm.setStatusFilter(BookFilter.all);
                  },
                )
              : ListView.builder(
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    final book = books[index];
                    return BookCard(book: book, viewModel: vm);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, BookFilter filter, LibraryViewModel vm) {
    final isSelected = vm.statusFilter == filter;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => vm.setStatusFilter(filter),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildActiveLoansTab(BuildContext context, LibraryViewModel vm) {
    final activeLoans = vm.activeLoans;

    if (activeLoans.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.bookmark_border,
        title: 'No active loans',
        subtitle: 'All books are currently returned and available in the catalogue.',
        actionLabel: 'Browse Catalogue',
        onAction: () {
          setState(() {
            _selectedTabIndex = 0;
          });
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: activeLoans.length,
      itemBuilder: (context, index) {
        final loan = activeLoans[index];
        return LoanCard(loan: loan, viewModel: vm);
      },
    );
  }

  Widget _buildHistoryTab(BuildContext context, LibraryViewModel vm) {
    final returnedLoans = vm.returnedLoans;

    if (returnedLoans.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.history,
        title: 'No returned records yet',
        subtitle: 'When students return borrowed books, their history and settled fines will be recorded here.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: returnedLoans.length,
      itemBuilder: (context, index) {
        final loan = returnedLoans[index];
        return LoanCard(loan: loan, viewModel: vm);
      },
    );
  }

  Widget _buildSummaryTab(BuildContext context, LibraryViewModel vm) {
    return SingleChildScrollView(
      child: FineSummaryCard(viewModel: vm),
    );
  }
}
