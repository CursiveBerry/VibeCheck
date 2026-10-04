import 'package:cloud_firestore/cloud_firestore.dart';

DateTime readTimestamp(dynamic value) =>
    value is Timestamp ? value.toDate() : DateTime.now();

List<String> readStringList(dynamic value) =>
    value is List ? value.map((e) => e.toString()).toList() : <String>[];

class ConfessionModel {
  const ConfessionModel({
    required this.id,
    required this.content,
    required this.vibeTag,
    required this.anonName,
    required this.authorId,
    required this.upvotes,
    required this.upvotedBy,
    required this.timestamp,
  });

  final String id;
  final String content;
  final String vibeTag;
  final String anonName;
  final String authorId;
  final int upvotes;
  final List<String> upvotedBy;
  final DateTime timestamp;

  // Parsing the data back to the app...
  factory ConfessionModel.fromMap(String docId, Map<String, dynamic> map) {
    final voters = readStringList(map['upvotedBy']);
    return ConfessionModel(
      id: docId,
      content: (map['content'] as String?) ?? '',
      vibeTag: (map['vibeTag'] as String?) ?? 'Stressed',
      anonName: (map['anonName'] as String?) ?? 'Anonymous Ghost 👻',
      authorId: (map['authorId'] as String?) ?? '',
      upvotes: (map['upvotes'] as num?)?.toInt() ?? voters.length,
      upvotedBy: voters,
      timestamp: readTimestamp(map['timestamp']),
    );
  }

  // Uploading newly added confessions to firebase...
  Map<String, dynamic> toMap() => {
    'content': content,
    'vibeTag': vibeTag,
    'anonName': anonName,
    'authorId': authorId,
    'upvotes': 0,
    'upvotedBy': <String>[],
    'timestamp': FieldValue.serverTimestamp(),
  };

  bool isUpvotedBy(String? uid) => uid != null && upvotedBy.contains(uid);
  bool isOwnedBy(String? uid) =>
      uid != null && uid.isNotEmpty && authorId == uid;
}
