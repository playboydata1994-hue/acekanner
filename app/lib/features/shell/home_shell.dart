import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Bottom navigation: Home, Examinations, Classes, Settings.
///
/// Deliberately not a Scaffold: each tab screen is its own Scaffold, so
/// snack bars appear inside that screen and push its floating action button
/// up instead of covering it.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        children: [
          Expanded(
            // The navigation bar below handles the bottom system inset.
            child: MediaQuery.removePadding(
              context: context,
              removeBottom: true,
              child: shell,
            ),
          ),
          NavigationBar(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: (index) =>
                shell.goBranch(index, initialLocation: index == shell.currentIndex),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.assignment_outlined),
                selectedIcon: Icon(Icons.assignment),
                label: 'Exams',
              ),
              NavigationDestination(
                icon: Icon(Icons.groups_outlined),
                selectedIcon: Icon(Icons.groups),
                label: 'Classes',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Holds the four tab navigators. Each tab gets its own [ScaffoldMessenger]
/// (messages stay in the tab that showed them) and hidden tabs neither animate
/// nor take part in hero transitions.
class BranchStack extends StatelessWidget {
  const BranchStack({super.key, required this.currentIndex, required this.children});

  final int currentIndex;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: currentIndex,
      children: [
        for (var i = 0; i < children.length; i++)
          HeroMode(
            enabled: i == currentIndex,
            child: TickerMode(
              enabled: i == currentIndex,
              child: ScaffoldMessenger(child: children[i]),
            ),
          ),
      ],
    );
  }
}
