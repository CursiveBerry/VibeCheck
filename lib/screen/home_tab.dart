import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibe_check/screen/app_theme.dart';
import 'package:vibe_check/widgets/pop_widgets.dart';
import '../models/confession_model.dart';
import '../providers/app_providers.dart';
import '../services/firebase_services.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final confessions = ref.watch(filteredConfessionsProvider);
    final selectedTag = ref.watch(selectedVibeTagProvider);
    final uid = ref.watch(currentUidProvider).value;
    final filters = ['All', ...vibeStyles.map((v) => v.label)];

    return Column(
      children: [
        SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            itemCount: filters.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final tag = filters[i];
              final style = tag == 'All' ? null : vibeStyleFor(tag);
              return PopChip(
                label: style == null ? 'All' : '${style.emoji} $tag',
                selected: selectedTag == tag,
                color: style?.color ?? AppColors.lime,
                onTap: () =>
                    ref.read(selectedVibeTagProvider.notifier).select(tag),
              );
            },
          ),
        ),
        Expanded(
          child: confessions.when(
            data: (items) {
              if (items.isEmpty) {
                return EmptyState(
                  emoji: '🫖',
                  title: selectedTag == 'All'
                      ? 'No confessions yet'
                      : 'Nothing in $selectedTag yet',
                  hint: 'Tap "Spill tea" and post the first one.',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.only(top: 4, bottom: 110),
                itemCount: items.length,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 20, 10),
                  child: _ConfessionCard(item: items[i], uid: uid),
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.ink),
            ),
            error: (e, _) => ErrorState(
              message: friendlyError(e),
              onRetry: () => ref.invalidate(confessionsStreamProvider),
            ),
          ),
        ),
      ],
    );
  }
}

class _ConfessionCard extends ConsumerWidget {
  const _ConfessionCard({required this.item, required this.uid});
  final ConfessionModel item;
  final String? uid;

  Future<void> _vote(BuildContext context, WidgetRef ref) async {
    try {
      final id = await ref.read(currentUidProvider.future);
      await ref.read(firestoreServiceProvider).toggleUpvote(item.id, id);
    } catch (e) {
      if (context.mounted) showToast(context, friendlyError(e));
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    if (!await confirmDelete(context, 'confession')) return;
    try {
      await ref.read(firestoreServiceProvider).deleteConfession(item.id);
    } catch (e) {
      if (context.mounted) showToast(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = vibeStyleFor(item.vibeTag);
    final voted = item.isUpvotedBy(uid);

    return PopCard(
      color: style.color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: popDecoration(Colors.white, pill: true, shadow: 0),
                child: Text(style.emoji, style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.anonName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      timeAgo(item.timestamp),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              Sticker(label: item.vibeTag),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            item.content,
            style: const TextStyle(
              fontSize: 17,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              GestureDetector(
                onTap: () => _vote(context, ref),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: popDecoration(
                    voted ? AppColors.tangerine : Colors.white,
                    pill: true,
                    shadow: voted ? 0 : 3,
                  ),
                  child: Text(
                    '🔥 ${item.upvotes}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              if (item.isOwnedBy(uid))
                IconButton(
                  tooltip: 'Delete',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.ink,
                  ),
                  onPressed: () => _delete(context, ref),
                ),
            ],
          ),
        ],
      ),
    );
  }
}