import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../widgets/mobile_frame.dart';

/// ==== CONFIG (edit to your env) ====
/// Keep these in sync with users_page.dart
const String baseUrl = 'https://omorals.com/php_server';

/// If your endpoints require Bearer auth, set it here.
/// Leave null if not required.
const String? bearerToken = null; // e.g. 'eyJhbGciOi...'

Map<String, String> _headers() {
  final h = <String, String>{'Content-Type': 'application/json'};
  if (bearerToken != null) h['Authorization'] = 'Bearer $bearerToken';
  return h;
}

/// ===== Simple models =====
class ProjectInvolvement {
  final int? projectId;
  final String? title;
  final String? stageName;
  final String? status;
  final String? role; // 'assignee' | 'tester' | 'other'

  ProjectInvolvement({this.projectId, this.title, this.stageName, this.status, this.role});

  factory ProjectInvolvement.fromJson(Map<String, dynamic> j) => ProjectInvolvement(
    projectId: j['project_id'] is num ? (j['project_id'] as num).toInt() : null,
    title: j['title']?.toString(),
    stageName: j['stage_name']?.toString(),
    status: j['status']?.toString(),
    role: j['role']?.toString(),
  );
}

class UserProfilePage extends StatefulWidget {
  final int userId;
  final String? displayName;

  const UserProfilePage({super.key, required this.userId, this.displayName});

  /// Helper for imperative navigation (from UsersPage onTap)
  static Route routeTo({required int userId, String? displayName}) {
    return MaterialPageRoute(
      builder: (_) => UserProfilePage(userId: userId, displayName: displayName),
    );
  }

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late Future<Map<String, dynamic>?> _userFut;
  late Future<List<ProjectInvolvement>> _projectsFut;

  @override
  void initState() {
    super.initState();
    _userFut = _fetchUser(widget.userId);
    _projectsFut = _fetchProjects(widget.userId);
  }

  Future<Map<String, dynamic>?> _fetchUser(int id) async {
    final url = Uri.parse('$baseUrl/user.php/user/get?id=$id');
    final resp = await http.get(url, headers: _headers());
    if (resp.statusCode == 404) return null;
    if (resp.statusCode != 200) {
      throw Exception('User fetch failed: ${resp.statusCode}');
    }
    final map = jsonDecode(resp.body) as Map<String, dynamic>;
    return map['user'] as Map<String, dynamic>?;
  }

  Future<List<ProjectInvolvement>> _fetchProjects(int id) async {
    final url = Uri.parse('$baseUrl/user.php/user/projects?user_id=$id');
    final resp = await http.get(url, headers: _headers());
    if (resp.statusCode == 404) return <ProjectInvolvement>[];
    if (resp.statusCode != 200) {
      // If endpoint not present yet, just show empty list instead of erroring the whole page
      return <ProjectInvolvement>[];
    }
    final map = jsonDecode(resp.body) as Map<String, dynamic>;
    final list = (map['projects'] as List? ?? []);
    return list.map((e) => ProjectInvolvement.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> _refresh() async {
    setState(() {
      _userFut = _fetchUser(widget.userId);
      _projectsFut = _fetchProjects(widget.userId);
    });
    await Future.wait([_userFut, _projectsFut]);
  }

  @override
  Widget build(BuildContext context) {
    final headerName = widget.displayName ?? 'Profile';
    return MobileFrame(
      child: Scaffold(
        appBar: AppBar(title: Text('Profile • $headerName')),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              FutureBuilder<Map<String, dynamic>?>(
                future: _userFut,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const _SkeletonUserCard();
                  }
                  if (snap.hasError) {
                    return _ErrorBox('User load error: ${snap.error}');
                  }
                  final u = snap.data;
                  if (u == null) {
                    return const _ErrorBox('User not found');
                  }
                  final name = (u['name'] ?? '').toString();
                  final email = (u['email'] ?? '').toString();
                  final role = (u['role'] ?? '').toString();
                  final status = (u['status'] ?? '').toString();
                  final phone = (u['phone'] ?? '').toString();
                  final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(radius: 28, child: Text(initials)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 4),
                                Text(email),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: -6,
                                  children: [
                                    _Chip('Role: $role', Icons.badge_outlined),
                                    _Chip('Status: $status', Icons.verified_user_outlined),
                                    if (phone.isNotEmpty) _Chip('Phone: $phone', Icons.phone_outlined),
                                    _Chip('ID: ${widget.userId}', Icons.tag),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Text('Projects involved', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              FutureBuilder<List<ProjectInvolvement>>(
                future: _projectsFut,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const _SkeletonProjects();
                  }
                  if (snap.hasError) {
                    return _ErrorBox('Projects load error: ${snap.error}');
                  }
                  final items = snap.data ?? const <ProjectInvolvement>[];
                  if (items.isEmpty) {
                    return const Text('No project involvement found.');
                  }
                  return Column(
                    children: items.map((p) {
                      final title = p.title?.isNotEmpty == true
                          ? p.title!
                          : 'Project #${p.projectId ?? '-'}';
                      final subtitle =
                          'Stage: ${p.stageName ?? '-'} • Status: ${p.status ?? '-'} • As: ${p.role ?? '-'}';
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.work_outline),
                          title: Text(title),
                          subtitle: Text(subtitle),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ===== Little UI helpers =====

class _Chip extends StatelessWidget {
  final String text;
  final IconData icon;
  const _Chip(this.text, this.icon);

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(text),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox(this.message);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          message,
          style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
        ),
      ),
    );
  }
}

class _SkeletonUserCard extends StatelessWidget {
  const _SkeletonUserCard();
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Text('…')),
        title: _bar(context),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _bar(context, w: 180),
            const SizedBox(height: 8),
            _bar(context, w: 120),
          ],
        ),
      ),
    );
  }

  Widget _bar(BuildContext context, {double w = 220, double h = 14}) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(.5),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

class _SkeletonProjects extends StatelessWidget {
  const _SkeletonProjects();
  @override
  Widget build(BuildContext context) {
    return Column(children: List.generate(3, (i) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.work_outline),
          title: _bar(context, w: 200),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: _bar(context, w: 160, h: 12),
          ),
        ),
      );
    }));
  }

  Widget _bar(BuildContext context, {double w = 220, double h = 14}) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(.5),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}