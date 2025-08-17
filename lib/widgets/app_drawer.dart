import 'package:flutter/material.dart';

import '../screens/users_page.dart';

class AppDrawer extends StatelessWidget {
final String token;

  const AppDrawer({super.key, required this.token});


  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            const DrawerHeader(
              child: ListTile(
                title: Text('OMorals', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                subtitle: Text('Workflow Manager'),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.people_alt_outlined),
              title: const Text('Users'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UsersPage(token: token,),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}