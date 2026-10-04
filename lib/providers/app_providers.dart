import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibe_check/services/firebase_services.dart';
import '../models/confession_model.dart';
import '../models/quest_model.dart';

// UI STATE (Notifier-based, no legacy StateProvider)

class BottomNavIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void select(int index) => state = index;
}

final bottomNavIndexProvider = NotifierProvider<BottomNavIndexNotifier, int>(
  BottomNavIndexNotifier.new,
);

class SelectedVibeTagNotifier extends Notifier<String> {
  @override
  String build() => 'All';
  void select(String tag) => state = tag;
}

final selectedVibeTagProvider =
    NotifierProvider<SelectedVibeTagNotifier, String>(
      SelectedVibeTagNotifier.new,
    );

// SERVICES

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(FirebaseAuth.instance),
);

final firestoreServiceProvider = Provider<FirestoreService>(
  (ref) => FirestoreService(FirebaseFirestore.instance),
);

final currentUidProvider = FutureProvider<String>(
  (ref) => ref.watch(authServiceProvider).ensureSignedIn(),
);

// FIRESTORE STREAMS

final confessionsStreamProvider =
    StreamProvider.autoDispose<List<ConfessionModel>>(
      (ref) => ref.watch(firestoreServiceProvider).confessionsStream(),
    );

final filteredConfessionsProvider =
    Provider.autoDispose<AsyncValue<List<ConfessionModel>>>((ref) {
      final asyncConfessions = ref.watch(confessionsStreamProvider);
      final selectedTag = ref.watch(selectedVibeTagProvider);

      return asyncConfessions.whenData((confessions) {
        if (selectedTag == 'All') return confessions;
        return confessions.where((c) => c.vibeTag == selectedTag).toList();
      });
    });

final questsStreamProvider = StreamProvider.autoDispose<List<QuestModel>>(
  (ref) => ref.watch(firestoreServiceProvider).questsStream(),
);
