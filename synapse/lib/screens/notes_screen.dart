import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notes_service.dart';
import '../widgets/task_password_dialog.dart';
import 'notes_trash_screen.dart';
import 'note_edit_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final NotesService _notesService = NotesService();

  Future<void> _openNote(
    BuildContext context,
    String noteId,
    String title,
    String content,
    bool isLocked,
    String? passwordHash,
  ) async {
    // Check if note is locked (has passwordHash)
    final bool isActuallyLocked = isLocked && passwordHash != null && passwordHash.isNotEmpty;
    
    if (isActuallyLocked) {
      final enteredHash = await showDialog<String>(
        context: context,
        builder: (_) => TaskPasswordDialog(taskTitle: title),
      );

      if (enteredHash == null || enteredHash != passwordHash) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Access denied. Wrong password.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NoteEditScreen(
            noteId: noteId,
            initialTitle: title,
            initialContent: content,
            initialIsLocked: isLocked,
            initialPasswordHash: passwordHash,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final currentUser = FirebaseAuth.instance.currentUser;

    // Check if user is authenticated
    if (currentUser == null) {
      return Scaffold(
        backgroundColor: colorScheme.background,
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          title: Text('My Notes', style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface)),
        ),
        body: Center(
          child: Text(
            'Please sign in to view notes',
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        title: Text('My Notes', style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface)),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: colorScheme.onSurface),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotesTrashScreen()),
              );
            },
            tooltip: 'Trash',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _notesService.getNotesStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print('[NotesScreen] Stream error: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: colorScheme.error, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading notes: ${snapshot.error}',
                    style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: colorScheme.primary));
          }

          final notes = snapshot.data?.docs ?? [];
          if (notes.isEmpty) {
            return Center(
              child: Text(
                'No notes yet. Tap + to create one.',
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final doc = notes[index];
              final data = doc.data() as Map<String, dynamic>;
              final title = data['title'] as String? ?? 'Untitled';
              final content = data['content'] as String? ?? '';
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
              final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate();
              final isLocked = data['isLocked'] == true;
              final passwordHash = data['passwordHash'] as String?;
              
              // Determine if note is actually locked (has passwordHash)
              final bool isActuallyLocked = isLocked && passwordHash != null && passwordHash.isNotEmpty;

              return GestureDetector(
                onTap: () => _openNote(
                  context,
                  doc.id,
                  title,
                  content,
                  isLocked,
                  passwordHash,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: isActuallyLocked
                        ? Border.all(color: colorScheme.primary.withOpacity(0.5), width: 2)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isActuallyLocked)
                            Icon(
                              Icons.lock,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: isActuallyLocked
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.lock_outline,
                                      size: 32,
                                      color: colorScheme.outline,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tap to unlock',
                                      style: textTheme.bodySmall?.copyWith(
                                        fontSize: 12,
                                        color: colorScheme.onSurface.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Text(
                                content,
                                style: textTheme.bodyMedium?.copyWith(
                                  fontSize: 14,
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                                maxLines: 5,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                      if (updatedAt != null || createdAt != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _formatDate(updatedAt ?? createdAt!),
                          style: textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ],
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
              builder: (_) => const NoteEditScreen(),
            ),
          );
        },
        backgroundColor: colorScheme.primary,
        child: Icon(Icons.add, color: colorScheme.onPrimary),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
