import 'package:apilize/main.dart';
import 'package:apilize/pages/create_api_page.dart';
import 'package:flutter/material.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Stats Grid
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 16.0,
              children: [
                _buildStatCard('Total Requests', '1,234', Colors.blue),
                _buildStatCard('Success Rate', '98%', Colors.green),
                _buildStatCard('Avg Response', '245ms', Colors.orange),
              ],
            ),

            const SizedBox(height: 20),

            OutlinedButton(
              child: ListTile(
                leading: const Icon(Icons.send_rounded),
                title: Text("Test APIs"),
                subtitle: Text("Tests your apis here!"),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => APITesterHome()),
              ),
            ),
            SizedBox(height: 15),
            OutlinedButton(
              child: ListTile(
                leading: const Icon(Icons.send_rounded),
                title: Text("Write APIs"),
                subtitle: Text("New APIs!"),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CreateAPIPage()),
              ),
            ),
            Expanded(
              child: Card(
                child: ListView.builder(
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: const Icon(Icons.access_time),
                      title: Text('API Call ${index + 1}'),
                      subtitle: Text('Endpoint: /api/data/${index + 1}'),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
