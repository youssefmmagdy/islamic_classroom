import 'package:flutter/material.dart';
import '../models/course.dart';
import 'tabs/posts_tab_screen.dart';
import 'tabs/assignments_tab_screen.dart';
import 'tabs/sessions_tab_screen.dart';
import 'tabs/users_tab_screen.dart';

class CourseDetailsScreen extends StatefulWidget {
  final Course course;

  const CourseDetailsScreen({super.key, required this.course});

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  int _currentIndex = 0;
  final List<GlobalKey> _tabKeys = [
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
  ];

  void _refreshCurrentTab() {
    // Force rebuild of current tab by updating its key
    setState(() {
      _tabKeys[_currentIndex] = GlobalKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course.name),
        centerTitle: true,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          PostsTabScreen(key: _tabKeys[0], course: widget.course),
          AssignmentsTabScreen(key: _tabKeys[1], course: widget.course),
          SessionsTabScreen(key: _tabKeys[2], course: widget.course),
          UsersTabScreen(key: _tabKeys[3], course: widget.course),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() => _currentIndex = i);
          // Refresh the tab when switching to it
          _refreshCurrentTab();
        },
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'المنشورات'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'الواجبات'),
          BottomNavigationBarItem(icon: Icon(Icons.event_note), label: 'الجلسات'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'المستخدمون'),
        ],
      ),
    );
  }
}
