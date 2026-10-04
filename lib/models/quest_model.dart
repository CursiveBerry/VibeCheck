import 'package:cloud_firestore/cloud_firestore.dart';
import 'confession_model.dart' show readTimestamp, readStringList;

class QuestModel {
  const QuestModel({
    required this.id,
    required this.title,
    required this.location,
    required this.hostName,
    required this.authorId,
    required this.maxSpots,
    required this.participants,
    required this.timestamp,
  });

  final String id;
  final String title;
  final String location;
  final String hostName;
  final String authorId;
  final int maxSpots;

  // Parsing the data back to the app...
  final List<String> participants;
  final DateTime timestamp;

  factory QuestModel.fromMap(String docId, Map<String, dynamic> map) {
    return QuestModel(
      id: docId,
      title: (map['title'] as String?) ?? '',
      location: (map['location'] as String?) ?? '',
      hostName: (map['hostName'] as String?) ?? 'Anon',
      authorId: (map['authorId'] as String?) ?? '',
      maxSpots: (map['maxSpots'] as num?)?.toInt() ?? 4,
      participants: readStringList(map['participants']),
      timestamp: readTimestamp(map['timestamp']),
    );
  }

  // Uploading newly added confessions to firebase...
  Map<String, dynamic> toMap() => {
    'title': title,
    'location': location,
    'hostName': hostName,
    'authorId': authorId,
    'maxSpots': maxSpots,
    'participants': participants,
    'timestamp': FieldValue.serverTimestamp(),
  };

  bool get isFull => participants.length >= maxSpots;
  bool hasJoined(String? uid) => uid != null && participants.contains(uid);
  bool isHost(String? uid) => uid != null && uid.isNotEmpty && authorId == uid;
}
