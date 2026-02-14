import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/task_service.dart';
import '../theme/app_theme.dart';
import 'edit_task_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TaskService _taskService = TaskService();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Filter tasks by title (case-insensitive)
  bool _matchesQuery(Map<String, dynamic> data, String query) {
    if (query.isEmpty) return false;
    final title = ((data['title'] as String?) ?? '').toLowerCase();
    final desc = ((data['description'] as String?) ?? '').toLowerCase();
    return title.contains(query) || desc.contains(query);
  }

  /// Extract common keywords from task titles for suggestions
  List<String> _extractKeywords(List<QueryDocumentSnapshot> docs) {
    final wordCount = <String, int>{};
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['isDeleted'] == true) continue;
      final title = (data['title'] as String?) ?? '';
      for (var word in title.toLowerCase().split(RegExp(r'\s+'))) {
        if (word.length > 3) {
          wordCount[word] = (wordCount[word] ?? 0) + 1;
        }
      }
    }
    final sorted = wordCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(6).map((e) => e.key).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Search',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onBackground,
                ),
              ),
              const SizedBox(height: 20),
              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Search tasks...',
                    hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                    prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _query = value.trim().toLowerCase();
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),
              // Suggestions / Results from Firestore
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _taskService.getTasks(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Couldn\'t load tasks.',
                          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
                        ),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.netflixRed),
                        ),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];

                    // Show suggestions when query is empty
                    if (_query.isEmpty) {
                      final keywords = _extractKeywords(docs);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.lightbulb_outline, size: 18, color: colorScheme.onSurfaceVariant),
                              const SizedBox(width: 8),
                              Text(
                                'Suggestions',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (keywords.isEmpty)
                            Text(
                              'No suggestions yet',
                              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
                            )
                          else
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: keywords.map((keyword) {
                                return GestureDetector(
                                  onTap: () {
                                    _searchController.text = keyword;
                                    setState(() {
                                      _query = keyword.toLowerCase();
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surface,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: colorScheme.outline, width: 1),
                                    ),
                                    child: Text(
                                      keyword,
                                      style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      );
                    }

                    // Filter tasks by query
                    final filtered = docs.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      if (data['isDeleted'] == true) return false;
                      return _matchesQuery(data, _query);
                    }).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Text(
                          'No tasks match "$_query"',
                          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final doc = filtered[i];
                        final data = doc.data() as Map<String, dynamic>;
                        final title = data['title'] as String? ?? 'Untitled';
                        final status = data['status'] as String? ?? 'ToDo';
                        final dt = (data['dateTime'] as Timestamp?)?.toDate();
                        String dateStr = 'No date';
                        if (dt != null) {
                          dateStr = DateFormat('dd MMM yyyy, HH:mm').format(dt);
                        }
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (ctx) => EditTaskScreen(
                                  taskId: doc.id,
                                  taskData: data,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.shadow.withOpacity(0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.onSurface,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        dateStr,
                                        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        status == 'notDone' ? 'Not Done' : status,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: status == 'notDone'
                                              ? AppTheme.netflixRed
                                              : colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
