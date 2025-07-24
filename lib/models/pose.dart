// lib/models/pose.dart
class Pose {
  final int id;
  final int servo1;
  final int servo2;
  final int servo3;
  final int servo4;

  Pose({
    required this.id,
    required this.servo1,
    required this.servo2,
    required this.servo3,
    required this.servo4,
  });

  factory Pose.fromJson(Map<String, dynamic> json) {
    return Pose(
      id: int.parse(json['id']),
      servo1: int.parse(json['servo1']),
      servo2: int.parse(json['servo2']),
      servo3: int.parse(json['servo3']),
      servo4: int.parse(json['servo4']),
    );
  }
}