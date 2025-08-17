import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import '../widgets/mobile_frame.dart';

class ProjectDetailsPage extends StatefulWidget {
  final int projectId;
  final String projectTitle;
  final String token;

  const ProjectDetailsPage({
    super.key,
    required this.projectId,
    required this.projectTitle,
    required this.token,
  });

  @override
  State<ProjectDetailsPage> createState() => _ProjectDetailsPageState();
}

class _ProjectDetailsPageState extends State<ProjectDetailsPage> {
  List<dynamic> stages = [];
  List<dynamic> comments = [];
  bool loading = true;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    await fetchStages();
    await fetchComments();
  }

  Future<void> fetchStages() async {
    final url = Uri.parse(
        "https://omorals.com/php_server/project.php/project/stages?project_id=${widget.projectId}");
    final response = await http.get(url, headers: {
      "Authorization": "Bearer ${widget.token}",
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        stages = data['stages'];
        loading = false;
      });
    }
  }

  Future<void> fetchComments() async {
    final url = Uri.parse(
        "https://omorals.com/php_server/project.php/project/comments?project_id=${widget.projectId}");
    final response = await http.get(url, headers: {
      "Authorization": "Bearer ${widget.token}",
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        comments = data['comments'];
      });
    }
  }

  Future<void> addComment(int stageId) async {
    final url = Uri.parse(
        "https://omorals.com/php_server/project.php/project/comment");
    final response = await http.post(url,
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "project_id": widget.projectId,
          "stage_id": stageId,
          "content": _commentController.text
        }));

    if (response.statusCode == 200) {
      _commentController.clear();
      fetchComments(); // refresh
    }
  }

  @override
  Widget build(BuildContext context) {
    return MobileFrame(
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.projectTitle),
          automaticallyImplyLeading: true,
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Stages", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ...stages.map((s) => Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text(s['stage_name']),
                  subtitle: Text(
                      "Status: ${s['status']}\nAssignee: ${s['assignee_user_id'] ?? 'Unassigned'}\nTester: ${s['tester_user_id'] ?? 'N/A'}"),
                  trailing: Icon(
                    s['status'] == "APPROVED"
                        ? Icons.check_circle
                        : Icons.hourglass_bottom,
                    color: s['status'] == "APPROVED"
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
              )),
              const SizedBox(height: 16),
              Text("Comments",
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ...comments.map((c) => Card(
                child: ListTile(
                  title: Text(c['user_name']),
                  subtitle: Text(c['content']),
                  trailing: Text(c['created_at']),
                ),
              )),
              const SizedBox(height: 70),
            ],
          ),
        ),
        bottomSheet: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    hintText: "Add a comment...",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.red),
                onPressed: () {
                  if (_commentController.text.isNotEmpty) {
                    addComment(stages.first['stage_id']); // default: first stage
                  }
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}