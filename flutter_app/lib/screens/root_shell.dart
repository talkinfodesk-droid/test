import 'package:flutter/material.dart';

import 'community_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'workouts_screen.dart';

/// Bottom navigation seen in the recording: Home · Workouts · History · Community.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  static const _screens = <Widget>[
    HomeScreen(),
    WorkoutsScreen(),
    HistoryScreen(),
    CommunityScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.view_agenda_outlined), label: 'Workouts'),
          BottomNavigationBarItem(
              icon: Icon(Icons.show_chart), label: 'History'),
          BottomNavigationBarItem(
              icon: Icon(Icons.groups_outlined), label: 'Community'),
        ],
      ),
    );
  }
}
