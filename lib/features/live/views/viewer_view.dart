import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../../shared/theme/app_theme.dart';
import '../providers/room_provider.dart';

class ViewerView extends ConsumerStatefulWidget {
  const ViewerView({super.key});

  @override
  ConsumerState<ViewerView> createState() => _ViewerViewState();
}

class _ViewerViewState extends ConsumerState<ViewerView> {
  VideoTrack? _remoteVideoTrack;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setupRoom());
  }

  void _setupRoom() {
    final roomState = ref.read(roomProvider);
    if (roomState is! RoomConnected) return;
    roomState.room.addListener(_onRoomChanged);
    _onRoomChanged(); // check for tracks that arrived before listener was added
  }

  void _onRoomChanged() {
    final roomState = ref.read(roomProvider);
    if (roomState is! RoomConnected || !mounted) return;

    VideoTrack? found;
    for (final participant in roomState.room.remoteParticipants.values) {
      for (final pub in participant.videoTrackPublications) {
        if (pub.subscribed && pub.track != null) {
          found = pub.track as VideoTrack;
          break;
        }
      }
      if (found != null) break;
    }

    setState(() => _remoteVideoTrack = found);
  }

  Future<void> _leave() async {
    final roomState = ref.read(roomProvider);
    if (roomState is RoomConnected) {
      roomState.room.removeListener(_onRoomChanged);
    }
    await ref.read(roomProvider.notifier).disconnect();
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  void dispose() {
    final roomState = ref.read(roomProvider);
    if (roomState is RoomConnected) {
      roomState.room.removeListener(_onRoomChanged);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(roomProvider);
    if (roomState is! RoomConnected) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    final roomName = roomState.config.roomName;
    final hostIdentity = roomState.room.remoteParticipants.values
        .firstOrNull
        ?.identity;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Remote video ──
          if (_remoteVideoTrack != null)
            VideoTrackRenderer(_remoteVideoTrack!)
          else
            _WaitingForHost(roomName: roomName),

          // ── Top bar ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // LIVE badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.liveBadge,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: Colors.white, size: 7),
                          SizedBox(width: 5),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Host identity
                    if (hostIdentity != null)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '@$hostIdentity · $roomName',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                    else
                      const Spacer(),
                    const SizedBox(width: 10),
                    // Leave button
                    GestureDetector(
                      onTap: _leave,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom leave button ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: GestureDetector(
                    onTap: _leave,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: const Text(
                        'Leave Stream',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaitingForHost extends StatelessWidget {
  const _WaitingForHost({required this.roomName});
  final String roomName;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D0D0D),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.card,
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.textSecondary.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.live_tv_outlined,
                  color: AppColors.textSecondary, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              roomName,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Waiting for host to go live…',
              style:
                  TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
