import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../widgets/mobile_frame.dart';

class CreateProjectPage extends StatefulWidget {
  final String token;
  const CreateProjectPage({super.key, required this.token});

  @override
  State<CreateProjectPage> createState() => _CreateProjectPageState();
}

class _CreateProjectPageState extends State<CreateProjectPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _deadlineController = TextEditingController();

  bool _loading = false;
  String? _result;

  Future<void> _createProject() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _result = null;
    });

    try {
      final response = await ApiService.createProject(
        token: widget.token,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        deadline: _deadlineController.text.trim(),
      );

      setState(() {
        _result = "✅ Success: ${response['message'] ?? response}";
      });
    } catch (e) {
      setState(() {
        _result = "❌ Error: $e";
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MobileFrame(
      child: Scaffold(
        appBar: AppBar(title: const Text("Create Project"), automaticallyImplyLeading: true,),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: "Project Title"),
                  validator: (v) =>
                  v == null || v.isEmpty ? "Title required" : null,
                ),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: "Description"),
                  validator: (v) =>
                  v == null || v.isEmpty ? "Description required" : null,
                ),
                TextFormField(
                  controller: _deadlineController,
                  decoration: const InputDecoration(labelText: "Deadline (YYYY-MM-DD)"),
                  validator: (v) =>
                  v == null || v.isEmpty ? "Deadline required" : null,
                ),
                const SizedBox(height: 20),
                _loading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _createProject,
                  child: const Text("Create Project"),
                ),
                if (_result != null) ...[
                  const SizedBox(height: 20),
                  Text(_result!,
                      style: TextStyle(
                          color: _result!.startsWith("✅")
                              ? Colors.green
                              : Colors.red)),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}