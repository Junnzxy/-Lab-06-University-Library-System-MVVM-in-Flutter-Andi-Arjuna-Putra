enum LoanStatus {
  active,
  overdue,
  missing,
  returned,
}

class Loan {
  final String id;
  final String bookId;
  final String studentId;
  final DateTime borrowDate;
  final DateTime dueDate;
  DateTime? returnDate;
  double? assessedFine;

  Loan({
    required this.id,
    required this.bookId,
    required this.studentId,
    required this.borrowDate,
    required this.dueDate,
    this.returnDate,
    this.assessedFine,
  });

  bool get isReturned => returnDate != null;

  Loan copyWith({
    String? id,
    String? bookId,
    String? studentId,
    DateTime? borrowDate,
    DateTime? dueDate,
    DateTime? returnDate,
    double? assessedFine,
  }) {
    return Loan(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      studentId: studentId ?? this.studentId,
      borrowDate: borrowDate ?? this.borrowDate,
      dueDate: dueDate ?? this.dueDate,
      returnDate: returnDate ?? this.returnDate,
      assessedFine: assessedFine ?? this.assessedFine,
    );
  }
}
