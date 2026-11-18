import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/i18n.dart';
import '../core/state.dart';
import '../widgets/common.dart';
import 'community.dart';
import 'explore.dart';
import 'home.dart';
import 'orders.dart';
import 'profile.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _i = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AppState>().refreshUnread());
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final tabs = <Widget>[
      HomeTab(key: ValueKey('h${app.tick}${app.lang}'), onJump: (i) => setState(() => _i = i)),
      ExploreTab(key: ValueKey('e${app.tick}${app.lang}')),
      CommunityTab(key: ValueKey('c${app.tick}')),
      OrdersTab(key: ValueKey('o${app.tick}')),
      const ProfileTab(),
    ];
    return Scaffold(
      body: IndexedStack(index: _i, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (v) {
          setState(() => _i = v);
          app.refreshUnread();
        },
        destinations: [
          NavigationDestination(icon: const LIcon('house', size: 22), selectedIcon: const LIcon('house', size: 22, color: Color(0xFF5E7A3A)), label: t('home')),
          NavigationDestination(icon: const LIcon('compass', size: 22), selectedIcon: const LIcon('compass', size: 22, color: Color(0xFF5E7A3A)), label: t('explore')),
          NavigationDestination(icon: const LIcon('users', size: 22), selectedIcon: const LIcon('users', size: 22, color: Color(0xFF5E7A3A)), label: t('community')),
          NavigationDestination(icon: const LIcon('ticket', size: 22), selectedIcon: const LIcon('ticket', size: 22, color: Color(0xFF5E7A3A)), label: t('orders')),
          NavigationDestination(icon: const LIcon('user', size: 22), selectedIcon: const LIcon('user', size: 22, color: Color(0xFF5E7A3A)), label: t('profile')),
        ],
      ),
    );
  }
}
