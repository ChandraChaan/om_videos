import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:om_videos/screens/stage_actions_page.dart';

import '../widgets/mobile_frame.dart';

class ProjectDetailsPage extends StatefulWidget {
  final int projectId;
  final String projectTitle;
  final String projectStage;
  final String token;

  const ProjectDetailsPage({
    super.key,
    required this.projectId,
    required this.projectTitle,
    required this.projectStage,
    required this.token,
  });

  @override
  State<ProjectDetailsPage> createState() => _ProjectDetailsPageState();
}

class _ProjectDetailsPageState extends State<ProjectDetailsPage> {
  List<dynamic> stages = [];
  List<dynamic> comments = [];
  int? stageIdFinal;
  bool loading = true;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    await fetchStages();
    await getStageSequenceId(widget.projectStage);
  }

  Future<void> getStageSequenceId(String currentStageName) async {
    print("[DEBUG] Entering getStageSequenceId() with currentStage=$currentStageName");

    // Static map of stage_name → sequence (stage_id)
    final Map<String, int> stageMap = {
      "SCRIPT": 1,
      "VOICE_OVER": 2,
      "EDITING": 3,
      "UPLOAD": 4,
    };

    if (stageMap.containsKey(currentStageName)) {
      final seqId = stageMap[currentStageName];
      print("[DEBUG] Matched stage: $currentStageName → Returning stage_id=$seqId");

      setState(() {
        stageIdFinal = seqId;

      });
    }
    await fetchComments();
    print("[DEBUG] Stage not found in map! Returning null.");

  }

  Future<void> fetchStages() async {
    print("[DEBUG] Starting fetchStages() ...");

    final url = Uri.parse(
        "https://omorals.com/php_server/project.php/project/stages?project_id=${widget.projectId}");
    print("[DEBUG] Request URL: $url");

    try {
      print("[DEBUG] Sending GET request with token: ${widget.token}");
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer ${widget.token}",
        },
      );

      // print("[DEBUG] Response status: ${response.statusCode}");
      // print("[DEBUG] Raw response body: ${response.body}");

      if (response.statusCode == 200) {
        print("[DEBUG] Decoding JSON ...");
        final data = jsonDecode(response.body);

        // print("[DEBUG] Parsed JSON: $data");

        setState(() {
          stages = data['stages'] ?? [];
          loading = false;
        });

        print("[DEBUG] Stages updated in state: $stages");
        // Get the first not-approved stage id
        print("[DEBUG] Pending Stage ID to work on: $stageIdFinal");
        print("[DEBUG] Loading set to false");
      } else {
        print("[ERROR] Failed to fetch stages, status: ${response.statusCode}");
        print("[ERROR] Body: ${response.body}");
      }
    } catch (e) {
      print("[EXCEPTION] Error in fetchStages(): $e");
    }

    print("[DEBUG] fetchStages() finished");
  }

  Future<void> addComment() async {
    final url = Uri.parse(
        "https://omorals.com/php_server/project.php/project/comment");

    final bodyData = {
      "project_stage_id": stageIdFinal,
      "message": _commentController.text
    };

    print("[addComment] URL: $url");
    print("[addComment] Headers: {Authorization: Bearer ${widget.token}, Content-Type: application/json}");
    print("[addComment] Body: $bodyData");

    try {
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
        body: jsonEncode(bodyData),
      );

      print("[addComment] Status Code: ${response.statusCode}");
      print("[addComment] Response Body: ${response.body}");

      if (response.statusCode == 200) {
        print("[addComment] Comment added successfully ✅");
        _commentController.clear();
        // await fetchComments(); // refresh comments
      } else {
        print("[addComment] Failed ❌");
      }
    } catch (e) {
      print("[addComment] Exception: $e");
    }
  }

  Future<void> fetchComments() async {
    print("Fetching comments for project ${widget.projectId}, stage $stageIdFinal ...");
    final url = Uri.parse(
        "https://omorals.com/php_server/project.php/project/comments?project_id=${widget.projectId}&stage_id=$stageIdFinal");

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
      );

      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          comments = data['comments'] ?? [];
        });
      } else {
        throw Exception("Failed to fetch comments");
      }
    } catch (e) {
      print("Error fetching comments: $e");
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
              ...stages.map((s) => InkWell(
                onTap: (){
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StageActionsPage(token: widget.token, projectId: widget.projectId, stageId: s['stage_id'],),
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    title: Text(s['stage_name']),
                    subtitle: Text(
                        "Status: ${s['status']}\nAssignee: ${s['assignee_name'] ?? 'Unassigned'}\nTester: ${s['tester_name'] ?? 'N/A'}"),
                    trailing: Icon(
                      s['status'] == "APPROVED"
                          ? Icons.check_circle
                          : Icons.hourglass_bottom,
                      color: s['status'] == "APPROVED"
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                ),
              )),
              const SizedBox(height: 16),
              Text("Comments",
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ...comments.map((c) => Card(
                child: ListTile(
                  title: Text('${c['message']}'),
                  subtitle: Text(' - ${c['author_name']}'),
                  trailing: Text('${c['created_at']}'),
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
                    addComment(); // default: first stage
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