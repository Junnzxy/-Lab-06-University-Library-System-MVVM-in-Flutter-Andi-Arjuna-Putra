import 'package:flutter/foundation.dart';

import '../models/book.dart';
import '../models/loan.dart';

enum BookFilter { all, available, borrowed, overdue, missing }

class LibraryViewModel extends ChangeNotifier {
  double weeklyFineRate = 5000.0;
  static const int defaultLoanDurationDays = 6;
  static const int missingMonthsThreshold = 6;

  final List<Book> _books = [];
  final List<Loan> _loans = [];
  DateTime _currentDate = DateTime.now();
  String _searchQuery = '';
  BookFilter _statusFilter = BookFilter.all;

  LibraryViewModel({bool seedDefaultData = true}) {
    if (seedDefaultData) {
      _seedInitialData();
    }
  }

  List<Book> get books => List.unmodifiable(_books);
  List<Loan> get loans => List.unmodifiable(_loans);
  DateTime get currentDate => _currentDate;
  String get searchQuery => _searchQuery;
  BookFilter get statusFilter => _statusFilter;

  List<Loan> get activeLoans =>
      _loans.where((loan) => !loan.isReturned).toList();

  List<Loan> get returnedLoans =>
      _loans.where((loan) => loan.isReturned).toList();

  List<Loan> get overdueLoans => _loans
      .where(
        (loan) =>
            !loan.isReturned &&
            (getOverdueStatus(loan) == LoanStatus.overdue ||
                getOverdueStatus(loan) == LoanStatus.missing),
      )
      .toList();

  List<Loan> get missingLoans => _loans
      .where(
        (loan) =>
            !loan.isReturned && getOverdueStatus(loan) == LoanStatus.missing,
      )
      .toList();

  List<Book> get filteredBooks {
    return _books.where((book) {
      final matchesQuery =
          _searchQuery.isEmpty ||
          book.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          book.author.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (book.isbn != null &&
              book.isbn!.toLowerCase().contains(_searchQuery.toLowerCase()));

      if (!matchesQuery) return false;

      switch (_statusFilter) {
        case BookFilter.all:
          return true;
        case BookFilter.available:
          return book.isAvailable;
        case BookFilter.borrowed:
          return !book.isAvailable;
        case BookFilter.overdue:
          if (book.isAvailable) return false;
          final loan = getActiveLoanForBook(book.id);
          return loan != null && getOverdueStatus(loan) == LoanStatus.overdue;
        case BookFilter.missing:
          if (book.isAvailable) return false;
          final loan = getActiveLoanForBook(book.id);
          return loan != null && getOverdueStatus(loan) == LoanStatus.missing;
      }
    }).toList();
  }

  double get totalOutstandingFines {
    double total = 0.0;
    for (final loan in activeLoans) {
      total += calculateFine(loan);
    }
    return total;
  }

  double get totalSettledFines {
    double total = 0.0;
    for (final loan in returnedLoans) {
      if (loan.assessedFine != null) {
        total += loan.assessedFine!;
      }
    }
    return total;
  }

  ({bool success, String message}) borrowBook({
    required String bookId,
    required String studentId,
    DateTime? borrowDate,
    int durationDays = defaultLoanDurationDays,
  }) {
    final trimmedStudentId = studentId.trim();
    if (trimmedStudentId.isEmpty) {
      return (success: false, message: 'Student ID cannot be empty.');
    }

    final bookIndex = _books.indexWhere((b) => b.id == bookId);
    if (bookIndex == -1) {
      return (success: false, message: 'Book not found.');
    }

    final book = _books[bookIndex];

    if (!book.isAvailable) {
      return (
        success: false,
        message: 'Book "${book.title}" is already borrowed and not available.',
      );
    }

    final existingActiveLoan = _loans.any(
      (loan) => loan.bookId == bookId && !loan.isReturned,
    );
    if (existingActiveLoan) {
      return (
        success: false,
        message: 'An active loan already exists for this book.',
      );
    }

    final effectiveBorrowDate = borrowDate ?? _currentDate;
    final dueDate = effectiveBorrowDate.add(Duration(days: durationDays));

    final newLoan = Loan(
      id: 'LOAN-${DateTime.now().millisecondsSinceEpoch}-${_loans.length + 1}',
      bookId: bookId,
      studentId: trimmedStudentId,
      borrowDate: effectiveBorrowDate,
      dueDate: dueDate,
    );

    _books[bookIndex].isAvailable = false;
    _loans.insert(0, newLoan);

    notifyListeners();
    return (
      success: true,
      message:
          'Successfully borrowed "${book.title}". Due date: ${_formatDate(dueDate)}',
    );
  }

