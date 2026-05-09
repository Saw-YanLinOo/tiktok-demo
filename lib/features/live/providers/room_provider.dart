import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';
import '../models/room_config.dart';
import '../services/token_service.dart';
import '../../../config/env.dart';

// ─────────────────────────────────────────────
// State
// ─────────────────────────────────────────────
sealed class RoomState {}

class RoomIdle extends RoomState {}

class RoomConnecting extends RoomState {}

class RoomConnected extends RoomState {
  RoomConnected({required this.room, required this.config});
  final Room room;
  final RoomConfig config;
}

class RoomError extends RoomState {
  RoomError(this.message);
  final String message;
}

// ─────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────
class RoomNotifier extends StateNotifier<RoomState> {
  RoomNotifier() : super(RoomIdle());

  Room? _room;

  Future<void> connect(RoomConfig config) async {
    state = RoomConnecting();
    try {
      final token = TokenService.generate(config);

      _room = Room(
        roomOptions: const RoomOptions(
          defaultCameraCaptureOptions: CameraCaptureOptions(
            cameraPosition: CameraPosition.front,
          ),
          defaultAudioCaptureOptions: AudioCaptureOptions(
            noiseSuppression: true,
            echoCancellation: true,
          ),
        ),
      );
      await _room!.connect(Env.livekitUrl, token);

      if (config.isHost) {
        await _room!.localParticipant?.setCameraEnabled(true);
        await _room!.localParticipant?.setMicrophoneEnabled(true);
      }

      state = RoomConnected(room: _room!, config: config);
    } catch (e) {
      await _room?.disconnect();
      _room = null;
      state = RoomError(e.toString());
    }
  }

  Future<void> toggleMic() async {
    final current = state;
    if (current is! RoomConnected) return;
    final isEnabled = current.room.localParticipant?.isMicrophoneEnabled() ?? false;
    await current.room.localParticipant?.setMicrophoneEnabled(!isEnabled);
    // Force UI rebuild by re-emitting the same state
    state = RoomConnected(room: current.room, config: current.config);
  }

  Future<void> disconnect() async {
    await _room?.disconnect();
    _room = null;
    state = RoomIdle();
  }

  @override
  void dispose() {
    _room?.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────
final roomProvider = StateNotifierProvider<RoomNotifier, RoomState>(
  (ref) => RoomNotifier(),
);
