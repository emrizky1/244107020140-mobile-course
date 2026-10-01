import 'package:flutter/material.dart';

import '../data/local/note.dart';

/// Dedicated widget for a single note row.
/// Shows an "unsynced" badge when [Note.dirty] is true.
class NoteTile extends StatelessWidget {
  const NoteTile({
    super.key,
    required this.note,
    this.onTap,
    this.onDelete,
  });

  final Note note;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: note.dirty
          ? Badge(
              label: const Text('unsynced'),
              child: const Icon(Icons.cloud_off, color: Colors.orange),
            )
          : const Icon(Icons.cloud_done, color: Colors.green),
      title: Text(note.title),
      subtitle: Text(
        note.body.isEmpty ? '(no body)' : note.body,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: onDelete != null
          ? IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            )
          : null,
    );
  }
}
