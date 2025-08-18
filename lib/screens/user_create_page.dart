import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:om_videos/screens/user_profile_page.dart';

import '../utils/token_storage.dart';
import '../widgets/mobile_frame.dart';

/// ==== CONFIG (match users/profile screens) ====
/// e.g. 'http://localhost/php_server' OR 'https://omorals.com/php_server'
const String baseUrl = 'https://omorals.com/php_server';


class UserCreatePage extends StatefulWidget {
  final String token;

  const UserCreatePage({super.key, required this.token});

  @override
  State<UserCreatePage> createState() => _UserCreatePageState();
}

class _UserCreatePageState extends State<UserCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  // Your backend expects lowercase roles (based on earlier APIs)
  final List<Map<String, String>> _roles = const [
    {'v': 'voice',  't': 'Voice Artist'},
    {'v': 'writer', 't': 'Writer'},
    {'v': 'editor', 't': 'Editor'},
    {'v': 'social', 't': 'Social Media Manager'},
    {'v': 'tester', 't': 'Tester'},
    {'v': 'hr', 't': 'HR'},

  ];
  String _role = 'voice';

  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final url = Uri.parse('$baseUrl/register.php');
      final resp = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': widget.token,
        },
        body: jsonEncode({
          'name': _name.text.trim(),
          'email': _email.text.trim(),
          'password': _password.text,
          'role': _role, // send lowercase role value
        }),
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User created')),
        );
        // Pop with true so caller can refresh list
        Navigator.pop(context, true);
      } else {
        // Try to surface backend error message if present
        String msg = 'Create failed (${resp.statusCode})';
        try {
          final m = jsonDecode(resp.body);
          if (m is Map && m['error'] != null) {
            msg = m['error'].toString();
          }
        } catch (_) {}
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final btnChild = _submitting
        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
        : const Icon(Icons.check);

    return MobileFrame(
      child: Scaffold(
        appBar: AppBar(title: const Text('Create User')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Name'),
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.isEmpty) return 'Required';
                    final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(t);
                    return ok ? null : 'Invalid email';
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _role,
                  items: _roles
                      .map((r) => DropdownMenuItem(value: r['v'], child: Text(r['t']!)))
                      .toList(),
                  onChanged: _submitting ? null : (v) => setState(() => _role = v ?? 'voice'),
                  decoration: const InputDecoration(labelText: 'Role'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirm,
                  decoration: const InputDecoration(labelText: 'Confirm Password'),
                  obscureText: true,
                  validator: (v) => (v != _password.text) ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: btnChild,
                  label: const Text('Create'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}