# University Library System - MVVM in Flutter

**Lab 06 - Visual Programming (Semester 3)**  
**Student:** Andi Arjuna Putra  
**Repository:** [-Lab-06-University-Library-System-MVVM-in-Flutter-Andi-Arjuna-Putra](https://github.com/Junnzxy/-Lab-06-University-Library-System-MVVM-in-Flutter-Andi-Arjuna-Putra)

---

## Project Overview

The **University Library System** is a Flutter application engineered with the **Model-View-ViewModel (MVVM)** architectural pattern. It models university library operations including book catalog browsing, borrowing and returning workflows, dynamic date simulation, and automated fine calculation with overdue and missing status management.

---

## Check Yourself: Concept & Architecture Questions

### 1. What is the difference between the Model, View, and ViewModel in this application?
The **Model** (`Book`, `Loan`) encapsulates the raw data entities and properties; the **View** (`LibraryScreen`, `BookCard`, `LoanCard`, etc.) purely handles UI rendering and user interactions; and the **ViewModel** (`LibraryViewModel`) acts as the state and business logic controller that processes loans, computes fines, and notifies listeners via `ChangeNotifier`.

### 2. What should happen if a student attempts to borrow a book that already has an active loan?
The application rejects the borrow request, prevents duplicate loan creation, and returns a failure result with an informative message stating that the book is currently borrowed and unavailable.

### 3. Why is it better to calculate the fine in one place rather than repeating the formula in multiple widgets?
Centralizing the fine calculation inside a single ViewModel method (`calculateFine()`) adheres to the DRY (*Don't Repeat Yourself*) principle, preventing calculation inconsistencies across UI cards and allowing business rule changes to take effect everywhere immediately.

### 4. What is the difference between a book being Overdue and being Missing?
An **Overdue** book has exceeded its due date by up to 6 months and incurs standard weekly late fines (Rp5,000 per started week), whereas a **Missing** book has been overdue for more than 6 months and incurs the accumulated late fine plus the book's full replacement cost.

### 5. If the university changes its weekly fine from Rp5,000 to Rp7,000, how should the app be updated?
You only need to update the `weeklyFineRate` property in `LibraryViewModel` (e.g., updating its default value to `7000.0` or assigning it dynamically), and all fine computations across the application will automatically update without modifying any UI widget code.

---

## Architecture & Folder Structure

```text
lib/
├── main.dart                          # Application entry point & Provider wiring
├── models/
│   ├── book.dart                      # Book entity (id, title, author, isbn, replacementPrice, isAvailable)
│   └── loan.dart                      # Loan entity (id, bookId, studentId, borrowDate, dueDate, returnDate)
├── viewmodels/
│   └── library_view_model.dart        # Business logic, state management, fine engine (ChangeNotifier)
└── views/
    ├── library_screen.dart            # Main scaffold with TabBar (Books, Active Loans, History)
    └── widgets/
        ├── book_card.dart             # Book item presentation & borrow trigger
        ├── borrow_dialog.dart         # Student ID & borrow duration input modal
        ├── date_simulator_bar.dart    # Interactive time travel bar (+1 day, +1 week, +1 month, +6 months)
        ├── empty_state.dart           # Reusable empty state view
        ├── fine_summary_card.dart     # Overview card showing active overdue and missing books
        └── loan_card.dart             # Active/returned loan item presentation & return action
```

---

## Business Rules Implemented

1. **Standard Loan Duration:** Default loan duration is **6 days** (due on day 7).
2. **On-Time Returns:** Returning a book on or before the due date incurs **Rp0** fine.
3. **Overdue Penalty:** Starts on day 1 after the due date at **Rp5,000 per started week**.
4. **Missing Policy:** If a book is unreturned for more than **6 calendar months** past its due date, its status becomes **Missing**, charging the accumulated overdue fine **plus the book's replacement price**.
5. **Interactive Date Simulation:** Allows testing time-dependent overdue transitions and fine accrual interactively within the UI.

---

## Testing & Verification

Automated test suite covers all requirements:
- `test/library_view_model_test.dart` (9 comprehensive unit tests verifying MVVM business logic, loan states, fine calculation, missing thresholds, and dynamic fine rates).
- `test/widget_test.dart` (UI widget & interaction test suite).

Run tests locally:
```bash
flutter analyze
flutter test
```
