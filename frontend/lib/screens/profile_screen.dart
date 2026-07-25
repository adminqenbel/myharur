import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../api_client.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchProfile();
  }

  Future<Map<String, dynamic>> _fetchProfile() async {
    final response = await ApiClient.dio.get('/users/me');
    return response.data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _profileFuture = _fetchProfile();
              });
            },
          )
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            // Usually indicates Guest Mode (401 Unauthorized)
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Guest User', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Please log in to view your profile.', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Go to Login'),
                  )
                ],
              ),
            );
          }

          final user = snapshot.data;
          if (user == null) {
            return const Center(child: Text('User data is null.'));
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (user['profile'] != null && user['profile']['avatar_url'] != null)
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(user['profile']['avatar_url']),
                  )
                else
                  const CircleAvatar(
                    radius: 50,
                    child: Icon(Icons.person, size: 50),
                  ),
                const SizedBox(height: 20),
                Text(
                  '${user['profile']?['first_name'] ?? ''} ${user['profile']?['last_name'] ?? ''}'.trim().isNotEmpty 
                    ? '${user['profile']['first_name']} ${user['profile']['last_name']}'
                    : 'Unknown User',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(user['email'] ?? '', style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user['role']?['name'] ?? 'User',
                    style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 40),
                OutlinedButton(
                  onPressed: () {
                    ApiClient.dio.options.headers.remove('Authorization');
                    context.go('/login');
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Logout'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
