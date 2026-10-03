import 'package:flutter/material.dart';

class AnnouncementPage extends StatelessWidget {
  const AnnouncementPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Announcement $id')),
      body: Center(child: Text('Announcement ID: $id')),
    );
  }
}