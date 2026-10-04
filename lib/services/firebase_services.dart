import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/confession_model.dart';
import '../models/quest_model.dart';

// An error whose message is safe to show to the user as-is.
class AppException implements Exception {
  const AppException(this.message);
  final String message;
  @override
  String toString() => message;
}

String friendlyError(Object e) {
  if (e is AppException) return e.message;
  if (e is FirebaseException && e.code == 'permission-denied') {
    return 'Firestore rules blocked that. Check your security rules.';
  }
  return 'Something broke. Check your connection and try again.';
}

// Auth: every device gets an anonymous account so votes / joins / ownership are tied to a stable user id instead of a random name.

class AuthService {
  AuthService(this._auth);
  final FirebaseAuth _auth;
  static String? _sessionFallbackId;

  Future<String> ensureSignedIn() async {
    final existing = _auth.currentUser;
    if (existing != null) return existing.uid;
    try {
      final cred = await _auth.signInAnonymously();
      final user = cred.user;
      if (user != null) return user.uid;
    } catch (e) {
      debugPrint('Anonymous sign-in failed: $e');
    }
    // Fallback
    return _sessionFallbackId ??=
        'guest_${DateTime.now().microsecondsSinceEpoch}';
  }
}

// Firestore: all reads/writes live here, widgets never touch Firestore.

class FirestoreService {
  FirestoreService(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _confessions =>
      _db.collection('confessions');
  CollectionReference<Map<String, dynamic>> get _quests =>
      _db.collection('quests');
  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  Stream<List<ConfessionModel>> confessionsStream() => _confessions
      .orderBy('timestamp', descending: true)
      .limit(100)
      .snapshots()
      .map(
        (s) =>
            s.docs.map((d) => ConfessionModel.fromMap(d.id, d.data())).toList(),
      );

  Stream<List<QuestModel>> questsStream() => _quests
      .orderBy('timestamp', descending: true)
      .limit(100)
      .snapshots()
      .map(
        (s) => s.docs.map((d) => QuestModel.fromMap(d.id, d.data())).toList(),
      );

  // ---- Confessions ----
  Future<void> addConfession({
    required String content,
    required String vibeTag,
    required String anonName,
    required String uid,
  }) async {
    final confession = ConfessionModel(
      id: '',
      content: content,
      vibeTag: vibeTag,
      anonName: anonName,
      authorId: uid,
      upvotes: 0,
      upvotedBy: const [],
      timestamp: DateTime.now(),
    );
    await _confessions.add(confession.toMap());
  }

  /// Toggle: one fire per user. Transaction avoids lost updates when several people tap at once.

  Future<void> toggleUpvote(String confessionId, String uid) {
    return _db.runTransaction<void>((tx) async {
      final ref = _confessions.doc(confessionId);
      final snap = await tx.get(ref);
      final data = snap.data();
      if (data == null) throw const AppException('That post is gone.');
      final voters = readStringList(data['upvotedBy']);
      if (voters.contains(uid)) {
        tx.update(ref, {
          'upvotedBy': FieldValue.arrayRemove([uid]),
          'upvotes': FieldValue.increment(-1),
        });
      } else {
        tx.update(ref, {
          'upvotedBy': FieldValue.arrayUnion([uid]),
          'upvotes': FieldValue.increment(1),
        });
      }
    });
  }

  Future<void> deleteConfession(String id) => _confessions.doc(id).delete();

  // ---- Quests ----
  Future<void> addQuest({
    required String title,
    required String location,
    required String hostName,
    required int maxSpots,
    required String uid,
  }) async {
    final quest = QuestModel(
      id: '',
      title: title,
      location: location,
      hostName: hostName,
      authorId: uid,
      maxSpots: maxSpots,
      participants: [uid],
      timestamp: DateTime.now(),
    );
    await _quests.add(quest.toMap());
  }

  /// Join / leave with a capacity check inside a transaction so the quest can never be over-booked.

  Future<void> toggleJoin(String questId, String uid) {
    return _db.runTransaction<void>((tx) async {
      final ref = _quests.doc(questId);
      final snap = await tx.get(ref);
      final data = snap.data();
      if (data == null) {
        throw const AppException('That quest no longer exists.');
      }

      final people = readStringList(data['participants']);
      final max = (data['maxSpots'] as num?)?.toInt() ?? 4;

      if (people.contains(uid)) {
        if (data['authorId'] == uid) {
          throw const AppException(
            "You're the host. Delete the quest if you want out.",
          );
        }
        tx.update(ref, {
          'participants': FieldValue.arrayRemove([uid]),
        });
      } else {
        if (people.length >= max) throw const AppException('Quest is full.');
        tx.update(ref, {
          'participants': FieldValue.arrayUnion([uid]),
        });
      }
    });
  }

  Future<void> deleteQuest(String id) => _quests.doc(id).delete();

  // ---- Profile (remembers the nicknames a user picked) ----
  Future<Map<String, dynamic>> getProfile(String uid) async {
    try {
      final snap = await _users.doc(uid).get();
      return snap.data() ?? <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  Future<void> saveProfile(String uid, Map<String, dynamic> data) =>
      _users.doc(uid).set(data, SetOptions(merge: true));
}
