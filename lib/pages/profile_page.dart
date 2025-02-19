import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final String _username = "User"; // Replace with actual user data
  final String _email = "user@example.com";
  final String _avatarUrl = "https://ui-avatars.com/api/?name=User";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(_username),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(_avatarUrl),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _buildProfileSection(
                icon: Icons.person,
                title: 'Account Information',
                children: [
                  _buildInfoTile('Username', _username),
                  _buildInfoTile('Email', _email),
                ],
              ),
              _buildProfileSection(
                icon: Icons.analytics,
                title: 'Statistics',
                children: [
                  _buildInfoTile('APIs Created', '5'),
                  _buildInfoTile('Total Requests', '1.2K'),
                ],
              ),
              _buildProfileSection(
                icon: Icons.settings,
                title: 'Preferences',
                children: [
                  ListTile(
                    title: const Text('Edit Profile'),
                    leading: const Icon(Icons.edit),
                    onTap: () {
                      // TODO: Implement edit profile
                    },
                  ),
                  ListTile(
                    title: const Text('Change Password'),
                    leading: const Icon(Icons.lock),
                    onTap: () {
                      // TODO: Implement password change
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Implement logout
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Logout'),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        ...children,
        const Divider(),
      ],
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return ListTile(
      title: Text(label),
      trailing: Text(
        value,
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }
}