  ({bool success, String message}) returnBook(
    String loanId, {
    DateTime? returnDate,
  }) {
    final loanIndex = _loans.indexWhere((l) => l.id == loanId);
    if (loanIndex == -1) {
      return (success: false, message: 'Loan record not found.');
    }

    final loan = _loans[loanIndex];
    if (loan.isReturned) {
      return (success: false, message: 'This book has already been returned.');
    }

    final effectiveReturnDate = returnDate ?? _currentDate;
    final fine = calculateFine(loan, asOfDate: effectiveReturnDate);

    loan.returnDate = effectiveReturnDate;
    loan.assessedFine = fine;

    final bookIndex = _books.indexWhere((b) => b.id == loan.bookId);
    if (bookIndex != -1) {
      _books[bookIndex].isAvailable = true;
    }

    notifyListeners();

    final fineNotice = fine > 0
        ? ' Assessed fine: Rp${_formatCurrency(fine)}.'
        : ' No overdue fine.';
    return (
      success: true,
      message:
          'Book successfully returned on ${_formatDate(effectiveReturnDate)}.$fineNotice',
    );
  }

  LoanStatus getOverdueStatus(Loan loan, {DateTime? asOfDate}) {
    if (loan.isReturned) {
      return LoanStatus.returned;
    }

    final dateToEvaluate = asOfDate ?? _currentDate;

    if (isLoanMissing(loan, asOfDate: dateToEvaluate)) {
      return LoanStatus.missing;
    }

    final normalizedEffective = _normalizeDate(dateToEvaluate);
    final normalizedDue = _normalizeDate(loan.dueDate);

    if (normalizedEffective.isAfter(normalizedDue)) {
      return LoanStatus.overdue;
    }

    return LoanStatus.active;
  }

  int getCompletedOverdueWeeks(Loan loan, {DateTime? asOfDate}) {
    final daysOverdue = getDaysOverdue(loan, asOfDate: asOfDate);
    if (daysOverdue <= 0) {
      return 0;
    }
    return ((daysOverdue - 1) ~/ 7) + 1;
  }

  int getDaysOverdue(Loan loan, {DateTime? asOfDate}) {
    final dateToEvaluate = loan.returnDate ?? (asOfDate ?? _currentDate);
    final normalizedEffective = _normalizeDate(dateToEvaluate);
    final normalizedDue = _normalizeDate(loan.dueDate);

    final diff = normalizedEffective.difference(normalizedDue).inDays;
    return diff > 0 ? diff : 0;
  }

  bool isLoanMissing(Loan loan, {DateTime? asOfDate}) {
    final dateToEvaluate = loan.returnDate ?? (asOfDate ?? _currentDate);
    final normalizedEffective = _normalizeDate(dateToEvaluate);

    final sixMonthsAfterDue = addCalendarMonths(
      loan.dueDate,
      missingMonthsThreshold,
    );
    final normalizedThreshold = _normalizeDate(sixMonthsAfterDue);

    return normalizedEffective.isAtSameMomentAs(normalizedThreshold) ||
        normalizedEffective.isAfter(normalizedThreshold);
  }

  double calculateFine(Loan loan, {DateTime? asOfDate}) {
    if (loan.isReturned && loan.assessedFine != null) {
      return loan.assessedFine!;
    }

    final dateToEvaluate = loan.returnDate ?? (asOfDate ?? _currentDate);
    final daysOverdue = getDaysOverdue(loan, asOfDate: dateToEvaluate);

    if (daysOverdue <= 0) {
      return 0.0;
    }

    final weeksOverdue = ((daysOverdue - 1) ~/ 7) + 1;
    final overdueFine = weeksOverdue * weeklyFineRate;

    if (isLoanMissing(loan, asOfDate: dateToEvaluate)) {
      final book = getBookById(loan.bookId);
      final replacementPrice = book?.replacementPrice ?? 200000.0;
      return overdueFine + replacementPrice;
    }

    return overdueFine;
  }

  static DateTime addCalendarMonths(DateTime date, int months) {
    int newYear = date.year + (date.month - 1 + months) ~/ 12;
    int newMonth = (date.month - 1 + months) % 12 + 1;
    int daysInNewMonth = DateTime(newYear, newMonth + 1, 0).day;
    int newDay = date.day > daysInNewMonth ? daysInNewMonth : date.day;
    return DateTime(newYear, newMonth, newDay);
  }

