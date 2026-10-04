import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibe_check/screen/app_theme.dart';
import 'package:vibe_check/widgets/pop_widgets.dart';
import '../providers/app_providers.dart';
import '../widgets/create_modal.dart';
import 'home_tab.dart';
import 'quests_tab.dart';

class MainLayout extends ConsumerWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(bottomNavIndexProvider);
    // Kick off anonymous sign-in as soon as the app opens.
    ref.watch(currentUidProvider);

    final isHome = index == 0;
    final accent = isHome ? AppColors.pink : AppColors.mint;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        title: Text(
          isHome ? 'vibecheck' : 'sidequests',
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Sticker(
              label: isHome ? 'campus feed' : 'go touch grass',
              color: accent,
              angle: -0.06,
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(2),
          child: ColoredBox(color: AppColors.ink, child: SizedBox(height: 2)),
        ),
      ),

      // IndexedStack keeps both tabs alive: scroll position and Firestore streams survive tab switches.
      body: IndexedStack(
        index: index,
        children: [HomeTab(), const QuestsTab()],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [
            BoxShadow(color: AppColors.ink, offset: Offset(3, 3)),
          ],
        ),
        child: FloatingActionButton.extended(
          elevation: 0,
          highlightElevation: 0,
          backgroundColor: accent,
          foregroundColor: AppColors.ink,
          shape: const StadiumBorder(
            side: BorderSide(color: AppColors.ink, width: 2),
          ),
          icon: const Icon(Icons.add_rounded),
          label: Text(
            isHome ? 'Spill tea' : 'Host quest',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          onPressed: () => showCreateModal(context, index),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.paper,
          border: Border(top: BorderSide(color: AppColors.ink, width: 2)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: _NavItem(
                    emoji: '💬',
                    label: 'Vibes',
                    color: AppColors.pink,
                    selected: isHome,
                    onTap: () =>
                        ref.read(bottomNavIndexProvider.notifier).select(0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NavItem(
                    emoji: '🧭',
                    label: 'SideQuests',
                    color: AppColors.mint,
                    selected: !isHome,
                    onTap: () =>
                        ref.read(bottomNavIndexProvider.notifier).select(1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.emoji,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration:
            popDecoration(
              selected ? color : Colors.transparent,
              pill: true,
              shadow: selected ? 3 : 0,
            ).copyWith(
              border: Border.all(
                color: selected ? AppColors.ink : Colors.transparent,
                width: 2,
              ),
            ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
