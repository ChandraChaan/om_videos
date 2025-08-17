import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:om_videos/screens/user_create_page.dart';
import 'package:om_videos/screens/user_profile_page.dart';

import '../widgets/mobile_frame.dart';

/// ==== CONFIG (edit to your env) ====
/// e.g. 'http://localhost/php_server' OR 'https://omorals.com/php_server'
const String baseUrl = 'https://omorals.com/php_server';

/// If your user endpoints are protected with Bearer, set it here (or inject it).
/// Leave null if not required.
const String? bearerToken = null; // e.g. 'eyJhbGciOi...'

Map<String, String> _headers() {
  final h = <String, String>{'Content-Type': 'application/json'};
  if (bearerToken != null) h['Authorization'] = 'Bearer $bearerToken';
  return h;
}

/// Simple user model for list
class UserLite {
  final int id;
  final String name;
  final String email;
  final String role;
  final String status;
  final String? phone;

  UserLite({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    this.phone,
  });

  factory UserLite.fromJson(Map<String, dynamic> j) => UserLite(
    id: (j['id'] as num).toInt(),
    name: (j['name'] ?? '').toString(),
    email: (j['email'] ?? '').toString(),
    role: (j['role'] ?? '').toString(),
    status: (j['status'] ?? '').toString(),
    phone: j['phone']?.toString(),
  );
}

class UsersPage extends StatefulWidget {
  final String token;

  const UsersPage({super.key, required this.token});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  late Future<List<UserLite>> _future;
  String _query = '';
  Timer? _debounce;
  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<UserLite>> _load() async {
    final url = Uri.parse('$baseUrl/user.php/user/list');
    final resp = await http.get(url, headers: _headers());
    if (resp.statusCode != 200) {
      throw Exception('Users fetch failed: ${resp.statusCode}');
    }
    final map = jsonDecode(resp.body) as Map<String, dynamic>;
    final list = (map['users'] as List? ?? [])
        .map((e) => UserLite.fromJson(e as Map<String, dynamic>))
        .toList();

    // Optional local search filter
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list.where((u) {
      return u.name.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          u.role.toLowerCase().contains(q) ||
          u.status.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _refresh() async {
    // 1) Make a new future outside (optional, but clear)
    final f = _load();

    // 2) Update state synchronously with a block
    setState(() {
      _future = f;
    });

    // 3) If the caller (e.g., RefreshIndicator) wants to await completion:
    await f;
  }

  void _openUser(UserLite u) {
    // TODO: navigate to your profile screen; for now, just a snack.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfilePage(userId: u.id, displayName: u.name,),
      ),
    );

    // Navigator.pushNamed(context, UserProfilePage.route, arguments: UserProfileArgs(userId: u.id, displayName: u.name));
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(content: Text('Selected: ${u.name} (#${u.id})')),
    // );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MobileFrame(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Users'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search name / email / role',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  isDense: true,
                ),
                onChanged: (v) {
                  _query = v;
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 300), () {
                    final f = _load();
                    setState(() {
                      _future = f;
                    });
                  });
                },
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                _refresh();
              },
            ),
          ],
        ),
        body: FutureBuilder<List<UserLite>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error: ${snap.error}'),
                ),
              );
            }
            final users = snap.data ?? const <UserLite>[];
            if (users.isEmpty) {
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  children: const [
                    SizedBox(height: 160),
                    Center(child: Text('No users found')),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.separated(
                itemCount: users.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final u = users[i];
                  final initials = (u.name.isNotEmpty ? u.name[0] : '?').toUpperCase();
                  return ListTile(
                    leading: CircleAvatar(child: Text(initials)),
                    title: Text(u.name),
                    subtitle: Text('${u.email} • ${u.role} • ${u.status}${u.phone != null && u.phone!.isNotEmpty ? ' • ${u.phone}' : ''}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openUser(u),
                  );
                },
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            // TODO: push your Create User page
            // Navigator.pushNamed(context, UserCreatePage.route);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UserCreatePage(token:widget.token),
              ),
            );
            // ScaffoldMessenger.of(context).showSnackBar(
            //   const SnackBar(content: Text('Create User tapped')),
            // );
          },
          icon: const Icon(Icons.person_add),
          label: const Text('Create'),
        ),
      ),
    );
  }
}