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
import 'package:provider/provider.dart';

/// Custom color scheme
class AppColors {
  static const primary = Color.fromARGB(255, 255, 255, 255);
  static const secondary = Color(0xFF00BFA6);
  static const accent = Color(0xFFFF6584);
  static const background = Color.fromARGB(255, 0, 0, 0);
  static const surface = Color(0xFF252849);
  static const text = Color(0xFFF8F9FA);
  static const textSecondary = Color(0xFFB8B9CB);
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
          title: 'Apilook',
          theme: ThemeData(
            useMaterial3: false,
            scaffoldBackgroundColor: AppColors.background,
            colorScheme: const ColorScheme(
              brightness: Brightness.dark,
              primary: Color.fromARGB(255, 255, 255, 255),
              secondary: AppColors.secondary,
              surface: AppColors.surface,
              background: AppColors.background,
              error: Color(0xFFFF4848),
              onPrimary: AppColors.text,
              onSecondary: AppColors.text,
              onSurface: AppColors.text,
              onBackground: AppColors.text,
              onError: AppColors.text,
            ),
            appBarTheme: const AppBarTheme(
              elevation: 0,
              backgroundColor: AppColors.surface,
              iconTheme: IconThemeData(color: AppColors.text),
              titleTextStyle: TextStyle(
                color: AppColors.text,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: AppColors.text),
              bodyMedium: TextStyle(color: AppColors.textSecondary),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.text,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
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

class APITesterHome extends StatefulWidget {
  const APITesterHome({super.key});
  @override
  State<APITesterHome> createState() => _APITesterHomeState();
}

class _APITesterHomeState extends State<APITesterHome>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const Dashboard(),
    const RequestPage(),
    const SettingsPage(),
    const ProfilePage(),
  ];

  void _onDestinationSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // Use LayoutBuilder to adjust for desktop vs mobile screen sizes.
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth >= 800;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Apilook'),
            centerTitle: isDesktop,
          ),
          body: isDesktop
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: _onDestinationSelected,
                      backgroundColor: AppColors.surface,
                      selectedIconTheme:
                          const IconThemeData(color: AppColors.primary),
                      unselectedIconTheme:
                          const IconThemeData(color: AppColors.textSecondary),
                      selectedLabelTextStyle:
                          const TextStyle(color: AppColors.primary),
                      unselectedLabelTextStyle:
                          const TextStyle(color: AppColors.textSecondary),
                      labelType: NavigationRailLabelType.all,
                      destinations: const [
                        NavigationRailDestination(
                          icon: Icon(Icons.dashboard_outlined),
                          selectedIcon: Icon(Icons.dashboard),
                          label: Text('Dashboard'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.compare_arrows_outlined),
                          selectedIcon: Icon(Icons.compare_arrows),
                          label: Text('Requests'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.settings_outlined),
                          selectedIcon: Icon(Icons.settings),
                          label: Text('Settings'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.person_outline),
                          selectedIcon: Icon(Icons.person),
                          label: Text('Profile'),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.background,
                              AppColors.surface,
                            ],
                          ),
                        ),
                        child: _pages[_selectedIndex],
                      ),
                    ),
                  ],
                )
              : Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.background,
                        AppColors.surface,
                      ],
                    ),
                  ),
                  child: _pages[_selectedIndex],
                ),
          bottomNavigationBar: isDesktop
              ? null
              : Container(
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
                        _buildNavItem(0, Icons.dashboard_outlined,
                            Icons.dashboard, 'Dashboard'),
                        _buildNavItem(1, Icons.compare_arrows_outlined,
                            Icons.compare_arrows, 'Requests'),
                        _buildNavItem(2, Icons.settings_outlined,
                            Icons.settings, 'Settings'),
                        _buildNavItem(
                            3, Icons.person_outline, Icons.person, 'Profile'),
                      ],
                    ),
                  ),
                ),
        );
      },
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
