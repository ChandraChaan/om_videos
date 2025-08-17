import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../widgets/mobile_frame.dart';
import 'create_project_page.dart';
import 'project_details_page.dart';

class DashboardScreen extends StatefulWidget {
  final String token; // pass from login

  DashboardScreen({required this.token});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<List<dynamic>> _projectsFuture;

  @override
  void initState() {
    super.initState();
    _projectsFuture = ApiService.getProjects(widget.token);
  }

  refresh() {
    setState(() {
      _projectsFuture = ApiService.getProjects(widget.token);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MobileFrame(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Dashboard"),
          automaticallyImplyLeading: false,
          backgroundColor: Colors.red,
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                refresh();
              },
            ),
          ],
        ),
        body: FutureBuilder<List<dynamic>>(
          future: _projectsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text("No projects found"));
            }

            final projects = snapshot.data!;

            return ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final project = projects[index];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProjectDetailsPage(
                          token: widget.token,
                          projectTitle: project["title"],
                          projectId: project["id"],
                          projectStage: project["current_stage"],
                        ),
                      ),
                    );
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    margin: EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project["title"] ?? "Untitled",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text("Deadline: ${project['deadline'] ?? 'N/A'}"),
                          SizedBox(height: 8),
                          Text("Stage: ${project['current_stage'] ?? 'N/A'}"),
                          SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: (project['progress'] ?? 0) / 100,
                            backgroundColor: Colors.grey[300],
                            color: Colors.red,
                            minHeight: 8,
                          ),
                          SizedBox(height: 6),
                          Text("${project['progress'] ?? 0}% completed"),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreateProjectPage(token: widget.token),
              ),
            );
          },
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}
