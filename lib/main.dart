import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/supabase_service.dart';
import 'providers/auth_provider.dart';
import 'providers/notes_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/notes/notes_list_screen.dart';

/// Main entry point of the application
///
/// Initializes Supabase and sets up providers before running the app
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseService.initialize();

  runApp(const MyApp());
}

/// Root widget of the application
///
/// Sets up:
/// - MultiProvider for state management
/// - Material theme
/// - Initial routing based on auth state
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth provider - manages authentication state
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // Notes provider - manages notes CRUD operations
        ChangeNotifierProvider(create: (_) => NotesProvider()),
      ],
      child: MaterialApp(
        title: 'NoteTaker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        home: const AuthGate(),
      ),
    );
  }
}

/// Auth gate that decides which screen to show based on auth state
///
/// - If user is authenticated -> NotesListScreen
/// - If user is not authenticated -> LoginScreen
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Check if user is authenticated
        if (authProvider.isAuthenticated) {
          return const NotesListScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