  Book? getBookById(String id) {
    try {
      return _books.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  Loan? getActiveLoanForBook(String bookId) {
    try {
      return _loans.firstWhere((l) => l.bookId == bookId && !l.isReturned);
    } catch (_) {
      return null;
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(BookFilter filter) {
    _statusFilter = filter;
    notifyListeners();
  }

  void setSimulatedDate(DateTime date) {
    _currentDate = date;
    notifyListeners();
  }

  void resetToToday() {
    _currentDate = DateTime.now();
    notifyListeners();
  }

  void advanceDays(int days) {
    _currentDate = _currentDate.add(Duration(days: days));
    notifyListeners();
  }

  void advanceMonths(int months) {
    _currentDate = addCalendarMonths(_currentDate, months);
    notifyListeners();
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatCurrency(double amount) {
    return amount.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  void _seedInitialData() {
    _books.addAll([
      Book(
        id: 'DKV-101',
        title: 'Tipografi dalam Desain Komunikasi Visual',
        author: 'Surianto Rustan',
        replacementPrice: 180000.0,
        category: 'Tipografi',
        isbn: '978-9792243222',
        isAvailable: true,
      ),
      Book(
        id: 'DKV-102',
        title: 'Nirmana: Elemen-Elemen Seni dan Desain',
        author: 'Sadjiman Ebdi Sanyoto',
        replacementPrice: 220000.0,
        category: 'Dasar Desain',
        isbn: '978-9799988102',
        isAvailable: true,
      ),
      Book(
        id: 'DKV-103',
        title: 'Tata Huruf & Tipografi Terapan',
        author: 'Danton Sihombing',
        replacementPrice: 195000.0,
        category: 'Tipografi',
        isbn: '978-9792271836',
        isAvailable: false,
      ),
      Book(
        id: 'DKV-104',
        title: 'Metodologi Desain Komunikasi Visual',
        author: 'Agus Sachari',
        replacementPrice: 210000.0,
        category: 'Teori Desain',
        isbn: '978-9797561849',
        isAvailable: false,
      ),
      Book(
        id: 'DKV-105',
        title: 'Dasar-Dasar Desain Komunikasi Visual',
        author: 'Hendi Hendratman',
        replacementPrice: 240000.0,
        category: 'Grafis Digital',
        isbn: '978-6028758253',
        isAvailable: false,
      ),
      Book(
        id: 'DKV-106',
        title: 'Fotografi Komersial & Tata Cahaya Studio',
        author: 'Darwis Triadi',
        replacementPrice: 350000.0,
        category: 'Fotografi DKV',
        isbn: '978-9792238419',
        isAvailable: true,
      ),
      Book(
        id: 'DKV-107',
        title: 'Branding & Desain Identitas Visual',
        author: 'Robin Landa',
        replacementPrice: 280000.0,
        category: 'Branding',
        isbn: '978-0470557624',
        isAvailable: true,
      ),
    ]);

    final now = _currentDate;

    _loans.add(
      Loan(
        id: 'LOAN-DKV-001',
        bookId: 'DKV-103',
        studentId: 'DKV-2024-001',
        borrowDate: now.subtract(const Duration(days: 3)),
        dueDate: now.add(const Duration(days: 3)),
      ),
    );

    _loans.add(
      Loan(
        id: 'LOAN-DKV-002',
        bookId: 'DKV-104',
        studentId: 'DKV-2024-002',
        borrowDate: now.subtract(const Duration(days: 14)),
        dueDate: now.subtract(const Duration(days: 8)),
      ),
    );

    final missingDueDate = DateTime(now.year, now.month - 7, now.day);
    _loans.add(
      Loan(
        id: 'LOAN-DKV-003',
        bookId: 'DKV-105',
        studentId: 'DKV-2024-003',
        borrowDate: missingDueDate.subtract(const Duration(days: 6)),
        dueDate: missingDueDate,
      ),
    );

    _loans.add(
      Loan(
        id: 'LOAN-DKV-004',
        bookId: 'DKV-101',
        studentId: 'DKV-2024-004',
        borrowDate: now.subtract(const Duration(days: 12)),
        dueDate: now.subtract(const Duration(days: 6)),
        returnDate: now.subtract(const Duration(days: 6)),
        assessedFine: 0.0,
      ),
    );
  }
}
