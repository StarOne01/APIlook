import 'package:apilize/auth/auth_controller.dart';
import 'package:apilize/dashboard.dart';
import 'package:apilize/models/request_model.dart';
import 'package:apilize/pages/profile_page.dart';
import 'package:apilize/pages/requests_page.dart';
import 'package:apilize/pages/settings_page.dart';
import 'package:apilize/services/supabase_service.dart';
import 'package:apilize/views/login_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

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
        // ...existing providers...
      ],
      child: const APIlize(),
    ),
  );
}

class APIlize extends StatelessWidget {
  const APIlize({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return MaterialApp(
      title: 'APIlize',
      home: auth.isAuthenticated ? const APITesterHome() : LoginView(),
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surfaceContainerHighest,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(child: _pages[_selectedIndex]),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedIndex: _selectedIndex,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.compare_arrows_outlined),
            selectedIcon: Icon(Icons.compare_arrows),
            label: 'Requests',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
