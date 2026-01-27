import 'package:flutter/material.dart';
import '../services/notes_service.dart';
import '../theme/app_theme.dart';
import '../widgets/task_password_dialog.dart';

class NoteEditScreen extends StatefulWidget {
  final String? noteId;
  final String? initialTitle;
  final String? initialContent;
  final bool initialIsLocked;
  final String? initialPasswordHash;

  const NoteEditScreen({
    super.key,
    this.noteId,
    this.initialTitle,
    this.initialContent,
    this.initialIsLocked = false,
    this.initialPasswordHash,
  });

  @override
  State<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  final NotesService _notesService = NotesService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _isSaving = false;
  bool _isLocked = false;
  String? _passwordHash;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.initialTitle ?? '';
    _contentController.text = widget.initialContent ?? '';
    _isLocked = widget.initialIsLocked;
    _passwordHash = widget.initialPasswordHash;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (widget.noteId != null) {
        await _notesService.updateNote(
          noteId: widget.noteId!,
          title: title,
          content: content,
          isLocked: _isLocked,
          passwordHash: _passwordHash,
        );
      } else {
        await _notesService.createNote(
          title: title,
          content: content,
          isLocked: _isLocked,
          passwordHash: _passwordHash,
        );
      }
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note saved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteNote() async {
    if (widget.noteId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900]
            : Colors.white,
        title: Text(
          'Delete Note',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
          ),
        ),
        content: const Text('Move this note to trash?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.netflixRed)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _notesService.deleteNote(widget.noteId!);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Note moved to trash'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleLock(bool value) async {
    if (value) {
      // Show password dialog to set password
      final passwordHash = await showDialog<String>(
        context: context,
        builder: (_) => const TaskPasswordDialog(isSettingPassword: true),
      );
      if (passwordHash != null && passwordHash.length == 64) {
        setState(() {
          _isLocked = true;
          _passwordHash = passwordHash;
        });
      }
    } else {
      setState(() {
        _isLocked = false;
        _passwordHash = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        title: Text(widget.noteId != null ? 'Edit Note' : 'New Note'),
        actions: [
          if (widget.noteId != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteNote,
            ),
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _saveNote,
              child: const Text('Save', style: TextStyle(color: AppTheme.netflixRed)),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                hintText: 'Title',
                hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]),
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 16),
            // Lock toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _isLocked ? Icons.lock : Icons.lock_open,
                    color: _isLocked ? AppTheme.netflixRed : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isLocked ? 'Note is locked' : 'Lock this note',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Switch(
                    value: _isLocked,
                    onChanged: _toggleLock,
                    activeColor: AppTheme.netflixRed,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _contentController,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'Start writing...',
                  hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]),
                  border: InputBorder.none,
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
