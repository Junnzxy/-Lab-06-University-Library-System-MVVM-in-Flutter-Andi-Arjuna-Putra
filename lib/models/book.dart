class Book {
  final String id;
  final String title;
  final String author;
  final double replacementPrice;
  bool isAvailable;
  final String? category;
  final String? isbn;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.replacementPrice,
    this.isAvailable = true,
    this.category,
    this.isbn,
  });

  Book copyWith({
    String? id,
    String? title,
    String? author,
    double? replacementPrice,
    bool? isAvailable,
    String? category,
    String? isbn,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      replacementPrice: replacementPrice ?? this.replacementPrice,
      isAvailable: isAvailable ?? this.isAvailable,
      category: category ?? this.category,
      isbn: isbn ?? this.isbn,
    );
  }
}
