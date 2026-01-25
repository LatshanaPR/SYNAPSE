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
    return Scaffold(
      backgroundColor: AppTheme.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Search',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search tasks...',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[900],
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
                          style: TextStyle(color: Colors.grey[400], fontSize: 14),
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
                              Icon(Icons.lightbulb_outline, size: 18, color: Colors.grey[400]),
                              const SizedBox(width: 8),
                              Text(
                                'Suggestions',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (keywords.isEmpty)
                            Text(
                              'No suggestions yet',
                              style: TextStyle(color: Colors.grey[500], fontSize: 14),
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
                                      color: Colors.grey[900],
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.grey[800]!, width: 1),
                                    ),
                                    child: Text(
                                      keyword,
                                      style: const TextStyle(fontSize: 14, color: Colors.white),
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
                          style: TextStyle(color: Colors.grey[400], fontSize: 14),
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
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
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
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        dateStr,
                                        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        status == 'notDone' ? 'Not Done' : status,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: status == 'notDone'
                                              ? AppTheme.netflixRed
                                              : Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right, color: Colors.grey[400]),
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
