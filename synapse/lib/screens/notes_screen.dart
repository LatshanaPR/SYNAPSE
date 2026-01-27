import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notes_service.dart';
import '../theme/app_theme.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = FirebaseAuth.instance.currentUser;

    // Check if user is authenticated
    if (currentUser == null) {
      return Scaffold(
        backgroundColor: isDark ? AppTheme.black : Colors.white,
        appBar: AppBar(
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          title: const Text('My Notes'),
        ),
        body: Center(
          child: Text(
            'Please sign in to view notes',
            style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        title: const Text('My Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
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
                  Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading notes: ${snapshot.error}',
                    style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.netflixRed));
          }

          final notes = snapshot.data?.docs ?? [];
          if (notes.isEmpty) {
            return Center(
              child: Text(
                'No notes yet. Tap + to create one.',
                style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
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
                    color: isDark ? Colors.grey[900] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: isActuallyLocked
                        ? Border.all(color: AppTheme.netflixRed.withOpacity(0.5), width: 2)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
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
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isActuallyLocked)
                            Icon(
                              Icons.lock,
                              size: 18,
                              color: AppTheme.netflixRed,
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
                                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tap to unlock',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Text(
                                content,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                                maxLines: 5,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                      if (updatedAt != null || createdAt != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _formatDate(updatedAt ?? createdAt!),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[500] : Colors.grey[500],
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
        backgroundColor: AppTheme.netflixRed,
        child: const Icon(Icons.add, color: Colors.white),
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
