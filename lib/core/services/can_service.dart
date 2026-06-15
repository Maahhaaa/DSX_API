import 'package:firebase_database/firebase_database.dart';

class CANMessage {
  final String canId;
  final double timestamp;
  final int byte1, byte2, byte3, byte4, byte5, byte6, byte7, byte8;
  final double timeDiff;
  final String label;

  CANMessage({
    required this.canId,
    required this.timestamp,
    required this.byte1,
    required this.byte2,
    required this.byte3,
    required this.byte4,
    required this.byte5,
    required this.byte6,
    required this.byte7,
    required this.byte8,
    required this.timeDiff,
    required this.label,
  });

  factory CANMessage.fromMap(Map map) => CANMessage(
    canId: map['can_id']?.toString() ?? '0x0',
    timestamp: _toDouble(map['timestamp']),
    byte1: _toInt(map['byte1']),
    byte2: _toInt(map['byte2']),
    byte3: _toInt(map['byte3']),
    byte4: _toInt(map['byte4']),
    byte5: _toInt(map['byte5']),
    byte6: _toInt(map['byte6']),
    byte7: _toInt(map['byte7']),
    byte8: _toInt(map['byte8']),
    timeDiff: _toDouble(map['time_diff']),
    label: map['label']?.toString() ?? 'unknown',
  );
}

class CANStats {
  final double messageFrequency;
  final int totalMessages;
  final int dosCount;
  final int normalCount;
  final String? lastAlert;

  CANStats({
    required this.messageFrequency,
    required this.totalMessages,
    required this.dosCount,
    required this.normalCount,
    this.lastAlert,
  });

  factory CANStats.fromMap(Map map) => CANStats(
    messageFrequency: _toDouble(map['message_frequency']),
    totalMessages: _toInt(map['total_messages']),
    dosCount: _toInt(map['dos_count']),
    normalCount: _toInt(map['normal_count']),
    lastAlert: map['last_alert']?.toString(),
  );
}

class CANService {
  final _db = FirebaseDatabase.instance;

  Stream<bool> connectedStream() {
    return _db.ref('.info/connected').onValue.map(
      (event) => event.snapshot.value == true,
    );
  }

  // Live latest messages. orderByKey avoids requiring a timestamp index in RTDB rules.
  Stream<List<CANMessage>> messagesStream() {
    return _db
        .ref('can_messages')
        .orderByKey()
        .limitToLast(50)
        .onValue
        .map((event) => _messagesFromSnapshotValue(event.snapshot.value));
  }

  Future<List<CANMessage>> latestMessagesOnce() async {
    final snapshot = await _db
        .ref('can_messages')
        .orderByKey()
        .limitToLast(50)
        .get();
    return _messagesFromSnapshotValue(snapshot.value);
  }

  // only attack messages
  Stream<List<CANMessage>> alertsStream() {
    return messagesStream().map(
      (msgs) => msgs.where((m) => m.label.toLowerCase() != 'normal').toList(),
    );
  }

  // stats (frequency, counts, last alert)
  Stream<CANStats> statsStream() {
    return _db.ref('stats').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null || data is! Map) {
        return CANStats(
          messageFrequency: 0,
          totalMessages: 0,
          dosCount: 0,
          normalCount: 0,
        );
      }
      return CANStats.fromMap(Map.from(data));
    });
  }

  Future<CANStats> latestStatsOnce() async {
    final snapshot = await _db.ref('stats').get();
    final data = snapshot.value;
    if (data == null || data is! Map) {
      return CANStats(
        messageFrequency: 0,
        totalMessages: 0,
        dosCount: 0,
        normalCount: 0,
      );
    }
    return CANStats.fromMap(Map.from(data));
  }
}

List<CANMessage> _messagesFromSnapshotValue(Object? value) {
  if (value == null || value is! Map) return [];
  return value.values
      .whereType<Map>()
      .map((e) => CANMessage.fromMap(Map.from(e)))
      .toList()
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
}

double _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _toInt(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
