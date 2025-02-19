import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isDarkMode = false;
  String _selectedJSEngine = 'QuickJS';
  bool _enableNativeAssets = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('darkMode') ?? false;
      _selectedJSEngine = prefs.getString('jsEngine') ?? 'QuickJS';
      _enableNativeAssets = prefs.getBool('nativeAssets') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _isDarkMode);
    await prefs.setString('jsEngine', _selectedJSEngine);
    await prefs.setBool('nativeAssets', _enableNativeAssets);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            children: [
              SwitchListTile(
                title: const Text('Dark Mode'),
                value: themeProvider.isDarkMode,
                onChanged: (bool value) {
                  themeProvider.toggleTheme();
                },
              ),
              const SizedBox(height: 16),
              _buildSection(
                'JavaScript Engine',
                [
                  DropdownButtonFormField<String>(
                    value: _selectedJSEngine,
                    decoration: const InputDecoration(
                      labelText: 'Select JS Engine',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    items: ['QuickJS', 'V8', 'JavaScriptCore']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedJSEngine = value;
                          _saveSettings();
                        });
                      }
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Enable Native Assets'),
                    subtitle: const Text('Requires restart'),
                    value: _enableNativeAssets,
                    onChanged: (value) {
                      setState(() {
                        _enableNativeAssets = value;
                        _saveSettings();
                      });
                    },
                  ),
                ],
              ),
              _buildSection(
                'API Configuration',
                [
                  ListTile(
                    title: const Text('Clear API Cache'),
                    trailing: const Icon(Icons.cleaning_services),
                    onTap: () {
                      // TODO: Implement cache clearing
                    },
                  ),
                  ListTile(
                    title: const Text('Export Settings'),
                    trailing: const Icon(Icons.upload),
                    onTap: () {
                      // TODO: Implement settings export
                    },
                  ),
                ],
              ),
              _buildSection(
                'Account',
                [
                  ListTile(
                    title: const Text('Sign Out'),
                    trailing: const Icon(Icons.logout),
                    onTap: () {
                      // TODO: Implement sign out
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        ...children,
        const Divider(),
      ],
    );
  }
}
