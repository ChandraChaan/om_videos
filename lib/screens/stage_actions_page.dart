import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// ===== CONFIG =====
/// e.g. 'http://localhost/php_server' OR 'https://omorals.com/php_server'
const String baseUrl = 'https://omorals.com/php_server';

/// Your header token (you showed this exact raw header in cURL).
/// If your project.php expects Bearer, change the line in _headers() below.


class StageActionsPage extends StatefulWidget {
  final String token;
  final int projectId;
  final int stageId;

  const StageActionsPage({super.key, required this.token, required this.projectId, required this.stageId});

  @override
  State<StageActionsPage> createState() => _StageActionsPageState();
}

class _StageActionsPageState extends State<StageActionsPage>
    with SingleTickerProviderStateMixin {
  final _projectIdCtrl = TextEditingController();
  final _feedbackCtrl = TextEditingController();

  int? _selectedUserId;

  bool _loadingStages = false;
  bool _loadingUsers = false;
  bool _submitting = false;

  List<_UserLite> _users = [];

  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadUsers();
  }

  @override
  void dispose() {
    _tab.dispose();
    _projectIdCtrl.dispose();
    _feedbackCtrl.dispose();
    super.dispose();
  }

  Map<String, String> _headers({bool json = true}) {
    final h = <String, String>{};
    if (json) h['Content-Type'] = 'application/json';
    // You showed raw Authorization header in cURL. Keep it the same:
    h['Authorization'] = widget.token;

    // If your project.php requires Bearer instead, use this instead:
    // h['Authorization'] = 'Bearer $projectToken';

    return h;
  }

  Future<void> _loadUsers() async {
    setState(() => _loadingUsers = true);
    try {
      final url = Uri.parse('$baseUrl/user.php/user/list');
      final resp = await http.get(url, headers: _headers(json: false));
      if (resp.statusCode != 200) throw 'Users fetch failed ${resp.statusCode}';
      final map = jsonDecode(resp.body) as Map<String, dynamic>;
      final lst = (map['users'] as List? ?? [])
          .map((e) => _UserLite.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() => _users = lst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Users error: $e')));
    } finally {
      if (mounted) setState(() => _loadingUsers = false);
    }
  }


  Future<void> _assign() async {
    print("[ASSIGN] Start assigning user to stage...");
    if (_selectedUserId == null) {
      print("[ASSIGN] No user selected!");
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please select a User')));
      return;
    }

    setState(() {
      print("[ASSIGN] Setting submitting=true");
      _submitting = true;
    });

    try {
      final url = Uri.parse('$baseUrl/project.php/project/assign');
      print("[ASSIGN] URL => $url");
      final bodyData = {
        'project_id': widget.projectId,
        'stage_id': widget.stageId,
        'user_id': _selectedUserId,
      };
      print("[ASSIGN] Request body => $bodyData");

      final resp = await http.post(
        url,
        headers: _headers(),
        body: jsonEncode(bodyData),
      );

      print("[ASSIGN] Status Code => ${resp.statusCode}");
      print("[ASSIGN] Response Body => ${resp.body}");

      if (resp.statusCode != 200) {
        String msg = 'Assign failed (${resp.statusCode})';
        try {
          final m = jsonDecode(resp.body);
          if (m is Map && m['error'] != null) msg = m['error'].toString();
        } catch (e) {
          print("[ASSIGN] JSON decode failed: $e");
        }
        throw msg;
      }

      if (!mounted) {
        print("[ASSIGN] Widget not mounted, stopping.");
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Assigned successfully')));
      print("[ASSIGN] Success ✅");
    } catch (e) {
      print("[ASSIGN] Exception => $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          print("[ASSIGN] Reset submitting=false");
          _submitting = false;
        });
      }
    }
  }

  Future<void> _approveReject(String decision) async {
    print("[APPROVE/REJECT] Start decision=$decision");
    setState(() {
      print("[APPROVE/REJECT] Setting submitting=true");
      _submitting = true;
    });

    try {
      final url = Uri.parse('$baseUrl/project.php/project/approve');
      print("[APPROVE/REJECT] URL => $url");

      final bodyData = {
        'project_id': widget.projectId,
        'stage_id': widget.stageId,
        'decision': decision,
        'feedback': _feedbackCtrl.text.trim().isEmpty
            ? null
            : _feedbackCtrl.text.trim(),
      };
      print("[APPROVE/REJECT] Request body => $bodyData");

      final resp = await http.post(
        url,
        headers: _headers(),
        body: jsonEncode(bodyData),
      );

      print("[APPROVE/REJECT] Status Code => ${resp.statusCode}");
      print("[APPROVE/REJECT] Response Body => ${resp.body}");

      if (resp.statusCode != 200) {
        String msg = 'Update failed (${resp.statusCode})';
        try {
          final m = jsonDecode(resp.body);
          if (m is Map && m['error'] != null) msg = m['error'].toString();
        } catch (e) {
          print("[APPROVE/REJECT] JSON decode failed: $e");
        }
        throw msg;
      }

      if (!mounted) {
        print("[APPROVE/REJECT] Widget not mounted, stopping.");
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(decision == 'APPROVED'
            ? 'Stage approved'
            : 'Stage rejected'),
      ));
      print("[APPROVE/REJECT] Success ✅ decision=$decision");
    } catch (e) {
      print("[APPROVE/REJECT] Exception => $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          print("[APPROVE/REJECT] Reset submitting=false");
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _loadingStages || _loadingUsers || _submitting;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stage Actions'),
        bottom: TabBar(
            controller: _tab,
            tabs: const [
          Tab(text: 'Assign'),
          Tab(text: 'Approve/Reject'),
        ]),
      ),
      body: AbsorbPointer(
        absorbing: busy,
        child: TabBarView(
          controller: _tab,
          children: [
            _buildAssignTab(),
            _buildApproveTab(),
          ],
        ),
      ),
      floatingActionButton: busy
          ? const FloatingActionButton(
        onPressed: null,
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      )
          : null,
    );
  }


  Widget _userPicker() {
    return DropdownButtonFormField<int>(
      value: _selectedUserId,
      items: _users
          .map((u) => DropdownMenuItem<int>(
        value: u.id,
        child: Text('${u.name} • ${u.role} • ${u.status}'),
      ))
          .toList(),
      onChanged: (v) => setState(() => _selectedUserId = v),
      decoration: const InputDecoration(labelText: 'Assign to User'),
    );
  }

  Widget _buildAssignTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // _projectAndStagePicker(),
        const SizedBox(height: 12),
        _loadingUsers
            ? const Center(child: Padding(
            padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
            : _userPicker(),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _submitting ? null : _assign,
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('Assign'),
        ),
      ],
    );
  }

  Widget _buildApproveTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // _projectAndStagePicker(),
        const SizedBox(height: 12),
        TextField(
          controller: _feedbackCtrl,
          decoration: const InputDecoration(
            labelText: 'Feedback (optional)',
            hintText: 'Looks good / Fix intro...',
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _submitting ? null : () => _approveReject('APPROVED'),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Approve'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _submitting ? null : () => _approveReject('REJECTED'),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Reject'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// ===== Models =====

class _UserLite {
  final int id;
  final String name;
  final String role;
  final String status;

  _UserLite({
    required this.id,
    required this.name,
    required this.role,
    required this.status,
  });

  factory _UserLite.fromJson(Map<String, dynamic> j) => _UserLite(
    id: (j['id'] as num).toInt(),
    name: (j['name'] ?? '').toString(),
    role: (j['role'] ?? '').toString(),
    status: (j['status'] ?? '').toString(),
  );
}