import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibe_check/screen/app_theme.dart';
import '../models/quest_model.dart';
import '../providers/app_providers.dart';
import '../services/firebase_services.dart';
import '../widgets/pop_widgets.dart';

const _questColors = [
  AppColors.mint,
  AppColors.lime,
  AppColors.sky,
  AppColors.pink,
];

class QuestsTab extends ConsumerWidget {
  const QuestsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quests = ref.watch(questsStreamProvider);
    final uid = ref.watch(currentUidProvider).value;

    return quests.when(
      data: (items) {
        if (items.isEmpty) {
          return const EmptyState(
            emoji: '🧭',
            title: 'No sidequests yet',
            hint: 'Tap "Host quest" and get people out of their rooms.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 110),
          itemCount: items.length,
          itemBuilder: (context, i) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 20, 10),
            child: _QuestCard(
              quest: items[i],
              uid: uid,
              color: _questColors[i % _questColors.length],
            ),
          ),
        );
      },
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.ink)),
      error: (e, _) => ErrorState(
        message: friendlyError(e),
        onRetry: () => ref.invalidate(questsStreamProvider),
      ),
    );
  }
}

class _QuestCard extends ConsumerStatefulWidget {
  const _QuestCard({
    required this.quest,
    required this.uid,
    required this.color,
  });
  final QuestModel quest;
  final String? uid;
  final Color color;

  @override
  ConsumerState<_QuestCard> createState() => _QuestCardState();
}

class _QuestCardState extends ConsumerState<_QuestCard> {
  bool _busy = false;

  Future<void> _toggleJoin() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final id = await ref.read(currentUidProvider.future);
      await ref.read(firestoreServiceProvider).toggleJoin(widget.quest.id, id);
    } catch (e) {
      if (mounted) showToast(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    if (!await confirmDelete(context, 'quest')) return;
    try {
      await ref.read(firestoreServiceProvider).deleteQuest(widget.quest.id);
    } catch (e) {
      if (mounted) showToast(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final quest = widget.quest;
    final joined = quest.hasJoined(widget.uid);
    final isHost = quest.isHost(widget.uid);
    final full = quest.isFull;

    String label;
    VoidCallback? onPressed = _toggleJoin;
    if (isHost) {
      label = "You're hosting 👑";
      onPressed = () =>
          showToast(context, "You're the host. Delete the quest to cancel it.");
    } else if (joined) {
      label = 'Leave quest';
    } else if (full) {
      label = 'Quest full';
      onPressed = null;
    } else {
      label = 'Join quest';
    }

    final dots = quest.maxSpots.clamp(1, 12);

    return PopCard(
      color: widget.color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'hosted by ${quest.hostName} · ${timeAgo(quest.timestamp)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (isHost)
                GestureDetector(
                  onTap: _delete,
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.ink,
                    size: 22,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            quest.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: popDecoration(Colors.white, pill: true, shadow: 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  size: 15,
                  color: AppColors.ink,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    quest.location,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: List.generate(dots, (i) {
                    final filled = i < quest.participants.length;
                    return Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: filled ? AppColors.ink : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.ink, width: 2),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${quest.participants.length}/${quest.maxSpots}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: full ? AppColors.danger : AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          PopButton(
            label: label,
            loading: _busy,
            color: joined ? Colors.white : AppColors.butter,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}