import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/loan.dart';
import 'package:flutter_application_1/viewmodels/library_view_model.dart';

void main() {
  group('LibraryViewModel MVVM and Business Logic Tests', () {
    late LibraryViewModel viewModel;

    setUp(() {
      viewModel = LibraryViewModel(seedDefaultData: false);
    });

    test('Check 1: Available books are displayed correctly', () {
      expect(viewModel.books.isEmpty, isTrue);

      final seededVM = LibraryViewModel(seedDefaultData: true);
      final availableCount = seededVM.books.where((b) => b.isAvailable).length;
      expect(availableCount, greaterThan(0));
      expect(seededVM.filteredBooks.isNotEmpty, isTrue);
    });

    test('Check 2: Borrowing a book creates loan and marks book unavailable', () {
      final seededVM = LibraryViewModel(seedDefaultData: true);
      final availableBook = seededVM.books.firstWhere((b) => b.isAvailable);

      final initialLoanCount = seededVM.activeLoans.length;
      final result = seededVM.borrowBook(
        bookId: availableBook.id,
        studentId: 'STD-999',
      );

      expect(result.success, isTrue);
      expect(availableBook.isAvailable, isFalse);
      expect(seededVM.activeLoans.length, equals(initialLoanCount + 1));

      final duplicateResult = seededVM.borrowBook(
        bookId: availableBook.id,
        studentId: 'STD-888',
      );
      expect(duplicateResult.success, isFalse);
    });

    test('Check 3: Returning a book marks it available and sets return date', () {
      final seededVM = LibraryViewModel(seedDefaultData: true);
      final activeLoan = seededVM.activeLoans.first;
      final book = seededVM.getBookById(activeLoan.bookId)!;

      expect(book.isAvailable, isFalse);
      expect(activeLoan.isReturned, isFalse);

      final returnResult = seededVM.returnBook(activeLoan.id);
      expect(returnResult.success, isTrue);
      expect(book.isAvailable, isTrue);
      expect(activeLoan.isReturned, isTrue);
      expect(activeLoan.returnDate, isNotNull);
    });

    test('Check 4: Due date is properly assigned for 6-day duration', () {
      final seededVM = LibraryViewModel(seedDefaultData: true);
      final availableBook = seededVM.books.firstWhere((b) => b.isAvailable);

      final borrowDate = DateTime(2023, 10, 1);
      seededVM.borrowBook(
        bookId: availableBook.id,
        studentId: 'STD-111',
        borrowDate: borrowDate,
        durationDays: 6,
      );

      final newLoan = seededVM.activeLoans.first;
      expect(newLoan.borrowDate, equals(borrowDate));
      expect(newLoan.dueDate, equals(DateTime(2023, 10, 7)));
    });

    test('Check 5: On-time return has Rp0 overdue fine', () {
      final dueDate = DateTime(2023, 10, 7);
      final loan = Loan(
        id: 'L-ONTIME',
        bookId: 'DKV-101',
        studentId: 'S-1',
        borrowDate: DateTime(2023, 10, 1),
        dueDate: dueDate,
        returnDate: DateTime(2023, 10, 7),
      );

      final fineOnDueDate = viewModel.calculateFine(loan);
      expect(fineOnDueDate, equals(0.0));

      loan.returnDate = DateTime(2023, 10, 5);
      expect(viewModel.calculateFine(loan), equals(0.0));
    });

    test('Check 6: Overdue fine starts on day 7 after loan and increases after 1 week overdue', () {
      final dueDate = DateTime(2023, 10, 7);
      final loan = Loan(
        id: 'L-OVERDUE',
        bookId: 'DKV-101',
        studentId: 'S-1',
        borrowDate: DateTime(2023, 10, 1),
        dueDate: dueDate,
      );

      final oneDayOverdueDate = DateTime(2023, 10, 8);
      expect(viewModel.getDaysOverdue(loan, asOfDate: oneDayOverdueDate), equals(1));
      expect(viewModel.getCompletedOverdueWeeks(loan, asOfDate: oneDayOverdueDate), equals(1));
      expect(viewModel.calculateFine(loan, asOfDate: oneDayOverdueDate), equals(5000.0));

      final sevenDaysOverdueDate = DateTime(2023, 10, 14);
      expect(viewModel.getDaysOverdue(loan, asOfDate: sevenDaysOverdueDate), equals(7));
      expect(viewModel.getCompletedOverdueWeeks(loan, asOfDate: sevenDaysOverdueDate), equals(1));
      expect(viewModel.calculateFine(loan, asOfDate: sevenDaysOverdueDate), equals(5000.0));

      final eightDaysOverdueDate = DateTime(2023, 10, 15);
      expect(viewModel.getDaysOverdue(loan, asOfDate: eightDaysOverdueDate), equals(8));
      expect(viewModel.getCompletedOverdueWeeks(loan, asOfDate: eightDaysOverdueDate), equals(2));
      expect(viewModel.calculateFine(loan, asOfDate: eightDaysOverdueDate), equals(10000.0));
    });

    test('Check 7: Six-month overdue is marked Missing and charges replacement price plus accumulated fine', () {
      final seededVM = LibraryViewModel(seedDefaultData: true);
      final missingLoan = seededVM.loans.firstWhere((l) => l.id == 'LOAN-DKV-003');

      expect(seededVM.isLoanMissing(missingLoan), isTrue);
      expect(seededVM.getOverdueStatus(missingLoan), equals(LoanStatus.missing));

      final book = seededVM.getBookById(missingLoan.bookId)!;
      final fine = seededVM.calculateFine(missingLoan);
      final daysOverdue = seededVM.getDaysOverdue(missingLoan);
      final weeksOverdue = ((daysOverdue - 1) ~/ 7) + 1;
      final expectedOverdueFine = weeksOverdue * seededVM.weeklyFineRate;

      expect(fine, equals(expectedOverdueFine + book.replacementPrice));
      expect(fine, greaterThan(book.replacementPrice));
    });

    test('Check 8 & 9: ChangeNotifier notifications and fine rate customization', () {
      int notifyCount = 0;
      viewModel.addListener(() => notifyCount++);

      viewModel.setSearchQuery('Tipografi');
      expect(notifyCount, equals(1));

      viewModel.setStatusFilter(BookFilter.available);
      expect(notifyCount, equals(2));

      viewModel.weeklyFineRate = 7000.0;
      final loan = Loan(
        id: 'L1',
        bookId: 'DKV-101',
        studentId: 'S1',
        borrowDate: DateTime(2023, 1, 1),
        dueDate: DateTime(2023, 1, 7),
      );
      final fine = viewModel.calculateFine(loan, asOfDate: DateTime(2023, 1, 8));
      expect(fine, equals(7000.0));
    });
  });
}
