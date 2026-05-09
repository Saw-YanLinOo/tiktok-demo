enum RoomRole { host, viewer }

class RoomConfig {
  const RoomConfig({
    required this.roomName,
    required this.role,
    required this.identity,
  });

  final String roomName;
  final RoomRole role;
  final String identity;

  bool get isHost => role == RoomRole.host;
}
