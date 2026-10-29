import 'package:flutter/material.dart';
import 'viewmodels/library_view_model.dart';
import 'views/library_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final libraryViewModel = LibraryViewModel(seedDefaultData: true);

  runApp(UniversityLibraryApp(viewModel: libraryViewModel));
}

class UniversityLibraryApp extends StatelessWidget {
  final LibraryViewModel viewModel;

  const UniversityLibraryApp({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'University Library System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: LibraryScreen(viewModel: viewModel),
    );
  }
}
