import 'package:apilook/auth/auth_controller.dart';
import 'package:apilook/dashboard.dart';
import 'package:apilook/models/request_model.dart';
import 'package:apilook/pages/profile_page.dart';
import 'package:apilook/pages/requests_page.dart';
import 'package:apilook/pages/settings_page.dart';
import 'package:apilook/providers/theme_provider.dart';
import 'package:apilook/services/supabase_service.dart';
import 'package:apilook/views/login_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

// Add custom color scheme
class AppColors {
  static const primary = Color.fromARGB(255, 255, 255, 255); // Vibrant purple
  static const secondary = Color(0xFF00BFA6); // Turquoise
  static const accent = Color(0xFFFF6584); // Coral pink
  static const background = Color.fromARGB(255, 0, 0, 0); // Dark navy
  static const surface = Color(0xFF252849); // Lighter navy
  static const text = Color(0xFFF8F9FA); // Off white
  static const textSecondary = Color(0xFFB8B9CB); // Muted lavender
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final supabaseService = SupabaseService(
    supabaseUrl: "https://cpowvsbphxtlkfxgmrjn.supabase.co",
    supabaseKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNwb3d2c2JwaHh0bGtmeGdtcmpuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzk2MDk3NTAsImV4cCI6MjA1NTE4NTc1MH0.JCT8q8wCudvenI_vk_wOP6ocEknTpRU0i5DqqTVX9lQ",
  );
  await supabaseService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthController(supabaseService),
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          theme: ThemeData(
            useMaterial3: false,
            scaffoldBackgroundColor: const Color.fromARGB(255, 0, 0, 0),
            colorScheme: const ColorScheme(
              brightness: Brightness.dark,
              primary: Color.fromARGB(255, 255, 255, 255),
              secondary: AppColors.secondary,
              surface: Color.fromARGB(255, 0, 0, 0),
              error: Color(0xFFFF4848),
              onPrimary: AppColors.text,
              onSecondary: AppColors.text,
              onSurface: AppColors.text,
              onError: AppColors.text,
            ),
            appBarTheme: const AppBarTheme(
              elevation: 0,
              backgroundColor: AppColors.surface,
              iconTheme: IconThemeData(color: AppColors.text),
              titleTextStyle: TextStyle(
                  color: AppColors.text,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: AppColors.text),
              bodyMedium: TextStyle(color: AppColors.textSecondary),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.text,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            cardTheme: CardTheme(
              color: AppColors.surface,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: AppColors.surface.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: AppColors.primary.withOpacity(0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: AppColors.primary.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.secondary),
              ),
            ),
            tabBarTheme: TabBarTheme(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorSize: TabBarIndicatorSize.label,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppColors.secondary.withOpacity(0.2),
              ),
            ),
            dialogTheme: DialogTheme(
              backgroundColor: AppColors.surface,
              elevation: 16,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          home: const APITesterHome(),
        );
      },
    );
  }
}

class apilook extends StatelessWidget {
  const apilook({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return MaterialApp(
      title: 'Apilook',
      home: true || auth.isAuthenticated ? const APITesterHome() : LoginView(),
    );
  }
}

class APITesterHome extends StatefulWidget {
  const APITesterHome({super.key});

  @override
  State<APITesterHome> createState() => _APITesterHomeState();
}

class _APITesterHomeState extends State<APITesterHome>
    with TickerProviderStateMixin {
  // Add this to your state class
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const Dashboard(),
    const RequestPage(),
    const SettingsPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.background,
              AppColors.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom app bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.api,
                        color: const Color.fromARGB(255, 255, 114, 143)),
                    const SizedBox(width: 12),
                    Text(
                      'Apilook',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _pages[_selectedIndex]),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                  0, Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
              _buildNavItem(1, Icons.compare_arrows_outlined,
                  Icons.compare_arrows, 'Requests'),
              _buildNavItem(
                  2, Icons.settings_outlined, Icons.settings, 'Settings'),
              _buildNavItem(3, Icons.person_outline, Icons.person, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      int index, IconData icon, IconData selectedIcon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
