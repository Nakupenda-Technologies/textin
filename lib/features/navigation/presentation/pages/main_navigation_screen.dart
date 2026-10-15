import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../profile/presentation/pages/profile_screen.dart';
import '../../../texting/presentation/pages/texting_inbox_screen.dart';
import '../../../whispers/presentation/pages/whispers_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  static const _tabs = [
    TextingInboxScreen(),
    WhispersScreen(),
    ProfileScreen(),
  ];

  int _index = 0;
  final Set<int> _visited = {0};

  void _select(int index) {
    setState(() {
      _index = index;
      _visited.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          for (var i = 0; i < _tabs.length; i++)
            _visited.contains(i) ? _tabs[i] : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _select,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(PhosphorIconsRegular.chatCircleDots),
            activeIcon: Icon(PhosphorIconsFill.chatCircleDots),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(PhosphorIconsRegular.waveform),
            activeIcon: Icon(PhosphorIconsFill.waveform),
            label: 'Whispers',
          ),
          BottomNavigationBarItem(
            icon: Icon(PhosphorIconsRegular.userCircle),
            activeIcon: Icon(PhosphorIconsFill.userCircle),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
